from staticmemgamesystem cimport StaticMemGameSystem, MemComponent


ctypedef struct ScaleStruct2D:
    unsigned int entity_id
    float sx
    float sy


cdef class ScaleComponent2D(MemComponent):
    pass


cdef class ScaleSystem2D(StaticMemGameSystem):
    pass
