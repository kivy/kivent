from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty)
from kivy.clock import Clock
from random import randint, random
from kivy.core.window import Window
from math import radians
import kivent_cython  


class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_interval(self.update_fps, .1)

    def update_fps(self, dt):
        self.fps = str(int(Clock.get_fps()))


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def init_game(self, dt):
        self.setup_states()
        Clock.schedule_interval(self.update, 0)
        Clock.schedule_once(self.test_init, .5)

    def setup_map(self):
        self.gameworld.currentmap = self.gameworld.systems['map']

    def test_init(self, dt):
        self.set_state()
        self.setup_map()
        entities = self.gameworld.entities
        for i in range(2000):
            renderer = {'size': (28, 28), 'texture': 'star1'}
            rotate = 0.0
            pos = (random()*800, random()*600)
            x_vel = randint(-100, 100)
            y_vel = randint(-100, 100)
            angle = radians(randint(-360, 360))
            angular_velocity = radians(randint(-150, -150))
            shape_dict = {
                'inner_radius': 0,
                'outer_radius': 14,
                'mass': 50,
                'offset': (0, 0)}
            col_shape = {
                'shape_type': 'circle',
                'elasticity': .5,
                'collision_type': 1,
                'shape_info': shape_dict,
                'friction': 1.0}
            col_shapes = [col_shape]
            physics_component = {
                'main_shape': 'circle',
                'velocity': (x_vel, y_vel),
                'position': pos,
                'angle': angle,
                'angular_velocity': angular_velocity,
                'vel_limit': 250,
                'ang_vel_limit': radians(200),
                'mass': 50, 'col_shapes': col_shapes}
            create_component_dict = {'position': pos,
                'rotate': rotate, 'renderer': renderer,
                'physics': physics_component}
            component_order = ['position', 'rotate',  'physics', 'renderer']
            ent = self.gameworld.init_entity(create_component_dict, component_order)
            particles = {'particle_file': 'assets/pexfiles/engine_burn_effect1.pex',
                'parent': ent, 'offset': 10.}
            p_ent = self.gameworld.init_entity({'particles': particles}, ['particles'])
            particle_comp = entities[p_ent].particles
            particle_comp.system_on = True



    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer', 'particles'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'particles', 'physics'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class BasicApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    BasicApp().run()
