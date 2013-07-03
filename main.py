import kivy
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ObjectProperty, NumericProperty, 
    BooleanProperty)
from kivy.clock import Clock
from kivent_cython import (GameWorld, GameSystem, GameMap, GameView, ParticleManager, 
    QuadRenderer, PhysicsRenderer, CymunkPhysics, PhysicsPointRenderer, QuadTreePointRenderer)
from kivy.core.window import Window
import yacs_ui_elements
import player_character
import levels
import projectiles
import musiccontroller
#import cProfile
import os
import sys

class TestGame(Widget):
    gameworld = ObjectProperty(None)
    state = StringProperty(None)
    number_of_asteroids = NumericProperty(0, allownone=True)
    loading_new_level = BooleanProperty(False)
    cleared = BooleanProperty(True)

    def __init__(self, **kwargs):
        super(TestGame, self).__init__(**kwargs)
        Clock.schedule_once(self.init_game)
        print kwargs


    def init_game(self, dt):
        try: 
            self._init_game(0)
        except:
            print 'failed: rescheduling init **this is not guaranteed to be ok**'
            Clock.schedule_once(self.init_game)

    def on_state(self, instance, value):
        if value == 'choose_character':
            self.gameworld.systems['quadtree_renderer'].enter_delete_mode()
            self.gameworld.systems['asteroids_level'].clear_level()
            self.clear_gameworld_objects()
            self.cleared = False
            Clock.schedule_once(self.check_clear)

    def check_quadtree_created(self, dt):
        systems = self.gameworld.systems
        quadtree_renderer = systems['quadtree_renderer']
        if quadtree_renderer.quadtree:
            Clock.schedule_once(self.setup_new_level)
            self.cleared = True
        else:
            Clock.schedule_once(self.check_quadtree_created)

            
    def check_clear(self, dt):
        systems = self.gameworld.systems
        systems_to_check = ['asteroids_level', 'asteroid_system', 'projectile_system', 'quadtree_renderer']
        num_entities = 0
        self.check_clear_counter = 0
        for system in systems_to_check:
            num_entities += len(systems[system].entity_ids)
        print num_entities
        if num_entities > 0:
            self.check_clear_counter += 1
            if self.check_clear_counter > 10:
                self.clear_gameworld_objects()
            Clock.schedule_once(self.check_clear, .01)
        else:
            Clock.schedule_once(self.setup_new_quadtree)
            Clock.schedule_once(self.check_quadtree_created)
                
    def setup_new_quadtree(self, dt):
        Clock.schedule_once(self.gameworld.systems['quadtree_renderer'].setup_quadtree)

    def setup_new_level(self, dt):
        Clock.schedule_once(self.gameworld.systems['asteroids_level'].generate_new_level)
        
    def setup_states(self):
        self.gameworld.add_state(state_name='main_menu', systems_added=['background_renderer', 
            'quadtree_renderer', 'default_map'], 
            systems_removed=['physics_renderer', 'particle_manager', 'point_particle_manager',
            'physics_point_renderer'], 
            systems_paused=['cymunk-physics', 'default_gameview', 
            'physics_renderer', 'physics_point_renderer',
            'particle_manager', 'point_particle_manager', 'asteroid_system', 
            'player_character'], systems_unpaused=[],
            screenmanager_screen='main_menu')
        self.gameworld.add_state(state_name='choose_character', systems_added=[
            'background_renderer', 'quadtree_renderer',  'default_map'], 
            systems_removed=['physics_renderer', 'particle_manager', 'point_particle_manager',
             'physics_point_renderer'], 
            systems_paused=['cymunk-physics', 'default_gameview', 
            'physics_renderer', 'physics_point_renderer', 'quadtree_renderer',
            'particle_manager', 'point_particle_manager', 'asteroid_system', 
            'player_character'], systems_unpaused=[],
            screenmanager_screen='choose_character')
        self.gameworld.add_state(state_name='main_game', systems_added=[ 'background_renderer', 
            'physics_renderer', 'quadtree_renderer', 'physics_point_renderer', 'cymunk-physics', 
            'default_map', 'particle_manager', 'point_particle_manager'], 
            systems_removed=[], systems_paused=[], 
            systems_unpaused=['cymunk-physics', 'default_gameview', 
            'physics_renderer', 'particle_manager', 'point_particle_manager', 'quadtree_renderer',
            'asteroid_system', 'player_character', 'physics_point_renderer'], screenmanager_screen='main_game')
        self.gameworld.add_state(state_name='game_over', systems_added=[ 'background_renderer', 
            'physics_renderer', 'quadtree_renderer', 'physics_point_renderer', 'cymunk-physics', 
            'default_map', 'particle_manager', 'point_particle_manager'], 
            systems_removed=[], systems_paused=[], 
            systems_unpaused=['cymunk-physics', 'default_gameview', 
            'physics_renderer', 'particle_manager', 'point_particle_manager',
            'asteroid_system', 'player_character', 'physics_point_renderer'], screenmanager_screen='game_over')

    def clear_gameworld_objects(self):
        systems = self.gameworld.systems
        systems['player_character'].clear_character()
        systems['asteroid_system'].clear_asteroids()
        systems['projectile_system'].clear_projectiles()

    def set_main_menu_state(self):
        self.gameworld.state = 'main_menu'
        self.gameworld.music_controller.play('track5')
        choose_character = self.gameworld.gamescreenmanager.get_screen('choose_character').choose_character
        choose_character.current_ship = choose_character.list_of_ships[0]

    def setup_map(self):
        self.gameworld.currentmap = self.gameworld.systems['default_map']

    def start_round(self, character_to_spawn):
        print self.cleared
        if self.cleared:
            character_system = self.gameworld.systems['player_character']
            character_system.spawn_player_character(character_to_spawn)
            Clock.schedule_once(self.gameworld.systems['asteroid_system'].generate_asteroids)
            self.gameworld.state = 'main_game'


    def setup_gameobjects(self):
        Clock.schedule_once(self.gameworld.systems['asteroids_level'].generate_new_level)

    def _init_game(self, dt):
        self.setup_states()
        self.setup_map()
        self.set_main_menu_state()
        self.setup_collision_callbacks()
        self.setup_gameobjects()
        Clock.schedule_interval(self.update, 1./30.)

    def update(self, dt):
        self.gameworld.update(dt)     

    def setup_collision_callbacks(self):
        systems = self.gameworld.systems
        physics = systems['cymunk-physics']
        character_system = systems['player_character']
        projectile_system = systems['projectile_system']
        physics.add_collision_handler(1,3, begin_func=projectile_system.collision_begin_asteroid_bullet,
            separate_func=projectile_system.begin_collision_solve_asteroid_bullet)
        physics.add_collision_handler(2,3, begin_func=projectile_system.collision_begin_ship_bullet,
            separate_func=projectile_system.collision_solve_ship_bullet)
        physics.add_collision_handler(2,1, separate_func=character_system.collision_solve_ship_asteroid)
        physics.add_collision_handler(3,3, begin_func=projectile_system.collision_begin_bullet_bullet, 
            separate_func=projectile_system.collision_solve_bullet_bullet)
    
    def test_remove_entity(self, dt):
        self.gameworld.remove_entity(0)

    def on_number_of_asteroids(self, instance, value):
        if value == 0 and self.state == 'main_game':
            self.gameworld.systems['asteroids_level'].current_level_id += 1
            self.gameworld.state = 'choose_character'

    def player_lose(self, dt):
        self.gameworld.state = 'game_over'
            

class KivEntApp(App):
    def build(self):
        Window.clearcolor = (0, 0, 0, 1.)
        
if __name__ == '__main__':
   KivEntApp().run()
    # sd_card_path = os.path.dirname('/sdcard/profiles/')
    # print sd_card_path
    # if not os.path.exists(sd_card_path):
    #     print 'making directory'
    #     os.mkdir(sd_card_path)
    # print 'path: ', sd_card_path
    # cProfile.run('KivEntApp().run()', sd_card_path + '/asteroidsprof.prof')