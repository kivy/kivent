from kivy.properties import StringProperty
from kivy.uix.screenmanager import ScreenManager, Screen


class GameScreenManager(ScreenManager):
    state = StringProperty('initial')

    def __init__(self, **kwargs):
        super(GameScreenManager, self).__init__(**kwargs)
        self.states = {}

    def on_state(self, instance, value):
        self.current = self.states[value]

    def on_touch_down(self, touch):
        super(GameScreenManager, self).on_touch_down(touch)

    def on_touch_up(self, touch):
        super(GameScreenManager, self).on_touch_up(touch)
        
    def on_touch_move(self, touch):
        super(GameScreenManager, self).on_touch_move(touch)
        
class GameScreen(Screen):
    name = StringProperty('default_screen_id')

