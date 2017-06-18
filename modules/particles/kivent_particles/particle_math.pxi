from libc.math cimport fmax, fmin, sqrt
from libc.stdlib cimport rand, RAND_MAX
from libc.math cimport sin, cos, pow

DEF PI = 3.14159265358979323846

cdef inline float cy_random():
    return <float>rand()/<float>RAND_MAX


cdef inline float cy_radians(float degrees):
    return degrees*(PI/180.0)

cdef inline float cy_degrees(float radians):
    return radians*(180./PI)


cdef inline void rotate_offset(float* offset, float angle_radians, 
    float* output):
    cdef float cs = cos(angle_radians)
    cdef float sn = sin(angle_radians)
    output[0] = offset[0] * cs - offset[1] * sn
    output[1] = offset[0] * sn + offset[1] * cs


cdef inline unsigned char char_lerp(unsigned char v0, unsigned char v1, 
    float t):
    return <unsigned char>((1-t)*v0 + t * v1)


cdef inline float random_variance(float base, float variance):
    return base + variance * (cy_random() * 2.0 - 1.0)


cdef inline void color_delta(unsigned char* color1, unsigned char* color2, 
    float* output, float dt):
    cdef int i 
    for i in range(4):
        output[i] = ((<float>color2[i] - <float>color1[i]) / dt)


cdef inline void color_variance(unsigned char* base, unsigned char* variance, 
    unsigned char* output):
    cdef int i
    for i in range(4):
        output[i] = <unsigned char>fmin(fmax(0., random_variance(<float>base[i], 
            <float>variance[i])), 255.)


cdef inline void color_integrate(float* current, float* delta, 
    float* output, float dt):
    cdef int i
    for i in range(4):
        output[i] = fmin(fmax(0., <float>current[i] + delta[i]*dt), 255.)


cdef inline void color_copy(float* from_color, unsigned char* destination):
    cdef int i
    for i in range(4):
        destination[i] = <unsigned char>from_color[i]


cdef inline float calc_distance(float point_1_x, float point_1_y, 
    float point_2_x, float point_2_y):
    cdef double x_dist2 = point_2_x - point_1_x
    cdef double y_dist2 = point_2_y - point_1_y
    x_dist2 *= x_dist2
    y_dist2 *= y_dist2    
    return <float>sqrt(x_dist2 + y_dist2)