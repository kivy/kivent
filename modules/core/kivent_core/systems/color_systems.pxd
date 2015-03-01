from staticmemgamesystem cimport StaticMemGameSystem, MemComponent


ctypedef struct ColorStruct:
    unsigned int entity_id
    float r
    float g
    float b
    float a


cdef class ColorComponent(MemComponent):
    pass


cdef class ColorSystem(StaticMemGameSystem):
    pass