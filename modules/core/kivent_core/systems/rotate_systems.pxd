from staticmemgamesystem cimport StaticMemGameSystem, MemComponent


ctypedef struct RotateStruct2D:
    unsigned int entity_id
    float r


cdef class RotateComponent2D(MemComponent):
    pass


cdef class RotateSystem2D(StaticMemGameSystem):
    pass
