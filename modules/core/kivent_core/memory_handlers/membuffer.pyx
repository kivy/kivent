from cpython cimport bool
from libc.stdlib cimport malloc, free

cdef class Buffer:

    def __cinit__(self, unsigned int size_in_blocks, unsigned int type_size,
        unsigned int master_block_size):
        cdef unsigned int size_in_bytes = size_in_blocks * master_block_size
        self.used_count = 0
        self.data = NULL
        self.free_block_count = 0
        self.size = size_in_bytes // type_size
        self.real_size = size_in_bytes
        self.type_size = type_size
        self.size_in_blocks = size_in_blocks
        self.free_blocks = []
        self.data_in_free = 0

    def __dealloc__(self):
        self.free_blocks = None
        self.size = 0
        self.free_block_count = 0
        self.deallocate_memory()

    cdef bool check_empty(self):
        return self.used_count == 0

    cdef void* allocate_memory(self) except NULL:
        self.data = malloc(self.real_size)
        if self.data == NULL:
            raise MemoryError()
        return self.data

    cdef void deallocate_memory(self):
        if self.data != NULL:
            free(self.data)

    cdef unsigned int add_data(self, unsigned int block_count) except -1:
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

    cdef void remove_data(self, unsigned int block_index, 
        unsigned int block_count):
        self.free_blocks.append((block_index, block_count))
        self.data_in_free += block_count
        self.free_block_count += 1
        if self.data_in_free >= self.used_count:
            self.clear()

    cdef void* get_pointer(self, unsigned int block_index) except NULL:
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]

    cdef unsigned int get_largest_free_block(self):
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

    cdef unsigned int get_first_free_block_that_fits(self, 
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

    cdef unsigned int get_blocks_on_tail(self):
        return self.size - self.used_count

    cdef bool can_fit_data(self, unsigned int block_count):
        cdef unsigned int blocks_on_tail = self.get_blocks_on_tail()
        cdef unsigned int largest_free = self.get_largest_free_block()
        if block_count <= blocks_on_tail or block_count <= largest_free:
            return True
        else:
            return False

    cdef void clear(self):
        '''Clear the whole buffer and mark all blocks as available.
        '''
        self.used_count = 0
        self.free_blocks = []
        self.free_block_count = 0
        self.data_in_free = 0