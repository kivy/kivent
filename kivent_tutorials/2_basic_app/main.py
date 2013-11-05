#import kivy
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty)
from kivy.clock import Clock
import kivent_cython  # import needed for kv to work


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
        self.set_state()
        Clock.schedule_interval(self.update, 0)

    def update(self, dt):
        self.gameworld.update(dt)

    def setup_states(self):
        self.gameworld.add_state(state_name='main', systems_added=[],
                                 systems_removed=[], systems_paused=[],
                                 systems_unpaused=[],
                                 screenmanager_screen='main')

    def set_state(self):
        self.gameworld.state = 'main'


class BasicApp(App):
    def build(self):
        pass


if __name__ == '__main__':
    BasicApp().run()
