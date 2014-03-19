
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ListProperty, NumericProperty, 
DictProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from functools import partial
from kivy.graphics.transformation import Matrix
from kivy.graphics import RenderContext


class Entity(object):

    def __init__(self, entity_id):
        self.entity_id = entity_id


class GameWorld(Widget):
    state = StringProperty('initial')
    number_entities = NumericProperty(1)
    gamescreenmanager = ObjectProperty(None)
    currentmap = ObjectProperty(None, allownone = True)
    viewport = StringProperty('default_gameview')
    
    def __init__(self, **kwargs):
        cdef list entities
        cdef dict states
        cdef list deactivated_entities
        cdef list entities_to_remove
        cdef dict systems
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
        self.states[state_name] = {'systems_added': systems_added, 
        'systems_removed': systems_removed, 'systems_paused': systems_paused, 
        'systems_unpaused': systems_unpaused}
        self.gamescreenmanager.states[state_name] = screenmanager_screen

    def on_state(self, instance, value):
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
        entity = Entity(self.number_entities)
        self.entities.append(entity)
        self.number_entities += 1
        return entity

    def init_entity(self, dict components_to_use, list component_order):
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
        self.entities_to_remove.append(entity_id)

    def remove_entity(self, int entity_id):
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
        del entity.load_order
        Clock.schedule_once(partial(
            self.add_entity_to_deactivated, entity_id), 1.0)

    def add_entity_to_deactivated(self, int entity_id, dt):
        self.deactivated_entities.append(entity_id)

    def update(self, dt):
        cdef dict systems = self.systems
        cdef object system
        for system_name in systems:
            system = systems[system_name]
            if system.updateable and not system.paused:
                system._update(dt)
        Clock.schedule_once(self.remove_entities)

    def update_render_state(self, object viewport):
        camera_pos = viewport.camera_pos
        camera_size = viewport.size
        proj = self.matrix.view_clip(
            -camera_pos[0], camera_size[0] + -camera_pos[0], 
            -camera_pos[1], camera_size[1] + -camera_pos[1], 0., 100, 0)
        self.canvas['projection_mat'] = proj

    def remove_entities(self, dt):
        entities_to_remove = [entity_id for entity_id in self.entities_to_remove]
        remove_entity = self.remove_entity
        er = self.entities_to_remove.remove
        for entity_id in entities_to_remove:
            remove_entity(entity_id)
            er(entity_id)

    def load_entity(self, entity_dict):
        pass

    def save_entity(self, entity):
        entity_dict = {}
        return entity_dict

    def clear_entities(self):
        entities = self.entities
        er = self.remove_entity
        for entity in self.entities:
            er(entity['id'])

    def remove_system(self, system_id):
        systems = self.systems
        systems[system_id].on_delete_system()
        self.remove_widget(systems[system_id])
        del systems[system_id]

    def add_system(self, widget, dt):
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
