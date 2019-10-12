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
from kivent_core.managers.resource_managers import texture_manager
from os.path import dirname, join, abspath

texture_manager.load_atlas(join(dirname(dirname(abspath(__file__))), 'assets', 
    'stars.atlas'))

def lerp(v0, v1, t):
    return (1.-t)*v0 + t * v1

class FadingSystem(GameSystem):
    make_entity = ObjectProperty(None)
    
    def update(self, dt):
        entities = self.gameworld.entities
        for component in self.components:
            if component is not None:
                entity_id = component.entity_id
                entity = entities[entity_id]
                color_comp = entity.color
                component.current_time += dt
                current_time = component.current_time
                fade_out_start = component.fade_out_start
                time = component.time
                fade_out_time = time - fade_out_start
                if current_time >= time:
                    self.gameworld.remove_entity(entity_id)
                    self.make_entity()
                if current_time < fade_out_start:
                    color_comp.a = lerp(0., 255., 
                        current_time / fade_out_start)
                else:
                    color_comp.a = lerp(255., 0., 
                        (current_time - fade_out_start) / fade_out_time)


Factory.register('FadingSystem', cls=FadingSystem)


class TestGame(Widget):
    def on_kv_post(self, *args):
        self.gameworld.init_gameworld(
            ['color', 'position', 'renderer', 'fade'],
            callback=self.init_game)

    def init_game(self):
        self.setup_states()
        self.load_resources()
        self.set_state()
        self.draw_some_stuff()

    def load_resources(self):
        keys = ['star1', 'star2', 'star3', 'star_circle', 'star_square']
        self.model_keys = model_keys = []
        mk_a = model_keys.append
        model_manager = self.gameworld.model_manager
        load_textured_rectangle = model_manager.load_textured_rectangle
        for x in range(100):
            model_key = 'star_m_' + str(x)
            tex_key = choice(keys)
            wh = randrange(1., 7.)
            real_name = load_textured_rectangle(
                'vertex_format_4f', wh, wh, tex_key, model_key)
            mk_a((model_key, tex_key))

    def draw_some_stuff(self):
        init_entity = self.gameworld.init_entity
        for x in range(1000):
            self.draw_a_star()

    def draw_a_star(self):
        model_to_use = choice(self.model_keys)
        pos = randint(0, Window.width), randint(0, Window.height)
        fade_in = randrange(10., 15.)
        fade_out = randrange(10., 15.)
        create_dict = {
            'position': pos,
            'color': (255, 255, 255, 0),
            'renderer': {'texture': model_to_use[1], 
                'model_key': model_to_use[0]},
            'fade': {'time': fade_in + fade_out,
                'fade_out_start': fade_in, 
                'current_time': 0,},
        }
        ent = self.gameworld.init_entity(create_dict, ['position', 'color', 
            'renderer', 'fade'])

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=['renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer', 'fade'],
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
