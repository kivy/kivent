from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone

cdef class EntityManager:
    cdef IndexedMemoryZone memory_index
    cdef unsigned int system_count

    cdef void clear_entity(EntityManager self, unsigned int entity_id)
    cdef void set_component(EntityManager self, unsigned int entity_id, 
        unsigned int component_id, unsigned int system_id)
    cdef unsigned int generate_entity(EntityManager self, zone)
    cdef void remove_entity(EntityManager self, unsigned int entity_id)
    cdef void set_entity_active(EntityManager self, unsigned int entity_id)