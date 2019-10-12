from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint, choice, randrange
import kivent_core
from kivent_core.gameworld import GameWorld
from kivent_core.systems.position_systems import PositionSystem2D
from kivent_core.systems.renderers import Renderer
from kivent_core.systems.gamesystem import GameSystem
from kivent_core.managers.resource_managers import texture_manager
from kivy.properties import StringProperty, ObjectProperty
from kivy.factory import Factory
from os.path import dirname, join, abspath

texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets', 
    'star1.png'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets', 
    'star2.png'))


class MyAnimationSystem(GameSystem):

    def update(self, dt):
        entities = self.gameworld.entities
        for component in self.components:
            if component is not None:
                entity_id = component.entity_id
                entity = entities[entity_id]
                render_comp = entity.renderer
                if render_comp.texture_key == 'star1':
                    render_comp.texture_key = 'star2'
                else:
                    render_comp.texture_key = 'star1'

Factory.register('MyAnimationSystem', cls=MyAnimationSystem)

class TestGame(Widget):
    def on_kv_post(self, *args):
        self.gameworld.init_gameworld(
            ['color', 'position', 'renderer'],
            callback=self.init_game)
        self.entities = []

    def init_game(self):
        self.setup_states()
        self.set_state()
        self.draw_some_stuff()

    def draw_some_stuff(self):
        init_entity = self.gameworld.init_entity
        for x in range(100):
            self.draw_a_star()

    def draw_a_star(self):
        pos = randint(0, Window.width), randint(0, Window.height)
        create_dict = {
            'position': pos,
            'animation': {},
            'renderer': {'texture': 'star1', 'size': (50., 50.)},
        }
        ent = self.gameworld.init_entity(create_dict, ['position', 'renderer',
            'animation'])
        self.entities.append(ent)
        

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
