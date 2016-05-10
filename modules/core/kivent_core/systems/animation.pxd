from kivent_core.systems.staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.rendering.animation cimport FrameList, Frame, FrameStruct
from libcpp cimport bool


ctypedef struct AnimationStruct:
    unsigned int entity_id
    void* frames
    unsigned int current_frame_index
    unsigned int current_duration

cdef class AnimationComponent(MemComponent):
    pass

cdef class AnimationSystem(StaticMemGameSystem):
    pass
