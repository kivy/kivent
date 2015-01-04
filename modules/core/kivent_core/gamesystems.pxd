cdef class ColorComponent:
    cdef int _component_index
    cdef ColorProcessor _processor

ctypedef struct ColorStruct:
    float r
    float g
    float b
    float a

cdef class ColorProcessor:
    cdef int _count
    cdef ColorStruct* _components
    cdef ColorComponent generate_component(self)
    cdef void clear_component(self, int component_index)
    cdef void init_component(self, int component_index, 
        float r, float g, float b, float a)

cdef class PositionComponent:
    cdef int _component_index
    cdef PositionProcessor _processor

ctypedef struct PositionStruct:
    float x
    float y
    float z
    float lx
    float ly
    float lz

cdef class PositionProcessor:
    cdef int _count
    cdef PositionStruct* _components
    cdef PositionComponent generate_component(self)
    cdef void clear_component(self, int component_index)
    cdef void init_component(self, int component_index, 
        float x, float y, float z)

cdef class ScaleComponent:
    cdef int _component_index
    cdef ScaleProcessor _processor

ctypedef struct ScaleStruct:
    float sx
    float sy
    float sz

cdef class ScaleProcessor:
    cdef int _count
    cdef ScaleStruct* _components
    cdef ScaleComponent generate_component(self)
    cdef void clear_component(self, int component_index)
    cdef void init_component(self, int component_index, 
        float sx, float sy, float sz)

cdef class RotateComponent:
    cdef int _component_index
    cdef RotateProcessor _processor

ctypedef struct RotateStruct:
    float r
    float lr

cdef class RotateProcessor:
    cdef int _count
    cdef RotateStruct* _components
    cdef RotateComponent generate_component(self)
    cdef void clear_component(self, int component_index)
    cdef void init_component(self, int component_index, float r)

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

