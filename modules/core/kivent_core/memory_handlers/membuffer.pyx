from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython cimport bool

cdef class Buffer:

    def __cinit__(Buffer self, unsigned int size_in_blocks, 
        unsigned int size_of_blocks, unsigned int type_size):
        cdef unsigned int size_in_bytes = (
            size_in_blocks * size_of_blocks * 1024)
        self.used_count = 0
        self.data = NULL
        self.free_block_count = 0
        self.block_count = size_in_bytes // type_size
        self.size = size_in_blocks
        self.size_of_blocks = size_of_blocks * 1024
        self.real_size = size_in_bytes
        self.type_size = type_size
        self.free_blocks = []
        self.data_in_free = 0

    def __dealloc__(Buffer self):
        self.free_blocks = None
        self.block_count = 0
        self.free_block_count = 0
        self.deallocate_memory()

    cdef void allocate_memory(Buffer self):
        self.data = PyMem_Malloc(self.real_size)

    cdef void deallocate_memory(Buffer self):
        if self.data != NULL:
            PyMem_Free(self.data)

    cdef unsigned int add_data(Buffer self, unsigned int block_count) except -1:
        cdef unsigned int largest_free_block = 0
        cdef unsigned int index
        cdef unsigned int data_in_free = self.data_in_free
        cdef unsigned int tail_count = self.get_blocks_on_tail()
        if data_in_free >= block_count:
            largest_free_block = self.get_largest_free_block()
        if block_count <= largest_free_block:
            index = self.get_first_free_block_that_fits(block_count)
            self.data_in_free -= block_count
            self.free_block_count -= 1
        elif block_count <= tail_count:
            index = self.used_count
            self.used_count += block_count
        else:
            raise MemoryError()
        return index

    cdef void remove_data(Buffer self, unsigned int block_index, 
        unsigned int block_count):
        self.free_blocks.append((block_index, block_count))
        self.data_in_free += block_count
        self.free_block_count += 1
        if self.free_block_count == self.used_count:
            self.clear()

    cdef void* get_pointer(Buffer self, unsigned int block_index):
        cdef char* data = <char*>self.data
        return &data[block_index*self.size_of_blocks]

    cdef unsigned int get_largest_free_block(Buffer self):
        cdef unsigned int free_block_count = self.free_block_count
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, block_count
        cdef list free_blocks = self.free_blocks
        cdef unsigned int largest_block_count = 0
        for i in range(free_block_count):
            free_block = free_blocks[i]
            index, block_count = free_block
            if block_count > largest_block_count:
                largest_block_count = block_count
        return largest_block_count

    cdef unsigned int get_first_free_block_that_fits(Buffer self, 
        unsigned int block_count):
        cdef unsigned int free_block_count = self.free_block_count
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, free_block_size
        cdef list free_blocks = self.free_blocks
        cdef unsigned int new_block_count
        for i in range(free_block_count):
            free_block = free_blocks[i]
            index, free_block_size = free_block
            if block_count == free_block_size:
                free_blocks.pop(i)
                return index
            elif block_count < free_block_size:
                free_blocks.pop(i)
                new_block_count = free_block_size - block_count
                free_blocks.append((index+block_count, new_block_count))
                self.free_block_count += 1
                return index

    cdef unsigned int get_blocks_on_tail(Buffer self):
        return self.block_count - self.used_count

    cdef bool can_fit_data(Buffer self, unsigned int block_count):
        cdef unsigned int blocks_on_tail = self.get_blocks_on_tail()
        cdef unsigned int largest_free = self.get_largest_free_block()
        if block_count < blocks_on_tail or block_count < largest_free:
            return True
        else:
            return False

    cdef void clear(Buffer self):
        '''Clear the whole buffer and mark all blocks as available.
        '''
        self.used_count = 0
        self.free_blocks = []
        self.free_block_count = 0
        self.data_in_free = 0