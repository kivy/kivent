
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ListProperty, NumericProperty, 
DictProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from functools import partial
from kivy.graphics.transformation import Matrix
from kivy.graphics import RenderContext


class Entity(object):
    '''Entity is pretty much just a python object. It has an entity_id assigned 
    to it by the GameWorld that will never be changed. load_order is a list
    of components in the order in which they must be initialized.'''

    def __init__(self, entity_id):
        self.entity_id = entity_id
        self.load_order = []


class GameWorld(Widget):
    '''GameWorld is the manager of all Entities and GameSystems in your Game.
    It will be responsible for initializing and removing entities, as well as
    managing which GameSystems are added, removed, and paused.'''
    state = StringProperty('initial')
    '''State is a string property that corresponds to the current state for
    your application in the states dict. It will control the current screen
    of the gamescreenmanager, as well as which systems are currently added or
    removed from canvas or paused.'''
    number_entities = NumericProperty(1)
    '''This is the current number of entities in the system. Do not modify 
    directly, used to generate entity_ids'''
    gamescreenmanager = ObjectProperty(None)
    '''Reference to the GameScreenManager your game will use for UI screens.'''
    currentmap = ObjectProperty(None, allownone = True)
    '''Reference to the current GameMap object'''
    viewport = StringProperty('default_gameview')
    '''system_id of the current GameView'''
    
    def __init__(self, **kwargs):
        cdef list entities
        '''entities is a list of all entity objects, entity_id corresponds
        to position in this list.'''
        cdef dict states
        '''states is a dict of lists of system_ids with keys 'systems_added',
        'systems_removed', 'systems_paused', 'systems_unpaused'''
        cdef list deactivated_entities
        '''list that contains all entity_ids not currently in use'''
        cdef list entities_to_remove
        '''list of entity_ids that will be cleaned up in the next cleanup
        tick'''
        cdef dict systems
        '''dict with keys system_id, can be used to access your gamesystems'''
        self.canvas = RenderContext()
        super(GameWorld, self).__init__(**kwargs)
        self.entities = []
        self.entities.append(Entity(0))
        self.states = {}
        self.deactivated_entities = []
        self.entities_to_remove = []
        self.systems = {}
        self.matrix = Matrix()

    def add_state(self, state_name, systems_added, systems_removed, 
        systems_paused, systems_unpaused, screenmanager_screen):
        '''This function takes in lists of system_ids for systems_added,
        systems_removed, systems_paused, and systems_unpaused. state_name, and 
        screenmanager_screen are strings corresponding to the name of this 
        state and the name of the screen for gamescreenmanager to use.
        '''
        self.states[state_name] = {'systems_added': systems_added, 
            'systems_removed': systems_removed, 
            'systems_paused': systems_paused, 
            'systems_unpaused': systems_unpaused}
        self.gamescreenmanager.states[state_name] = screenmanager_screen

    def on_state(self, instance, value):
        '''State change is handled here, systems will be added or removed
        in the order that they are listed. This allows control over the 
        arrangement of rendering layers. Later systems will be rendered on top
        of early.'''
        state_dict = self.states[value]
        gamescreenmanager = self.gamescreenmanager
        gamescreenmanager.state = value
        systems = self.systems
        children = self.children
        for system in state_dict['systems_added']:
            if systems[system] in children:
                pass
            else:
                self.add_widget(systems[system])
        for system in state_dict['systems_removed']:
            if systems[system] in children:
                self.remove_widget(systems[system])
        for system in state_dict['systems_paused']:
            systems[system].paused = True
        for system in state_dict['systems_unpaused']:
            systems[system].paused = False

    def create_entity(self):
        '''Used internally if there is not an entity currently available in
        deactivated_entities to create a new entity. Do not call directly.'''
        entity = Entity(self.number_entities)
        self.entities.append(entity)
        self.number_entities += 1
        return entity

    def init_entity(self, dict components_to_use, list component_order):
        '''This is the function used to create a new entity. It returns the 
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
        '''This function can be used to schedule the destruction of an entity
        for a time in the future using partial and kivy's Clock.schedule_once
        '''
        self.entities_to_remove.append(entity_id)

    def remove_entity(self, int entity_id):
        '''This function immediately removes an entity from the gameworld.'''
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
        Clock.schedule_once(partial(
            self.add_entity_to_deactivated, entity_id), 1.0)

    def add_entity_to_deactivated(self, int entity_id, dt):
        '''Used internally when entities are removed.'''
        self.deactivated_entities.append(entity_id)

    def update(self, dt):
        '''Call the update function in order to advance time in your gameworld.
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

    def update_render_state(self, object viewport):
        '''Used internally by gameview to update GameWorld canvas, this 
        needs a better architecture in the future as this info should be 
        contained inside GameView instead'''
        camera_pos = viewport.camera_pos
        camera_size = viewport.size
        proj = self.matrix.view_clip(
            -camera_pos[0], camera_size[0] + -camera_pos[0], 
            -camera_pos[1], camera_size[1] + -camera_pos[1], 0., 100, 0)
        self.canvas['projection_mat'] = proj

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
        '''Used to delete a GameSystem from the GameWorld'''
        systems = self.systems
        systems[system_id].on_delete_system()
        self.remove_widget(systems[system_id])
        del systems[system_id]

    def add_system(self, widget, dt):
        '''Used internally by add_widget.'''
        self.systems[widget.system_id] = widget
        widget.on_add_system()

    def add_widget(self, widget):
        if isinstance(widget, GameSystem) and widget.system_id not in self.systems:
            Clock.schedule_once(partial(self.add_system, widget))
        super(GameWorld, self).add_widget(widget)
        
    def remove_widget(self, widget):
        if isinstance(widget, GameSystem):
            widget.on_remove_system()
        super(GameWorld, self).remove_widget(widget)
