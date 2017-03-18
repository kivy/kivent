from kivy.app import App
from kivy.logger import Logger
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint, choice
from math import radians, pi, sin, cos
import kivent_core
import kivent_cymunk
from kivent_core.gameworld import GameWorld
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.systems.renderers import RotateRenderer
from kivent_core.systems.position_systems import PositionSystem2D
from kivent_core.systems.rotate_systems import RotateSystem2D
from kivent_cymunk.interaction import CymunkTouchSystem
from kivy.properties import StringProperty, NumericProperty
from functools import partial
from os.path import dirname, join, abspath

texture_manager.load_atlas(join(dirname(dirname(abspath(__file__))), 'assets', 
    'background_objects.atlas'))



class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        self.gameworld.init_gameworld(
            ['cymunk_physics', 'poly_renderer', 'rotate', 'position',  'cymunk_touch' ],
            callback=self.init_game)

    def init_game(self):
        self.setup_states()
        self.set_state()
        self.draw_some_stuff()

    def destroy_created_entity(self, ent_id, dt):
        self.gameworld.remove_entity(ent_id)
        self.app.count -= 1

    def draw_some_stuff(self):

        self.load_svg('objects.svg', self.gameworld)


    def load_svg(self, fname, gameworld):
        mm = gameworld.model_manager
        data = mm.get_model_info_for_svg(fname)

        for info in data['model_info']:
            Logger.debug("adding object with title/element_id=%s/%s", info.title, info.element_id)
            model_name = mm.load_model_from_model_info(info, data['svg_name'])

            pverts = info.path_vertices

            poly_shape = {
                'shape_type': 'poly',
                'elasticity': 0.6,
                'collision_type': 1,
                'friction': 1.0,
                'shape_info': {
                    'mass': 50,
                    'offset': (0, 0),
                    'vertices': pverts
                }

            }
            
            pos = (float(randint(100, 600)), float(randint(100, 400)))
            #pos = (100, 100)

            physics = {
                    'main_shape': 'poly',
                    'velocity': (0, 0),
                    'position': pos,
                    'angle': 0,
                    'angular_velocity': radians(0),
                    'ang_vel_limit': radians(0),
                    'mass': 50, 
                    'col_shapes': [poly_shape]
            }

            create_dict = {
                    'position': pos,
                    'poly_renderer': {'model_key': model_name},
                    'cymunk_physics': physics, 
                    'rotate': radians(0),
            }

            ent = gameworld.init_entity(create_dict, ['position', 'rotate', 'poly_renderer', 'cymunk_physics'])
            self.app.count += 1

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['poly_renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['poly_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


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
