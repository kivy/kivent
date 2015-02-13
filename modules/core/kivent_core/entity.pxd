from kivent_core.memory_handlers.indexing cimport MemComponent


cdef class Entity(MemComponent):
    cdef list _load_order

    cdef void set_component(Entity self, unsigned int component_id, 
        unsigned int system_id)
    cdef unsigned int get_component_index(Entity self, str name)