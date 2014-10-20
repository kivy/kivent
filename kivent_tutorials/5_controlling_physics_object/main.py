from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import cymunk
import kivent
from random import randint
from math import radians, atan2, degrees
from kivent import GameSystem, texture_manager
from cymunk import PivotJoint, GearJoint, Body
from kivy.properties import NumericProperty, ListProperty
from kivy.vector import Vector

texture_manager.load_atlas('assets/background_objects.atlas')
texture_manager.load_atlas('assets/foreground_objects.atlas')

class TestGame(Widget):
    current_entity = NumericProperty(None)

    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def ensure_startup(self):
        systems_to_check = ['map', 'physics', 'renderer', 'rotate', 'position']
        systems = self.gameworld.systems
        for each in systems_to_check:
            if each not in systems:
                return False
        return True

    def init_game(self, dt):
        if self.ensure_startup():
            self.setup_map()
            self.setup_states()
            self.set_state()
            self.setup_collision_callbacks()
            self.draw_some_stuff()
            Clock.schedule_interval(self.update, 0)
        else:
            Clock.schedule_once(self.init_game)

    def on_touch_down(self, touch):
        gameworld = self.gameworld
        entities = gameworld.entities
        entity = entities[self.current_entity]
        steering = entity.steering
        steering.target = (touch.x, touch.y)

    def draw_some_stuff(self):
        size = Window.size
        for x in range(1):
            pos = (250, 250)
            ship_id = self.create_ship(pos)
            self.current_entity = ship_id

    def no_collide(self, space, arbiter):
        return False

    def setup_collision_callbacks(self):
        systems = self.gameworld.systems
        physics_system = systems['physics']
        physics_system.add_collision_handler(
            1, 2, 
            begin_func=self.no_collide)

    def create_ship(self, pos):
        x_vel = 0
        y_vel = 0
        angle = 0
        angular_velocity = 0
        shape_dict = {'inner_radius': 0, 'outer_radius': 45, 
            'mass': 10, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .0, 
            'collision_type': 1, 'shape_info': shape_dict, 'friction': .7}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 
            'velocity': (x_vel, y_vel), 
            'position': pos, 'angle': angle, 
            'angular_velocity': angular_velocity, 
            'vel_limit': 750, 
            'ang_vel_limit': radians(900), 
            'mass': 50, 'col_shapes': col_shapes}
        steering_component = {
            'turn_speed': 10.0,
            'stability': 900000.0,
            'max_force': 200000.0,
            'speed': 350,
            }
        create_component_dict = {'physics': physics_component, 
            'physics_renderer': {'texture': 'ship7', 'size': (96 , 88)}, 
            'position': pos, 'rotate': 0, 'steering': steering_component}
        component_order = ['position', 'rotate', 
            'physics', 'physics_renderer', 'steering']
        return self.gameworld.init_entity(create_component_dict, component_order)

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer', 'physics_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'physics_renderer',
                'steering'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()
