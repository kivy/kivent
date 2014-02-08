from cpython cimport bool

cdef class keParticleEmitter:
    cdef EmitterConfig emitter_config
    cdef float emit_angle
    cdef float x
    cdef float y
    cdef float life_span
    cdef bool paused
    cdef int emitter_type
    cdef float emission_rate
    cdef int number_of_particles
    cdef float frame_time

    def __cinit__(self):
        self.emit_angle = 0.0
        self.x = 0.0
        self.y = 0.0
        self.life_span = 1.0
        self.paused = False
        self.emitter_type = 0
        self.number_of_particles = 10
        self.emission_rate = 1.0
        self.frame_time = 0.0

    def calculate_emission_rate(self):
        number_of_particles = self.number_of_particles
        life_span = self.life_span
        self.emission_rate = <float>number_of_particles / life_span

    property x:
        def __get__(self):
            return self.x
        def __set__(self, float value):
            self.x = value

    property y:
        def __get__(self):
            return self.y
        def __set__(self, float value):
            self.y = value

    property emitter_config:
        def __get__(self):
            return self.emitter_config
        def __set__(self, emitter_config):
            self.emitter_config = emitter_config

    property emit_angle:
        def __get__(self):
            return self.emit_angle
        def __set__(self, float value):
            self.emit_angle = value

    property life_span:
        def __get__(self):
            return self.life_span
        def __set__(self, float value):
            self.life_span = value
            self.calculate_emission_rate()

    property paused:
        def __get__(self):
            return self.paused
        def __set__(self, value):
            self.paused = value

    property emitter_type:
        def __get__(self):
            return self.emitter_type
        def __set__(self, value):
            self.emitter_type = value

    property number_of_particles:
        def __get__(self):
            return self.number_of_particles
        def __set__(self, value):
            self.number_of_particles = value
            self.calculate_emission_rate()


cdef class EmitterConfig:
    cdef float life_span_variance
    cdef float start_size
    cdef float start_size_variance
    cdef float end_size
    cdef float end_size_variance
    cdef float emit_angle_variance
    cdef float start_rotation
    cdef float start_rotation_variance
    cdef float end_rotation
    cdef float end_rotation_variance
    cdef float emitter_x_variance
    cdef float emitter_y_variance
    cdef float gravity_x
    cdef float gravity_y
    cdef float speed
    cdef float speed_variance
    cdef float radial_acceleration
    cdef float radial_acceleration_variance
    cdef float tangential_acceleration
    cdef float tangential_acceleration_variance
    cdef float max_radius
    cdef float max_radius_variance
    cdef float min_radius
    cdef float rotate_per_second
    cdef float rotate_per_second_variance
    cdef keColor start_color
    cdef keColor start_color_variance
    cdef keColor end_color
    cdef keColor end_color_variance
    cdef keTexInfo tex_info

    def __cinit__(self):
        cdef keColor default
        life_span_variance = 0.0
        gravity_x = 0.0
        gravity_y = 0.0
        start_size = 10.0
        start_size_variance = 0.0
        end_size = 1.0
        end_size_variance = 0.0
        emit_angle_variance = 0.0
        start_rotation = 0.0
        start_rotation_variance = 0.0
        end_rotation = 0.0
        end_rotation_variance = 0.0
        emitter_x_variance = 0.0
        emitter_y_variance = 0.0
        speed = 10.0
        speed_variance = 0.0
        radial_acceleration = 0.0
        radial_acceleration_variance = 0.0
        tangential_acceleration = 0.0
        tangential_acceleration_variance = 0.0
        max_radius = 25.0
        max_radius_variance = 0.0
        min_radius = 0.0
        rotate_per_second = 0.0
        rotate_per_second_variance = 0.0
        default.r = 1.0
        default.g = 1.0
        default.b = 1.0
        default.a = 1.0
        start_color = default
        start_color_variance = default
        end_color = default
        end_color_variance = default
        emitter_type = 0.0

    property life_span_variance:
        def __get__(self):
            return self.life_span_variance
        def __set__(self, value):
            self.life_span_variance = value

    property gravity_x:
        def __get__(self):
            return self.gravity_x
        def __set__(self, value):
            self.gravity_x = value

    property gravity_y:
        def __get__(self):
            return self.gravity_y
        def __set__(self, value):
            self.gravity_y = value

    property start_size:
        def __get__(self):
            return self.start_size
        def __set__(self, value):
            self.start_size = value

    property start_size_variance:
        def __get__(self):
            return self.start_size_variance
        def __set__(self, value):
            self.start_size_variance = value

    property end_size:
        def __get__(self):
            return self.end_size
        def __set__(self, value):
            self.end_size = value

    property end_size_variance:
        def __get__(self):
            return self.end_size_variance
        def __set__(self, value):
            self.end_size_variance = value

    property emit_angle_variance:
        def __get__(self):
            return self.emit_angle_variance
        def __set__(self, value):
            self.emit_angle_variance = value

    property start_rotation:
        def __get__(self):
            return self.start_rotation
        def __set__(self, value):
            self.start_rotation = value

    property start_rotation_variance:
        def __get__(self):
            return self.start_rotation_variance
        def __set__(self, value):
            self.start_rotation_variance = value

    property end_rotation:
        def __get__(self):
            return self.end_rotation
        def __set__(self, value):
            self.end_rotation = value

    property end_rotation_variance:
        def __get__(self):
            return self.end_rotation_variance
        def __set__(self, value):
            self.end_rotation_variance = value

    property emitter_x_variance:
        def __get__(self):
            return self.emitter_x_variance
        def __set__(self, value):
            self.emitter_x_variance = value

    property emitter_y_variance:
        def __get__(self):
            return self.emitter_y_variance
        def __set__(self, value):
            self.emitter_y_variance = value

    property speed:
        def __get__(self):
            return self.speed
        def __set__(self, value):
            self.speed = value

    property speed_variance:
        def __get__(self):
            return self.speed_variance
        def __set__(self, value):
            self.speed_variance = value

    property radial_acceleration:
        def __get__(self):
            return self.radial_acceleration
        def __set__(self, value):
            self.radial_acceleration = value

    property radial_acceleration_variance:
        def __get__(self):
            return self.radial_acceleration_variance
        def __set__(self, value):
            self.radial_acceleration_variance = value

    property tangential_acceleration:
        def __get__(self):
            return self.tangential_acceleration
        def __set__(self, value):
            self.tangenialt_acceleration = value

    property tangential_acceleration_variance:
        def __get__(self):
            return self.tangential_acceleration_variance
        def __set__(self, value):
            self.tangential_acceleration_variance = value

    property max_radius:
        def __get__(self):
            return self.max_radius
        def __set__(self, value):
            self.max_radius = value

    property max_radius_variance:
        def __get__(self):
            return self.max_radius_variance
        def __set__(self, value):
            self.max_radius_variance = value

    property min_radius:
        def __get__(self):
            return self.min_radius
        def __set__(self, value):
            self.min_radius = value

    property rotate_per_second:
        def __get__(self):
            return self.rotate_per_second
        def __set__(self, value):
            self.rotate_per_second = value

    property rotate_per_second_variance:
        def __get__(self):
            return self.rotate_per_second_variance
        def __set__(self, value):
            self.rotate_per_second_variance = value

    property start_color:
        def __get__(self):
            return self.start_color
        def __set__(self, value):
            self.start_color = value

    property start_color_variance:
        def __get__(self):
            return self.start_color_variance
        def __set__(self, value):
            self.start_color_variance = value

    property end_color:
        def __get__(self):
            return self.end_color
        def __set__(self, value):
            self.end_color = value

    property end_color_variance:
        def __get__(self):
            return self.end_color_variance
        def __set__(self, value):
            self.end_color_variance = value
