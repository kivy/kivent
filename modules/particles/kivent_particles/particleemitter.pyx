from cpython cimport bool

cdef class ParticleEmitter:

    def __cinit__(self):
        self._emit_angle = 0.0
        self._x = 0.0
        self._y = 0.0
        self._life_span = 1.0
        self._paused = False
        self._emitter_type = 0
        self._number_of_particles = 10
        self._emission_rate = 1.0
        self._frame_time = 0.0

    def calculate_emission_rate(self):
        cdef int number_of_particles = self._number_of_particles
        cdef float life_span = self._life_span
        self._emission_rate = <float>number_of_particles / life_span

    property x:
        def __get__(self):
            return self._x
        def __set__(self, float value):
            self._x = value

    property y:
        def __get__(self):
            return self._y
        def __set__(self, float value):
            self._y = value

    property emitter_config:
        def __get__(self):
            return self._emitter_config
        def __set__(self, emitter_config):
            self._emitter_config = emitter_config

    property emit_angle:
        def __get__(self):
            return self._emit_angle
        def __set__(self, float value):
            self._emit_angle = value

    property life_span:
        def __get__(self):
            return self._life_span
        def __set__(self, float value):
            self._life_span = value
            self.calculate_emission_rate()

    property paused:
        def __get__(self):
            return self._paused
        def __set__(self, value):
            self._paused = value

    property emitter_type:
        def __get__(self):
            return self._emitter_type
        def __set__(self, value):
            self._emitter_type = value

    property number_of_particles:
        def __get__(self):
            return self._number_of_particles
        def __set__(self, value):
            self._number_of_particles = value
            self.calculate_emission_rate()


cdef class EmitterConfig:

    def __cinit__(self):
        cdef KEColor default
        self._life_span_variance = 0.0
        self._gravity_x = 0.0
        self._gravity_y = 0.0
        self._start_size = 10.0
        self._start_size_variance = 0.0
        self._end_size = 1.0
        self._end_size_variance = 0.0
        self._emit_angle_variance = 0.0
        self._start_rotation = 0.0
        self._start_rotation_variance = 0.0
        self._end_rotation = 0.0
        self._end_rotation_variance = 0.0
        self._emitter_x_variance = 0.0
        self._emitter_y_variance = 0.0
        self._speed = 10.0
        self._speed_variance = 0.0
        self._radial_acceleration = 0.0
        self._radial_acceleration_variance = 0.0
        self._tangential_acceleration = 0.0
        self._tangential_acceleration_variance = 0.0
        self._max_radius = 25.0
        self._max_radius_variance = 0.0
        self._min_radius = 0.0
        self._rotate_per_second = 0.0
        self._rotate_per_second_variance = 0.0
        default.r = 1.0
        default.g = 1.0
        default.b = 1.0
        default.a = 1.0
        self._start_color = default
        self._start_color_variance = default
        self._end_color = default
        self._end_color_variance = default
        self._emitter_type = 0.0

    property life_span_variance:
        def __get__(self):
            return self._life_span_variance
        def __set__(self, value):
            self._life_span_variance = value

    property gravity_x:
        def __get__(self):
            return self._gravity_x
        def __set__(self, value):
            self._gravity_x = value

    property gravity_y:
        def __get__(self):
            return self._gravity_y
        def __set__(self, value):
            self._gravity_y = value

    property start_size:
        def __get__(self):
            return self._start_size
        def __set__(self, value):
            self._start_size = value

    property start_size_variance:
        def __get__(self):
            return self._start_size_variance
        def __set__(self, value):
            self._start_size_variance = value

    property end_size:
        def __get__(self):
            return self._end_size
        def __set__(self, value):
            self._end_size = value

    property end_size_variance:
        def __get__(self):
            return self._end_size_variance
        def __set__(self, value):
            self._end_size_variance = value

    property emit_angle_variance:
        def __get__(self):
            return self._emit_angle_variance
        def __set__(self, value):
            self._emit_angle_variance = value

    property start_rotation:
        def __get__(self):
            return self._start_rotation
        def __set__(self, value):
            self._start_rotation = value

    property start_rotation_variance:
        def __get__(self):
            return self._start_rotation_variance
        def __set__(self, value):
            self._start_rotation_variance = value

    property end_rotation:
        def __get__(self):
            return self._end_rotation
        def __set__(self, value):
            self._end_rotation = value

    property end_rotation_variance:
        def __get__(self):
            return self._end_rotation_variance
        def __set__(self, value):
            self._end_rotation_variance = value

    property emitter_x_variance:
        def __get__(self):
            return self._emitter_x_variance
        def __set__(self, value):
            self._emitter_x_variance = value

    property emitter_y_variance:
        def __get__(self):
            return self._emitter_y_variance
        def __set__(self, value):
            self._emitter_y_variance = value

    property speed:
        def __get__(self):
            return self._speed
        def __set__(self, value):
            self._speed = value

    property speed_variance:
        def __get__(self):
            return self._speed_variance
        def __set__(self, value):
            self._speed_variance = value

    property radial_acceleration:
        def __get__(self):
            return self._radial_acceleration
        def __set__(self, value):
            self._radial_acceleration = value

    property radial_acceleration_variance:
        def __get__(self):
            return self._radial_acceleration_variance
        def __set__(self, value):
            self._radial_acceleration_variance = value

    property tangential_acceleration:
        def __get__(self):
            return self._tangential_acceleration
        def __set__(self, value):
            self._tangenialt_acceleration = value

    property tangential_acceleration_variance:
        def __get__(self):
            return self._tangential_acceleration_variance
        def __set__(self, value):
            self._tangential_acceleration_variance = value

    property max_radius:
        def __get__(self):
            return self._max_radius
        def __set__(self, value):
            self._max_radius = value

    property max_radius_variance:
        def __get__(self):
            return self._max_radius_variance
        def __set__(self, value):
            self._max_radius_variance = value

    property min_radius:
        def __get__(self):
            return self._min_radius
        def __set__(self, value):
            self._min_radius = value

    property rotate_per_second:
        def __get__(self):
            return self._rotate_per_second
        def __set__(self, value):
            self._rotate_per_second = value

    property rotate_per_second_variance:
        def __get__(self):
            return self._rotate_per_second_variance
        def __set__(self, value):
            self._rotate_per_second_variance = value

    property start_color:
        def __get__(self):
            return self._start_color
        def __set__(self, value):
            self._start_color = value

    property start_color_variance:
        def __get__(self):
            return self._start_color_variance
        def __set__(self, value):
            self._start_color_variance = value

    property end_color:
        def __get__(self):
            return self._end_color
        def __set__(self, value):
            self._end_color = value

    property end_color_variance:
        def __get__(self):
            return self._end_color_variance
        def __set__(self, value):
            self._end_color_variance = value
