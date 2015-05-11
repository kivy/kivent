from cymunk.cymunk cimport (Body, PivotJoint, GearJoint, cpBody, cpPivotJoint)
from cpython cimport bool
from kivent_core.systems.staticmemgamesystem cimport (StaticMemGameSystem, 
    MemComponent)

ctypedef struct CymunkTouchStruct:
    unsigned int entity_id
    cpBody* touch_body 
    cpPivotJoint* pivot

cdef class CymunkTouchComponent(MemComponent):
    cdef Body _touch_body
    cdef PivotJoint _pivot

cdef class CymunkTouchSystem(StaticMemGameSystem):
    pass

cdef class SteeringComponent: 
    cdef Body _steering_body
    cdef PivotJoint _pivot
    cdef GearJoint _gear
    cdef tuple _target
    cdef float _speed
    cdef bool _active