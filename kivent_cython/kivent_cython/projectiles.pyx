from kivy.clock import Clock
from functools import partial


cdef class ProjectileComponent:
    cdef float _damage
    cdef float _accel
    cdef bool _armed
    cdef float _lifespan
    cdef list _linked
    
    def __cinit__(self, float damage, float accel, 
        bool armed, float life_span):
        self._damage = damage
        self._accel = accel
        self._armed = armed
        self._linked = []
        self._lifespan = life_span

    property damage:
        def __get__(self):
            return self._damage
        def __set__(self, float value):
            self._damage = value

    property accel:
        def __get__(self):
            return self._accel
        def __set__(self, float value):
            self._accel = value

    property lifespan:
        def __get__(self):
            return self._lifespan
        def __set__(self, float value):
            self._lifespan = value

    property armed:
        def __get__(self):
            return self._armed
        def __set__(self, bool value):
            self._armed = value

    property linked:
        def __get__(self):
            return self._linked
        def __set__(self, list value):
            self._linked = value

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
        timed_remove_entity = gameworld.timed_remove_entity
        fe_p = fire_events.pop
        cdef int i
        cdef int entity_id
        cdef object character
        cdef int current_bullet_ammo, current_rocket_ammo
        cdef str projectile_type
        cdef float projectile_width
        cdef float projectile_height
        cdef PhysicsComponent character_physics
        cdef PositionComponent character_position
        cdef list hard_points
        cdef int number_of_shots
        cdef tuple position_offset
        cdef float angle
        cdef float x, y
        for entity_id in entity_ids:
            entity = entities[entity_id]
            projectile_system = entity.projectile_system
            if not hasattr(projectile_system, 'linked'): 
                projectile_system._lifespan += dt
                if projectile_system._lifespan >= 14.0:
                    c_once(
                        partial(timed_remove_entity, entity_id))
        for i in xrange(num_events):
            entity_id = fe_p(0)
            character = entities[entity_id]
            is_character = False
            if entity_id == player_character_system.current_character_id:
                is_character = True
            ship_system_data = character.ship_system
            current_projectile_type = ship_system_data.current_projectile_type
            current_bullet_ammo = ship_system_data.current_bullet_ammo
            current_rocket_ammo = ship_system_data.current_rocket_ammo
            projectile_type = ship_system_data.projectile_type + current_projectile_type
            projectile = projectiles_dict[projectile_type]
            projectile_width = projectile['width']
            projectile_height = projectile['height']
            character_physics = character.cymunk_physics
            character_position = character.position
            hard_points = ship_system_data.hard_points
            number_of_shots = len(hard_points)
            if ((current_projectile_type == '_bullet' and 
                 current_bullet_ammo - number_of_shots >= 0) or 
                (current_projectile_type == '_rocket' and 
                current_rocket_ammo - number_of_shots >= 0)):
                for hard_point in hard_points:
                    position_offset = (
                        hard_point[0], hard_point[1] + projectile_height*.5)
                    angle = character_physics.body.angle
                    x, y = position_offset
                    position_offset_rotated = get_rotated_vector(
                        angle, x, y
                        )
                    location = (
                        character_position._x + position_offset_rotated[0],
                        character_position._y + position_offset_rotated[1])
                    bullet_ent_id = spawn_proj(
                        location, angle, ship_system_data.color, 
                        projectiles_dict[projectile_type])
                    fire_projectile(bullet_ent_id)
                if current_projectile_type == '_bullet':
                    ship_system_data.current_bullet_ammo -= number_of_shots
                    c_once(partial(sound_system.schedule_play, 'bulletfire'))  
                if current_projectile_type == '_rocket':
                    ship_system_data.current_rocket_ammo -= number_of_shots
                    c_once(partial(sound_system.schedule_play, 'rocketfire'))
                if is_character:
                    player_character_system.current_bullet_ammo = ship_system_data.current_bullet_ammo
                    player_character_system.current_rocket_ammo = ship_system_data.current_rocket_ammo

    def remove_entity(self, int entity_id):
        gameworld = self.gameworld
        entities = gameworld.entities
        entity = entities[entity_id]
        if hasattr(entity.projectile_system, 'linked'):
            linked = entity.projectile_system.linked
            for each in linked:
                gameworld.remove_entity(each)
        super(ProjectileSystem, self).remove_entity(entity_id)

    def create_rocket_explosion(self, entity_id):
        gameworld = self.gameworld
        entities = gameworld.entities
        entity = entities[entity_id]
        entity.physics_renderer.render = False
        entity.cymunk_physics.body.velocity = (0, 0)
        entity.cymunk_physics.body.reset_forces()
        projectile_data = entity.projectile_system
        linked = projectile_data.linked
        engine_effect_id = linked[0]
        explosion_effect_id = linked[1]
        engine_effect = entities[engine_effect_id].particles
        explosion_effect = entities[explosion_effect_id].particles
        engine_effect.system_on = False
        explosion_effect.system_on = True
        if entity.physics_renderer.on_screen:
            sound_system = gameworld.systems['sound_system']
            Clock.schedule_once(partial(
                sound_system.schedule_play, 'rocketexplosion'))
        projectile_data.armed = False
        Clock.schedule_once(partial(
            gameworld.timed_remove_entity, entity_id), 2.0)

    def spawn_projectile(self, projectile_type, location, angle, color):
        bullet_ent_id = self.spawn_projectile_with_dict(
            location, angle, color, 
            self.projectiles_dict[projectile_type])
        self.fire_projectile(bullet_ent_id)

    def generate_component(self, tuple projectile_args):
        new_component = ProjectileComponent.__new__(ProjectileComponent, 
            projectile_args[0], projectile_args[1], projectile_args[2], 
            projectile_args[3])
        return new_component

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
        gameworld = self.gameworld
        init_entity = gameworld.init_entity
        entities = gameworld.entities
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
            'position': location, 
            'angle': angle, 
            'angular_velocity': 0, 
            'mass': projectile_dict['mass'], 
            'vel_limit': projectile_dict['vel_limit'], 
            'ang_vel_limit': keRadians(projectile_dict['ang_vel_limit']),
            'col_shapes': [projectile_col_shape_dict]}
        projectile_renderer_dict = {
            'texture': projectile_dict['texture'], 
            'size': (projectile_dict['width'], projectile_dict['height'])}
        create_projectile_dict = {
            'position': location,
            'rotate': angle,
            'cymunk_physics': projectile_physics_component_dict, 
            'physics_renderer': projectile_renderer_dict, 
            'projectile_system': (projectile_dict['damage'], 
                projectile_dict['accel'], True, 0.0)}
        component_order = ['position', 'rotate', 'cymunk_physics', 
            'physics_renderer', 'projectile_system']
        bullet_ent_id = init_entity(create_projectile_dict, component_order)
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
                'offset': projectile_dict['height']*.5, 
                'parent': bullet_ent_id}
            particle_system2 = {'particle_file': explosion_string, 
                'offset': 0, 'parent': bullet_ent_id}
            p_ent = init_entity(
                {'particles': particle_system1}, ['particles'])
            p_ent2 = init_entity(
                {'particles': particle_system2}, ['particles'])
            particle_comp = entities[p_ent].particles
            particle_comp.system_on = True
            projectile_system_data = entities[bullet_ent_id].projectile_system
            projectile_system_data.linked = [p_ent, p_ent2]
        return bullet_ent_id

    def set_armed(self, entity_id, dt):
        entities = self.gameworld.entities
        bullet = entities[entity_id]
        if hasattr(bullet, 'projectile_system'):
            bullet.projectile_system.armed = True

    def fire_projectile(self, entity_id):
        entities = self.gameworld.entities
        bullet = entities[entity_id]
        physics_data = bullet.cymunk_physics
        unit_vector = physics_data.unit_vector
        projectile_system = bullet.projectile_system
        bullet_accel = projectile_system.accel
        force = bullet_accel*unit_vector[0], bullet_accel*unit_vector[1]
        force_offset = -unit_vector[0], -unit_vector[1]
        bullet_body = bullet.cymunk_physics.body
        bullet_body.apply_impulse(force, force_offset)
        if len(projectile_system.linked) > 0:
            bullet_body.apply_force(force, force_offset)
            engine_effect = entities[projectile_system.linked[0]].particles
            engine_effect.system_on = True


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
        projectile_system = bullet.projectile_system
        if projectile_system.armed:
            bullet_damage = projectile_system.damage
            systems['asteroid_system'].damage(asteroid_id, bullet_damage)
            if len(projectile_system.linked) > 0:
                self.create_rocket_explosion(bullet_id)
            else:
                projectile_system.armed = False
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
        proj1_s = bullet1.projectile_system
        bullet2 = entities[bullet_id2]
        proj2_s = bullet2.projectile_system
        if proj1_s.armed and proj2_s.armed:
            if len(proj1_s.linked) > 0:
                self.create_rocket_explosion(bullet_id1)
            else:
                proj1_s.armed = False
                Clock.schedule_once(
                    partial(gameworld.timed_remove_entity, bullet_id1))
            if len(proj2_s.linked) > 0:
                self.create_rocket_explosion(bullet_id2)
            else:
                proj2_s.armed = False
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
        if bullet.projectile_system.armed:
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
        if bullet1.projectile_system.armed and bullet2.projectile_system.armed:
            if bullet1.physics_renderer.on_screen or bullet2.physics_renderer.on_screen:
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
        if bullet.projectile_system.armed:
            if bullet.physics_renderer.on_screen:
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
        projectile_system = bullet.projectile_system
        if projectile_system.armed:
            bullet_damage = bullet.projectile_system.damage
            systems['ship_system'].damage(ship_id, bullet_damage)
            if len(projectile_system.linked) > 0:
                self.create_rocket_explosion(bullet_id)
            else:
                projectile_system.armed = False
                Clock.schedule_once(
                    partial(gameworld.timed_remove_entity, bullet_id))
            return True
        else:
            print 'collision with bullet after explosion'
            return False