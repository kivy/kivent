from staticmemgamesystem cimport StaticMemGameSystem, MemComponent


ctypedef struct PositionStruct2D:
    unsigned int entity_id
    float x
    float y


cdef class PositionComponent2D(MemComponent):
    pass


cdef class PositionSystem2D(StaticMemGameSystem):
    pass
