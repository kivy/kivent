from kivent_core.memory_handlers.indexing cimport MemComponent
from staticmemgamesystem cimport StaticMemGameSystem


ctypedef struct PositionStruct2D:
    unsigned int entity_id
    float x
    float y


cdef class PositionComponent2D(MemComponent):
    pass


cdef class PositionSystem2D(StaticMemGameSystem):
    pass