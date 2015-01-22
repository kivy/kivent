from cymunk cimport Body, cpBody
from kivent_core.gamesystems cimport StaticMemGameSystem
from kivent_core.membuffer cimport MemComponent

cdef class PhysicsComponent(MemComponent):
    cdef Body _body
    cdef list _shapes
    cdef str _shape_type

ctypedef struct PhysicsStruct:
    unsigned int entity_id
    cpBody* body




