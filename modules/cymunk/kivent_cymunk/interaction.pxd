from cymunk cimport (Body, PivotJoint, GearJoint)
from cpython cimport bool

cdef class CymunkTouchComponent:
    cdef Body _touch_body
    cdef PivotJoint _pivot


cdef class SteeringComponent: 
    cdef Body _steering_body
    cdef PivotJoint _pivot
    cdef GearJoint _gear
    cdef tuple _target
    cdef float _speed
    cdef bool _active