
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ListProperty, 
    NumericProperty, DictProperty, BooleanProperty, ObjectProperty)
from kivy.clock import Clock
from math import fabs
from kivy.core.window import Window


class Component(object):
    pass


cdef class RotateComponent:
    cdef float _r

    def __cinit__(self, float r):
        self._r = r

    property r:
        def __get__(self):
            return self._r
        def __set__(self, float value):
            self._r = value


cdef class ScaleComponent:
    cdef float _s

    def __cinit__(self, float s):
        self._s = s

    property s:
        def __get__(self):
            return self._s
        def __set__(self, float value):
            self._s = value


cdef class PositionComponent:
    cdef float _x
    cdef float _y
    
    def __cinit__(self, float x, float y):
        self._x = x
        self._y = y

    property x:
        def __get__(self):
            return self._x
        def __set__(self, float value):
            self._x = value

    property y:
        def __get__(self):
            return self._y
        def __set__(self, float value):
            self._y = value


cdef class ColorComponent:
    cdef float _r
    cdef float _g
    cdef float _b
    cdef float _a
    
    def __cinit__(self, float r, float g, float b, float a):
        self._r = r
        self._g = g
        self._b = b
        self._a = a

    property r:
        def __get__(self):
            return self._r
        def __set__(self, float value):
            self._r = value

    property g:
        def __get__(self):
            return self._g
        def __set__(self, float value):
            self._g = value

    property b:
        def __get__(self):
            return self._b
        def __set__(self, float value):
            self._b = value

    property a:
        def __get__(self):
            return self._a
        def __set__(self, float value):
            self._a = value


class GameSystem(Widget):
    system_id = StringProperty('default_id')
    updateable = BooleanProperty(False)
    renderable = BooleanProperty(False)
    paused = BooleanProperty(False)
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

    def generate_component(self, args):
        #this is the function that generates a new component
        new_component = Component()
        for each in args:
            setattr(new_component, each, args[each])
        return new_component

    def create_component(self, object entity, args):
        setattr(entity, self.system_id, self.generate_component(args))
        self.entity_ids.append(entity.entity_id)

    def generate_entity_component_dict(self, int entity_id):
        cdef dict entity = self.gameworld.entities[entity_id]
        return entity[self.system_id]

    def save_component(self, int entity_id):
        entity_component_dict = self.generate_entity_component_dict(entity_id)
        return entity_component_dict

    def remove_entity(self, int entity_id):
        self.entity_ids.remove(entity_id)

    def on_remove_system(self):
        pass

    def on_add_system(self):
        pass

    def on_delete_system(self):
        pass


class PositionSystem(GameSystem):

    def generate_component(self, tuple pos):
        x = pos[0]
        y = pos[1]
        new_component = PositionComponent.__new__(PositionComponent, x, y)
        return new_component

class ScaleSystem(GameSystem):

    def generate_component(self, float s):
        new_component = ScaleComponent.__new__(ScaleComponent, s)
        return new_component

class RotateSystem(GameSystem):

    def generate_component(self, float r):
        new_component = RotateComponent.__new__(RotateComponent, r)
        return new_component


class ColorSystem(GameSystem):

    def generate_component(self, list color):
        r = color[0]
        g = color[1]
        b = color[2]
        a = color[3]
        new_component = ColorComponent.__new__(ColorComponent, r, g, b, a)
        return new_component


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
        cdef PositionComponent position_data
        gameworld = self.gameworld
        if self.focus_entity:
            entity_to_focus = self.entity_to_focus
            entity = gameworld.entities[entity_to_focus]
            position_data = entity.position
            camera_pos = self.camera_pos
            camera_speed_multiplier = self.camera_speed_multiplier
            size = self.size
            dist_x = -camera_pos[0] - position_data._x + size[0]*.5
            dist_y = -camera_pos[1] - position_data._y + size[1]*.5
            if self.lock_scroll:
               dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
            self.camera_pos[0] += dist_x*camera_speed_multiplier*dt
            self.camera_pos[1] += dist_y*camera_speed_multiplier*dt
        gameworld.update_render_state(self)

    def on_size(self, instance, value):
        if self.lock_scroll and self.gameworld.currentmap:
            dist_x, dist_y = self.lock_scroll(0, 0)
            self.camera_pos[0] += dist_x
            self.camera_pos[1] += dist_y
        self.gameworld.update_render_state(self)

    def forced_camera_update(self):
        systems = self.gameworld.systems
        for system in systems:
            sys_obj = systems[system]
            if sys_obj.renderable and not sys_obj.paused:
                sys_obj.update(0.0)

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
            if fabs(dist_x) + fabs(dist_y) > 2:
                if self.lock_scroll and self.gameworld.currentmap:
                    dist_x, dist_y = self.lock_scroll(dist_x, dist_y)
                self.camera_pos[0] += dist_x
                self.camera_pos[1] += dist_y

    def lock_scroll(self, float distance_x, float distance_y):
        currentmap = self.gameworld.currentmap
        size = self.size
        pos = self.pos
        map_size = currentmap.map_size
        margins = currentmap.margins
        camera_pos = self.camera_pos
        cdef float x= pos[0]
        cdef float y = pos[1]
        cdef float w = size[0]
        cdef float h = size[1]
        cdef float mw = map_size[0]
        cdef float mh = map_size[1]
        cdef float marg_x = margins[0]
        cdef float marg_y = margins[1]
        cdef float cx = camera_pos[0]
        cdef float cy = camera_pos[1]

        if cx + distance_x > x + marg_x:
            distance_x = x - cx + marg_x
        elif cx + mw + distance_x <= x + w - marg_x:
            distance_x = x + w - marg_x - cx - mw

        if cy + distance_y > y + marg_y:
            distance_y = y - cy + marg_y 
        elif cy + mh + distance_y <= y + h - marg_y:
            distance_y = y + h - cy - mh  - marg_y

        return distance_x, distance_y

