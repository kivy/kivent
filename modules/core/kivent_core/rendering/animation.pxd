from managers.resource_managers cimport ModelManager
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock


ctypedef struct FrameStruct:
    unsigned int texkey
    void* model
    unsigned int duration


cdef class Frame:
    cdef FrameStruct* frame_pointer
    cdef ModelManager* model_manager


cdef class FrameList:
    cdef MemoryBlock frames_block
    cdef Buffer frame_buffer
    cdef ModelManager model_manager
    cdef unsigned int _frame_count

    cdef Frame* get_frame(unsigned int i)
    cdef void* remove_frame(unsigned int i)
