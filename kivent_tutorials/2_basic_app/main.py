from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
import kivent
from kivent import texture_manager

texture_manager.load_atlas('assets/background_objects.atlas')
texture_manager.load_image('assets/ship7.png')


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game, 1.0)

    def init_game(self, dt):
        
        self.setup_map()
        self.setup_states()
        self.set_state()
        self.draw_some_stuff()
        Clock.schedule_interval(self.update, 0)


    def draw_some_stuff(self):
        create_dict = {
            'position': (200., 200.),
            'renderer': {'texture': 'asteroid1', 'size': (64., 64.)},
        }
        self.gameworld.init_entity(create_dict, ['position', 'renderer'])
        create_dict = {
            'position': (200., 275.),
            'renderer': {'texture': 'asteroid1', 'size': (64., 64.)},
        }
        self.gameworld.init_entity(create_dict, ['position', 'renderer'])
        create_dict = {
            'position': (100., 275.),
            'renderer': {'texture': 'ship7', 'size': (100., 64.)},
        }
        self.gameworld.init_entity(create_dict, ['position', 'renderer'])

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

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
    YourAppNameApp().run()
