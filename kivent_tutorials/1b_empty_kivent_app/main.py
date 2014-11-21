import kivy
from kivy.app import App
from kivy.uix.widget import Widget
import kivent_core
from kivy.clock import Clock


class TestGame(Widget):
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def init_game(self, dt):
        try:
            self.setup_map()
            self.setup_states()
            self.set_state()
        except:
            Clock.schedule_once(self.init_game)

    def setup_map(self):
        gameworld = self.gameworld
        gameworld.currentmap = gameworld.systems['map']

    def setup_states(self):
        self.gameworld.add_state(state_name='main', 
            systems_added=[],
            systems_removed=[], systems_paused=[],
            systems_unpaused=[],
            screenmanager_screen='main')
   
    def set_state(self):
        self.gameworld.state = 'main'



class YourAppNameApp(App):
    def build(self):
        pass


if __name__ == '__main__':
    YourAppNameApp().run()
