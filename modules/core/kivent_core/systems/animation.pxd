from staticmemgamesystem cimport StaticMemGameSystem, MemComponent


ctypedef struct AnimationStruct:
    unsigned int entity_id
    FrameStruct** frames
    unsigned int frame_count
    unsigned int current_frame
    unsigned int current_duration

ctypedef struct FrameStruct:
    unsigned int texkey
    void* model
    unsigned int duration

cdef class AnimationComponent(MemComponent):
    cdef FrameStruct* get_current_frame(self)

cdef class AnimationSystem(StaticMemGameSystem):
    pass
