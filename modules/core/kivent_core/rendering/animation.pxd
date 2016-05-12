from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock


ctypedef struct FrameStruct:
    unsigned int texkey
    void* model
    float duration


cdef class Frame:
    cdef FrameStruct* frame_pointer
    cdef ModelManager model_manager


cdef class FrameList:
    cdef MemoryBlock frames_block
    cdef ModelManager model_manager
    cdef str name
    cdef unsigned int frame_count
