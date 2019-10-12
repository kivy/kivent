from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.core.window import Window
from random import randint, choice
import kivent_core
from kivent_core.gameworld import GameWorld
from kivent_core.systems.position_systems import PositionSystem2D
from kivent_core.systems.renderers import Renderer
from kivent_core.systems.animation_sys import AnimationSystem
from kivent_core.managers.resource_managers import texture_manager
from kivy.properties import StringProperty
from os.path import dirname, join, abspath

texture_manager.load_atlas(join(dirname(dirname(abspath(__file__))), 'assets',
    'stars.atlas'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets',
    'star1-blue.png'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets',
    'star2-blue.png'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets',
    'star3-blue.png'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets',
    'star1-red.png'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets',
    'star2-red.png'))
texture_manager.load_image(join(dirname(dirname(abspath(__file__))), 'assets',
    'star3-red.png'))


class TestGame(Widget):
    def on_kv_post(self, *args):
        self.gameworld.init_gameworld(
            ['renderer', 'position', 'animation'],
            callback=self.init_game)

    def init_game(self):
        self.setup_states()
        self.load_models()
        self.load_animations()
        self.set_state()
        self.draw_some_stuff()
        self.save_animations()
        Clock.schedule_interval(self.shuffle_animations,1)

    def load_models(self):
        model_manager = self.gameworld.model_manager
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star1', 'star1-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star2', 'star2-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star3', 'star3-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star1-blue', 'star1-blue-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star2-blue', 'star2-blue-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star3-blue', 'star3-blue-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star1-red', 'star1-red-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star2-red', 'star2-red-4')
        model_manager.load_textured_rectangle('vertex_format_4f', 2., 2.,
            'star3-red', 'star3-red-4')

    def load_animations(self):
        animation_manager = self.gameworld.animation_manager
        for i in range(50):
            time = randint(100,700)
            color = choice(['','-red','-blue'])
            animation_frames = [
                    {'texture': 'star1%s' % color,
                     'model' : 'star1%s-4' % color,
                     'duration' : time },
                    {'texture': 'star2%s' % color,
                     'model' : 'star2%s-4' % color,
                     'duration' : time },
                    {'texture': 'star3%s' % color,
                     'model' : 'star3%s-4' % color,
                     'duration' : time }]
            animation_manager.load_animation('star-animation-%d' % i, 3,
                                             animation_frames)
        animation_manager.load_json('../assets/animations.json')

    def save_animations(self):
        animation_manager = self.gameworld.animation_manager
        animation_manager.save_to_json(['star-animation-1',
                                        'star-animation-2'],
                                       'anim.json')
        animation_manager.save_to_json(['star-animation-3'],
                                       'anim.json')

    def shuffle_animations(self,dt):
        for i in range(3000):
            ent = self.gameworld.entities[i]
            try:
                anim_component = ent.animation
                anim_component.animation = 'star-animation-%d' % randint(0,51)
            except IndexError:
                pass

    def draw_some_stuff(self):
        init_entity = self.gameworld.init_entity
        for x in range(3000):
            pos = randint(0,Window.width), randint(0, Window.height)
            animation = randint(0,51)
            create_dict = {
                'position': pos,
                'renderer': {'texture': 'star1',
                    'model_key': 'star1-4'},
                'animation': {
                    'name': 'star-animation-%d' % animation,
                    'loop': True}
            }
            ent = init_entity(create_dict,
                              ['position', 'renderer', 'animation'])

    def setup_states(self):
        self.gameworld.add_state(state_name='main',
            systems_added=['renderer'],
            systems_removed=[], systems_paused=[],
            systems_unpaused=['renderer','animation'],
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

