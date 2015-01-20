from membuffer cimport MemComponent

cdef class Entity(MemComponent):
    cdef list _load_order


cdef class EntityProcessor:
    cdef int _count
    cdef int _mem_count
    cdef float _growth_rate
    cdef int _system_count
    cdef int* _entity_index
    cdef dict _systems
    cdef Entity generate_entity(self)
    cdef void clear_entity(self, int entity_id)
    cdef void set_component(self, int entity_id, int component_id, int system_id)
    cdef void change_allocation(self, int new_count)
