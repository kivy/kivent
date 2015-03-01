from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint
import kivent_core
from kivent_core.gameworld import GameWorld
from kivent_core.systems.position_systems import PositionSystem2D
from kivent_core.systems.gameview import GameView
from kivent_core.systems.renderers import Renderer
from kivent_core.managers.resource_managers import texture_manager
from kivy.properties import StringProperty
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
        for x in range(100000):
            pos = randint(0, 800), randint(0, 800)
            create_dict = {
                'position': pos,
                'renderer': {'texture': 'star1', 'size': (3., 3.)},
            }
            ent = init_entity(create_dict, ['position', 'renderer'])
            #print(self.gameworld.entity_manager.get_entity_ids(ent))


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

class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)


class YourAppNameApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)


if __name__ == '__main__':
    YourAppNameApp().run()
    
    # cProfile.run('YourAppNameApp().run()', 'prof.prof')