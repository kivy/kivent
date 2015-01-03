cdef class Entity:
    cdef int _id
    cdef int* _component_ids
    cdef list _load_order
    cdef int _component_count
    cdef dict _systems