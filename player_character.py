from kivy.properties import (StringProperty, ListProperty, 
NumericProperty, BooleanProperty, DictProperty)
from kivent_cython import (GameSystem)
from kivy.clock import Clock
from functools import partial
from kivy.vector import Vector
import math

class ShipSystem(GameSystem):
    ship_dicts = DictProperty(None)
    updateable = BooleanProperty(True)

    def __init__(self, **kwargs):
        super(ShipSystem, self).__init__(**kwargs)
        self.setup_ship_dicts()

    def update_death_animation(self, entity_id, dt):
        entity = self.gameworld.entities[entity_id]
        entity['physics_renderer']['render'] = False
        entity['particle_manager']['explosion_effect']['particle_system'].emitter_type = 0

    def do_death(self, entity_id):
        entity = self.gameworld.entities[entity_id]
        entity['particle_manager']['engine_effect']['particle_system_on'] = False
        entity['particle_manager']['explosion_effect']['particle_system_on'] = True
        Clock.schedule_once(partial(self.update_death_animation, entity_id), .5)
        Clock.schedule_once(partial(self.gameworld.timed_remove_entity, 
            entity_id), 2.0)
        Clock.schedule_once(self.gameworld.parent.player_lose, 4.0)


    def spawn_player_character(self, character_to_spawn):
        self.spawn_ship_with_dict(self.ship_dicts[character_to_spawn])

    def setup_ship_dicts(self):
        ship_dicts = self.ship_dicts
        ship_dicts['ship_1'] = {'name': 'Bulldog','health': 180, 'mass': 250, 'max_speed': 150, 
        'max_turn_speed': 65, 'accel': 15000,'angular_accel': 95, 'caliber': '14px', 
        'num_weapons': 2, 'texture': 'assets/ships/ship1-1.png', 'price': 1000,
        'width': 108, 'height': 96, 'offset_distance': 50, 'color': 'green',
        'engine_effect': 'assets/pexfiles/engine_burn_effect3.pex', 'engine_offset': 65,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(46, 59), (-46, 59)]}
        ship_dicts['ship_2'] = {'name': 'Falcon','health': 150, 'mass': 175,'max_speed': 190, 
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
        ship_dicts['ship_4'] = {'name': 'Archon','health': 130, 'mass': 140,'max_speed': 200, 
        'max_turn_speed': 85, 'accel': 18000,'angular_accel': 100, 'caliber': '14px', 
        'num_weapons': 1, 'texture': 'assets/ships/ship5.png', 'price': 1000,
        'width': 62, 'height': 100, 'offset_distance': 50, 'color': 'orange',
        'engine_effect': 'assets/pexfiles/engine_burn_effect6.pex', 'engine_offset': 27,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(-18, 63)]}
        ship_dicts['ship_5'] = {'name': 'Cavalier','health': 110, 'mass': 120,'max_speed': 220, 
        'max_turn_speed': 125, 'accel': 22000,'angular_accel': 90, 'caliber': '8px', 
        'num_weapons': 1, 'texture': 'assets/ships/ship6.png', 'price': 1000,
        'width': 66, 'height': 80, 'offset_distance': 50, 'color': 'green',
        'engine_effect': 'assets/pexfiles/engine_burn_effect8.pex', 'engine_offset': 47,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(0, 47)]}
        ship_dicts['ship_6'] = {'name': 'Shield','health': 150, 'mass': 160,'max_speed': 180, 
        'max_turn_speed': 150, 'accel': 25000,'angular_accel': 235, 'caliber': '6px', 
        'num_weapons': 2, 'texture': 'assets/ships/ship7.png', 'price': 1000,
        'width': 76, 'height': 80, 'offset_distance': 50, 'color': 'blue',
        'engine_effect': 'assets/pexfiles/engine_burn_effect9.pex', 'engine_offset': 45,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(-6, 47), (6, 47)]}
        
    def get_ship_values(self, ship_name):
        if ship_name in self.ship_dicts:
            return self.ship_dicts[ship_name] 
        else:
            print 'ship: ', ship_name, 'does not exist'

    def clear_ships(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))

    def fire_projectiles(self, entity_id):
        gameworld = self.gameworld
        character = gameworld.entities[entity_id]
        projectile_system = gameworld.systems['projectile_system']
        ship_system_data = character['ship_system']
        projectiles_dict = projectile_system.projectiles_dict
        projectile_type = ship_system_data['projectile_type']+ship_system_data['current_projectile_type']
        projectile_width = projectiles_dict[projectile_type]['width']
        projectile_height = projectiles_dict[projectile_type]['height']
        character_physics = character['cymunk-physics']
        character_position = character_physics['position']
        for hard_point in ship_system_data['hard_points']:
            
            position_offset = hard_point[0], hard_point[1] + projectile_height*.5
            position_offset_rotated = Vector(position_offset).rotate(character_physics['angle'])
            location = (character_position[0] + position_offset_rotated[0],
                character_position[1] + position_offset_rotated[1])
            angle = character_physics['body'].angle
            projectile_system.spawn_projectile(projectile_type, location, 
                angle, ship_system_data['color'])

    def update(self, dt):
        for entity_id in self.entity_ids:
            character = self.gameworld.entities[entity_id]
            physics_data = character['cymunk-physics']
            physics_body = physics_data['body']
            system_data = character[self.system_id]
            if system_data['fire_engines'] and 'unit_vector' in physics_data:   
                unit_vector = physics_data['unit_vector']
                offset = {'x': system_data['offset_distance'] * -unit_vector['x'], 
                'y': system_data['offset_distance'] * -unit_vector['y']}
                force = {'x': system_data['engine_speed_multiplier'] * system_data['accel']*dt * -unit_vector['x'], 
                'y': system_data['engine_speed_multiplier'] * system_data['accel']*dt * -unit_vector['y']}
                physics_body.apply_impulse(force, offset)
            if physics_body.is_sleeping:
                physics_body.activate()
            turning = system_data['is_turning']
            if turning == 'left':
                physics_body.angular_velocity += system_data['turn_speed_multiplier']*system_data['ang_accel']*dt
            elif turning == 'right':
                physics_body.angular_velocity -= system_data['turn_speed_multiplier']*system_data['ang_accel']*dt
            if system_data['health'] <= 0 and not system_data['character_dying']:
                self.do_death(entity_id)
                system_data['character_dying'] = True
                
    def damage(self, entity_id, damage):
        system_id = self.system_id
        entities = self.gameworld.entities
        entity = entities[entity_id]
        system_data = entity[system_id]
        system_data['health'] -= damage
        self.gameworld.systems['player_character'].current_health = system_data['health']

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

    def spawn_ship_with_dict(self, ship_dict):
        box_dict = {'width': ship_dict['width'], 'height': ship_dict['height'],
         'mass': ship_dict['mass']}
        col_shape_dict = {'shape_type': 'box', 'elasticity': .5, 
        'collision_type': 2, 'shape_info': box_dict, 'friction': 1.0}
        physics_component_dict = { 'main_shape': 'box', 
        'velocity': (0, 0), 'position': (500, 500), 'angle': 0, 
        'angular_velocity': 0, 'mass': ship_dict['mass'], 'vel_limit': ship_dict['max_speed'], 
        'ang_vel_limit': math.radians(ship_dict['max_turn_speed']), 'col_shapes': [col_shape_dict]}
        ship_system_dict = {'health': ship_dict['health'], 'accel': ship_dict['accel'], 
        'offset_distance': ship_dict['offset_distance'], 'color': ship_dict['color'],
        'ang_accel': math.radians(ship_dict['angular_accel']), 'hard_points': ship_dict['hard_points'], 
        'projectile_type': ship_dict['caliber'], 'is_turning': 'zero', 'fire_engines': False, 
        'turn_speed_multiplier': 0, 'engine_speed_multiplier': 0, 'character_dying': False,
        'current_projectile_type': '_bullet'}
        particle_system1 = {'particle_file': ship_dict['engine_effect'], 
        'offset': ship_dict['engine_offset']}
        particle_system2 = {'particle_file': ship_dict['explosion_effect'], 'offset': 0}
        particle_systems = {'engine_effect': particle_system1, 'explosion_effect': particle_system2}
        create_component_dict = {'cymunk-physics': physics_component_dict, 
        'physics_renderer': {'texture': ship_dict['texture']}, 
        'ship_system': ship_system_dict,
        'particle_manager': particle_systems, 'player_character': {}}
        component_order = ['cymunk-physics', 'physics_renderer', 'ship_system',
         'player_character', 'particle_manager']
        self.gameworld.init_entity(create_component_dict, component_order)

class PlayerCharacter(GameSystem):
    current_character_id = NumericProperty(None, allownone=True)
    touch_values = ListProperty([])
    current_health = NumericProperty(1., allownone=True)
    current_projectile_type = StringProperty('_bullet')
    weapons_locked = BooleanProperty(False)
    total_health = NumericProperty(1., allownone=True)

    def __init__(self, **kwargs):
        super(PlayerCharacter, self).__init__(**kwargs) 

    def on_weapons_locked(self, instance, value):
        if value == True:
            gameworld = self.gameworld
            character = gameworld.entities[self.current_character_id]
            projectile_system = gameworld.systems['projectile_system']
            system_data = character[self.system_id]
            ship_system_data = character['ship_system']
            current_projectile_dict = projectile_system.projectiles_dict[
                ship_system_data['projectile_type']+self.current_projectile_type]
            cooldown = current_projectile_dict['cooldown']
            Clock.schedule_once(self.reset_weapon_lock, cooldown)

    def reset_weapon_lock(self, dt):
        self.weapons_locked = False

    def on_touch_values(self, instance, value):
        if not self.current_character_id == None:
            entity = self.gameworld.entities[self.current_character_id]
            ship_system_data = entity['ship_system']
            physics_body = entity['cymunk-physics']['body']
            if not value == []:

                if value[0] <= .33:
                    ship_system_data['is_turning'] = 'left'
                    ship_system_data['turn_speed_multiplier'] = 1 - value[0]/.33
                if value[0] >= .66:
                    ship_system_data['is_turning'] = 'right'
                    ship_system_data['turn_speed_multiplier'] = (value[0]-.66)/.33
                if .33 < value[0] < .66:
                    ship_system_data['is_turning'] = 'zero'
                    physics_body.angular_velocity = 0
                if value[1] >= .34:
                    ship_system_data['fire_engines'] = True
                    ship_system_data['engine_speed_multiplier'] = (value[1] - .33 )/ .66 
                    entity['particle_manager']['engine_effect']['particle_system_on'] = True
                if value[1] < .34: 
                    ship_system_data['fire_engines'] = False
                    entity['particle_manager']['engine_effect']['particle_system_on'] = False
            else:
                ship_system_data['is_turning'] = 'zero'
                ship_system_data['fire_engines'] = False

                physics_body.angular_velocity = 0
                entity['particle_manager']['engine_effect']['particle_system_on'] = False

    def create_component(self, entity_id, entity_component_dict):
        super(PlayerCharacter, self).create_component(entity_id, entity_component_dict)
        self.current_character_id = entity_id
        ship_dict = self.gameworld.entities[entity_id]['ship_system']
        self.gameworld.systems[self.viewport].entity_to_focus = entity_id
        self.total_health = ship_dict['health']
        self.current_health = ship_dict['health']


    def remove_entity(self, entity_id):
        self.current_character_id = None
        super(PlayerCharacter, self).remove_entity(entity_id)

    def fire_projectiles(self, dt):
        if not self.current_character_id == None:
            if not self.weapons_locked:
                ship_system = self.gameworld.systems['ship_system']
                ship_system.fire_projectiles(self.current_character_id)
                self.weapons_locked = True
                
    def spawn_projectile(self, state):
        if state == 'down':
            Clock.schedule_once(self.fire_projectiles)
        
    def on_current_projectile_type(self, instance, value):
        self.weapons_locked = True
        character = self.gameworld.entities[self.current_character_id]
        character['ship_system']['current_projectile_type'] = value
       


    