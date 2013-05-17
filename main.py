import kivy
kivy.require('1.6.0')

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ObjectProperty, ListProperty, 
NumericProperty, BooleanProperty)
from kivy.clock import Clock
from kivy.graphics import Line, Translate, PushMatrix, PopMatrix
from kivent.gamescreens import GameScreenManager, GameScreen
from kivent.gameworld import GameWorld
from kivent.gamesystems import GameSystem, GameMap, GameView
from kivent.renderers import QuadRenderer, PhysicsRenderer, QuadTreeQuadRenderer
from kivent.physics import CymunkPhysics
from kivy.atlas import Atlas
import random
import math
import cProfile

class PlayerCharacter(GameSystem):
    current_character_id = NumericProperty(None)
    do_fire_engines = BooleanProperty(False)
    updateable = BooleanProperty(True)

    def create_component(self, entity_id, entity_component_dict):
        super(PlayerCharacter, self).create_component(entity_id, entity_component_dict)
        self.current_character_id = entity_id
        self.gameworld.systems[self.viewport].entity_to_focus = entity_id

    def turn_ship(self, value):
        character = self.gameworld.entities[self.current_character_id]
        physics_body = character['cymunk-physics']['body']
        physics_body.angular_velocity = value

    def update(self, dt):
        if self.do_fire_engines:
            character = self.gameworld.entities[self.current_character_id]
            physics_body = character['cymunk-physics']['body']
            system_data = character[self.system_id]
            unit_vector = physics_body.rotation_vector
            offset = {'x': system_data['offset_distance'] * -unit_vector['x'], 
            'y': system_data['offset_distance'] * -unit_vector['y']}
            force = {'x': system_data['accel']*dt * -unit_vector['x'], 
            'y': system_data['accel']*dt * -unit_vector['y']}
            physics_body.apply_impulse(force, offset)

    def fire_engines(self, state):
        if state == 'down':
            self.do_fire_engines = True
        if state == 'normal':
            self.do_fire_engines = False

        
        

class DebugPanel(Widget):
    fps = StringProperty(None)

    def __init__(self, **kwargs):
        super(DebugPanel, self).__init__(**kwargs)
        Clock.schedule_once(self.update_fps)

    def update_fps(self,dt):
        self.fps = str(int(Clock.get_fps()))
        Clock.schedule_once(self.update_fps, .05)


class MapOverlay(GameSystem):
    system_id = StringProperty('map_overlay')
    def __init__(self, **kwargs):
        super(MapOverlay, self).__init__(**kwargs)
        Clock.schedule_once(self.draw_overlay)
        
    def on_pos(self, instance, value):
        self.map_translate.xy = self.pos

    def draw_overlay(self, dt):
        gameworld = self.gameworld
        if not gameworld.currentmap:
            Clock.schedule_once(self.draw_overlay)
            return
        currentmap = gameworld.currentmap
        num_cols = currentmap.num_cols
        num_rows = currentmap.num_rows
        tile_size = currentmap.tile_size
        with self.canvas:
            PushMatrix()
            self.map_translate = Translate()
            for row in xrange(num_rows+1):
                line_start_pos = (0, tile_size[1] * row)
                line_end_pos = (tile_size[0] * num_cols, tile_size[1] * row)
                Line(points =[line_start_pos[0], line_start_pos[1], line_end_pos[0], 
                    line_end_pos[1]], width = 1)
            for col in xrange(num_cols+1):
                line_start_pos = (tile_size[0] * col, 0)
                line_end_pos = (tile_size[0] * col, num_rows * tile_size[1])
                Line(points =[line_start_pos[0], line_start_pos[1], line_end_pos[0], 
                    line_end_pos[1]], width = 1)
            PopMatrix()


class TiledGameMap(GameMap):
    system_id = StringProperty('default_tiled_map')
    num_cols = NumericProperty(30)
    num_rows = NumericProperty(30)
    tile_size = ListProperty((80, 80))

    def __init__(self, **kwargs):
        super(TiledGameMap, self).__init__(**kwargs)
        Clock.schedule_once(self.init_map)

    def init_map(self, dt):
        tile_size = self.tile_size
        self.map_size = (float(self.num_cols * tile_size[0]), float(self.num_rows * tile_size[1]))

    def on_touch_down(self, touch):
        if self.active:
            camera_pos = self.gameworld.systems[self.viewport].camera_pos
            touch_x_adjusted = touch.x - camera_pos[0]
            touch_y_adjusted = touch.y - camera_pos[1]
            tile_size = self.tile_size
        
            print math.floor(touch_x_adjusted/tile_size[0]), math.floor(touch_y_adjusted/tile_size[1])

class MainMenuScreen(GameScreen):
    name = StringProperty('main_menu')

class MainGameScreen(GameScreen):
    name = StringProperty('main_game')

class TestGame(Widget):
    gameworld = ObjectProperty(None)
    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)

    def init_game(self, dt):
        try: 
            self._init_game(0)
        except:
            print 'failed: rescheduling init **this is not guaranteed to be ok**'
            Clock.schedule_once(self.init_game)

    def setup_states(self):
        self.gameworld.add_state(state_name='main_menu', systems_added=[], 
            systems_removed=['position_renderer', 'physics_renderer', 
            'map_overlay', 'background_renderer', 'quadtree_renderer'], 
            systems_paused=['cymunk-physics', 'default_gameview'], systems_unpaused=[],
            screenmanager_screen='main_menu')
        self.gameworld.add_state(state_name='main_game', systems_added=[ 'quadtree_renderer', 
            'position_renderer', 'background_renderer', 
            'physics_renderer', 'cymunk-physics', 'default_map'], 
            systems_removed=['map_overlay', 'default_tiled_map'], systems_paused=[], 
            systems_unpaused=['cymunk-physics', 'default_gameview'], screenmanager_screen='main_game')
        self.gameworld.add_state(state_name='map_editor', systems_added=['map_overlay', 
            'default_tiled_map'], 
            systems_removed=['physics_renderer'], 
            systems_paused=['cymunk-physics'], systems_unpaused=[],
            screenmanager_screen='main_game')

    def set_main_menu_state(self):
        self.gameworld.state = 'main_menu'

    def setup_map(self):
        self.gameworld.currentmap = self.gameworld.systems['default_map']

    def setup_gameobjects(self):
        Clock.schedule_once(self.test_prerendered_background)
        for x in range(100):
            Clock.schedule_once(self.test_entity)
        print 'generating asteroids'
        for x in range(50):
            Clock.schedule_once(self.test_physics_entity)
        Clock.schedule_once(self.test_player_character)

    def _init_game(self, dt):
        self.setup_states()
        self.setup_map()
        self.set_main_menu_state()
        self.setup_gameobjects()

    def test_prerendered_background(self, dt):
        atlas_address = 'assets/prerendered_backgrounds/stardust_backgrounds/stardust7.atlas'
        self.generate_prerendered_background(atlas_address, (512, 512))
        
    def generate_prerendered_background(self, atlas_address, atlas_size):
        stardust_atlas = Atlas(atlas_address)
        num_tiles = len(stardust_atlas.textures)
        map_to_use = self.gameworld.systems['default_map']
        map_size = map_to_use.map_size
        side_length_x = math.sqrt(num_tiles)
        side_length_y = side_length_x
        scale_x = map_size[0]/atlas_size[0]
        scale_y = map_size[1]/atlas_size[1]
        x_distance = map_size[0]/side_length_x
        y_distance = map_size[1]/side_length_y
        position_dict = {}
        index = 0
        size = (x_distance, y_distance)
        print size
        for y in range(int(side_length_y)):
            for x in range(int(side_length_x)):
                position_dict[index] = (x * x_distance + x_distance *.5, y * y_distance + y_distance*.5)
                index += 1
        for num in range(num_tiles):
            create_component_dict = {'position': {'position': position_dict[num], 
            'scale_x': scale_x, 'scale_y': scale_y}, 
            'background_renderer': {'texture': atlas_address, 'texture_key': str(num+1), 
            'render': False, 'size': size}}
            component_order = ['position', 'background_renderer']
            self.gameworld.init_entity(create_component_dict, component_order)

    def test_physics_entity(self, dt):
        rand_x = random.randint(0, self.gameworld.currentmap.map_size[0])
        rand_y = random.randint(0, self.gameworld.currentmap.map_size[1])
        x_vel = random.randint(-150, 150)
        y_vel = random.randint(-150, 150)
        angle = math.radians(random.randint(-360, 360))
        angular_velocity = math.radians(random.randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 45, 'mass': 100, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
        'collision_type': 1, 'shape_info': shape_dict, 'friction': .4}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 'velocity': (x_vel, y_vel), 
        'position': (rand_x, rand_y), 'angle': angle, 'angular_velocity': angular_velocity, 
        'mass': 100, 'col_shapes': col_shapes}
        create_component_dict = {'cymunk-physics': physics_component, 
        'physics_renderer': {'texture': 'assets/background_objects/asteroid2.png', 
        'render': False, 'size': (45, 45)}}
        component_order = ['cymunk-physics', 'physics_renderer']
        self.gameworld.init_entity(create_component_dict, component_order)

    def test_entity(self, dt):
        rand_x = random.randint(0, self.gameworld.currentmap.map_size[0])
        rand_y = random.randint(0, self.gameworld.currentmap.map_size[1])
        create_component_dict = {'position': {'position': (rand_x, rand_y)}, 
        'quadtree_renderer': {'texture': 'assets/background_objects/star1.png', 'render': False, 'size': (14,14)}}
        component_order = ['position', 'quadtree_renderer']
        self.gameworld.init_entity(create_component_dict, component_order)


    def test_remove_entity(self, dt):
        self.gameworld.remove_entity(0)

    def test_player_character(self, dt):
        box_dict = {'width': 108, 'height': 96, 'mass': 250}
        col_shape_dict = {'shape_type': 'box', 'elasticity': .5, 
        'collision_type': 2, 'shape_info': box_dict, 'friction': .5}
        physics_component_dict = { 'main_shape': 'box', 
        'velocity': (0, 0), 'position': (500, 500), 'angle': 0, 
        'angular_velocity': 0, 'mass': 250, 'vel_limit': 180, 'ang_vel_limit': math.radians(45),
         'col_shapes': [col_shape_dict]}
        ship_dict = {'health': 100, 'accel': 5000, 'offset_distance': 50}
        create_component_dict = {'cymunk-physics': physics_component_dict, 
        'physics_renderer': {'texture': 'assets/ships/ship1-1.png', 
        'render': False, 'size': (64, 52)}, 'player_character': ship_dict}
        component_order = ['cymunk-physics', 'physics_renderer', 'player_character']
        self.gameworld.init_entity(create_component_dict, component_order)



class KivEntApp(App):
    def build(self):
        pass

if __name__ == '__main__':
    cProfile.run('KivEntApp().run()', 'prof')