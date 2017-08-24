from random import randint, choice
from math import radians, pi, sin, cos
from functools import partial
from os.path import dirname, join, abspath

from cymunk import Body, PivotJoint
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent_core
import kivent_cymunk
from kivent_core.gameworld import GameWorld
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.systems.renderers import RotateRenderer
from kivent_core.systems.position_systems import PositionSystem2D
from kivent_core.systems.rotate_systems import RotateSystem2D
from kivent_cymunk.interaction import CymunkTouchSystem
from kivy.properties import StringProperty, NumericProperty

def get_asset_path(asset, asset_loc):
    return join(dirname(dirname(abspath(__file__))), asset_loc, asset)

texture_manager.load_image('redcircle.png')
texture_manager.load_image('greencircle.png')
texture_manager.load_image(get_asset_path('blue-tile.png', 'assets'))



class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        self.gameworld.init_gameworld(
            ['cymunk_physics', 'rotate_renderer', 'rotate', 'position',
            'cymunk_touch'],
            callback=self.init_game)

    def init_game(self):
        self.setup_states()
        self.set_state()

        phy = self.gameworld.physics
        phy.space.set_default_collision_handler(begin=self.on_default_collision)

        self.draw_floor()

    def draw_floor(self):
        self.gameworld.init_entity(
                    {'cymunk_physics': {'main_shape': 'box',
                                        'velocity': (0, 0), 
                                        'position': (0, 0),
                                        'angle': 0,
                                        'angular_velocity': 0, 
                                        'ang_vel_limit': 0,
                                        'mass': 0, 
                                        'col_shapes': [{'shape_info': {'width': 100000, 
                                                                       'height': 10, 
                                                                       'mass': 0},
                                                        'shape_type': 'box', 
                                                        'elasticity': 0.8,
                                                        'collision_type': 1, 
                                                        'friction': 0.8}]},
                      'rotate_renderer': {'texture': 'blue-tile',
                                          'size': (100000, 10),
                                          'render': True},
                      'position': (0, 0),
                      'rotate': 0},
                    ['position', 'rotate', 'rotate_renderer', 'cymunk_physics']
                )

    def draw_some_stuff(self):
        size = Window.size
        w, h = size[0], size[1]
        delete_time = 2.5
        create_asteroid = self.create_asteroid
        pos = (randint(0, w), randint(0, h))
        ent_id = create_asteroid(pos)
        self.app.count += 100

    def create_asteroid(self, pos):
        e1 = self.create_body(pos, 100, 'greencircle', mass=10)
        posx, posy = pos
        pos2 = posx, posy - 125
        e2 = self.create_body(pos2, 20, 'redcircle', mass=30, collision_type=0)

        body1 = self.gameworld.entities[e1].cymunk_physics.body
        body2 = self.gameworld.entities[e2].cymunk_physics.body

        pivot = PivotJoint(body1, body2, pos2)
        self.gameworld.physics.space.add(pivot)

    def create_body(self, pos, radius, texture, mass, collision_type=1):
        shape_dict = {'inner_radius': 0, 'outer_radius': radius, 
            'mass': mass, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
            'collision_type': collision_type, 
            'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 
            'velocity': (0, 0), 
            'position': pos, 'angle': 0, 'angular_velocity': 0, 
            'vel_limit': 250, 
            'ang_vel_limit': radians(200), 
            'mass': mass, 'col_shapes': col_shapes}
        create_component_dict = {'cymunk_physics': physics_component, 
            'rotate_renderer': {'texture': texture, 
            'size': (radius*2, radius*2),
            'render': True}, 
            'position': pos, 'rotate': 0, }
        component_order = ['position', 'rotate', 'rotate_renderer', 
            'cymunk_physics',]
        return self.gameworld.init_entity(
            create_component_dict, component_order)

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['rotate_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['rotate_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'

    def on_default_collision(self, arbiter):
        #ignore collision for shapes with collision_type == 0
        for shape in arbiter.shapes:
            if shape.collision_type == 0:
                return False
        return True



class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)

class YourAppNameApp(App):
    count = NumericProperty(0)


if __name__ == '__main__':
    YourAppNameApp().run()
