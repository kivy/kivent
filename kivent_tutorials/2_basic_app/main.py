from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint
import kivent_core
from kivent_core.gameworld import GameWorld
from kivent_core.gamesystems import PositionSystem2D
from kivent_core.renderers import texture_manager
import cProfile
texture_manager.load_atlas('assets/background_objects.atlas')
texture_manager.load_image('assets/ship7.png')

class TestGame(Widget):
    def __init__(self, **kwargs):
        print('here')
        super(TestGame, self).__init__(**kwargs)
        print('before gameworld init')
        self.gameworld.init_gameworld(
            ['map', 'renderer', 'position', 'gameview'],
            callback=self.init_game)
        print('gameworld inited')

    def init_game(self):
        print('in setup')
        self.setup_states()
        self.set_state()
        self.draw_some_stuff()


    def draw_some_stuff(self):
        print('drawing some stuff')
        init_entity = self.gameworld.init_entity
        for x in range(500000):
            pos = randint(0, 800), randint(0, 800)
            create_dict = {
                'position': pos,
                'renderer': {'texture': 'star1', 'size': (16., 16.)},
            }
            init_entity(create_dict, ['position', 'renderer'])



    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer'],
            screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    #YourAppNameApp().run()
    cProfile.run('YourAppNameApp().run()', 'prof.prof')