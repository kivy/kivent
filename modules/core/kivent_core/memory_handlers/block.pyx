from membuffer cimport Buffer

cdef class MemoryBlock(Buffer):
    
    def __cinit__(MemoryBlock self, unsigned int size_in_blocks, 
        unsigned int size_of_blocks, unsigned int type_size):
        self.master_index = 0

    cdef void allocate_memory_with_buffer(MemoryBlock self, 
        Buffer master_buffer):
        self.master_buffer = master_buffer
        cdef unsigned int index = master_buffer.add_data(self.size)
        self.master_index = index
        self.data = master_buffer.get_pointer(index)

    cdef void remove_from_buffer(MemoryBlock self):
        cdef Buffer master_buffer = self.master_buffer
        master_buffer.remove_data(self.master_index, self.size)
        self.master_index = 0

    cdef void deallocate_memory(MemoryBlock self):
        pass

    cdef void* get_pointer(MemoryBlock self, unsigned int block_index):
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]