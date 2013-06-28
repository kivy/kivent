import kivy
kivy.require('1.7.0')
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.properties import (StringProperty, ObjectProperty, ListProperty, 
NumericProperty, BooleanProperty, DictProperty)
from kivy.clock import Clock
from kivent_cython import (GameWorld,GameSystem, GameMap, GameView, ParticleManager, 
    QuadRenderer, PhysicsRenderer, CymunkPhysics, PhysicsPointRenderer, QuadTreePointRenderer)
from kivy.atlas import Atlas
from kivy.vector import Vector
import random
import math
from functools import partial
from kivy.core.audio import SoundLoader
from kivy.core.window import Window
import yacs_ui_elements
#import cProfile
import os
import sys

class AsteroidsLevel(GameSystem):
    system_id = StringProperty('asteroids_level')
    current_level_id = NumericProperty(0)

    def generate_new_level(self, dt):
        dust_choices_gold = ['assets/prerendered_backgrounds/stardust_backgrounds/stardust1.atlas', 
        'assets/prerendered_backgrounds/stardust_backgrounds/stardust4.atlas',
        'assets/prerendered_backgrounds/stardust_backgrounds/stardust7.atlas'] 
        dust_choices_green = ['assets/prerendered_backgrounds/stardust_backgrounds/stardust2.atlas', 
        'assets/prerendered_backgrounds/stardust_backgrounds/stardust5.atlas']
        dust_choices_purple = ['assets/prerendered_backgrounds/stardust_backgrounds/stardust3.atlas']
        dust_choices_blue = ['assets/prerendered_backgrounds/stardust_backgrounds/stardust6.atlas', 
        'assets/prerendered_backgrounds/stardust_backgrounds/stardust8.atlas']
        star_choice_gold = ['assets/background_objects/star3.png', 'assets/background_objects/star7.png']
        star_choice_green = ['assets/background_objects/star5.png', 'assets/background_objects/star8.png']
        star_choice_blue = ['assets/background_objects/star1.png', 'assets/background_objects/star2.png']
        star_choice_purple = ['assets/background_objects/star4.png', 'assets/background_objects/star6.png']
        color_choice = [star_choice_gold, star_choice_green, star_choice_purple, star_choice_blue]
        first_color_choice = random.choice(color_choice)
        second_color_choice = random.choice(color_choice)
        num_star_1 = random.randint(0, 25)
        num_star_2 = random.randint(0, 15)
        num_star_3 = random.randint(0, 10)
        num_star_4 = random.randint(0, 10)
        self.generate_stars(first_color_choice[0], first_color_choice[1], second_color_choice[0], second_color_choice[1], 
            num_star_1, num_star_2, num_star_3, num_star_4)
        #generate background
        chance_of_dust = random.random()
        if chance_of_dust >= .4:
            if first_color_choice == star_choice_gold:
                bg_choice = random.choice(dust_choices_gold)
            if first_color_choice == star_choice_green:
                bg_choice = random.choice(dust_choices_green)
            if first_color_choice == star_choice_blue:
                bg_choice = random.choice(dust_choices_blue)
            if first_color_choice == star_choice_purple:
                bg_choice = random.choice(dust_choices_purple)
            self.generate_prerendered_background(bg_choice, (512, 512))

    def clear_level(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))

    def generate_stars(self, first_star_choice1, first_star_choice2, second_star_choice1, 
        second_star_choice2, num_star_1, num_star_2, num_star_3, num_star_4):
        for x in range(num_star_1):
            self.generate_star(first_star_choice1, (14, 14))
        for x in range(num_star_2):
            self.generate_star(first_star_choice2, (8, 8))
        for x in range(num_star_3):
            self.generate_star(second_star_choice1, (14, 14))
        for x in range(num_star_4):
            self.generate_star(second_star_choice2, (8, 8))

    def generate_star(self, star_graphic, star_size):
        rand_x = random.randint(0, self.gameworld.currentmap.map_size[0])
        rand_y = random.randint(0, self.gameworld.currentmap.map_size[1])
        create_component_dict = {'position': {'position': (rand_x, rand_y)}, 
        'quadtree_renderer': {'texture': star_graphic, 'size': star_size}, 
        'asteroids_level': {'level_id': self.current_level_id}}
        component_order = ['position', 'quadtree_renderer', 'asteroids_level']
        self.gameworld.init_entity(create_component_dict, component_order)
    
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
        for y in range(int(side_length_y)):
            for x in range(int(side_length_x)):
                position_dict[index] = (x * x_distance + x_distance *.5, 
                    y * y_distance + y_distance*.5)
                index += 1
        for num in range(num_tiles):
            create_component_dict = {'position': {'position': position_dict[num], 
            'scale_x': scale_x, 'scale_y': scale_y}, 
            'background_renderer': {'texture': atlas_address, 
            'texture_key': str(num+1), 'size': size}, 
            'asteroids_level': {'level_id': self.current_level_id}}
            component_order = ['position', 'background_renderer', 'asteroids_level']
            self.gameworld.init_entity(create_component_dict, component_order)

class AsteroidSystem(GameSystem):
    system_id = StringProperty('asteroid_system')
    updateable = BooleanProperty(True)
    number_of_asteroids = NumericProperty(0)

    def generate_asteroids(self, dt):
        current_level_id = self.gameworld.systems['asteroids_level'].current_level_id
        level_asteroids = [(0, 5), (1, 9), (5, 15), (10, 20), (15,25)]
        if current_level_id <= 4:
            num_small_asteroids = level_asteroids[current_level_id][1]
            num_big_asteroids = level_asteroids[current_level_id][0]
        if current_level_id > 4:
            num_big_asteroids = (current_level_id - 1) * 5
            num_small_asteroids = (current_level_id + 1) * 5

        #small asteroids
        for x in range(num_small_asteroids):
            rand_x = random.randint(0, self.gameworld.currentmap.map_size[0])
            rand_y = random.randint(0, self.gameworld.currentmap.map_size[1])
            self.create_asteroid_1((rand_x, rand_y))
        #big asteroids
        for x in range(num_big_asteroids):
            rand_x = random.randint(0, self.gameworld.currentmap.map_size[0])
            rand_y = random.randint(0, self.gameworld.currentmap.map_size[1])
            self.create_asteroid_2((rand_x, rand_y))


    def clear_asteroids(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))

    def create_asteroid_2(self, pos):
        x_vel = random.randint(-75, 75)
        y_vel = random.randint(-75, 75)
        angle = math.radians(random.randint(-360, 360))
        angular_velocity = math.radians(random.randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 43, 'mass': 150, 
        'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
        'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 'velocity': (x_vel, y_vel), 
        'position': (pos[0], pos[1]), 'angle': angle, 
        'angular_velocity': angular_velocity, 
        'mass': 100, 'col_shapes': col_shapes}
        asteroid_component = {'health': 30, 'damage': 15, 
        'asteroid_size': 2, 'pending_destruction': False}
        create_component_dict = {'cymunk-physics': physics_component, 
        'physics_renderer': {'texture': 'assets/background_objects/asteroid2.png'}, 
        'asteroid_system': asteroid_component}
        component_order = ['cymunk-physics', 'physics_renderer', 'asteroid_system']
        self.gameworld.init_entity(create_component_dict, component_order)

    def create_asteroid_1(self, pos):
        x = pos[0]
        y = pos[1]
        x_vel = random.randint(-100, 100)
        y_vel = random.randint(-100, 100)
        angle = math.radians(random.randint(-360, 360))
        angular_velocity = math.radians(random.randint(-150, -150))
        shape_dict = {'inner_radius': 0, 'outer_radius': 32, 'mass': 50, 'offset': (0, 0)}
        col_shape = {'shape_type': 'circle', 'elasticity': .5, 
        'collision_type': 1, 'shape_info': shape_dict, 'friction': 1.0}
        col_shapes = [col_shape]
        physics_component = {'main_shape': 'circle', 'velocity': (x_vel, y_vel), 
        'position': (x, y), 'angle': angle, 'angular_velocity': angular_velocity, 
        'mass': 50, 'col_shapes': col_shapes}
        asteroid_component = {'health': 15, 'damage': 5, 
        'asteroid_size': 1, 'pending_destruction': False}
        create_component_dict = {'cymunk-physics': physics_component, 
        'physics_renderer': {'texture': 'assets/background_objects/asteroid1.png'}, 
        'asteroid_system': asteroid_component}
        component_order = ['cymunk-physics', 'physics_renderer', 'asteroid_system']
        self.gameworld.init_entity(create_component_dict, component_order)

    def create_component(self, entity_id, entity_component_dict):
        super(AsteroidSystem, self).create_component(entity_id, entity_component_dict)
        self.number_of_asteroids += 1

    def remove_entity(self, entity_id):
        super(AsteroidSystem, self).remove_entity(entity_id)
        self.number_of_asteroids -= 1

    def update(self, dt):
        system_id = self.system_id
        entities = self.gameworld.entities
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            if system_id not in entity:
                continue
            system_data = entity[system_id]
            if system_data['health'] <= 0 and not system_data['pending_destruction']:
                system_data['pending_destruction'] = True
                if system_data['asteroid_size'] == 2:
                    for x in range(4):
                        position = entity['cymunk-physics']['position']
                        self.create_asteroid_1(position)
                Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))
                

    def damage(self, entity_id, damage):
        system_id = self.system_id
        entities = self.gameworld.entities
        entity = entities[entity_id]
        system_data = entity[system_id]
        system_data['health'] -= damage

class MusicController(Widget):
    music_dir = StringProperty('assets/music/final/')
    def __init__(self, **kwargs):
        super(MusicController, self).__init__(**kwargs)
        self.music_dict = {}
        self.track_names = ['track1', 'track2', 'track3', 'track4', 'track5']
        Clock.schedule_once(self.load_music)
        
        
    def load_music(self, dt):
        print 'loading music'
        print self.music_dir
        track_names = self.track_names
        music_dict = self.music_dict
        for track_name in track_names:
            music_dict[track_name] = SoundLoader.load(self.music_dir + track_name + '.ogg')
            music_dict[track_name].seek(0)

    def play_new_song(self, dt):
        self.play(random.choice(self.track_names))

    def schedule_choose_new_song(self, value):
        start_delay = random.random() * 20.0
        print start_delay, 'start delay'
        Clock.schedule_once(self.play_new_song, start_delay)

    def play(self, sound_name):
        if sound_name in self.music_dict:
            self.music_dict[sound_name].play()
            self.music_dict[sound_name].bind(on_stop=self.schedule_choose_new_song)
        else:
            print "file",sound_name,"not found in", self.music_dir

    def stop(self, sound_name):
        if sound_name in self.music_dict:
            self.music_dict[sound_name].stop()
        else:
            print "file", sound_name, "not found in", self.music_dir

class ProjectileSystem(GameSystem):

    def __init__(self, **kwargs):
        super(ProjectileSystem, self).__init__(**kwargs)
        self.setup_projectiles_dicts()

    def create_rocket_explosion(self, entity_id):
        gameworld = self.gameworld
        entities = gameworld.entities
        entity = entities[entity_id]
        entity['physics_point_renderer']['render'] = False
        entity['projectile_system']['armed'] = False
        entity['cymunk-physics']['body'].velocity = (0, 0)
        entity['point_particle_manager']['engine_effect']['particle_system_on'] = False
        entity['point_particle_manager']['explosion_effect']['particle_system_on'] = True
        Clock.schedule_once(partial(gameworld.timed_remove_entity, entity_id), 2.0)


    def spawn_projectile(self, projectile_type, location, angle, color):
        bullet_ent_id = self.spawn_projectile_with_dict(location, angle, color, 
            self.projectiles_dict[projectile_type])
        Clock.schedule_once(partial(self.set_armed, bullet_ent_id), .05)
        self.fire_projectile(bullet_ent_id)

    def setup_projectiles_dicts(self):
        self.projectiles_dict = projectiles_dict = {}
        projectiles_dict['14px_bullet'] = {'width': 14, 'height': 14, 'mass': 50, 
        'vel_limit': 260, 'ang_vel_limit': 60, 'damage': 10, 
        'accel': 50000, 'texture': 'assets/projectiles/bullet-14px.png', 'type': 'bullet'}
        projectiles_dict['8px_bullet'] = {'width': 8, 'height': 8, 'mass': 45, 
        'vel_limit': 275, 'ang_vel_limit': 60, 'damage': 9, 
        'accel': 50000, 'texture': 'assets/projectiles/bullet-8px.png', 'type': 'bullet'}
        projectiles_dict['6px_bullet'] = {'width': 6, 'height': 6, 'mass': 35, 
        'vel_limit': 300, 'ang_vel_limit': 60, 'damage': 7, 
        'accel': 50000, 'texture': 'assets/projectiles/bullet-6px.png', 'type': 'bullet'}
        projectiles_dict['14px_rocket'] = {'width': 14, 'height': 28, 'mass': 75, 
        'vel_limit': 260, 'ang_vel_limit': 60, 'damage': 25, 
        'accel': 80000, 'texture': 'assets/projectiles/rocket-14px.png', 'type': 'rocket'}
        projectiles_dict['8px_rocket'] = {'width': 8, 'height': 20, 'mass': 60, 
        'vel_limit': 260, 'ang_vel_limit': 60, 'damage': 18, 
        'accel': 50000, 'texture': 'assets/projectiles/rocket-8px.png', 'type': 'rocket'}
        projectiles_dict['6px_rocket'] = {'width': 6, 'height': 14, 'mass': 50, 
        'vel_limit': 260, 'ang_vel_limit': 60, 'damage': 11, 
        'accel': 50000, 'texture': 'assets/projectiles/rocket-6px.png', 'type': 'rocket'}


    def spawn_projectile_with_dict(self, location, angle, color, projectile_dict):
        projectile_box_dict = {'width': projectile_dict['width'], 
        'height': projectile_dict['height'], 'mass': projectile_dict['mass']}
        projectile_col_shape_dict = {'shape_type': 'box', 'elasticity': 1.0, 
        'collision_type': 3, 'shape_info': projectile_box_dict, 'friction': .3}
        projectile_physics_component_dict = { 'main_shape': 'box', 
        'velocity': (0, 0), 'position': (location[0], location[1]), 'angle': angle, 
        'angular_velocity': 0, 'mass': projectile_dict['mass'], 
        'vel_limit': projectile_dict['vel_limit'], 
        'ang_vel_limit': math.radians(projectile_dict['ang_vel_limit']),
        'col_shapes': [projectile_col_shape_dict]}
        projectile_renderer_dict = {'texture': projectile_dict['texture']}
        create_projectile_dict = {'cymunk-physics': projectile_physics_component_dict, 
        'physics_point_renderer': projectile_renderer_dict, 
        'projectile_system': {'damage': projectile_dict['damage'], 
        'accel': projectile_dict['accel'], 'armed': False}, }
        component_order = ['cymunk-physics', 'physics_point_renderer', 
        'projectile_system']
        if projectile_dict['type'] == 'rocket':
            if color == 'orange':
                effect_string = 'assets/pexfiles/rocket_burn_effect1.pex'
                explosion_string = 'assets/pexfiles/rocket_explosion_1.pex'
            elif color == 'blue':
                effect_string = 'assets/pexfiles/rocket_burn_effect2.pex'
                explosion_string = 'assets/pexfiles/rocket_explosion_2.pex'
            elif color == 'green':
                effect_string = 'assets/pexfiles/rocket_burn_effect3.pex'
                explosion_string = 'assets/pexfiles/rocket_explosion_3.pex'
            elif color == 'purple':
                effect_string = 'assets/pexfiles/rocket_burn_effect4.pex'
                explosion_string = 'assets/pexfiles/rocket_explosion_3.pex'
            particle_system1 = {'particle_file': effect_string, 'offset': 0}
            particle_system2 = {'particle_file': explosion_string, 'offset': 0}
            particle_systems = {'engine_effect': particle_system1, 
            'explosion_effect': particle_system2}
            create_projectile_dict['point_particle_manager'] = particle_systems
            component_order.append('point_particle_manager')
        bullet_ent_id = self.gameworld.init_entity(create_projectile_dict, component_order)
        return bullet_ent_id

    def set_armed(self, entity_id, dt):
        entities = self.gameworld.entities
        bullet = entities[entity_id]
        if 'projectile_system' in bullet:
            bullet['projectile_system']['armed'] = True

    def fire_projectile(self, entity_id):
        entities = self.gameworld.entities
        bullet = entities[entity_id]
        physics_data = bullet['cymunk-physics']
        unit_vector = physics_data['unit_vector']
        bullet_accel = bullet['projectile_system']['accel']
        force = {'x': bullet_accel*-unit_vector['x'], 'y': bullet_accel*-unit_vector['y']}
        force_offset = {'x': -unit_vector['x'], 'y': -unit_vector['y']}
        bullet['cymunk-physics']['body'].apply_impulse(force, force_offset)
        if 'point_particle_manager' in bullet:

            bullet['point_particle_manager']['engine_effect']['particle_system_on'] = True

    def clear_projectiles(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))

    def begin_collision_solve_asteroid_bullet(self, arbiter, space):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        asteroid_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            bullet_damage = bullet['projectile_system']['damage']
            systems['asteroid_system'].damage(asteroid_id, bullet_damage)
            if 'point_particle_manager' in bullet:
                self.create_rocket_explosion(bullet_id)
            else:
                Clock.schedule_once(partial(gameworld.timed_remove_entity, bullet_id))
            return True
        else:
            return False

    def collision_solve_bullet_bullet(self, arbiter, space):
        bullet_id2 = arbiter.shapes[1].body.data
        bullet_id1 = arbiter.shapes[0].body.data
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet1 = entities[bullet_id1]
        bullet2 = entities[bullet_id2]
        if bullet1['projectile_system']['armed'] and bullet2['projectile_system']['armed']:
            if 'point_particle_manager' in bullet1:
                self.create_rocket_explosion(bullet_id1)
            else:
                Clock.schedule_once(partial(gameworld.timed_remove_entity, bullet_id1))
            if 'point_particle_manager' in bullet2:
                self.create_rocket_explosion(bullet_id2)
            else:
                Clock.schedule_once(partial(gameworld.timed_remove_entity, bullet_id2))

    def collision_begin_ship_bullet(self, arbiter, space):
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        ship_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            return True
        else:
            return False

    def collision_begin_bullet_bullet(self, arbiter, space):
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet_id2 = arbiter.shapes[1].body.data
        bullet_id1 = arbiter.shapes[0].body.data
        bullet1 = entities[bullet_id1]
        bullet2 = entities[bullet_id2]
        if bullet1['projectile_system']['armed'] and bullet2['projectile_system']['armed']:
            return True
        else:
            return False

    def collision_begin_asteroid_bullet(self, arbiter, space):
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        asteroid_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            return True
        else:
            return False

    def collision_solve_ship_bullet(self, arbiter, space):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        ship_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            bullet_damage = bullet['projectile_system']['damage']
            systems['player_character'].damage(ship_id, bullet_damage)
            if 'point_particle_manager' in bullet:
                self.create_rocket_explosion(bullet_id)
            else:
                Clock.schedule_once(partial(gameworld.timed_remove_entity, bullet_id))
            return True
        else:
            print 'collision with bullet after explosion'
            return False

class PlayerCharacter(GameSystem):
    current_character_id = NumericProperty(None, allownone=True)
    do_fire_engines = BooleanProperty(False)
    updateable = BooleanProperty(True)
    turning = StringProperty('zero')
    touch_values = ListProperty([])
    turn_speed_multiplier = NumericProperty(1.)
    engine_speed_multiplier = NumericProperty(1.)
    character_dying = BooleanProperty(False)
    ship_dicts = DictProperty(None)
    current_projectile_type = StringProperty('_bullet')

    def __init__(self, **kwargs):
        super(PlayerCharacter, self).__init__(**kwargs)
        self.setup_ship_dicts()

    def spawn_player_character(self, character_to_spawn):
        self.spawn_player_character_with_dict(self.ship_dicts[character_to_spawn])

    def setup_ship_dicts(self):
        ship_dicts = self.ship_dicts
        ship_dicts['ship_1'] = {'name': 'Bulldog','health': 180, 'mass': 250, 'max_speed': 150, 
        'max_turn_speed': 65, 'accel': 15000,'angular_accel': 95, 'caliber': '14px', 
        'num_weapons': 2, 'texture': 'assets/ships/ship1-1.png', 'price': 1000,
        'width': 108, 'height': 96, 'offset_distance': 50, 'color': 'green',
        'engine_effect': 'assets/pexfiles/engine_burn_effect3.pex', 'engine_offset': 65,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(46, 59), (-46, 59)]}
        ship_dicts['ship_2'] = {'name': 'Falcon','health': 150, 'mass': 175,'max_speed': 200, 
        'max_turn_speed': 80, 'accel': 20000,'angular_accel': 150, 'caliber': '6px', 
        'num_weapons': 4, 'texture': 'assets/ships/ship3.png', 'price': 1000,
        'width': 130, 'height': 70, 'offset_distance': 50, 'color': 'orange',
        'engine_effect': 'assets/pexfiles/engine_burn_effect4.pex', 'engine_offset': 30,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(38, 30), (-38, 30), (52, 30), (-52, 30)]}
        ship_dicts['ship_3'] = {'name': 'Monarch','health': 165, 'mass': 220,'max_speed': 180, 
        'max_turn_speed': 100, 'accel': 25000,'angular_accel': 200, 'caliber': '8px', 
        'num_weapons': 2, 'texture': 'assets/ships/ship2-1.png', 'price': 1000,
        'width': 90, 'height': 104, 'offset_distance': 50, 'color': 'blue',
        'engine_effect': 'assets/pexfiles/engine_burn_effect2.pex', 'engine_offset': 50,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(28, 51), (-28, 51)]}
        ship_dicts['ship_4'] = {'name': 'Skirmisher','health': 130, 'mass': 140,'max_speed': 220, 
        'max_turn_speed': 85, 'accel': 18000,'angular_accel': 100, 'caliber': '14px', 
        'num_weapons': 1, 'texture': 'assets/ships/ship5.png', 'price': 1000,
        'width': 62, 'height': 100, 'offset_distance': 50, 'color': 'orange',
        'engine_effect': 'assets/pexfiles/engine_burn_effect6.pex', 'engine_offset': 27,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(-18, 63)]}

    def get_ship_values(self, ship_name):
        if ship_name in self.ship_dicts:
            return self.ship_dicts[ship_name] 
        else:
            print 'ship: ', ship_name, 'does not exist'

    def spawn_player_character_with_dict(self, ship_dict):
        box_dict = {'width': ship_dict['width'], 'height': ship_dict['height'],
         'mass': ship_dict['mass']}
        col_shape_dict = {'shape_type': 'box', 'elasticity': .5, 
        'collision_type': 2, 'shape_info': box_dict, 'friction': 1.0}
        physics_component_dict = { 'main_shape': 'box', 
        'velocity': (0, 0), 'position': (500, 500), 'angle': 0, 
        'angular_velocity': 0, 'mass': ship_dict['mass'], 'vel_limit': ship_dict['max_speed'], 
        'ang_vel_limit': math.radians(ship_dict['max_turn_speed']), 'col_shapes': [col_shape_dict]}
        player_character_dict = {'health': ship_dict['health'], 'accel': ship_dict['accel'], 
        'offset_distance': ship_dict['offset_distance'], 'color': ship_dict['color'],
        'ang_accel': math.radians(ship_dict['angular_accel']), 'hard_points': ship_dict['hard_points'], 
        'projectile_type': ship_dict['caliber']}
        particle_system1 = {'particle_file': ship_dict['engine_effect'], 
        'offset': ship_dict['engine_offset']}
        particle_system2 = {'particle_file': ship_dict['explosion_effect'], 'offset': 0}
        particle_systems = {'engine_effect': particle_system1, 'explosion_effect': particle_system2}
        create_component_dict = {'cymunk-physics': physics_component_dict, 
        'physics_renderer': {'texture': ship_dict['texture']}, 
        'player_character': player_character_dict,
        'particle_manager': particle_systems}
        component_order = ['cymunk-physics', 'physics_renderer', 'player_character', 
        'particle_manager']
        self.gameworld.init_entity(create_component_dict, component_order)

    def clear_character(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))

    def on_touch_values(self, instance, value):
        if not self.current_character_id == None:
            entity = self.gameworld.entities[self.current_character_id]
            if not value == []:

                if value[0] <= .33:
                    self.turning = 'left'
                    self.turn_speed_multiplier = 1 - value[0]/.33
                if value[0] >= .66:
                    self.turning = 'right'
                    self.turn_speed_multiplier = (value[0]-.66)/.33
                if .33 < value[0] < .66:
                    self.turning = 'zero'
                if value[1] >= .34:
                    self.do_fire_engines = True
                    self.engine_speed_multiplier = (value[1] - .33 )/ .66 
                    entity['particle_manager']['engine_effect']['particle_system_on'] = True
                if value[1] < .34: 
                    self.do_fire_engines = False
                    entity['particle_manager']['engine_effect']['particle_system_on'] = False
            else:
                self.turning = 'zero'
                self.do_fire_engines = False
                entity['particle_manager']['engine_effect']['particle_system_on'] = False

    def create_component(self, entity_id, entity_component_dict):
        super(PlayerCharacter, self).create_component(entity_id, entity_component_dict)
        self.current_character_id = entity_id
        self.gameworld.systems[self.viewport].entity_to_focus = entity_id


    def remove_entity(self, entity_id):
        self.current_character_id = None
        self.character_dying = False
        super(PlayerCharacter, self).remove_entity(entity_id)

    def fire_projectiles(self, dt):
        if not self.current_character_id == None:
            character = self.gameworld.entities[self.current_character_id]
            projectile_system = self.gameworld.systems['projectile_system']
            system_data = character[self.system_id]
            for hard_point in system_data['hard_points']:
                character_physics = character['cymunk-physics']
                character_position = character_physics['position']
                position_offset = hard_point
                position_offset_rotated = Vector(position_offset).rotate(character_physics['angle'])
                location = (character_position[0] + position_offset_rotated[0],
                    character_position[1] + position_offset_rotated[1])
                angle = character_physics['body'].angle
                projectile_system.spawn_projectile(system_data['projectile_type']+self.current_projectile_type, location, angle, system_data['color'])

    def spawn_projectile(self, state):
        if state == 'down':
            Clock.schedule_once(self.fire_projectiles)
            Clock.schedule_interval(self.fire_projectiles, .5)
        if state == 'normal':
            Clock.unschedule(self.fire_projectiles)
        
    def update(self, dt):
        if not self.current_character_id == None:
            character = self.gameworld.entities[self.current_character_id]
            physics_data = character['cymunk-physics']
            physics_body = physics_data['body']
            system_data = character[self.system_id]
            if self.do_fire_engines and 'unit_vector' in physics_data:   
                unit_vector = physics_data['unit_vector']
                offset = {'x': system_data['offset_distance'] * -unit_vector['x'], 
                'y': system_data['offset_distance'] * -unit_vector['y']}
                force = {'x': self.engine_speed_multiplier * system_data['accel']*dt * -unit_vector['x'], 
                'y': self.engine_speed_multiplier * system_data['accel']*dt * -unit_vector['y']}
                physics_body.apply_impulse(force, offset)
            if physics_body.is_sleeping:
                physics_body.activate()
            if self.turning == 'left':
                physics_body.angular_velocity += self.turn_speed_multiplier*system_data['ang_accel']*dt
            elif self.turning == 'right':
                physics_body.angular_velocity -= self.turn_speed_multiplier*system_data['ang_accel']*dt
            if system_data['health'] <= 0 and not self.character_dying:
                self.do_death()
                self.character_dying = True

    def update_death_animation(self, dt):
        entity = self.gameworld.entities[self.current_character_id]
        entity['physics_renderer']['render'] = False
        entity['particle_manager']['explosion_effect']['particle_system'].emitter_type = 0

    def do_death(self):
        entity = self.gameworld.entities[self.current_character_id]
        entity['particle_manager']['engine_effect']['particle_system_on'] = False
        entity['particle_manager']['explosion_effect']['particle_system_on'] = True
        Clock.schedule_once(self.update_death_animation, .5)
        Clock.schedule_once(partial(self.gameworld.timed_remove_entity, self.current_character_id), 2.0)
        Clock.schedule_once(self.gameworld.parent.player_lose, 4.0)

    def on_turning(self, instance, value):
        if value == 'zero':
            if not self.current_character_id == None:
                character = self.gameworld.entities[self.current_character_id]
                physics_body = character['cymunk-physics']['body']
                physics_body.angular_velocity = 0

    def damage(self, entity_id, damage):
        system_id = self.system_id
        entities = self.gameworld.entities
        entity = entities[entity_id]
        system_data = entity[system_id]
        system_data['health'] -= damage


    def collision_solve_ship_asteroid(self, arbiter, space):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        asteroid_id = arbiter.shapes[1].body.data
        ship_id = arbiter.shapes[0].body.data
        asteroid = entities[asteroid_id]
        asteroid_damage = asteroid['asteroid_system']['damage']
        self.damage(ship_id, asteroid_damage)
        return True


class TestGame(Widget):
    gameworld = ObjectProperty(None)
    state = StringProperty(None)
    number_of_asteroids = NumericProperty(0, allownone=True)
    loading_new_level = BooleanProperty(False)
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
            Clock.schedule_once(self.check_clear)
            

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
            Clock.schedule_once(self.setup_new_level)
    
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