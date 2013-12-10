#import kivy
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty)
from kivy.clock import Clock
import kivent_cython
import random


class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_interval(self.update_fps, 0)

    def update_fps(self, dt):
        self.fps = str(int(Clock.get_fps()))


class TestGame(Widget):

    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self._init_game)

    def init_game(self, dt):
        self.setup_states()
        self.set_state()
        self.setup_map()
        self.load_star()
        Clock.schedule_interval(self.update, 0)

    def _init_game(self, dt):
        try:
            self.init_game(0)
        except:
            print 'failed: rescheduling init'
            Clock.schedule_once(self._init_game)

    def setup_map(self):
        self.gameworld.currentmap = self.gameworld.systems['map']

    def load_star(self):
        star_graphic = 'star.png'
        star_size = (28, 28)
        for x in xrange(50):
            rand_x = random.randint(0, self.gameworld.currentmap.map_size[0])
            rand_y = random.randint(0, self.gameworld.currentmap.map_size[1])
            create_component_dict = {
                'position': {'position': (rand_x, rand_y)},
                'quadtree_renderer': {'texture': star_graphic,
                                      'size': star_size}}
            component_order = ['position', 'quadtree_renderer']
            self.gameworld.init_entity(create_component_dict, component_order)

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(
            state_name='main',
            systems_added=['quadtree_renderer'],
            systems_removed=[],
            systems_paused=[],
            systems_unpaused=['quadtree_renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class BasicApp(App):
    def build(self):
        pass

if __name__ == '__main__':
    BasicApp().run()
