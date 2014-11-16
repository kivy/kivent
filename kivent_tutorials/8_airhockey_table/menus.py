__author__ = 'chozabu'

from kivy.uix.widget import Widget
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.popup import Popup
from kivy.uix.switch import Switch
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.relativelayout import RelativeLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.clock import Clock
from kivy.base import stopTouchApp
from kivy.uix.progressbar import ProgressBar

from random import random

import observer_actions


import json

class BoButton(Button):
	def __init__(self, **kwargs):
		super(Button, self).__init__(**kwargs)
		self.background_color = (1,1,1,0.5)

class basemenu():
	def on_activate(self):
		pass
	def on_back(self):
		pass
	def on_deactivate(self):
		pass

class PauseMenu(BoxLayout, basemenu):
    def __init__(self, gameref, **kwargs):
        super(PauseMenu, self).__init__(**kwargs)
        self.sname = 'pause'
        self.orientation = 'vertical'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height

        l = BoButton(text="Resume", font_size=40)
        l.bind(on_press=self.pausepressed)
        #l.size_hint = (.25,.25)
        #l.pos_hint = {'y':.25+.125}
        self.add_widget(l)
        b = BoButton(text="New Game", font_size=30)
        b.bind(on_press=self.quitpressed)
        self.add_widget( BoxLayout() )
        self.add_widget(b)
        #b.size_hint = (.25,.25)
        #b.pos_hint = {'y':.25+.125}
        self.mainlabel = l
    def pausepressed(self, instance=None):
        gameref = self.gameref
        gameref.setMenu(GameUIMenu(self.gameref))
    def quitpressed(self, instance=None):
        gameref = self.gameref
        gameref.setMenu(NewGameMenu(self.gameref))
    def on_activate(self):
        pass
    def on_back(self):
        pass
        #self.gameref.setMenu(GameUIMenu(self.gameref))

class VictoryMenu(BoxLayout, basemenu):
    def __init__(self, gameref, **kwargs):
        super(VictoryMenu, self).__init__(**kwargs)
        self.sname = 'victory'
        self.orientation = 'vertical'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height
        winner = kwargs.get("winner", 'No-One')
        self.victory_label = l = Label(text=winner+" Wins!", font_size=40)

        #l.size_hint = (.25,.25)
        #l.pos_hint = {'y':.25+.125}
        self.add_widget(l)
        b = BoButton(text="New Game", font_size=30)
        b.bind(on_press=self.quitpressed)
        self.add_widget( BoxLayout() )
        self.add_widget(b)
        #b.size_hint = (.25,.25)
        #b.pos_hint = {'y':.25+.125}
        self.mainlabel = l
    def quitpressed(self, instance=None):
        gameref = self.gameref
        gameref.setMenu(NewGameMenu(self.gameref))
    def on_activate(self):
        pass
    def on_back(self):
        pass
        #self.gameref.setMenu(GameUIMenu(self.gameref))

class NewGameMenu(BoxLayout, basemenu):
    def __init__(self, gameref, **kwargs):
        super(NewGameMenu, self).__init__(**kwargs)
        self.sname = 'new_game'
        self.orientation = 'vertical'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height

        l = BoButton(text="GO", font_size=80)
        l.bind(on_press=self.gopressed)
        #l.size_hint = (.25,.25)
        #l.pos_hint = {'y':.25+.125}
        self.add_widget(l)
        #b.size_hint = (.25,.25)
        #b.pos_hint = {'y':.25+.125}
        self.mainlabel = l
    def gopressed(self, instance=None):
        gameref = self.gameref
        gameref.new_game()
        gameref.setMenu(GameUIMenu(self.gameref))
    def on_activate(self):
        pass
    def on_back(self):
        pass
        #self.gameref.setMenu(GameUIMenu(self.gameref))
class GameUIMenu(BoxLayout, basemenu):
    def __init__(self, gameref, **kwargs):
        super(GameUIMenu, self).__init__(**kwargs)
        self.sname = 'ingame'
        self.orientation = 'vertical'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height


class ScoreBoard(BoxLayout):
    def __init__(self, gameref, **kwargs):
        super(ScoreBoard, self).__init__(**kwargs)
        self.sname = 'scoreboard'
        self.orientation = 'horizontal'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height

        l = Label(text="0", font_size=30, font_name='assets/ttf/EHSMB.TTF')
        #l.size_hint = (.25,.25)
        #l.pos_hint = {'y':.25+.125}
        self.add_widget(l)
        self.red_score = l

        l = Label(text="0", font_size=30, font_name='assets/ttf/EHSMB.TTF')
        #l.size_hint = (.25,.25)
        #l.pos_hint = {'y':.25+.125}
        self.add_widget(l)
        self.blue_score=l
    def update_scores(self):
        gameref = self.gameref
        self.red_score.text=str(gameref.red_score)
        self.blue_score.text=str(gameref.blue_score)

class ObserverMenu(BoxLayout):
    def __init__(self, gameref, **kwargs):
        super(ObserverMenu, self).__init__(**kwargs)
        self.sname = 'observer_menu'
        self.orientation = 'vertical'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height
        self.size_hint = (.2,1)
        self.pos_hint = {'x':.3+.1}

        self.topfl = topfl = RelativeLayout()
        self.top_button = l = BoButton(text="PowerUp", font_size=20)
        #l.size_hint = (.2,1)
        #l.pos_hint = {'x':.3+.1}
        l.observer_id=0
        l.bind(on_press=self.power_pressed)
        topfl.add_widget(l)

        #self. top_score = l = Label(text="0", font_size=30, font_name='assets/ttf/EHSMB.TTF')
        self.top_score = l = ProgressBar(max=10000)
        l.size_hint = (1,.1)
        #l.pos_hint = {'x':.3+.1}
        topfl.add_widget(l)
        self.add_widget(topfl)


        self.add_widget(BoxLayout(size_hint=(1,6.)))


        self.bottomfl = bottomfl = RelativeLayout()
        #self.bottom_score = l = Label(text="0", font_size=30, font_name='assets/ttf/EHSMB.TTF')
        self.bottom_score = l = ProgressBar(max=10000)
        l.size_hint = (1,.1)
        #l.size_hint = (.2,1)
        l.pos_hint = {'y':.5}
        bottomfl.add_widget(l)

        self.bottom_button  =l= BoButton(text="PowerUp", font_size=20)
        #l.size_hint = (.2,1)
        #l.pos_hint = {'x':.3+.1}
        l.observer_id=1
        #l.bind(on_press=self.power_pressed)
        #bottomfl.add_widget(l)
        sratio = self.width/1920.
        ssize = 150*sratio
        l = Button(background_normal='assets/png/observer_speedup.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":-0.3,"y":0})
        l.width=l.height=ssize
        l.observer_id=1
        l.bind(on_press=self.power_pressed)
        l.command="speedup"
        bottomfl.add_widget(l)
        l = Button(background_normal='assets/png/observer_vortex.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":1000./10000.,"y":0})
        l.width=l.height=ssize
        l.observer_id=1
        l.bind(on_press=self.power_pressed)
        l.command="vortex"
        bottomfl.add_widget(l)
        l = Button(background_normal='assets/png/observer_wall.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":5000./10000,"y":0})
        l.width=l.height=ssize
        l.observer_id=1
        l.bind(on_press=self.power_pressed)
        l.command="wall"
        bottomfl.add_widget(l)
        l = Button(background_normal='assets/png/observer_puck_storm.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":10000./10000,"y":0})
        l.width=l.height=ssize
        l.observer_id=1
        l.bind(on_press=self.power_pressed)
        l.command="puck_storm"
        bottomfl.add_widget(l)

        self.selector = l = Image(source='assets/png/observer_selector.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":-0.3,"y":0})
        l.width=l.height=ssize
        bottomfl.add_widget(l)
        self.add_widget(bottomfl)
    def update_scores(self):
        gameref = self.gameref
        #self.top_score.text=str(int(gameref.top_points))
        self.top_score.value=gameref.top_points
        self.set_powerup_text(gameref.top_points, self.top_button)
        #self.bottom_score.text=str(int(gameref.bottom_points))
        self.bottom_score.value=gameref.bottom_points
        #self.set_powerup_text(gameref.bottom_points, self.bottom_button)
    def set_powerup_text(self, points, instance):
        action, command = observer_actions.points_to_powerup(points)
        #pos_hint={"x":10000./10000,
        if instance.text != action:
            instance.text = action
            instance.command = command
    def power_pressed(self, instance=None, touch=None):
        gameref = self.gameref
        isbottom = instance.observer_id
        if isbottom:
            points = gameref.bottom_points
        else:
            points = gameref.top_points

        #action, command = observer_actions.points_to_powerup(points)
        actioncost = observer_actions.actioncosts[instance.command]
        if actioncost>points:return


        gameref.set_observer_action(isbottom,instance.command)
    def set_selector_pos(self, isbottom, command):
        actioncost = observer_actions.actioncosts[command]
        if actioncost==0:actioncost=-3000
        self.selector.pos_hint={"x":actioncost/10000.,"y":0}