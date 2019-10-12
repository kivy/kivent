import kivy
import kivent_core
from kivy.app import App
from kivy.uix.widget import Widget

class TestGame(Widget):
    def __init__(self, **kwargs):
    	super(TestGame, self).__init__(**kwargs)
    	print(dir(self))

class YourAppNameApp(App):
    def build(self):
        pass

if __name__ == '__main__':
    YourAppNameApp().run()
