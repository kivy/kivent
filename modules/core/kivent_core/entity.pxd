from kivent_core.systems.staticmemgamesystem cimport MemComponent

cdef class Entity(MemComponent):
    cdef list _load_order

    cdef void set_component(self, unsigned int component_id, 
        unsigned int system_id)
    cdef unsigned int get_component_index(self, str name)