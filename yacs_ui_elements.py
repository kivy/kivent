from kivy.properties import (StringProperty, ObjectProperty, ListProperty, 
    DictProperty, NumericProperty, BooleanProperty)
from kivy.uix.widget import Widget
from kivy.uix.label import Label
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.togglebutton import ToggleButton
from kivent_cython import (GameScreenManager, GameScreen)
from particlesystem import ParticleSystem
from kivy.clock import Clock

class YACSLabel(Label):
    pass

class YACSButtonCircle(ToggleButton):
    
    def on_touch_down(self, touch):
        if self.weapons_locked:
            pass
        else:
            super(YACSButtonCircle, self).on_touch_down(touch)

class YACSButton(Button):
    pass

class ShipToggleButton(ToggleButton):
    pass


class CharacterInputPanel(Widget):
    current_touch = ListProperty([])
    touch_effect = StringProperty('assets/pexfiles/touch_input_effect.pex')
    particle_system = ObjectProperty(None)
    def __init__(self, **kwargs):
        super(CharacterInputPanel, self).__init__(**kwargs)
        self.create_touch_event_effect()

    def create_touch_event_effect(self):
        self.particle_system = ParticleSystem(self.touch_effect)

    def determine_touch_values(self, touch_x, touch_y):
        x_value = (touch_x - self.pos[0])/self.size[0]
        y_value = (touch_y - self.pos[1])/self.size[1]
        return (x_value, y_value)

    def on_current_touch(self, instance, value):
        player_character = self.gameworld.systems['player_character']
        if not value == []: 
            touch_values = self.determine_touch_values(value[0], value[1])
            particle_system = self.particle_system
            particle_system.pos = value
            particle_system.start_color = [touch_values[1], .3, .0, 1.]
            particle_system.end_color = [touch_values[1], .0, .5, 1.]
            player_character.touch_values = touch_values
        else:
            player_character.touch_values = value

            
    def on_touch_down(self, touch):
        if self.collide_point(touch.x, touch.y):
            self.current_touch = (touch.x, touch.y)
            particle_system = self.particle_system
            particle_system.start()
            if particle_system not in self.children:
                self.add_widget(particle_system)
    
    def on_touch_move(self, touch):
        if self.collide_point(touch.x, touch.y):
            self.current_touch = (touch.x, touch.y)
            

    def on_touch_up(self, touch):
        if self.collide_point(touch.x, touch.y):
            self.current_touch = []
            particle_system = self.particle_system
            particle_system.stop()
            if particle_system in self.children:
                self.remove_widget(particle_system)


class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)

class ToggleWeaponPanel(Widget):
    bullet_button = ObjectProperty(None)
    rocket_button = ObjectProperty(None)
    weapon_type = StringProperty('_bullet')

    def toggle_weapon(self, state, weapon_type):
        if state == 'normal':
            if weapon_type == '_rocket':
                self.bullet_button.state = 'down'
                self.weapon_type = '_bullet'
            if weapon_type == '_bullet':
                self.rocket_button.state = 'down'
                self.weapon_type = '_rocket'
        if state == 'down':
            self.weapon_type = weapon_type

class WeaponToggleButton(ToggleButton):
    weapon_type = StringProperty('_bullet')
    ammo_amount = NumericProperty(0, allownone=True)

class ObjectivesPanel(Widget):

    def __init__(self, **kwargs):
        super(ObjectivesPanel, self).__init__(**kwargs)
        

    def reset_objectives(self):
        self.clear_panel()
        self.determine_panel_layouts()

    def clear_panel(self):
        children_to_remove = [x for x in self.layout.children]
        for child in children_to_remove:
            self.layout.remove_widget(child)


    def determine_panel_layouts(self):
        do_enemies = self.gameworld.do_enemies
        do_asteroids = self.gameworld.do_asteroids
        do_probes = self.gameworld.do_probes
        if do_enemies:
            self.layout.add_widget(self.enemies_label)
        if do_asteroids:
            self.layout.add_widget(self.asteroids_label)
        if do_probes:
            self.layout.add_widget(self.probes_label)



class ObjectiveLabel(Widget):
    objective_amount = NumericProperty(0, allownone=True)
    objective_image = StringProperty(None)

class MainMenuScreen(GameScreen):
    name = StringProperty('main_menu')

class MainGameScreen(GameScreen):
    name = StringProperty('main_game')

    def toggle_weapons(self, weapon_type):
        character_system = self.gameworld.systems['player_character']
        character_system.current_projectile_type = weapon_type



class GameOverScreen(GameScreen):
    name = StringProperty('game_over')

class ChooseCharacterWidget(Widget):
    current_ship = StringProperty('default')
    list_of_ships = ListProperty(['ship_1', 'ship_2', 'ship_3', 'ship_4', 'ship_5', 'ship_6'])
    gameworld = ObjectProperty(None)
    ship_dict = DictProperty(None)

    def on_ship_dict(self, instance, value):
        print 'ship_dict', value

    def on_current_ship(self, instance, value):
        self.ship_dict = self.gameworld.systems['ship_system'].get_ship_values(value)

    def get_next_ship(self):
        list_of_ships = self.list_of_ships
        index = list_of_ships.index(self.current_ship)
        index += 1
        if index > len(list_of_ships) - 1:
            index = 0
        if index < 0:
            index = len(list_of_ships) - 1
        self.current_ship = list_of_ships[index]

    def get_prev_ship(self):
        list_of_ships = self.list_of_ships
        index = list_of_ships.index(self.current_ship)
        index -= 1
        if index > len(list_of_ships) - 1:
            index = 0
        if index < 0:
            index = len(list_of_ships) - 1
        self.current_ship = list_of_ships[index]

class ChooseCharacterScreen(GameScreen):
    name = StringProperty('choose_character')

class StatBox(BoxLayout):
    stat_value = StringProperty('Default Value')
    stat_name = StringProperty('Default Name')

class HealthBar(BoxLayout):
    current_health = NumericProperty(1.0, allownone=True)
    total_health = NumericProperty(1.0, allownone=True)
    health_percentage = NumericProperty(1.0)

    def on_current_health(self, instance, value):
        if not value == None and not self.total_health == None:
            self.health_percentage = float(value)/float(self.total_health)

class YACSLabelNoBox(Label):
    pass
