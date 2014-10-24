from cymunk cimport Body

cdef class PhysicsComponent:
    cdef Body _body
    cdef list _shapes
    cdef str _shape_type