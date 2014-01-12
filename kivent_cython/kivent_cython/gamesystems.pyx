
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ListProperty, NumericProperty, DictProperty, 
BooleanProperty, ObjectProperty)
from kivy.clock import Clock
import math
from kivy.core.window import Window



class GameSystem(Widget):
    system_id = StringProperty('default_id')
    updateable = BooleanProperty(False)
    renderable = BooleanProperty(False)
    paused = BooleanProperty(False)
    active = BooleanProperty(True)
    gameworld = ObjectProperty(None)
    viewport = StringProperty('default_gameview')
    update_time = NumericProperty(1./60.)

    def __init__(self, **kwargs):
        cdef list entity_ids
        cdef float frame_time
        super(GameSystem, self).__init__(**kwargs)
        self.entity_ids = list()
        self.frame_time = 0.0

    def update(self, dt):
        pass

    def _update(self, dt):
        self.frame_time += dt
        update_time = self.update_time
        while self.frame_time >= update_time:
            self.update(update_time)
            self.frame_time -= update_time

    def draw_entity(self, int entity_id):
        pass

    def generate_component_data(self, dict entity_component_dict):
        #this is the load function
        return entity_component_dict

    def create_component(self, int entity_id, dict entity_component_dict):
        cdef dict entity = self.gameworld.entities[entity_id]
        entity[self.system_id] = self.generate_component_data(entity_component_dict)
        self.entity_ids.append(entity_id)

    def generate_entity_component_dict(self, int entity_id):
        cdef dict entity = self.gameworld.entities[entity_id]
        return entity[self.system_id]

    def save_component(self, int entity_id):
        entity_component_dict = self.generate_entity_component_dict(entity_id)
        return entity_component_dict

    def remove_entity(self, int entity_id):
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
    camera_pos = ListProperty((0., 0.))
    window_size = ListProperty((0., 0.))
    margins = ListProperty((0., 0.))
    map_color = ListProperty((1., 1., 1., 1.))
    default_margins = ListProperty((0., 0.))

    def on_map_size(self, instance, value):
        self.check_margins()

    def on_size(self, instance, value):
        self.check_margins()

    def check_margins(self):
        map_size = self.map_size
        window_size = Window.size
        window_larger_x = False
        window_larger_y = False
        if window_size[0] > map_size[0]:
            margin_x = (window_size[0] - map_size[0])/2.
            window_larger_x = True
        if window_size[1] > map_size[1]:
            margin_y = (window_size[1] - map_size[1])/2.
            window_larger_y = True
        if window_larger_x:
            self.margins[0] = margin_x
        if window_larger_y:
            self.margins[1] = margin_y
        if not window_larger_x and not window_larger_y:
            self.margins = self.default_margins
        print 'margins ', self.margins

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
    focus_entity = BooleanProperty(False)
    do_scroll = BooleanProperty(True)
    entity_to_focus = NumericProperty(None, allownone=True)
    focus_position_info_from = StringProperty('cymunk-physics')
    updateable = BooleanProperty(True)
    camera_speed_multiplier = NumericProperty(1)
    paused = BooleanProperty(True)
    has_camera_updated = BooleanProperty(False)
    force_camera_update = BooleanProperty(False)

    def on_entity_to_focus(self, instance, value):
        if value ==  None:
            self.focus_entity = False
        else:
            self.focus_entity = True

    def update(self, dt):
        cdef int entity_to_focus
        cdef float dist_x
        cdef float dist_y
        cdef dict entity
        cdef float camera_speed_multiplier 
        if self.focus_entity:
            entity_to_focus = self.entity_to_focus
            entity = self.gameworld.entities[entity_to_focus]
            position_data = entity[self.focus_position_info_from]['position']
            camera_pos = self.camera_pos
            camera_speed_multiplier = self.camera_speed_multiplier
            size = self.size
            dist_x = -camera_pos[0] - position_data[0] + size[0]*.5
            dist_y = -camera_pos[1] - position_data[1] + size[1]*.5
            if self.lock_scroll:
               dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
            self.camera_pos[0] += dist_x*camera_speed_multiplier*dt
            self.camera_pos[1] += dist_y*camera_speed_multiplier*dt


    def on_size(self, instance, value):
        if self.lock_scroll and self.gameworld.currentmap:
            dist_x, dist_y = self.lock_scroll(0, 0)
            self.camera_pos[0] += dist_x
            self.camera_pos[1] += dist_y

    def forced_camera_update(self):
        systems = self.gameworld.systems
        for system in systems:
            if systems[system].renderable and systems[system].active:
                systems[system].update(1)


    def on_camera_pos(self, instance, value):
        if self.force_camera_update:
            if not self.has_camera_updated:
                self.forced_camera_update()
                self.has_camera_updated = True
            else:
                self.has_camera_updated = False

    def on_touch_move(self, touch):
        if not self.focus_entity and self.do_scroll:
            dist_x = touch.dx
            dist_y = touch.dy
            if math.fabs(dist_x) + math.fabs(dist_y) > 2:
                if self.lock_scroll and self.gameworld.currentmap:
                    dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
                self.camera_pos[0] += dist_x
                self.camera_pos[1] += dist_y

    def lock_scroll(self, float distance_x, float distance_y):
        camera_pos = self.camera_pos
        currentmap = self.gameworld.currentmap
        map_size = currentmap.map_size
        margins = currentmap.margins
        size = self.size
        pos = self.pos
        if camera_pos[0] + distance_x > pos[0] + margins[0]:
            distance_x = pos[0] - camera_pos[0] + margins[0]
        elif camera_pos[0] + map_size[0] + distance_x <= pos[0] + size[0] - margins[0]:
            distance_x = pos[0] + size[0] - margins[0] - camera_pos[0] - map_size[0]

        if camera_pos[1] + distance_y > pos[1] + margins[1]:
            distance_y = pos[1] - camera_pos[1] + margins[1] 
        elif camera_pos[1] + map_size[1] + distance_y <= pos[1] + size[1] - margins[1]:
            distance_y = pos[1] + size[1] - camera_pos[1] - map_size[1]  - margins[1]

        return distance_x, distance_y

