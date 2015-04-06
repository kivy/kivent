from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone

cdef class EntityManager:
    cdef IndexedMemoryZone memory_index
    cdef unsigned int system_count

    cdef void clear_entity(self, unsigned int entity_id)
    cdef void set_component(self, unsigned int entity_id, 
        unsigned int component_id, unsigned int system_id)
    cdef unsigned int generate_entity(self, str zone) except -1
    cdef void remove_entity(self, unsigned int entity_id)
    cdef void set_entity_active(self, unsigned int entity_id)
    cdef unsigned int get_size(self)
   