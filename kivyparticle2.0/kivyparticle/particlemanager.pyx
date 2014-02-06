from cpython cimport bool
from xml.dom.minidom import parse as parse_xml
import json
from libc.math cimport trunc

EMITTER_TYPE_GRAVITY = 0
EMITTER_TYPE_RADIAL = 1

cdef inline keParticle init_particle(
    keParticle particle, void* emitter_ptr, int p_id):
    emitter = <keParticleEmitter>emitter_ptr
    particle.emitter_ptr = emitter_ptr
    ec = <EmitterConfig>emitter.emitter_config
    render_info = particle.render_info
    cdef float life_span = random_variance(emitter.life_span, 
        ec.life_span_variance)
    if life_span <= 0.0:
        return init_particle(particle, emitter_ptr, p_id)
    x, y = emitter.x, emitter.y
    particle.current_time = 0.0
    particle.total_time = life_span
    particle.particle_id = p_id
    particle.start_x = x
    particle.start_y = y
    cdef float angle = random_variance(emitter.emit_angle, 
        ec.emit_angle_variance)
    cdef float speed = random_variance(ec.speed, ec.speed_variance)
    particle.velocity_x = speed * cos(angle)
    particle.velocity_y = speed * sin(angle)
    particle.emit_radius = random_variance(ec.max_radius, 
        ec.max_radius_variance)
    particle.emit_radius_delta = (ec.max_radius - 
        ec.min_radius) / life_span

    particle.emit_rotation = random_variance(emitter.emit_angle, 
        ec.emit_angle_variance)
    particle.emit_rotation_delta = random_variance(ec.rotate_per_second, 
        ec.rotate_per_second_variance)

    particle.radial_acceleration = random_variance(
        ec.radial_acceleration, 
        ec.radial_acceleration_variance)
    particle.tangent_acceleration = random_variance(
        ec.tangential_acceleration, 
        ec.tangential_acceleration_variance)
    cdef float start_size = random_variance(ec.start_size, 
        ec.start_size_variance)
    cdef float end_size = random_variance(ec.end_size, 
        ec.end_size_variance)
    start_size = max(0.1, start_size)
    end_size = max(0.1, end_size)
    particle.scale_delta = ((end_size - start_size) / life_span) / 2.

    # colors
    cdef keColor start_color = random_color_variance(ec.start_color, 
        ec.start_color_variance)
    cdef keColor end_color = random_color_variance(ec.end_color, 
        ec.end_color_variance)

    particle.color_delta = color_delta(start_color, end_color, life_span)

    # rotation
    cdef float start_rotation = random_variance(ec.start_rotation, 
        ec.start_rotation_variance)
    cdef float end_rotation = random_variance(ec.end_rotation, 
        ec.end_rotation_variance)

    particle.rotation_delta = (end_rotation - start_rotation) / life_span
    render_info.x = random_variance(x, ec.emitter_x_variance)
    render_info.y = random_variance(y, ec.emitter_y_variance)
    render_info.scale = start_size / 2.
    render_info.rotation = start_rotation
    render_info.color = start_color
    render_info.tex_info = ec.tex_info
    particle.render_info = render_info
    return particle

cdef class keParticleManager:
    cdef int max_particles
    cdef int current_number_of_particles
    cdef int taken
    cdef list emitters
    cdef list emitter_configs
    cdef void* particles_ptr
    cdef void* frame_info_ptr
    cdef long v_count
    cdef void* indice_info_ptr
    cdef long i_count
    cdef dict particle_configs
    cdef object atlas_texture
    cdef str atlas_name
    cdef str atlas_page
    cdef str atlas_dir
    cdef list pyframe_info
    cdef list pyindice_info
    cdef int last_frame_count
    cdef keParticleEmitter emitter

    def __cinit__(self, int max_particles):
        self.particles_ptr = particles_ptr = <void *>malloc(
            sizeof(keParticle) * max_particles)
        if not particles_ptr:
            raise MemoryError()
        self.emitter = emitter = keParticleEmitter()
        self.max_particles = max_particles
        self.taken = 0
        self.particle_configs = {}
        self.emitters = []
        self.resize_particles(max_particles)

    def __dealloc__(self):
        particles = <keParticle *>self.particles_ptr
        if particles != NULL:
            free(particles)
            particles = NULL
        frame_info = <float *>self.frame_info_ptr
        if frame_info != NULL:
            free(frame_info)
            frame_info = NULL
        indice_info = <unsigned short *>self.indice_info_ptr
        if indice_info != NULL:
            free(indice_info)
            indice_info = NULL

    cdef _update_particles(self, float dt):
        cdef int number_of_particles = self.taken
        cdef int i
        cdef keParticle particle
        cdef EmitterConfig ec
        cdef keColor p_color
        cdef keColor p_color_d
        cdef keRenderInfo render_info
        cdef keTexInfo tex_info
        cdef keParticleEmitter emitter
        cdef void * emitter_ptr
        particles = <keParticle *>self.particles_ptr
        frame_info = <float *>self.frame_info_ptr
        if frame_info != NULL:
            free(frame_info)
            frame_info = NULL
        indice_info = <unsigned short *>self.indice_info_ptr
        if indice_info != NULL:
            free(indice_info)
            indice_info = NULL
        self.frame_info_ptr = frame_ptr = <void *>malloc(sizeof(float) * 
            number_of_particles * 4 * 12)
        self.v_count = <long>number_of_particles * 4 * 12
        self.indice_info_ptr = indices_ptr = <void *>malloc(
            sizeof(unsigned short) * number_of_particles * 6)
        self.i_count = <long>number_of_particles * 6
        if not frame_ptr or not indices_ptr:
            raise MemoryError()
        indice_info = <unsigned short *>indices_ptr
        frame_info = <float *>frame_ptr
        self.last_frame_count = number_of_particles
        for i in range(number_of_particles):
            offset = 4 * i
            indice_offset = i*6
            indice_info[indice_offset] = 0 + offset
            indice_info[indice_offset+1] = 1 + offset
            indice_info[indice_offset+2] = 2 + offset
            indice_info[indice_offset+3] = 2 + offset
            indice_info[indice_offset+4] = 3 + offset
            indice_info[indice_offset+5] = 0 + offset
            particle = particles[i]
            emitter_ptr = particle.emitter_ptr
            emitter = <keParticleEmitter>emitter_ptr
            ec = emitter.emitter_config
            render_info = particle.render_info
            passed_time = fmin(dt, particle.total_time - 
                particle.current_time)
            particle.current_time += passed_time
            if emitter.emitter_type == EMITTER_TYPE_RADIAL:
                e_x = emitter.x
                e_y = emitter.y
                particle.emit_rotation += (particle.emit_rotation_delta * 
                    passed_time)
                particle.emit_radius -= particle.emit_radius_delta * passed_time
                render_info.x = (e_x - 
                    cos(particle.emit_rotation) * particle.emit_radius)
                render_info.y = (e_y - 
                    sin(particle.emit_rotation) * particle.emit_radius)

                if particle.emit_radius < ec.min_radius:
                    particle.current_time = particle.total_time
            else:
                distance_x = render_info.x - particle.start_x
                distance_y = render_info.y - particle.start_y
                start_pos_x = particle.start_x
                current_pos_x = render_info.x
                start_pos_y = particle.start_y
                current_pos_y = render_info.y
                distance_scalar = calc_distance(start_pos_x, start_pos_y, 
                    current_pos_x, current_pos_y)
                if distance_scalar < 0.01:
                    distance_scalar = 0.01
                radial_x = distance_x / distance_scalar
                radial_y = distance_y / distance_scalar
                tangential_x = radial_x
                tangential_y = radial_y

                radial_x *= particle.radial_acceleration
                radial_y *= particle.radial_acceleration

                new_y = tangential_x
                tangential_x = -tangential_y * particle.tangent_acceleration
                tangential_y = new_y * particle.tangent_acceleration
                particle.velocity_x += passed_time * (ec.gravity_x + 
                    radial_x + tangential_x)
                particle.velocity_y += passed_time * (ec.gravity_y + 
                    radial_y + tangential_y)
                render_info.x += particle.velocity_x * passed_time
                render_info.y += particle.velocity_y * passed_time

            render_info.scale += particle.scale_delta * passed_time
            render_info.rotation += particle.rotation_delta * passed_time
            p_color = render_info.color
            p_color_d = particle.color_delta
            color = render_info.color
            color.r = p_color.r + p_color_d.r * passed_time
            color.g = p_color.g + p_color_d.g * passed_time
            color.b = p_color.b + p_color_d.b * passed_time
            color.a = p_color.a + p_color_d.a * passed_time
            render_info.color = color
            particle.render_info = render_info
            index = 48 * i
            x, y = render_info.x, render_info.y
            rotate = render_info.rotation
            tex_info = render_info.tex_info
            color = render_info.color
            w, h =  tex_info.w, tex_info.h
            scale = render_info.scale/w
            x0, y0 = tex_info.u0, tex_info.v0
            x1, y1 = tex_info.u1, tex_info.v1
            frame_info[index] = -w
            frame_info[index+1] = -h
            frame_info[index+2] = x0
            frame_info[index+3] = y0
            frame_info[index+4] = x
            frame_info[index+5] = y
            frame_info[index+6] = rotate
            frame_info[index+7] = color.r
            frame_info[index+8] = color.g
            frame_info[index+9] = color.b
            frame_info[index+10] = color.a
            frame_info[index+11] = scale
            frame_info[index+12] = w
            frame_info[index+13] = -h
            frame_info[index+14] = x1
            frame_info[index+15] = y0
            frame_info[index+16] = x
            frame_info[index+17] = y
            frame_info[index+18] = rotate
            frame_info[index+19] = color.r
            frame_info[index+20] = color.g
            frame_info[index+21] = color.b
            frame_info[index+22] = color.a
            frame_info[index+23] = scale
            frame_info[index+24] = w
            frame_info[index+25] = h
            frame_info[index+26] = x1
            frame_info[index+27] = y1
            frame_info[index+28] = x
            frame_info[index+29] = y
            frame_info[index+30] = rotate
            frame_info[index+31] = color.r
            frame_info[index+32] = color.g
            frame_info[index+33] = color.b
            frame_info[index+34] = color.a
            frame_info[index+35] = scale
            frame_info[index+36] = -w
            frame_info[index+37] = h
            frame_info[index+38] = x0
            frame_info[index+39] = y1
            frame_info[index+40] = x
            frame_info[index+41] = y
            frame_info[index+42] = rotate
            frame_info[index+43] = color.r
            frame_info[index+44] = color.g
            frame_info[index+45] = color.b
            frame_info[index+46] = color.a
            frame_info[index+47] = scale
            particles[i] = particle
            if particle.current_time >= particle.total_time:
                self._expire_particle(particle.particle_id)

    def get_emitter(self):
        return keParticleEmitter()

    def update(self, float dt):
        cdef list emitters = self.emitters
        cdef keParticleEmitter emitter
        for emitter in emitters:
            emitter_ptr = <void *>emitter
            if not emitter.paused:
                emitter.frame_time += dt
                time_between_particles = (
                    1.0 / emitter.emission_rate)
                number_of_updates = trunc(
                    emitter.frame_time / time_between_particles)
                emitter.frame_time -= (
                    time_between_particles * number_of_updates)
                for x in range(int(number_of_updates)):
                    self._init_particle(emitter_ptr)
        self._update_particles(dt)

    def add_emitter(self, keParticleEmitter emitter):
        self.emitters.append(emitter)

    def remove_emitter(self, keParticleEmitter emitter):
        self.emitters.remove(emitter)

    cdef _expire_particle(self, int particle_id):
        particles = <keParticle *>self.particles_ptr
        last_particle_id = self.taken - 1
        expiring_particle = particles[particle_id]
        last_particle = particles[last_particle_id]
        expiring_particle.particle_id = last_particle_id
        last_particle.particle_id = particle_id
        particles[particle_id] = last_particle
        particles[last_particle_id] = expiring_particle
        self.taken -= 1

    cdef _init_particle(self, void* emitter_ptr):
        taken = self.taken
        if taken < self.max_particles:
            particles = <keParticle *>self.particles_ptr
            particle_to_init = particles[taken]
            particles[taken] = init_particle(particle_to_init, emitter_ptr, taken)
            self.taken += 1
        else: 
            print 'too many particles'

    def resize_particles(self, int number_of_particles):
        new_size = sizeof(keParticle) * number_of_particles
        new_ptr = <void *>realloc(self.particles_ptr, new_size)
        particles = <keParticle *>new_ptr
        for x in range(number_of_particles):
            particles[x] = keParticle()
        self.particles_ptr = new_ptr
        self.taken = 0

    def return_uv_coordinates(self, 
        atlas_name, atlas_page, atlas_dir, texture_name):
        cdef keTexInfo tex_info
        atlas = self.atlas_texture 
        size = atlas.size
        atlas_size = (float(size[0]), float(size[1]))
        w, h = atlas_size
        with open(atlas_dir + atlas_name + '.atlas', 'r') as fd:
            atlas_data = json.load(fd)
        atlas_content = atlas_data[atlas_page]
        data = atlas_content[texture_name]
        x1, y1 = data[0], data[1]
        x2, y2 = x1 + data[2], y1 + data[3]
        tex_info.u0 = x1/w
        tex_info.v0 = 1.-y1/h
        tex_info.u1 = x2/w
        tex_info.v1 = 1.-y2/h
        tex_info.w = data[2]
        tex_info.h = data[3]
        return tex_info

    def load_particle_config(self, config):
        config_str = config
        config = parse_xml(config)
        particle_configs = self.particle_configs
        particle_configs[config_str] = particle_config = {}
        parse_data = self.parse_data
        texture_str = parse_data(config, 'texture', 'name')
        ec = particle_config['emitterconfig'] = EmitterConfig()
        particle_config['texture'] = texture_str
        ec.tex_info = self.return_uv_coordinates(
            self.atlas_name, self.atlas_page, self.atlas_dir, texture_str)
        ec.emitter_x_variance = particle_config['emitter_x_variance'] = float(
            parse_data(config, 'sourcePositionVariance', 'x'))
        ec.emitter_y_variance = particle_config['emitter_y_variance'] = float(
            parse_data(config, 'sourcePositionVariance', 'y'))
        ec.gravity_x = particle_config['gravity_x'] = float(parse_data(
            config, 'gravity', 'x'))
        ec.gravity_y = particle_config['gravity_y'] = float(parse_data(
            config,'gravity', 'y'))
        particle_config['emitter_type'] = int(parse_data(
            config, 'emitterType'))
        particle_config['max_num_particles'] = int(parse_data(
            config, 'maxParticles'))
        particle_config['life_span'] = max(0.01, float(parse_data(
            config, 'particleLifeSpan')))
        ec.life_span_variance = particle_config['life_span_variance'] = float(
            parse_data(config, 'particleLifespanVariance'))
        ec.start_size = particle_config['start_size'] = float(parse_data(
            config, 'startParticleSize'))
        ec.start_size_variance = particle_config[
            'start_size_variance'] = float(
            parse_data(config, 'startParticleSizeVariance'))
        ec.end_size = particle_config['end_size'] = float(parse_data(
            config, 'finishParticleSize'))
        ec.end_size_variance = particle_config['end_size_variance'] = float(
            parse_data(config, 'FinishParticleSizeVariance'))
        particle_config['emit_angle'] = keRadians(
            float(parse_data(config, 'angle')))
        ec.emit_angle_variance = particle_config[
            'emit_angle_variance'] = keRadians(
            float(parse_data(config, 'angleVariance')))
        ec.start_rotation = particle_config[
            'start_rotation'] = keRadians(
            float(parse_data(config, 'rotationStart')))
        ec.start_rotation_variance = particle_config[
            'start_rotation_variance'] = keRadians(
            float(parse_data(config, 'rotationStartVariance')))
        ec.end_rotation = particle_config['end_rotation'] = keRadians(
            float(parse_data(config, 'rotationEnd')))
        ec.end_rotation_variance = particle_config[
            'end_rotation_variance'] = keRadians(
            float(parse_data(config, 'rotationEndVariance')))
        ec.speed = particle_config['speed'] = float(self.parse_data(
            config, 'speed'))
        ec.speed_variance = particle_config['speed_variance'] = float(
            parse_data(config, 'speedVariance'))
        ec.radial_acceleration = particle_config[
            'radial_acceleration'] = float(
            parse_data(config, 'radialAcceleration'))
        ec.radial_acceleration_variance = particle_config[
            'radial_acceleration_variance'] = float(
            parse_data(config, 'radialAccelVariance'))
        ec.tangential_acceleration = particle_config[
            'tangential_acceleration'] = float(
            parse_data(config, 'tangentialAcceleration'))
        ec.tangential_acceleration_variance = particle_config[
            'tangential_acceleration_variance'] = float(
            parse_data(config, 'tangentialAccelVariance'))
        ec.max_radius = particle_config['max_radius'] = float(
            parse_data(config, 'maxRadius'))
        ec.max_radius_variance = particle_config[
            'max_radius_variance'] = float(
                parse_data(config, 'maxRadiusVariance'))
        ec.min_radius = particle_config['min_radius'] = float(self.parse_data(
            config, 'minRadius'))
        ec.rotate_per_second = particle_config[
            'rotate_per_second'] = keRadians(
            float(parse_data(config, 'rotatePerSecond')))
        ec.rotate_per_second_variance = particle_config[
            'rotate_per_second_variance'] = keRadians(
            float(parse_data(config, 'rotatePerSecondVariance')))
        parse_color = self.parse_color
        ec.start_color = particle_config[
            'start_color'] = parse_color(config, 'startColor')
        ec.start_color_variance = particle_config[
            'start_color_variance'] = parse_color(config, 'startColorVariance')
        ec.end_color = particle_config[
            'end_color'] = parse_color(config, 'finishColor')
        ec.end_color_variance = particle_config[
            'end_color_variance'] = parse_color(config, 'finishColorVariance')

    def load_particle_system_with_emitter(self, keParticleEmitter emitter, 
        config):
        config_dict = self.particle_configs[config]
        self.current_number_of_particles += config_dict[
            'max_num_particles']
        particle_system = emitter
        particle_system.life_span = config_dict['life_span']
        particle_system.number_of_particles = config_dict[
            'max_num_particles']
        particle_system.emitter_config = config_dict['emitterconfig']
        particle_system.emit_angle = config_dict['emit_angle']
        particle_system.emitter_type = config_dict['emitter_type']
        particle_system.calculate_emission_rate()
        return particle_system

    def parse_data(self, config, name, attribute='value'):
        return config.getElementsByTagName(
            name)[0].getAttribute(attribute)

    def parse_color(self, config, name):
        parse_data = self.parse_data
        cdef keColor color
        color.r = float(parse_data(config, name, 'red'))
        color.g = float(parse_data(config, name, 'green'))
        color.b = float(parse_data(config, name, 'blue'))
        color.a = float(parse_data(config, name, 'alpha'))
        return color

    property max_particles:
        def __get__(self):
            return self.max_particles
        def __set__(self, int new_number):
            self.max_particles = new_number
            self.resize_particles(new_number)

    property current_number_of_particles:
        def __get__(self):
            return self.current_number_of_particles
        def __set__(self, int new_number):
            self.current_number_of_particles = new_number

    property particles:
        def __get__(self):
            particles = <keParticle *>self.particles_ptr
            return_dict = {}
            for x in range(self.max_particles):
                particle = particles[x]
                ri = particle.render_info
                return_dict[x] = {'x': ri.x, 'y': ri.y, 
                    'id': particle.particle_id}
            return return_dict

    property pyframe_info:
        def __get__(self):
            frame_info = <float *>self.frame_info_ptr
            cdef int last_frame_count = self.last_frame_count
            cdef list return_list = []
            cdef int x
            for x in range(last_frame_count*4*12):
                return_list.append(frame_info[x])
            return return_list

    property pyindice_info:
        def __get__(self):
            indice_info = <unsigned short *>self.indice_info_ptr
            cdef int last_frame_count = self.last_frame_count
            cdef list return_list = []
            cdef int x
            for x in range(last_frame_count*6):
                return_list.append(indice_info[x])
            return return_list

    property emitters:
        def __get__(self):
            return self.emitters

    property atlas_texture:
        def __get__(self):
            return self.atlas_texture
        def __set__(self, texture_object):
            self.atlas_texture = texture_object

    property atlas_name:
        def __get__(self):
            return self.atlas_name
        def __set__(self, name):
            self.atlas_name = name

    property atlas_dir:
        def __get__(self):
            return self.atlas_dir
        def __set__(self, dirname):
            self.atlas_dir = dirname

    property atlas_page:
        def __get__(self):
            return self.atlas_page
        def __set__(self, pagename):
            self.atlas_page = pagename

    property particle_configs:
        def __get__(self):
            return self.particle_configs

