from kivent_core.memory_handlers.membuffer cimport Buffer

cdef class MemoryBlock(Buffer):
    cdef Buffer master_buffer
    cdef unsigned int master_index

    cdef void* allocate_memory_with_buffer(self,
    	Buffer master_buffer) except NULL
    cdef void remove_from_buffer(self)
    cdef void deallocate_memory(self)
