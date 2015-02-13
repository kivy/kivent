from membuffer cimport Buffer

cdef class MemoryBlock(Buffer):
    cdef Buffer master_buffer
    cdef unsigned int master_index
    
    cdef void allocate_memory_with_buffer(MemoryBlock self, 
    	Buffer master_buffer)
    cdef void remove_from_buffer(MemoryBlock self)
    cdef void deallocate_memory(MemoryBlock self)
    cdef void* get_pointer(MemoryBlock self, unsigned int block_index)