# cython: profile=True
from kivy.uix.widget import Widget
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from kivy.properties import (StringProperty, ListProperty, NumericProperty, 
DictProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from functools import partial
from kivy.graphics import RenderContext
from gamesystems import GameSystem

cdef class Entity:
    '''Entity is a python object that will hold all of the components
    attached to that particular entity. GameWorld is responsible for creating
    and recycling entities. You should never create an Entity directly or 
    modify an entity_id.
    
    **Attributes:**
        **entity_id** (int): The entity_id will be assigned on creation by the
        GameWorld. You will use this number to refer to the entity throughout
        your Game. 

        **load_order** (list): The load order is the order in which GameSystem
        components should be initialized.


    '''
    cdef int _id
    cdef int* _component_ids
    cdef list _load_order
    cdef int _component_count
    cdef dict _systems

    def __cinit__(self, int entity_id, int component_count, dict systems):
        self._id = entity_id
        self._load_order = []
        self._component_count = component_count
        self._component_ids = component_ids = <int *>PyMem_Malloc(
            component_count* sizeof(int))
        self._systems = systems
        if not component_ids:
            raise MemoryError()

    def __dealloc__(self):
        if self._component_ids != NULL:
            PyMem_Free(self._component_ids)

    def __getattr__(self, name):
        system = self._systems[name]
        system_index = system.system_index
        component_index = self._component_ids[system_index]
        return system.components[component_index]

    property entity_id:
        def __get__(self):
            return self._id

    property component_count:

        def __set__(self, int new_count):
            if new_count == self._component_count:
                return
            new_data = <int *>PyMem_Realloc(self._component_ids, 
                new_count * sizeof(int))
            if not new_data:
                raise MemoryError()
            self._component_ids = new_data
            self._component_count = new_count

        def __get__(self):
            return self._component_count

    property load_order:
        def __get__(self):
            return self._load_order

        def __set__(self, list value):
            self._load_order = value


class GameWorld(Widget):
    '''GameWorld is the manager of all Entities and GameSystems in your Game.
    It will be responsible for initializing and removing entities, as well as
    managing which GameSystems are added, removed, and paused.

    **Attributes:**
        **state** (StringProperty): State is a string property that corresponds 
        to the current state for your application in the states dict. It will 
        control the current screen of the gamescreenmanager, as well as which 
        systems are currently added or removed from canvas or paused.

        **number_entities** (NumericProperty): This is the current number of 
        entities in the system. Do not modify directly, used to generate 
        entity_ids.

        **gamescreenmanager** (ObjectProperty): Reference to the 
        GameScreenManager your game will use for UI screens.

        **currentmap** (ObjectProperty): Reference to the current GameMap 
        object

        **entities** (list): entities is a list of all entity objects, 
        entity_id corresponds to position in this list.

        **states** (dict): states is a dict of lists of system_ids with keys 
        'systems_added','systems_removed', 'systems_paused', 'systems_unpaused'

        **deactivated_entities** (list): list that contains all entity_ids not 
        currently in use

        **entities_to_remove** (list): list of entity_ids that will be cleaned 
        up in the next cleanup update tick

        **systems** (dict): dict with keys system_id, can be used to access 
        your gamesystems

    '''
    state = StringProperty('initial')
    number_entities = NumericProperty(1)
    gamescreenmanager = ObjectProperty(None)
    currentmap = ObjectProperty(None, allownone = True)
 
    
    def __init__(self, **kwargs):
        cdef list entities
        cdef dict states
        cdef list deactivated_entities
        cdef list entities_to_remove
        cdef dict systems
        cdef list system_index
        self.canvas = RenderContext(use_parent_projection=True,
            use_parent_modelview=True)
        super(GameWorld, self).__init__(**kwargs)
        self.entities = []
        self.entities.append(Entity(0))
        self.states = {}
        self.deactivated_entities = []
        self.entities_to_remove = []
        self.systems = {}
        self.systems_index = []
        self.unused_systems = []
        self.system_count = 0
        self.state_callbacks = {}


    def add_state(self, state_name, screenmanager_screen=None, 
        systems_added=None, systems_removed=None, systems_paused=None, 
        systems_unpaused=None, on_change_callback=None):
        '''
        Args:
            state_name (str): Name for this state, should be unique.

            screenmanager_screen (str): Name of the screen for 
            GameScreenManager to make current when this state is transitioned
            into.

            systems_added (list): List of system_id that should be added
            to the GameWorld canvas when this state is transitioned into.

            systems_removed (list): List of system_id that should be removed
            from the GameWorld canvas when this state is transitioned into.

            systems_paused (list): List of system_id that will be paused
            when this state is transitioned into.

            systems_unpaused (list): List of system_id that will be unpaused 
            when this state is transitioned into.

            on_change_callback (object): Callback function that will receive
            args of state_name, previous_state_name. The callback
            will run after the state change has occured


        This function adds a new state for your GameWorld that will help you
        organize which systems are active in canvas, paused, or unpaused,
        and help you link that up to a Screen for the GameScreenManager
        so that you can sync your UI and game logic.
        '''
        if systems_added is None:
            systems_added = []
        if systems_removed is None:
            systems_removed = []
        if systems_paused is None:
            systems_paused = []
        if systems_unpaused is None:
            systems_unpaused = []
        self.states[state_name] = {'systems_added': systems_added, 
            'systems_removed': systems_removed, 
            'systems_paused': systems_paused, 
            'systems_unpaused': systems_unpaused}
        self.gamescreenmanager.states[state_name] = screenmanager_screen
        self.state_callbacks[state_name] = on_change_callback
        self._last_state = 'initial'

    def on_state(self, instance, value):
        '''State change is handled here, systems will be added or removed
        in the order that they are listed. This allows control over the 
        arrangement of rendering layers. Later systems will be rendered on top
        of earlier.'''
        try:
            state_dict = self.states[value]
        except KeyError: 
            self.state = 'initial'
            self._last_state = 'initial'
            print('State does not exist, resetting to initial')
            return

        gamescreenmanager = self.gamescreenmanager
        gamescreenmanager.state = value
        systems = self.systems
        children = self.children
        for system in state_dict['systems_added']:
            _system = systems[system]
            if _system in children:
                pass
            elif _system.gameview is not None:
                gameview_system = systems[_system.gameview]
                if _system in gameview_system.children:
                    pass
                else:
                    gameview_system.add_widget(_system)
            else:
                self.add_widget(_system)
        for system in state_dict['systems_removed']:
            _system = systems[system]
            if _system.gameview is not None:
                gameview = systems[_system.gameview]
                gameview.remove_widget(_system)
            elif _system in children:
                self.remove_widget(_system)
        for system in state_dict['systems_paused']:
            systems[system].paused = True
        for system in state_dict['systems_unpaused']:
            systems[system].paused = False
        state_callback = self.state_callbacks[value]
        if state_callback is not None:
            state_callback(value, self._last_state)
            self._last_state = value

    def create_entity(self):
        '''Used internally if there is not an entity currently available in
        deactivated_entities to create a new entity. Do not call directly.'''
        entity = Entity(self.number_entities)
        self.entities.append(entity)
        self.number_entities += 1
        return entity

    def init_entity(self, dict components_to_use, list component_order):
        '''
        Args:
            components_to_use (dict): A dict where keys are the system_id and
            values correspond to the component creation args for that 
            GameSystem.

            component_order (list): Should contain all system_id in
            components_to_use arg, ordered in the order you want component
            initialization to happen.

        This is the function used to create a new entity. It returns the 
        entity_id of the created entity. components_to_use is a dict of 
        system_id, args to generate_component function. component_order is
        the order in which the components should be initialized'''
        cdef list deactivated_entities = self.deactivated_entities
        if deactivated_entities == []:
            entity = self.create_entity()
        else:
            entity = self.entities[deactivated_entities.pop()]
        cdef dict systems = self.systems
        entity.load_order = component_order
        for component in component_order:
            systems[component].create_component(entity, 
                components_to_use[component])
        return entity.entity_id

    def timed_remove_entity(self, int entity_id, dt):
        '''
        Args:
            entity_id (int): The entity_id of the Entity to be removed from
            the GameWorld

            dt (float): Time argument passed by Kivy's Clock.schedule

        This function can be used to schedule the destruction of an entity
        for a time in the future using partial and kivy's Clock.schedule_once
        '''
        self.entities_to_remove.append(entity_id)

    def remove_entity(self, int entity_id):
        '''
        Args:
            entity_id (int): The entity_id of the Entity to be removed from
            the GameWorld

        This function immediately removes an entity from the gameworld.
        '''
        if entity_id in self.deactivated_entities:
            return
        cdef object entity = self.entities[entity_id]
        cdef list components_to_delete = []
        cdef dict systems = self.systems
        cdef str data
        cdef str component
        ca = components_to_delete.append
        load_order = entity.load_order
        load_order.reverse()
        for data_system in load_order:    
            ca(data_system)
            systems[data_system].remove_entity(entity_id)
        for component in components_to_delete:
            delattr(entity, component)
        entity.load_order = []
        self.add_entity_to_deactivated(entity_id)

    def add_entity_to_deactivated(self, int entity_id):
        '''Used internally when entities are removed.'''
        self.deactivated_entities.append(entity_id)

    def update_entity_component_arrays(self, int new_count):
        cdef list entities = self.entities
        cdef Entity entity
        for entity in entities:
            entity.component_count = new_count

    def update(self, dt):
        '''
        Args:
            dt (float): Time argument, usually passed in automatically 
            by Kivy's Clock.

        Call the update function in order to advance time in your gameworld.
        Any GameSystem that is updateable and not paused will be updated. 
        Typically you will call this function using either Clock.schedule_once
        or Clock.schedule_interval
        '''
        cdef dict systems = self.systems
        cdef object system
        for system_name in systems:
            system = systems[system_name]
            if system.updateable and not system.paused:
                system._update(dt)
        Clock.schedule_once(self.remove_entities)

    def remove_entities(self, dt):
        '''Used internally to remove entities as part of the update tick'''
        original_ent_remove = self.entities_to_remove
        entities_to_remove = [entity_id for entity_id in original_ent_remove]
        remove_entity = self.remove_entity
        er = original_ent_remove.remove
        for entity_id in entities_to_remove:
            remove_entity(entity_id)
            er(entity_id)

    def clear_entities(self):
        '''Used to clear every entity in the GameWorld.'''
        entities = self.entities
        er = self.remove_entity
        for entity in self.entities:
            er(entity['id'])

    def delete_system(self, system_id):
        '''
        Args:
            system_id (str): The system_id of the GameSystem to be deleted
            from GameWorld.

        Used to delete a GameSystem from the GameWorld'''
        systems = self.systems
        systems[system_id].on_delete_system()
        system_index = self.get_system_index(system_id)
        self.unused_systems.append(system_index)
        self.systems_index[system_index] = None
        self.remove_widget(systems[system_id])
        del systems[system_id]

    def get_system_index(self, system_id):
        return self.systems_index.index(system_id)

    def add_system(self, widget, dt):
        '''Used internally by add_widget.'''
        self.systems[widget.system_id] = widget
        unused_systems = self.unused_systems
        free = unused_systems.pop()
        if free is not None:
            self.systems_index[free] = widget.system_id
            widget.system_index = free
        else:
            self.systems_index.append(widget.system_id)
            widget.system_index = self.system_count
            self.system_count += 1
            self.update_entity_component_arrays(self.system_count)
        widget.on_add_system()

    def add_widget(self, widget):
        systems = self.systems
        if isinstance(widget, GameSystem):
            if widget.system_id not in systems:
                Clock.schedule_once(partial(self.add_system, widget))
        super(GameWorld, self).add_widget(widget)
        
    def remove_widget(self, widget):
        if isinstance(widget, GameSystem):
            widget.on_remove_system()
        super(GameWorld, self).remove_widget(widget)
