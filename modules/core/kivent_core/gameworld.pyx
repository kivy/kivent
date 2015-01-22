# cython: profile=True
from kivy.uix.widget import Widget, WidgetException
from kivy.properties import (StringProperty, ListProperty, NumericProperty, 
DictProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from functools import partial
from kivy.graphics import RenderContext
from gamesystems import GameSystem, PositionSystem2D
from cwidget cimport CWidget
from entity cimport Entity, EntityManager
from system_manager cimport system_manager, DEFAULT_SYSTEM_COUNT, DEFAULT_COUNT
from membuffer cimport Buffer, memrange, IndexedMemoryZone, MemoryZone

def test_gameworld():

    gameworld = GameWorld()
    gameworld.zones = {'test': 1000, 'general': 1000, 'test2': 1000}
    pos_system = PositionSystem2D()
    pos_system.system_id = 'position'
    pos_system.zones = ['test', 'general']
    gameworld.add_system(pos_system)
    gameworld.allocate()
    entity = gameworld.entities[0]
    print(entity.entity_id)
    init_entity = gameworld.init_entity
    for x in range(150):
        component_list = ['position']
        creation_dict = {'position': (10., 10.)}
        print('making entity', x)
        ent_id = init_entity(creation_dict, component_list)
        print(ent_id)
    for entity in memrange(gameworld.entities):
        print(entity.entity_id, entity.position.x, entity.position.y)


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

        **entities** (list): entities is a list of all entity objects, 
        entity_id corresponds to position in this list.

        **states** (dict): states is a dict of lists of system_ids with keys 
        'systems_added','systems_removed', 'systems_paused', 'systems_unpaused'

        **entities_to_remove** (list): list of entity_ids that will be cleaned 
        up in the next cleanup update tick

        **systems** (dict): dict with keys system_id, can be used to access 
        your gamesystems

    '''
    state = StringProperty('initial')
    gamescreenmanager = ObjectProperty(None)
    zones = DictProperty({})
    size_of_gameworld = NumericProperty(1024)
    size_of_entity_block = NumericProperty(16)
    update_time = NumericProperty(1./60.)
    system_count = NumericProperty(None)
 
    
    def __init__(self, **kwargs):
        self.canvas = RenderContext(use_parent_projection=True,
            use_parent_modelview=True)
        super(GameWorld, self).__init__(**kwargs)
        self.states = {}
        self.state_callbacks = {}
        self.entity_manager = None
        self.entities = None
        self._system_count = DEFAULT_SYSTEM_COUNT
        self.entities_to_remove = []
        self.master_buffer = None

    def ensure_startup(self, list_of_systems):
        cdef dict system_index = system_manager.system_index
        for each in list_of_systems:
            if each not in system_index:
                return False
        return True

    def allocate(self):
        cdef Buffer master_buffer = Buffer(self.size_of_gameworld, 1024, 1)
        self.master_buffer = master_buffer
        master_buffer.allocate_memory()
        real_size_in_kb = master_buffer.real_size//1024
        zones = self.zones
        print(zones)
        if 'general' not in zones:
            zones['general'] = DEFAULT_COUNT

        cdef dict copy_from_obs_dict = {}
        for key in zones:
            copy_from_obs_dict[key] = zones[key]
            system_manager.add_zone(key, zones[key])
        system_count = self.system_count
        if system_count is None:
            system_count = self._system_count
        self.entity_manager = entity_manager = EntityManager(master_buffer, 
            self.size_of_entity_block, copy_from_obs_dict, system_count)
        self.entities = entity_manager.memory_index
        system_names = system_manager.system_index
        systems = system_manager.systems
        cdef MemoryZone memory_zone
        cdef IndexedMemoryZone memory_index
        total_count = 0
        for name in system_names:
            system_manager.configure_system_allocation(name)
            config_dict = system_manager.get_system_config_dict(name)
            system_id = system_names[name]
            system = systems[system_id]
            if system.do_components:
                system.allocate(master_buffer, config_dict)
                memory_index = system.components
                memory_zone = memory_index.memory_zone
                memory_count = memory_zone.block_size_in_kb*memory_zone.count
                total_count += memory_count
                print(name, 'system size in kb is',memory_count)

        print('We will need', total_count, 'for game, we have', 
            real_size_in_kb)
        assert(real_size_in_kb > total_count)


    def init_gameworld(self, list_of_systems, callback=None):
        if self.ensure_startup(list_of_systems):
            self.allocate()
            Clock.schedule_interval(self.update, self.update_time)
            if callback is not None:
                callback()
        else:
            Clock.schedule_once(
                lambda dt: self.init_gameworld(list_of_systems, 
                    callback=callback))

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
        children = self.children
        for system in state_dict['systems_added']:
            _system = system_manager.get_system(system)
            if _system in children:
                pass
            elif _system.gameview is not None:
                gameview_system = system_manager.get_system(_system.gameview)
                if _system in gameview_system.children:
                    pass
                else:
                    gameview_system.add_widget(_system)
            else:
                self.add_widget(_system)
        for system in state_dict['systems_removed']:
            _system = system_manager.get_system(system)
            if _system.gameview is not None:
                gameview = system_manager.get_system(_system.gameview)
                gameview.remove_widget(_system)
            elif _system in children:
                self.remove_widget(_system)
        for system in state_dict['systems_paused']:
            _system = system_manager.get_system(system)
            _system.paused = True
        for system in state_dict['systems_unpaused']:
            _system = system_manager.get_system(system)
            _system.paused = False
        state_callback = self.state_callbacks[value]
        if state_callback is not None:
            state_callback(value, self._last_state)
            self._last_state = value

    def get_entity(self, str zone):
        '''Used internally if there is not an entity currently available in
        deactivated_entities to create a new entity. Do not call directly.'''
        cdef EntityManager entity_manager = self.entity_manager
        entity_id = entity_manager.generate_entity(zone)
        return entity_id

    def init_entity(self, dict components_to_use, list component_order,
        zone='general'):
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
        cdef unsigned int entity_id = self.get_entity(zone)
        cdef Entity entity = self.entities[entity_id]
        entity.load_order = component_order
        cdef unsigned int system_id
        for component in component_order:
            system = system_manager.get_system(component)
            system_id = system_manager.get_system_index(component)
            component_id = system.create_component(
                entity_id, zone, components_to_use[component])
            entity.set_component(component_id, system_id)
        return entity_id

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
        cdef Entity entity = self.entities[entity_id]
        cdef dict systems = self.systems
        cdef EntityManager entity_manager = self.entity_manager
        load_order = entity.load_order
        load_order.reverse()
        for data_system in load_order:    
            systems[data_system].remove_entity(entity_id)
        entity.load_order = []
        entity_manager.remove_entity(entity_id)

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
        cdef dict systems = system_manager.systems
        cdef object system
        for system_index in systems:
            system = systems[system_index]
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
            er(entity.entity_id)

    def delete_system(self, system_id):
        '''
        Args:
            system_id (str): The system_id of the GameSystem to be deleted
            from GameWorld.

        Used to delete a GameSystem from the GameWorld'''
        systems = self.systems
        system = systems[system_id]
        system.on_delete_system()
        if system.do_components:
            system_index = self.get_system_index(system_id)
            self.unused_systems.append(system_index)
            self.systems_index[system_index] = None
        self.remove_widget(system)
        del systems[system_id]

    def get_system_index(self, system_id):
        return self.systems_index.index(system_id)

    def add_system(self, widget):
        '''Used internally by add_widget.'''
        system_index = system_manager.system_index
        if widget.system_id in system_index:
            return
        system_manager.add_system(widget.system_id, widget)
        widget.on_add_system()

    def add_widget(self, widget, index=0, canvas=None):
        systems = system_manager.system_index
        if isinstance(widget, GameSystem):
            if widget.system_id not in systems:
                Clock.schedule_once(lambda dt: self.add_system(widget))
        if not (isinstance(widget, Widget) or isinstance(widget, CWidget)):
            raise WidgetException(
                'add_widget() can be used only with instances'
                ' of the Widget class.')

        widget = widget.__self__
        if widget is self:
            raise WidgetException(
                'Widget instances cannot be added to themselves.')
        parent = widget.parent
        # Check if the widget is already a child of another widget.
        if parent:
            raise WidgetException('Cannot add %r, it already has a parent %r'
                                  % (widget, parent))
        widget.parent = parent = self
        # Child will be disabled if added to a disabled parent.
        if parent.disabled:
            widget.disabled = True

        canvas = self.canvas.before if canvas == 'before' else \
            self.canvas.after if canvas == 'after' else self.canvas

        if index == 0 or len(self.children) == 0:
            self.children.insert(0, widget)
            canvas.add(widget.canvas)
        else:
            canvas = self.canvas
            children = self.children
            if index >= len(children):
                index = len(children)
                next_index = 0
            else:
                next_child = children[index]
                next_index = canvas.indexof(next_child.canvas)
                if next_index == -1:
                    next_index = canvas.length()
                else:
                    next_index += 1

            children.insert(index, widget)
            # We never want to insert widget _before_ canvas.before.
            if next_index == 0 and canvas.has_before:
                next_index = 1
            canvas.insert(next_index, widget.canvas)
        
    def remove_widget(self, widget):
        if isinstance(widget, GameSystem):
            widget.on_remove_system()
        super(GameWorld, self).remove_widget(widget)
