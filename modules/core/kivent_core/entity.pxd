cdef class Entity:
    cdef int _id
    cdef list _load_order
    cdef EntityProcessor _processor


cdef class EntityProcessor:
    cdef int _count
    cdef int _system_count
    cdef int* _entity_index
    cdef dict _systems
    cdef Entity generate_entity(self)
    cdef void clear_entity(self, int entity_id)
