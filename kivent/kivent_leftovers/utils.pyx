include "common.pxi"
from libc.math cimport fmax, fmin
from libc.stdlib cimport rand, RAND_MAX


cdef inline float keRandom():
    return <float>rand()/<float>RAND_MAX


cdef inline float keRadians(float degrees):
    return (degrees*PI)/180.0


cdef inline float calc_distance(float point_1_x, float point_1_y, 
    float point_2_x, float point_2_y):
    cdef float x_dist2 = pow(point_2_x - point_1_x, 2)
    cdef float y_dist2 = pow(point_2_y - point_1_y, 2)
    return sqrt(x_dist2 + y_dist2)


cdef inline float random_variance(float base, float variance):
    return base + variance * (keRandom() * 2.0 - 1.0)


cdef inline keColor color_delta(keColor color1, keColor color2, float time):
    cdef keColor new_color
    new_color.r = (color2.r - color1.r) / time
    new_color.g = (color2.g - color1.g) / time
    new_color.b = (color2.b - color1.b) / time
    new_color.a = (color2.a - color1.a) / time
    return new_color


cdef inline keColor random_color_variance(keColor base, keColor variance):
    cdef keColor new_color
    r = fmin(fmax(0.0, (random_variance(base.r, variance.r))), 1.0)
    g = fmin(fmax(0.0, (random_variance(base.g, variance.g))), 1.0)
    b = fmin(fmax(0.0, (random_variance(base.b, variance.b))), 1.0)
    a = fmin(fmax(0.0, (random_variance(base.a, variance.a))), 1.0)
    new_color.r = r
    new_color.g = g
    new_color.b = b
    new_color.a = a
    return new_color