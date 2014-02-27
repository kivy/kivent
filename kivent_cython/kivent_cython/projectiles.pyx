from kivy.clock import Clock
from functools import partial


cdef tuple get_rotated_vector(float angle, float x, float y):
        return ((y * cos(angle)) - (x * sin(angle)), 
            (x * cos(angle)) + (y * sin(angle)))

class ProjectileSystem(GameSystem):

    def __init__(self, **kwargs):
        super(ProjectileSystem, self).__init__(**kwargs)
        self.fire_events = []
        self.setup_projectiles_dicts()

    def add_fire_event(self, int entity_id):
        self.fire_events.append(entity_id)

    def update(self, dt):
        cdef list fire_events = self.fire_events
        gameworld = self.gameworld
        cdef dict systems = gameworld.systems
        cdef list entities = gameworld.entities
        cdef list entity_ids = self.entity_ids
        player_character_system = systems['player_character']
        sound_system = gameworld.systems['sound_system']
        cdef dict projectiles_dict = self.projectiles_dict
        spawn_proj = self.spawn_projectile_with_dict
        fire_projectile = self.fire_projectile
        c_once = Clock.schedule_once
        cdef int num_events = len(fire_events)
        fe_p = fire_events.pop
        cdef int i
        cdef int entity_id
        cdef dict character
        cdef dict ship_system_data
        cdef int current_bullet_ammo, current_rocket_ammo
        cdef str projectile_type
        cdef float projectile_width
        cdef float projectile_height
        cdef dict character_physics
        cdef tuple character_position
        cdef list hard_points
        cdef int number_of_shots
        cdef tuple position_offset
        cdef float angle
        cdef float x, y
        for entity_id in entity_ids:
            entity = entities[entity_id]
            projectile_system = entity['projectile_system']
            if 'particle_manager' not in entity:
                projectile_system['life_span'] += dt
                if projectile_system['life_span'] >= 14.0:
                    c_once(
                        partial(gameworld.timed_remove_entity, entity_id))
        for i in xrange(num_events):
            entity_id = fe_p(0)
            character = entities[entity_id]
            is_character = False
            if entity_id == player_character_system.current_character_id:
                is_character = True
            ship_system_data = character['ship_system']
            current_projectile_type = ship_system_data[
                'current_projectile_type']
            current_bullet_ammo = ship_system_data['current_bullet_ammo']
            current_rocket_ammo = ship_system_data['current_rocket_ammo']
            projectile_type = ship_system_data[
                'projectile_type']+current_projectile_type
            projectile_width = projectiles_dict[projectile_type]['width']
            projectile_height = projectiles_dict[projectile_type]['height']
            character_physics = character['cymunk-physics']
            character_position = (
                character_physics['position'][0], 
                character_physics['position'][1])
            hard_points = ship_system_data['hard_points']
            number_of_shots = len(hard_points)
            if ((current_projectile_type == '_bullet' and 
                 current_bullet_ammo - number_of_shots >= 0) or 
                (current_projectile_type == '_rocket' and 
                current_rocket_ammo - number_of_shots >= 0)):
                for hard_point in hard_points:
                    position_offset = (
                        hard_point[0], hard_point[1] + projectile_height*.5)
                    angle = character_physics['body'].angle
                    x, y = position_offset
                    position_offset_rotated = get_rotated_vector(
                        angle, x, y
                        )
                    location = (
                        character_position[0] + position_offset_rotated[0],
                        character_position[1] + position_offset_rotated[1])
                    bullet_ent_id = spawn_proj(
                        location, angle, ship_system_data['color'], 
                        projectiles_dict[projectile_type])
                    fire_projectile(bullet_ent_id)
                if current_projectile_type == '_bullet':
                    ship_system_data['current_bullet_ammo'] -= number_of_shots
                    c_once(partial(sound_system.schedule_play, 'bulletfire'))  
                if current_projectile_type == '_rocket':
                    ship_system_data['current_rocket_ammo'] -= number_of_shots
                    c_once(partial(sound_system.schedule_play, 'rocketfire'))
                if is_character:
                    player_character_system.current_bullet_ammo = ship_system_data['current_bullet_ammo']
                    player_character_system.current_rocket_ammo = ship_system_data['current_rocket_ammo']

    def create_rocket_explosion(self, entity_id):
        gameworld = self.gameworld
        entities = gameworld.entities
        entity = entities[entity_id]
        
        entity['physics_renderer']['render'] = False
        entity['cymunk-physics']['body'].velocity = (0, 0)
        entity['cymunk-physics']['body'].reset_forces()
        entity['particle_manager'][
            'engine_effect']['particle_system_on'] = False
        entity['particle_manager'][
            'explosion_effect']['particle_system_on'] = True
        if entity['physics_renderer']['on_screen']:
            sound_system = gameworld.systems['sound_system']
            Clock.schedule_once(partial(
                sound_system.schedule_play, 'rocketexplosion'))
        entity['projectile_system']['armed'] = False
        Clock.schedule_once(partial(
            gameworld.timed_remove_entity, entity_id), 2.0)

    def spawn_projectile(self, projectile_type, location, angle, color):
        bullet_ent_id = self.spawn_projectile_with_dict(
            location, angle, color, 
            self.projectiles_dict[projectile_type])
        self.fire_projectile(bullet_ent_id)

    def setup_projectiles_dicts(self):
        self.projectiles_dict = projectiles_dict = {}
        projectiles_dict['14px_bullet'] = {
            'width': 14, 'height': 14, 'mass': 50, 
            'vel_limit': 260, 'ang_vel_limit': 60, 
            'damage': 10, 'cooldown': .25,
            'accel': 25000, 'texture': 'bullet-14px', 
            'type': 'bullet'}
        projectiles_dict['8px_bullet'] = {
            'width': 8, 'height': 8, 'mass': 45, 
            'vel_limit': 275, 'ang_vel_limit': 60, 
            'damage': 9, 'cooldown': .20,
            'accel': 25000, 'texture': 'bullet-8px', 
            'type': 'bullet'}
        projectiles_dict['6px_bullet'] = {
            'width': 6, 'height': 6, 'mass': 35, 
            'vel_limit': 300, 'ang_vel_limit': 60, 
            'damage': 7, 'cooldown': .15,
            'accel': 25000, 'texture': 'bullet-6px', 
            'type': 'bullet'}
        projectiles_dict['14px_rocket'] = {
            'width': 14, 'height': 28, 'mass': 75, 
            'vel_limit': 260, 'ang_vel_limit': 60, 
            'damage': 25, 'cooldown': 1.0,
            'accel': 40000, 'texture': 'rocket-14px', 
            'type': 'rocket'}
        projectiles_dict['8px_rocket'] = {
            'width': 8, 'height': 20, 'mass': 60, 
            'vel_limit': 260, 'ang_vel_limit': 60, 
            'damage': 18, 'cooldown': .9,
            'accel': 25000, 'texture': 'rocket-8px', 
            'type': 'rocket'}
        projectiles_dict['6px_rocket'] = {
            'width': 6, 'height': 14, 'mass': 50, 
            'vel_limit': 260, 'ang_vel_limit': 60, 
            'damage': 11, 'cooldown': .8,
            'accel': 25000, 'texture': 'rocket-6px', 
            'type': 'rocket'}

    def spawn_projectile_with_dict(self, 
        location, angle, color, projectile_dict):
        projectile_box_dict = {
        'width': projectile_dict['width'], 
        'height': projectile_dict['height'], 
        'mass': projectile_dict['mass']}
        projectile_col_shape_dict = {
        'shape_type': 'box', 'elasticity': 1.0, 
        'collision_type': 3, 
        'shape_info': projectile_box_dict, 
        'friction': .3}
        projectile_physics_component_dict = { 
        'main_shape': 'box', 
        'velocity': (0, 0), 
        'position': (location[0], location[1]), 
        'angle': angle, 
        'angular_velocity': 0, 
        'mass': projectile_dict['mass'], 
        'vel_limit': projectile_dict['vel_limit'], 
        'ang_vel_limit': keRadians(projectile_dict['ang_vel_limit']),
        'col_shapes': [projectile_col_shape_dict]}
        projectile_renderer_dict = {
        'texture': projectile_dict['texture'],
            'position_from': 'cymunk-physics', 
            'rotate_from': 'cymunk-physics'}
        create_projectile_dict = {
        'cymunk-physics': projectile_physics_component_dict, 
        'physics_renderer': projectile_renderer_dict, 
        'projectile_system': {'damage': projectile_dict['damage'], 
        'accel': projectile_dict['accel'], 'armed': True, 'life_span': 0.0}}
        component_order = ['cymunk-physics', 'physics_renderer', 
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
                explosion_string = 'assets/pexfiles/rocket_explosion_4.pex'
            particle_system1 = {'particle_file': effect_string, 
            'offset': projectile_dict['height']*.5}
            particle_system2 = {'particle_file': explosion_string, 
                'offset': 0}
            particle_systems = {'engine_effect': particle_system1, 
            'explosion_effect': particle_system2}
            create_projectile_dict['particle_manager'] = particle_systems
            component_order.append('particle_manager')
        bullet_ent_id = self.gameworld.init_entity(
            create_projectile_dict, component_order)
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
        force = bullet_accel*unit_vector[0], bullet_accel*unit_vector[1]
        force_offset = -unit_vector[0], -unit_vector[1]
        bullet_body = bullet['cymunk-physics']['body']
        bullet_body.apply_impulse(force, force_offset)
        if 'particle_manager' in bullet:
            bullet_body.apply_force(force, force_offset)
            bullet['particle_manager'][
                'engine_effect']['particle_system_on'] = True


    def clear_projectiles(self):
        for entity_id in self.entity_ids:
            Clock.schedule_once(
                partial(self.gameworld.timed_remove_entity, entity_id))

    def collision_solve_asteroid_bullet(self, space, arbiter):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        asteroid_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            bullet_damage = bullet['projectile_system']['damage']
            systems['asteroid_system'].damage(asteroid_id, bullet_damage)
            if 'particle_manager' in bullet:
                self.create_rocket_explosion(bullet_id)
            else:
                bullet['projectile_system']['armed'] = False
                Clock.schedule_once(
                    partial(gameworld.timed_remove_entity, bullet_id))
            return True
        else:
            return False

    def collision_solve_bullet_bullet(self, space, arbiter):
        bullet_id2 = arbiter.shapes[1].body.data
        bullet_id1 = arbiter.shapes[0].body.data
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet1 = entities[bullet_id1]
        bullet2 = entities[bullet_id2]
        if bullet1['projectile_system']['armed'] and bullet2['projectile_system']['armed']:
            if 'particle_manager' in bullet1:
                self.create_rocket_explosion(bullet_id1)
            else:
                bullet1['projectile_system']['armed'] = False
                Clock.schedule_once(
                    partial(gameworld.timed_remove_entity, bullet_id1))
            if 'particle_manager' in bullet2:
                self.create_rocket_explosion(bullet_id2)
            else:
                bullet2['projectile_system']['armed'] = False
                Clock.schedule_once(
                    partial(gameworld.timed_remove_entity, bullet_id2))

    def collision_begin_ship_bullet(self, space, arbiter):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        sound_system = systems['sound_system']
        bullet_id = arbiter.shapes[1].body.data
        character_id = systems['player_character'].current_character_id
        ship_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            if character_id == ship_id:
                Clock.schedule_once(partial(
                    sound_system.schedule_play, 'shiphitbybullet'))
            return True
        else:
            return False

    def collision_begin_bullet_bullet(self, space, arbiter):
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet_id2 = arbiter.shapes[1].body.data
        bullet_id1 = arbiter.shapes[0].body.data
        bullet1 = entities[bullet_id1]
        bullet2 = entities[bullet_id2]
        if bullet1['projectile_system']['armed'] and bullet2['projectile_system']['armed']:
            if bullet1['physics_renderer']['on_screen'] or bullet2['physics_renderer']['on_screen']:
                sound_system = gameworld.systems['sound_system']
                Clock.schedule_once(partial(sound_system.schedule_play, 'bullethitbullet'))
            return True
        else:
            return False

    def collision_begin_asteroid_bullet(self, space, arbiter):
        gameworld = self.gameworld
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        asteroid_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            if bullet['physics_renderer']['on_screen']:
                sound_system = gameworld.systems['sound_system']
                Clock.schedule_once(
                    partial(sound_system.schedule_play, 'bullethitasteroid'))
            return True
        else:
            return False

    def collision_solve_ship_bullet(self, space, arbiter):
        gameworld = self.gameworld
        systems = gameworld.systems
        entities = gameworld.entities
        bullet_id = arbiter.shapes[1].body.data
        ship_id = arbiter.shapes[0].body.data
        bullet = entities[bullet_id]
        if bullet['projectile_system']['armed']:
            bullet_damage = bullet['projectile_system']['damage']
            systems['ship_system'].damage(ship_id, bullet_damage)
            if 'particle_manager' in bullet:
                self.create_rocket_explosion(bullet_id)
            else:
                bullet['projectile_system']['armed'] = False
                Clock.schedule_once(
                    partial(gameworld.timed_remove_entity, bullet_id))
            return True
        else:
            print 'collision with bullet after explosion'
            return False