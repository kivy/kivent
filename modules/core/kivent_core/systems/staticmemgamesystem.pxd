from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from gamesystem cimport GameSystem
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.zonedblock cimport ZonedBlock
from cpython cimport bool


cdef class MemComponent:
    cdef void* pointer
    cdef unsigned int _id


cdef class StaticMemGameSystem(GameSystem):
    cdef IndexedMemoryZone imz_components
    cdef ZonedAggregator entity_components


cdef class ZonedAggregator:
    cdef ZonedBlock memory_block
    cdef unsigned int count
    cdef unsigned int total
    cdef dict entity_block_index
    cdef object gameworld
    cdef list system_names

    cdef bool check_empty(self)
    cdef void free(self)
    cdef unsigned int get_size(self)
    cdef void clear(self)
    cdef int remove_entity(self, unsigned int entity_id) except 0
    cdef unsigned int add_entity(self, unsigned int entity_id,
        str zone_name) except -1


cdef class ComponentPointerAggregator:
    cdef MemoryBlock memory_block
    cdef object gameworld
    cdef unsigned int count
    cdef unsigned int total
    cdef list system_names
    cdef dict entity_block_index

    cdef bool check_empty(self)
    cdef unsigned int get_size(self)
    cdef void free(self)
    cdef void clear(self)
    cdef int remove_entity(self, unsigned int entity_id) except 0
    cdef unsigned int add_entity(self, unsigned int entity_id) except -1
