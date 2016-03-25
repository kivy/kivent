from staticmemgamesystem cimport StaticMemGameSystem, MemComponent


ctypedef struct ColorStruct:
    unsigned int entity_id
    unsigned char[4] color

cdef class ColorComponent(MemComponent):
    pass


cdef class ColorSystem(StaticMemGameSystem):
    pass
