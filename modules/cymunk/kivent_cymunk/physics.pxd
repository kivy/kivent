from cymunk cimport Body, cpBody
from kivent_core.gamesystems cimport Processor

cdef class PhysicsComponent:
    cdef int _component_index
    cdef PhysicsProcessor _processor
    cdef Body _body
    cdef list _shapes
    cdef str _shape_type

ctypedef struct PhysicsStruct:
    cpBody* body


cdef class PhysicsProcessor(Processor):
    cdef PhysicsComponent generate_component(self)
    cdef void clear_component(self, int component_index)
    cdef void init_component(self, int component_index, cpBody* body)
    cdef void change_allocation(self, int new_count)


