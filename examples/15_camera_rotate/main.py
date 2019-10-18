"""15_camera_rotate

This example shows off the ability to rotate the camera.
To do this, simply start the example and use the scroll
wheel to rotate the camera.
"""
from kivy.app import App
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
from kivy.logger import Logger

texture_manager.load_atlas(join(dirname(dirname(abspath(__file__))), 'assets',
    'background_objects.atlas'))



class TestGame(Widget):
    """Test Game to show off camera rotation functionality."""
    
    def on_kv_post(self, *args):
        self.gameworld.init_gameworld(
            ['cymunk_physics', 'rotate_renderer', 'rotate', 'position',
            'cymunk_touch', 'camera1'],
            callback=self.init_game)

    def init_game(self):
        self.setup_states()
        self.set_state()
        self.gameview = self.gameworld.system_manager['camera1']

    def draw_some_stuff(self):
        x, y = int(-self.gameview.camera_pos[0]), int(-self.gameview.camera_pos[1])
        w, h =  int(self.gameview.size[0] + x), int(self.gameview.size[1] + y)
        create_asteroid = self.create_asteroid

        rows_cols = (4, 5)
            
        # Spread out the drawn asteroids all over the non-rotated gamewindow
        rows = 5
        cols = 4
        rows_offset = w * 1 / rows / 2
        cols_offset = h * 1 / cols / 2

        for i in range(rows):
            for j in range(cols):
                ent_id = create_asteroid(
                    (
                        x + w*i/rows + rows_offset,
                        y + h*j/cols + cols_offset
                    )
                )

        self.app.count += 100

    def create_asteroid(self, pos): 
        x_vel = randint(-500, 500)
        y_vel = randint(-500, 500)
        angle = radians(randint(-360, 360))
        angular_velocity = radians(randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 22,
            'mass': 50, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5,
            'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle',
            'velocity': (x_vel,y_vel),
            'position': pos, 'angle': angle,
            'angular_velocity': angular_velocity,
            'vel_limit': 1250,
            'ang_vel_limit': radians(1200),
            'mass': 50, 'col_shapes': col_shapes}
        create_component_dict = {'cymunk_physics': physics_component,
            'rotate_renderer': {'texture': 'asteroid1',
            'size': (45, 45),
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


    def on_touch_down(self, arg):
        """Implement scrollwheel camera rotation."""
        if arg.button == 'scrollup':
            self.gameview.camera_rotate -= radians(3)
        if arg.button == 'scrolldown':
            self.gameview.camera_rotate += radians(3)

        # Afte checking for mouse wheel events, still
        # support dragging asteroids around, as it
        # is quite fun:
        super().on_touch_down(arg)


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