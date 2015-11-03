from cymunk.cymunk cimport (Body, PivotJoint, GearJoint, cpBody, cpPivotJoint,
    cpGearJoint)
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

ctypedef struct SteeringStruct:
    unsigned int entity_id
    cpBody* steering_body
    cpPivotJoint* pivot
    cpGearJoint* gear
    float[2] target
    float speed
    float arrived_radius
    bint active
    bint has_target

cdef class SteeringComponent(MemComponent):
    cdef Body _steering_body
    cdef PivotJoint _pivot
    cdef GearJoint _gear

cdef class SteeringSystem(StaticMemGameSystem):
    pass

ctypedef struct SteeringAIStruct:
    unsigned int entity_id
    unsigned int target_id
    float desired_angle
    float desired_distance
    float angle_variance
    float distance_variance
    float base_distance
    float base_angle
    float current_time
    float recalculate_time

cdef class SteeringAIComponent(MemComponent):
    pass

cdef class SteeringAISystem(StaticMemGameSystem):
    pass