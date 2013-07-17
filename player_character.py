from kivy.properties import (StringProperty, ListProperty, 
NumericProperty, BooleanProperty, DictProperty)
from kivent_cython import (GameSystem)
from kivy.clock import Clock
from functools import partial
from kivy.vector import Vector
import math

class ShipAISystem(GameSystem):
    updateable = BooleanProperty(True)

    def calculate_desired_angle_delta(self, target_position, current_position, unit_vector):
        vector_between_ships = Vector(target_position) - Vector(current_position)
        unit_vector = (unit_vector['x'], unit_vector['y'])
        desired_angle_delta = Vector(unit_vector).angle((vector_between_ships[0], vector_between_ships[1]))
        return desired_angle_delta

    def calculate_target_position(self, offset_distance):
        gameworld = self.gameworld
        entities = gameworld.entities
        character_system = gameworld.systems['player_character']
        current_player_character_id = character_system.current_character_id
        if current_player_character_id:
            current_player_character = entities[current_player_character_id]
            physics_data = current_player_character['cymunk-physics']
            unit_vector = physics_data['unit_vector']
            position = physics_data['position']
            return (offset_distance * -unit_vector['x'] + position[0], 
                offset_distance * -unit_vector['y'] + position[1])

    def do_turning(self, position, unit_vector, turn_speed, ship_data, physics_body):
        gameworld = self.gameworld
        entities = gameworld.entities
        character_system = gameworld.systems['player_character']
        current_player_character_id = character_system.current_character_id
        if current_player_character_id:
            current_player_character = entities[current_player_character_id]
            target_physics_data = current_player_character['cymunk-physics']
            target_position = target_physics_data['position']
            desired_angle_change = self.calculate_desired_angle_delta(target_position, 
            position, unit_vector)
            desired_multiplier = math.fabs(desired_angle_change / math.degrees(turn_speed))
            ship_data['turn_speed_multiplier'] = min(1.0, desired_multiplier)
            if desired_angle_change < -1:
                ship_data['is_turning'] = 'left'
            if desired_angle_change > 1:
                ship_data['is_turning'] = 'right'
            if -1 <= desired_angle_change <= 1:
                ship_data['is_turning'] = 'zero'
                physics_body.angular_velocity = 0

    def do_thrusting(self, position, ship_data, entity, follow_distance, dt):
        gameworld = self.gameworld
        entities = gameworld.entities
        character_system = gameworld.systems['player_character']
        current_player_character_id = character_system.current_character_id
        if current_player_character_id:
            current_player_character = entities[current_player_character_id]
            target_physics_data = current_player_character['cymunk-physics']
            target_position = target_physics_data['position']
            distance_to_target = Vector(position).distance(target_position)
            thrust_speed = ship_data['accel']
            desired_multiplier = distance_to_target/(thrust_speed*dt)
            print desired_multiplier
            ship_data['engine_speed_multiplier'] = min(1.0, desired_multiplier)
            print distance_to_target
            if distance_to_target > follow_distance:
                ship_data['fire_engines'] = True
                entity['particle_manager']['engine_effect']['particle_system_on'] = True
            else: 
                ship_data['fire_engines'] = False
                entity['particle_manager']['engine_effect']['particle_system_on'] = False

    def update(self, dt):
        gameworld = self.gameworld
        entities = gameworld.entities
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            system_data = entity[self.system_id]
            physics_data = entity['cymunk-physics']
            ship_data = entity['ship_system']
            physics_body = physics_data['body']
            follow_distance = system_data['follow_distance']
            position = physics_data['position']
            turn_speed = ship_data['ang_accel']
            unit_vector = physics_data['unit_vector']
            current_angle = physics_data['angle']
            self.do_turning(position, unit_vector, turn_speed, ship_data, physics_body)
            self.do_thrusting(position, ship_data, entity, follow_distance, dt)
            
            
            

            
            

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
        gameworld = self.gameworld
        sound_system = gameworld.systems['sound_system']
        entity = gameworld.entities[entity_id]
        entity['particle_manager']['engine_effect']['particle_system_on'] = False
        entity['particle_manager']['explosion_effect']['particle_system_on'] = True
        sound_system.play('shipexplosion')
        Clock.schedule_once(partial(self.update_death_animation, entity_id), .5)
        Clock.schedule_once(partial(self.gameworld.timed_remove_entity, 
            entity_id), 2.0)
        if 'player_character' in entity:
            Clock.schedule_once(self.gameworld.parent.player_lose, 4.0)


    def spawn_player_character(self, character_to_spawn):
        self.spawn_ship_with_dict(self.ship_dicts[character_to_spawn], True, (500, 500))

    def setup_ship_dicts(self):
        ship_dicts = self.ship_dicts
        ship_dicts['ship_1'] = {'name': 'Bulldog','health': 180, 'mass': 250, 'max_speed': 150, 
        'max_turn_speed': 90, 'accel': 15000,'angular_accel': 45, 'caliber': '14px', 
        'num_weapons': 2, 'texture': 'assets/ships/ship1-1.png', 'price': 1000,
        'width': 108, 'height': 96, 'offset_distance': 50, 'color': 'green',
        'engine_effect': 'assets/pexfiles/engine_burn_effect3.pex', 'engine_offset': 65,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(46, 59), (-46, 59)]}
        ship_dicts['ship_2'] = {'name': 'Falcon','health': 150, 'mass': 175,'max_speed': 190, 
        'max_turn_speed': 100, 'accel': 20000,'angular_accel': 75, 'caliber': '6px', 
        'num_weapons': 4, 'texture': 'assets/ships/ship3.png', 'price': 1000,
        'width': 130, 'height': 70, 'offset_distance': 50, 'color': 'orange',
        'engine_effect': 'assets/pexfiles/engine_burn_effect4.pex', 'engine_offset': 30,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(38, 30), (-38, 30), (52, 30), (-52, 30)]}
        ship_dicts['ship_3'] = {'name': 'Monarch','health': 165, 'mass': 220,'max_speed': 180, 
        'max_turn_speed': 130, 'accel': 25000,'angular_accel': 100, 'caliber': '8px', 
        'num_weapons': 2, 'texture': 'assets/ships/ship2-1.png', 'price': 1000,
        'width': 90, 'height': 104, 'offset_distance': 50, 'color': 'blue',
        'engine_effect': 'assets/pexfiles/engine_burn_effect2.pex', 'engine_offset': 50,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(28, 51), (-28, 51)]}
        ship_dicts['ship_4'] = {'name': 'Archon','health': 130, 'mass': 140,'max_speed': 200, 
        'max_turn_speed': 110, 'accel': 18000,'angular_accel': 50, 'caliber': '14px', 
        'num_weapons': 1, 'texture': 'assets/ships/ship5.png', 'price': 1000,
        'width': 62, 'height': 100, 'offset_distance': 50, 'color': 'orange',
        'engine_effect': 'assets/pexfiles/engine_burn_effect6.pex', 'engine_offset': 27,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(-18, 63)]}
        ship_dicts['ship_5'] = {'name': 'Cavalier','health': 110, 'mass': 120,'max_speed': 220, 
        'max_turn_speed': 125, 'accel': 22000,'angular_accel': 45, 'caliber': '8px', 
        'num_weapons': 1, 'texture': 'assets/ships/ship6.png', 'price': 1000,
        'width': 66, 'height': 80, 'offset_distance': 50, 'color': 'green',
        'engine_effect': 'assets/pexfiles/engine_burn_effect8.pex', 'engine_offset': 47,
        'explosion_effect': 'assets/pexfiles/ship_explosion1.pex',
        'hard_points': [(0, 47)]}
        ship_dicts['ship_6'] = {'name': 'Shield','health': 150, 'mass': 160,'max_speed': 180, 
        'max_turn_speed': 150, 'accel': 25000,'angular_accel': 115, 'caliber': '6px', 
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
        sound_system = gameworld.systems['sound_system']
        ship_system_data = character['ship_system']
        current_projectile_type = ship_system_data['current_projectile_type']
        projectiles_dict = projectile_system.projectiles_dict
        projectile_type = ship_system_data['projectile_type']+current_projectile_type
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
        if current_projectile_type == '_bullet':
            sound_system.play('bulletfire')
        if current_projectile_type == '_rocket':
            sound_system.play('rocketfire')

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
                force = {'x': system_data['engine_speed_multiplier'] * system_data['accel']*dt * unit_vector['x'], 
                'y': system_data['engine_speed_multiplier'] * system_data['accel']*dt * unit_vector['y']}
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
        if system_data['health'] < 0:
            system_data['health'] = 0
        player_character_system = self.gameworld.systems['player_character']
        if entity_id == player_character_system.current_character_id:
            player_character_system.current_health = system_data['health']

    def collision_begin_ship_probe(self, arbiter, space):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        probe_id = arbiter.shapes[1].body.data
        ship_id = arbiter.shapes[0].body.data
        probe = entities[probe_id]
        ship = entities[ship_id]
        ship['ship_system']['current_probes'] += 1
        sound_system = systems['sound_system']
        sound_system.play('asteroidhitship')
        Clock.schedule_once(partial(gameworld.timed_remove_entity, probe_id))
        return False

    def collision_begin_ship_asteroid(self, arbiter, space):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        asteroid_id = arbiter.shapes[1].body.data
        ship_id = arbiter.shapes[0].body.data
        asteroid = entities[asteroid_id]
        asteroid_damage = asteroid['asteroid_system']['damage']
        self.damage(ship_id, asteroid_damage)
        sound_system = systems['sound_system']
        sound_system.play('asteroidhitship')
        return True 

    def spawn_ship_with_dict(self, ship_dict, is_player_character, position):
        box_dict = {'width': ship_dict['width'], 'height': ship_dict['height'],
         'mass': ship_dict['mass']}
        col_shape_dict = {'shape_type': 'box', 'elasticity': .5, 
        'collision_type': 2, 'shape_info': box_dict, 'friction': 1.0}
        physics_component_dict = { 'main_shape': 'box', 
        'velocity': (0, 0), 'position': position, 'angle': 0, 
        'angular_velocity': 0, 'mass': ship_dict['mass'], 'vel_limit': ship_dict['max_speed'], 
        'ang_vel_limit': math.radians(ship_dict['max_turn_speed']), 'col_shapes': [col_shape_dict]}
        ship_system_dict = {'health': ship_dict['health'], 'accel': ship_dict['accel'], 
        'offset_distance': ship_dict['offset_distance'], 'color': ship_dict['color'],
        'ang_accel': math.radians(ship_dict['angular_accel']), 'hard_points': ship_dict['hard_points'], 
        'projectile_type': ship_dict['caliber'], 'is_turning': 'zero', 'fire_engines': False, 
        'turn_speed_multiplier': 0, 'engine_speed_multiplier': 0, 'character_dying': False,
        'current_projectile_type': '_bullet', 'current_probes': 0}
        particle_system1 = {'particle_file': ship_dict['engine_effect'], 
        'offset': ship_dict['engine_offset']}
        particle_system2 = {'particle_file': ship_dict['explosion_effect'], 'offset': 0}
        particle_systems = {'engine_effect': particle_system1, 'explosion_effect': particle_system2}
        create_component_dict = {'cymunk-physics': physics_component_dict, 
        'physics_renderer': {'texture': ship_dict['texture']}, 
        'ship_system': ship_system_dict,
        'particle_manager': particle_systems}
        component_order = ['cymunk-physics', 'physics_renderer', 'ship_system',
         'particle_manager']
        if is_player_character:
            create_component_dict['player_character'] = {}
            component_order.append('player_character')
        else:
            create_component_dict['ship_ai_system'] = {'follow_distance': 250}
            component_order.append('ship_ai_system')
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


class ProbeSystem(GameSystem):
    updateable = BooleanProperty(True)

    def __init__(self, **kwargs):
        super(ProbeSystem, self).__init__(**kwargs)
        self.probe_dict = {}
        self.setup_probe_dict()

    def clear_probes(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(partial(self.gameworld.timed_remove_entity, entity_id))

    def update(self, dt):
        gameworld = self.gameworld
        entities = gameworld.entities
        for entity_id in self.entity_ids:
            entity = entities[entity_id]
            system_data = entity['probe_system']
            physics_data = entity['cymunk-physics']
            unit_vector = physics_data['unit_vector']
            system_data['position'] = (physics_data['position'][0] - unit_vector['x']*system_data['offset'],
                physics_data['position'][1] - unit_vector['y']*system_data['offset'])

            color = system_data['color']
            if color[3] >= 1.0:
                system_data['color_change'] = 'descending'
            if color[3] <= 0.:
                system_data['color_change'] = 'ascending'
            color_change = system_data['color_change']
            if color_change == 'ascending':
                new_alpha = color[3] + system_data['color_change_speed']*dt
                system_data['color'] = (color[0], color[1], color[2], new_alpha)
            if color_change == 'descending':
                new_alpha = color[3] - system_data['color_change_speed']*dt
                system_data['color'] = (color[0], color[1], color[2], new_alpha)

    def setup_probe_dict(self):
        self.probe_dict['probe1'] = {'inner_radius': 0, 'outer_radius': 16, 'mass': 100,
        'max_speed': 280, 'max_turn_speed': 180, 'texture': 'assets/ships/probe.png', 'offset': 5,
        'color': (0.788235294, 0.643137255, 1., 1.), 'color_change_speed': 1., 
        'lighting_texture': 'assets/ships/probelight.png'}

    def spawn_probe_with_dict(self, probe_dict, position):
        circle_dict = {'inner_radius': probe_dict['inner_radius'], 
        'outer_radius': probe_dict['outer_radius'], 'mass': probe_dict['mass'], 
        'offset': (0, 0)}
        col_shape_dict = {'shape_type': 'circle', 'elasticity': .5, 
        'collision_type': 4, 'shape_info': circle_dict, 'friction': 1.0}
        physics_component_dict = { 'main_shape': 'box', 
        'velocity': (0, 0), 'position': position, 'angle': 0, 
        'angular_velocity': 0, 'mass': probe_dict['mass'], 'vel_limit': probe_dict['max_speed'], 
        'ang_vel_limit': math.radians(probe_dict['max_turn_speed']), 'col_shapes': [col_shape_dict]}
        probe_system_dict = {'color': probe_dict['color'], 'offset': probe_dict['offset'], 
        'color_change_speed': probe_dict['color_change_speed'], 'color_change': 'ascending',
        'position': position}
        create_component_dict = {'cymunk-physics': physics_component_dict, 
        'physics_renderer': {'texture': probe_dict['texture']}, 
        'lighting_renderer': {'texture': probe_dict['lighting_texture'], 
        'size': (probe_dict['outer_radius']*2, probe_dict['outer_radius']*2)}, 
        'probe_system': probe_system_dict}
        component_order = ['cymunk-physics', 'physics_renderer', 'probe_system', 'lighting_renderer']
        self.gameworld.init_entity(create_component_dict, component_order)
    