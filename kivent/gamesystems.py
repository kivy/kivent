
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ListProperty, NumericProperty, DictProperty, 
BooleanProperty, ObjectProperty)
from kivy.clock import Clock
import math


class GameSystem(Widget):
    system_id = StringProperty('default_id')
    updateable = BooleanProperty(False)
    renderable = BooleanProperty(False)
    paused = BooleanProperty(False)
    active = BooleanProperty(True)
    gameworld = ObjectProperty(None)
    viewport = StringProperty('default_gameview')

    def __init__(self, **kwargs):
        super(GameSystem, self).__init__(**kwargs)
        self.entity_ids = list()

    def update(self, dt):
        pass

    def draw_entity(self, entity_id):
        pass

    def generate_component_data(self, entity_component_dict):
        #this is the load function
        return entity_component_dict

    def create_component(self, entity_id, entity_component_dict):
        entity = self.gameworld.entities[entity_id]
        entity[self.system_id] = self.generate_component_data(entity_component_dict)
        if self.renderable:
            self.draw_entity(entity_id)
        self.entity_ids.append(entity_id)

    def generate_entity_component_dict(self, entity_id):
        #This is the save function
        entity = self.gameworld.entities[entity_id]
        return entity[self.system_id]

    def save_component(self, entity_id):
        entity_component_dict = self.generate_entity_component_dict(entity_id)
        return entity_component_dict

    def remove_entity(self, entity_id):
        self.entity_ids.remove(entity_id)

    def on_init_system(self):
        pass

    def on_remove_system(self):
        self.active = False

    def on_add_system(self):
        self.active = True

    def on_delete_system(self):
        pass

class GameMap(GameSystem):
    system_id = StringProperty('default_map')
    map_size = ListProperty((2000., 2000.))

    def on_add_system(self):
        super(GameMap, self).on_add_system()
        if self.gameworld:
            self.gameworld.currentmap = self

    def on_remove_system(self):
        super(GameMap, self).on_remove_system()
        if self.gameworld.currentmap == self:
            self.gameworld.currentmap = None


class GameView(GameSystem):
    system_id = StringProperty('default_gameview')
    lock_scroll = BooleanProperty(True)
    camera_pos = ListProperty((0, 0))
    do_scroll = BooleanProperty(True)

    def on_size(self, instance, value):
        if self.lock_scroll and self.gameworld.currentmap:
            dist_x, dist_y = self.lock_scroll(0, 0)
            self.camera_pos[0] += dist_x
            self.camera_pos[1] += dist_y

    def on_camera_pos(self, instance, value):
        systems = self.gameworld.systems
        for system in systems:
            if systems[system].renderable and systems[system].active:
                systems[system].update(None)

    def on_touch_move(self, touch):
        if self.do_scroll:
            dist_x = touch.dx
            dist_y = touch.dy
            if math.fabs(dist_x) + math.fabs(dist_y) > 2:
                if self.lock_scroll and self.gameworld.currentmap:
                    dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
                self.camera_pos[0] += dist_x
                self.camera_pos[1] += dist_y

    def lock_scroll(self, distance_x, distance_y):
        camera_pos = self.camera_pos
        map_size = self.gameworld.currentmap.map_size
        size = self.size
        pos = self.pos

        if camera_pos[0] + distance_x > pos[0]:
            distance_x = pos[0] - camera_pos[0]
        elif camera_pos[0] + map_size[0] + distance_x <= pos[0] + size[0]:
            distance_x = pos[0] + size[0] - camera_pos[0] - map_size[0]

        if camera_pos[1] + distance_y > pos[1]:
            distance_y = pos[1] - camera_pos[1]
        elif camera_pos[1] + map_size[1] + distance_y <= pos[1] + size[1]:
            distance_y = pos[1] + size[1] - camera_pos[1] - map_size[1]

        return distance_x, distance_y