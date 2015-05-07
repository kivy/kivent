from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)


ctypedef struct VelocityStruct2D:
    unsigned int entity_id
    float vx
    float vy


cdef class VelocityComponent2D(MemComponent):
    pass


cdef class VelocitySystem2D(StaticMemGameSystem):
    pass