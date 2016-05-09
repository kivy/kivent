from staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from rendering.animation cimport FrameList, Frame
from cpython cimport bool


ctypedef struct AnimationStruct:
    unsigned int entity_id
    FrameList* frame_list
    unsigned int current_frame_index
    unsigned int current_duration
    bool loop

cdef class AnimationComponent(MemComponent):
    cdef Frame get_current_frame(self)

cdef class AnimationSystem(StaticMemGameSystem):
    pass
