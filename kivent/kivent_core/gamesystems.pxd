cdef class ColorComponent:
    cdef float _r
    cdef float _g
    cdef float _b
    cdef float _a

cdef class PositionComponent:
    cdef float _x
    cdef float _y

cdef class ScaleComponent:
    cdef float _s

cdef class RotateComponent:
    cdef float _r

cdef class LerpObject:
    cdef str _component
    cdef str _property
    cdef float _current_time
    cdef float _max_time
    cdef list _start_vals
    cdef list _end_vals
    cdef str _lerp_mode
    cdef object _callback

cdef class LerpComponent:
    cdef list _lerp_objects