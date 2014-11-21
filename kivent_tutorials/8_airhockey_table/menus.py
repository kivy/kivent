__author__ = 'chozabu'

from kivy.uix.widget import Widget
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.scatterlayout import ScatterLayout
from kivy.uix.scatter import Scatter, ScatterPlane
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
from kivy.properties import ObjectProperty

from random import random

import observer_actions


import json
class ScatterPlaneLayout(ScatterPlane):
    '''ScatterLayout class, see module documentation for more information.
    '''

    content = ObjectProperty()

    def __init__(self, **kw):
        self.content = FloatLayout()
        super(ScatterPlaneLayout, self).__init__(**kw)
        if self.content.size != self.size:
            self.content.size = self.size
        super(ScatterPlaneLayout, self).add_widget(self.content)
        self.bind(size=self.update_size)

    def update_size(self, instance, size):
        self.content.size = size

    def add_widget(self, *l):
        self.content.add_widget(*l)

    def remove_widget(self, *l):
        self.content.remove_widget(*l)

    def clear_widgets(self):
        self.content.clear_widgets()



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
        gameref.setMenu(self.gameref.game_ui_menu)
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
class GameUIMenu(FloatLayout, basemenu):
    def __init__(self, gameref, **kwargs):
        super(GameUIMenu, self).__init__(**kwargs)
        self.sname = 'ingame'
        self.orientation = 'vertical'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height
        self.player_menu = PlayerMenu(gameref)
        self.add_widget(self.player_menu)
        self.observer_menu = ObserverMenu(gameref)
        self.add_widget(self.observer_menu)


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

class ObserverPanel(ScatterPlaneLayout):
    def __init__(self, **kwargs):
        super(ObserverPanel, self).__init__(**kwargs)
        #self.topfl = topfl = ScatterPlaneLayout(do_rotation=False, do_scale=False,do_translation=False,auto_bring_to_front=False)
        self.observer_id=kwargs['observer_id']
        self.score = l = ProgressBar(max=10000)
        l.size_hint = (1,.1)
        l.pos_hint = {'y':.1}
        self.add_widget(l)
        sratio = self.width/1920.
        ssize = 150.*sratio*8.

        l = Button(background_normal='assets/png/observer_speedup.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":-0.3,"y":0})
        l.width=l.height=ssize
        l.bind(on_press=self.power_pressed)
        l.command="speedup"
        self.add_widget(l)
        self.vortex = l = Button(background_normal='assets/png/observer_vortex.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":1000./10000.,"y":0})
        l.width=l.height=ssize
        l.bind(on_press=self.power_pressed)
        l.command="vortex"
        self.add_widget(l)
        self.wall = l = Button(background_normal='assets/png/observer_wall.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":5000./10000,"y":0})
        l.width=l.height=ssize
        l.bind(on_press=self.power_pressed)
        l.command="wall"
        self.add_widget(l)
        self.puck_storm = l = Button(background_normal='assets/png/observer_puck_storm.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":10000./10000,"y":0})
        l.width=l.height=ssize
        l.bind(on_press=self.power_pressed)
        l.command="puck_storm"
        self.add_widget(l)

        self.selector = l = Image(source='assets/png/observer_selector.png', size_hint=(None,None), allow_stretch=True, pos_hint={"x":-0.3,"y":0})
        l.width=l.height=ssize
        self.add_widget(l)
    def power_pressed(self, instance):
        self.parent.power_pressed(instance, observer_id=self.observer_id)
    def update_scores(self, points):
        self.score.value=points
        self.puck_storm.disabled = points<10000
        self.wall.disabled = points<5000
        self.vortex.disabled = points<1000


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

        #sratio = self.width/1920.
        #ssize = 150*sratio

        self.topfl = topfl = ObserverPanel(do_rotation=False, do_scale=False,do_translation=False,
                                           auto_bring_to_front=False, observer_id=0)
        topfl.rotation=180
        self.add_widget(topfl)


        self.add_widget(BoxLayout(size_hint=(1,6.)))

        self.bottomfl = bottomfl = ObserverPanel(do_rotation=False, do_scale=False,do_translation=False,
                                                 auto_bring_to_front=False, observer_id=1)
        bottomfl.rotation=0

        self.add_widget(bottomfl)
    def update_scores(self):
        gameref = self.gameref

        top_points = gameref.top_points
        self.topfl.update_scores(top_points)

        bottom_points = gameref.bottom_points
        self.bottomfl.update_scores(bottom_points)
    def power_pressed(self, instance=None, touch=None, observer_id=None):
        gameref = self.gameref
        if observer_id!=None:
            isbottom=observer_id
        else:
            isbottom = instance.observer_id
        if isbottom:
            points = gameref.bottom_points
        else:
            points = gameref.top_points

        actioncost = observer_actions.actioncosts[instance.command]
        if actioncost>points:return


        gameref.set_observer_action(isbottom,instance.command)
    def set_selector_pos(self, isbottom, command):
        actioncost = observer_actions.actioncosts[command]
        if actioncost==0:actioncost=-3000
        if isbottom:
            self.bottomfl.selector.pos_hint={"x":actioncost/10000.,"y":0}
        else:
            self.topfl.selector.pos_hint={"x":actioncost/10000.,"y":0}

class PlayerPanel(ScatterPlaneLayout):
    def __init__(self, **kwargs):
        super(PlayerPanel, self).__init__(**kwargs)
        self.player_id=kwargs['player_id']
        #sratio = self.width/1920.
        #ssize = 150.*sratio*8.
        bl = BoxLayout(orientation='vertical')
        bl.size_hint = (1,1)
        self.size_hint = (1,1)
        #self.width = 1080
        #self.height= 100

        l = Button(background_normal='assets/png/pause.png', size_hint=(1,.1), allow_stretch=False)#, pos_hint={"x":-0.3,"y":0})
        #l.width=l.height=ssize
        l.bind(on_press=self.pause_pressed)
        bl.add_widget(BoxLayout(size_hint=(1,.1)))
        bl.add_widget(l)
        bl.add_widget(BoxLayout(size_hint=(1,.8)))
        self.add_widget(bl)
    def pause_pressed(self, instance):
        self.parent.pause_pressed(instance, player_id=self.player_id)


class PlayerMenu(BoxLayout):
    def __init__(self, gameref, **kwargs):
        super(PlayerMenu, self).__init__(**kwargs)
        self.sname = 'player_menu'
        self.orientation = 'horizontal'
        self.gameref = gameref
        self.width = gameref.width
        self.height = gameref.height
        self.size_hint = (1,1)
        #self.pos_hint = {'y':.3+.1}

        #sratio = self.width/1920.
        #ssize = 150*sratio

        self.leftfl = leftfl = PlayerPanel(do_rotation=False, do_scale=False,do_translation=False,
                                           auto_bring_to_front=False, player_id=0)
        leftfl.rotation=0
        leftfl.height=600
        #leftfl.x=200
        #leftfl.pos_hint={'x':.9}
        #leftfl = Button()
        self.add_widget(leftfl)


        self.add_widget(BoxLayout(size_hint_x=12))

        self.rightfl = rightfl = PlayerPanel(do_rotation=False, do_scale=False,do_translation=False,
                                                 auto_bring_to_front=False, player_id=1)
        #leftfl.x=200
        #rightfl.pos_hint={'y':.3}
        rightfl.rotation=180
        #rightfl = Button()

        self.add_widget(rightfl)
    def update_scores(self):
        gameref = self.gameref

        left_points = gameref.left_points
        self.leftfl.update_scores(left_points)

        right_points = gameref.right_points
        self.rightfl.update_scores(right_points)
    def pause_pressed(self, instance=None, touch=None, player_id=None):
        gameref = self.gameref
        gameref.setMenu(PauseMenu(gameref))