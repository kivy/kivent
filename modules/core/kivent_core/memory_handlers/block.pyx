# cython: profile=True
from membuffer cimport Buffer

cdef class MemoryBlock(Buffer):
    
    def __cinit__(self, unsigned int size_in_blocks, unsigned int type_size,
        unsigned int master_block_size):
        self.master_index = 0

    cdef void* allocate_memory_with_buffer(self, 
        Buffer master_buffer) except NULL:
        self.master_buffer = master_buffer
        cdef unsigned int index = master_buffer.add_data(self.size_in_blocks)
        self.master_index = index
        self.data = master_buffer.get_pointer(index)
        return self.data

    cdef void remove_from_buffer(self):
        self.master_buffer.remove_data(self.master_index, self.size)
        self.master_index = 0

    cdef void deallocate_memory(self):
        pass

    cdef void* get_pointer(self, unsigned int block_index) except NULL:
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]