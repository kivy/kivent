from membuffer cimport MemComponent, IndexedMemoryZone

cdef class Entity(MemComponent):
    cdef list _load_order

    cdef void set_component(self, unsigned int component_id, 
        unsigned int system_id)
    cdef unsigned int get_component_index(self, str name)

cdef class EntityManager:
    cdef IndexedMemoryZone memory_index
    cdef unsigned int system_count

    cdef void clear_entity(self, unsigned int entity_id)
    cdef void set_component(self, unsigned int entity_id, 
        unsigned int component_id, unsigned int system_id)
    cdef unsigned int generate_entity(self, zone)
    cdef void remove_entity(self, unsigned int entity_id)
    cdef void set_entity_active(self, unsigned int entity_id)
