from kivy.properties import (NumericProperty, BooleanProperty, ListProperty, 
    StringProperty, ObjectProperty, BoundedNumericProperty)
from kivy.graphics import (Color, Callback, Rotate, PushMatrix, 
    PopMatrix, Translate, Quad, Scale, Point, Mesh)
from libc.math cimport pow as power
from libc.math cimport sqrt, sin, cos, fmax, fmin
from random import random
from kivy.event import EventDispatcher

EMITTER_TYPE_GRAVITY = 0
EMITTER_TYPE_RADIAL = 1

cdef inline double calc_distance(tuple point_1, tuple point_2):
    cdef double x_dist2 = power(point_2[0] - point_1[0], 2)
    cdef double y_dist2 = power(point_2[1] - point_1[1], 2)
    return sqrt(x_dist2 + y_dist2)

cdef inline double random_variance(double base, double variance):
    return base + variance * (random() * 2.0 - 1.0)

cdef inline list random_color_variance(list base, list variance):
    return [fmin(fmax(0.0, (random_variance(base[i], variance[i]))), 1.0) 
            for i in range(4)]


class ParticleEmitter(EventDispatcher):
    max_num_particles = NumericProperty(200)
    adjusted_num_particles = NumericProperty(200)
    emit_angle = NumericProperty(0)
    gameworld = ObjectProperty(None)
    particle_manager = ObjectProperty(None)
    emitter_type = NumericProperty(0)
    texture = StringProperty(None)
    friction = NumericProperty(0.0)
    life_span = NumericProperty(1.0)
    emitter_config = ObjectProperty(None)
    _is_paused = BooleanProperty(False)

    def __init__(self, **kwargs):
        self.particles = list()
        self.frame_time = 0
        super(ParticleEmitter, self).__init__(**kwargs)

    def on_adjusted_num_particles(self, instance, value):
        self.emission_rate = value / self.life_span

    def on_max_number_particles(self, instance, value):
        self.emission_rate = value / self.life_span

    def receive_particle(self, int entity_id):
        cdef dict entity = self.gameworld.entities[entity_id]
        cdef list particles = self.particles
        cdef dict particle_manager = entity['particle_manager']
        cdef Particle particle = particle_manager['particle']
        self.init_particle(particle)
        particles.append(entity_id)

    def free_all_particles(self):
        self.free_particles(self.particles)
 
    def free_particles(self, list particles_to_free):
        cdef list particles = self.particles
        particle_manager = self.particle_manager
        cdef int entity_id
        cdef list manager_particles = particle_manager.particles
        get_by_index = particles.index
        pop_particle = particles.pop
        free_particle = manager_particles.append
        for entity_id in particles_to_free:
            particle = pop_particle(get_by_index(entity_id))
            free_particle(particle)

    def on_life_span(self,instance,value):
        self.emission_rate = self.max_num_particles/value

    def init_particle(self, Particle particle):
        ec = self.emitter_config
        cdef double life_span = random_variance(self.life_span, 
            ec.life_span_variance)
        if life_span <= 0.0:
            return
        pos = self.pos
        particle.current_time = 0.0
        particle.total_time = life_span
        particle.x = random_variance(pos[0], ec.emitter_x_variance)
        particle.y = random_variance(pos[1], ec.emitter_y_variance)
        particle.start_x = pos[0]
        particle.start_y = pos[1]
        particle.texture = self.texture
        cdef double angle = random_variance(self.emit_angle, 
            ec.emit_angle_variance)
        cdef double speed = random_variance(ec.speed, ec.speed_variance)
        particle.velocity_x = speed * cos(angle)
        particle.velocity_y = speed * sin(angle)

        particle.emit_radius = random_variance(ec.max_radius, 
            ec.max_radius_variance)
        particle.emit_radius_delta = (ec.max_radius - 
            ec.min_radius) / life_span

        particle.emit_rotation = random_variance(self.emit_angle, 
            ec.emit_angle_variance)
        particle.emit_rotation_delta = random_variance(ec.rotate_per_second, 
            ec.rotate_per_second_variance)

        particle.radial_acceleration = random_variance(
            ec.radial_acceleration, 
            ec.radial_acceleration_variance)
        particle.tangent_acceleration = random_variance(
            ec.tangential_acceleration, 
            ec.tangential_acceleration_variance)

        cdef double start_size = random_variance(ec.start_size, 
            ec.start_size_variance)
        cdef double end_size = random_variance(ec.end_size, 
            ec.end_size_variance)
        start_size = max(0.1, start_size)
        end_size = max(0.1, end_size)

        particle.scale = start_size / 2.
        particle.scale_delta = ((end_size - start_size) / life_span) / 2.

        # colors
        cdef list start_color = random_color_variance(ec.start_color[:], 
            ec.start_color_variance[:])
        cdef list end_color = random_color_variance(ec.end_color[:], 
            ec.end_color_variance[:])

        particle.color_delta = [(end_color[i] - 
            start_color[i]) / life_span for i in range(4)]
        particle.color = start_color

        # rotation
        cdef double start_rotation = random_variance(ec.start_rotation, 
            ec.start_rotation_variance)
        cdef double end_rotation = random_variance(ec.end_rotation, 
            ec.end_rotation_variance)
        particle.rotation = start_rotation
        particle.rotation_delta = (end_rotation - start_rotation) / life_span

    def advance_particle_gravity(self, Particle particle, float passed_time):
        cdef double distance_x = particle.x - particle.start_x
        cdef double distance_y = particle.y - particle.start_y
        cdef tuple start_pos = (particle.start_x, particle.start_y)
        cdef tuple current_pos = (particle.x, particle.y)
        cdef double distance_scalar = calc_distance(start_pos, current_pos)
        if distance_scalar < 0.01:
            distance_scalar = 0.01
        ec = self.emitter_config
        cdef double radial_x = distance_x / distance_scalar
        cdef double radial_y = distance_y / distance_scalar
        cdef double tangential_x = radial_x
        cdef double tangential_y = radial_y

        radial_x *= particle.radial_acceleration
        radial_y *= particle.radial_acceleration

        cdef double new_y = tangential_x
        tangential_x = -tangential_y * particle.tangent_acceleration
        tangential_y = new_y * particle.tangent_acceleration

        particle.velocity_x += passed_time * (ec.gravity_x + 
            radial_x + tangential_x)
        particle.velocity_y += passed_time * (ec.gravity_y + 
            radial_y + tangential_y)

        particle.velocity_x -= particle.velocity_x * self.friction
        particle.velocity_y -= particle.velocity_y * self.friction

        particle.x += particle.velocity_x * passed_time
        particle.y += particle.velocity_y * passed_time

    def advance_particle(self, Particle particle, float passed_time):
        passed_time = min(passed_time, particle.total_time - 
            particle.current_time)
        particle.current_time += passed_time

        if self.emitter_type == EMITTER_TYPE_RADIAL:
            pos = self.pos
            ec = self.emitter_config
            particle.emit_rotation += (particle.emit_rotation_delta * 
                passed_time)
            particle.emit_radius -= particle.emit_radius_delta * passed_time
            particle.x = (pos[0] - 
                cos(particle.emit_rotation) * particle.emit_radius)
            particle.y = (pos[1] - 
                sin(particle.emit_rotation) * particle.emit_radius)

            if particle.emit_radius < ec.min_radius:
                particle.current_time = particle.total_time

        else:
            self.advance_particle_gravity(particle, passed_time)

        particle.scale += particle.scale_delta * passed_time
        particle.rotation += particle.rotation_delta * passed_time

        particle.color = [particle.color[i] + particle.color_delta[i] * 
            passed_time for i in range(4)]


    def update(self, float dt):
        '''
        loop through particles
        if total_time < current_time:
            free particle
        else:
            advance_particle
        '''
        gameworld = self.gameworld
        cdef list entities = gameworld.entities
        cdef Particle particle
        cdef dict entity
        cdef list particles = self.particles
        cdef list particles_to_render = []
        cdef list particles_to_free = []
        append_particle = particles_to_render.append
        free_particle = particles_to_free.append
        advance_particle = self.advance_particle
        for entity_id in particles:
            entity = entities[entity_id]
            particle = entity['particle_manager']['particle']
            if particle.total_time <= particle.current_time:
                free_particle(entity_id)
            else:
                advance_particle(particle, dt)
                append_particle(particle)
        self.free_particles(particles_to_free)
        return particles_to_render


