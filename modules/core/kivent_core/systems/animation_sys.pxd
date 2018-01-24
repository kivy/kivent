from kivent_core.systems.staticmemgamesystem cimport StaticMemGameSystem, MemComponent
from kivent_core.rendering.animation cimport FrameList, Frame, FrameStruct


ctypedef struct AnimationStruct:
    unsigned int entity_id
    void* frames
    void* manager
    unsigned int current_frame_index
    float current_duration
    bint loop
    bint dirty

cdef class AnimationComponent(MemComponent):
    pass

cdef class AnimationSystem(StaticMemGameSystem):
    pass
