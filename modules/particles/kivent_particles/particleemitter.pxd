from cpython cimport bool
from utils cimport KEColor

cdef class EmitterConfig:
    cdef float _life_span_variance
    cdef float _start_size
    cdef float _start_size_variance
    cdef float _end_size
    cdef float _end_size_variance
    cdef float _emit_angle_variance
    cdef float _start_rotation
    cdef float _start_rotation_variance
    cdef float _end_rotation
    cdef float _end_rotation_variance
    cdef float _emitter_x_variance
    cdef float _emitter_y_variance
    cdef float _gravity_x
    cdef float _gravity_y
    cdef float _speed
    cdef float _speed_variance
    cdef float _radial_acceleration
    cdef float _radial_acceleration_variance
    cdef float _tangential_acceleration
    cdef float _tangential_acceleration_variance
    cdef float _max_radius
    cdef float _max_radius_variance
    cdef float _min_radius
    cdef float _rotate_per_second
    cdef float _rotate_per_second_variance
    cdef KEColor _start_color
    cdef KEColor _start_color_variance
    cdef KEColor _end_color
    cdef KEColor _end_color_variance


cdef class ParticleEmitter:
    cdef EmitterConfig _emitter_config
    cdef float _emit_angle
    cdef float _x
    cdef float _y
    cdef float _life_span
    cdef bool _paused
    cdef int _emitter_type
    cdef float _emission_rate
    cdef int _number_of_particles
    cdef float _frame_time


