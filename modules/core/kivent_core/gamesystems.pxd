from membuffer cimport (MemComponent, MemoryBlock, IndexedMemoryZone)
from cwidget cimport CWidget

cdef class GameSystem(CWidget):
    cdef float _frame_time

cdef class StaticMemGameSystem(GameSystem):
    cdef IndexedMemoryZone components

cdef class PositionSystem2D(StaticMemGameSystem):
    pass

cdef class ScaleSystem2D(StaticMemGameSystem):
    pass

cdef class RotateSystem2D(StaticMemGameSystem):
    pass

cdef class PositionComponent(MemComponent):
    pass

cdef class ColorSystem(StaticMemGameSystem):
    pass

cdef class PositionComponent2D(MemComponent):
    pass

cdef class ColorComponent(MemComponent):
    pass

cdef class RotateComponent2D(MemComponent):
    pass

cdef class ScaleComponent2D(MemComponent):
    pass

ctypedef struct PositionStruct2D:
    unsigned int entity_id
    float x
    float y

ctypedef struct ColorStruct:
    unsigned int entity_id
    float r
    float g
    float b
    float a

ctypedef struct ScaleStruct2D:
    unsigned int entity_id
    float sx
    float sy

ctypedef struct RotateStruct2D:
    unsigned int entity_id
    float r

cdef class LerpObject:
    cdef str _component
    cdef str _property
    cdef float _current_time
    cdef float _max_time
    cdef list _start_vals
    cdef list _end_vals
    cdef str _lerp_mode
    cdef object _callback

cdef class LerpComponent:
    cdef list _lerp_objects

