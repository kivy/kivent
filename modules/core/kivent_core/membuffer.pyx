from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython cimport bool

ctypedef struct Test:
    float x
    float y

def test_buffer(size_in_kb):
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    
    print('master counter: ', master_buffer.block_count)
    mem_blocks = []
    for x in range(8):
        mem_blocks.append(test_block(master_buffer, x))

    for x in range(8):
        test_block_read(mem_blocks[x], x)
    cdef MemoryBlock mem_block
    for x in range(2, 6):
        mem_block = mem_blocks[x]
        mem_block.remove_from_buffer()
        mem_blocks[x] = None

    for x in range(2, 6):
        mem_blocks[x] = test_block(master_buffer, x+8)

    for x in range(2, 6):
        test_block_read(mem_blocks[x], x+8)

    
def test_block_read(MemoryBlock mem_block, float block_index):
    cdef Test* data = <Test*>mem_block.data
    cdef Test* mem_test
    for i in range(mem_block.block_count):
        mem_test = &data[i]
        assert(mem_test.x==block_index)
        assert(mem_test.y==block_index)
    
def test_block(master_buffer, float block_index):
    cdef Test* mem_test
    mem_block_1 = MemoryBlock(1, 16, sizeof(Test))
    mem_block_1.allocate_memory_with_buffer(master_buffer)
    cdef Test* data = <Test*>mem_block_1.data
    print(sizeof(Test), mem_block_1.block_count)
    
    
    for i in range(mem_block_1.block_count):
        mem_test = &data[i]
        mem_test.x = block_index
        mem_test.y = block_index
    
    return mem_block_1

def test_pool(size_in_kb, size_of_pool):
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef MemoryPool memory_pool = MemoryPool(
        size_of_pool, master_buffer, sizeof(Test), 10000)
    cdef Test* data
    cdef Test* test_mem
    cdef Test* read_data
    cdef Test* read_mem
    cdef MemoryBlock memory_block
    cdef unsigned int x
    indices = []
    i_a = indices.append
    for x in range(600):
        index = memory_pool.get_free_slot()
        i_a(index)
        memory_block = memory_pool.get_memory_block_from_index(index)
        #print('memblock', memory_pool.get_block_from_index(index))
        data = <Test*>memory_block.data
        test_mem = &data[memory_pool.get_slot_index_from_index(index)]
        test_mem.x = float(index)
        test_mem.y = float(index)
        #print(test_mem.x, test_mem.y)

    for x in range(350):
        memory_pool.free_slot(x)

    for x in range(350):
        index = memory_pool.get_free_slot()
        memory_block = memory_pool.get_memory_block_from_index(index)
        data = <Test*>memory_block.data
        test_mem = &data[memory_pool.get_slot_index_from_index(index)]
        test_mem.x = float(index)
        test_mem.y = float(index)


    for index in indices:
        memory_block = memory_pool.get_memory_block_from_index(index)
        read_data = <Test*>memory_block.data
        #print('memblock', memory_pool.get_block_from_index(x))
        read_mem = &read_data[memory_pool.get_slot_index_from_index(index)]
        assert(read_mem.x==index)
        assert(read_mem.y==index)


cdef class ReservedMemoryPool:
    cdef unsigned int count
    cdef dict memory_pools
    cdef unsigned int used



cdef class MemoryPool:
    cdef unsigned int count
    cdef list memory_blocks
    cdef list blocks_with_free_space
    cdef unsigned int used
    cdef unsigned int free_count
    cdef Buffer master_buffer
    cdef unsigned int type_size
    cdef MemoryBlock master_block
    cdef unsigned int block_count
    cdef unsigned int slots_per_block
    
    def __cinit__(self, unsigned int block_size_in_kb, Buffer master_buffer,
        unsigned int type_size, unsigned int desired_count):
        self.blocks_with_free_space = []
        self.memory_blocks = mem_blocks = []
        self.used = 0
        self.free_count = 0
        self.type_size = type_size
        cdef unsigned int size_in_bytes = (block_size_in_kb * 1024)
        cdef unsigned int slots_per_block = size_in_bytes // type_size
        cdef unsigned int block_count = (desired_count/slots_per_block) + 1
        self.count = slots_per_block * block_count
        self.slots_per_block = slots_per_block
        self.block_count = block_count
        self.master_buffer = master_buffer
        cdef MemoryBlock master_block 
        self.master_block = master_block = MemoryBlock(block_count,
            block_size_in_kb, size_in_bytes)
        master_block.allocate_memory_with_buffer(master_buffer)
        mem_blocks_a = mem_blocks.append
        cdef MemoryBlock mem_block
        for x in range(block_count):
            mem_block = MemoryBlock(1, block_size_in_kb, type_size)
            mem_block.allocate_memory_with_buffer(master_block)
            mem_blocks_a(mem_block)


    cdef unsigned int get_block_from_index(self, unsigned int index):
        return index // self.slots_per_block 

    cdef unsigned int get_slot_index_from_index(self, unsigned int index):
        return index % self.slots_per_block

    cdef MemoryBlock get_memory_block_from_index(self, unsigned int index):
        return self.memory_blocks[self.get_block_from_index(index)]

    cdef unsigned int get_index_from_slot_index_and_block(self, 
        unsigned int slot_index, unsigned int block_index):
        return (block_index * self.slots_per_block) + slot_index

    cdef unsigned int get_free_slot(self):
        cdef unsigned int index
        cdef unsigned int block_index
        cdef MemoryBlock mem_block
        cdef list mem_blocks = self.memory_blocks
        cdef list free_blocks = self.blocks_with_free_space
        if self.used == self.count:
            raise MemoryError()
        if self.free_count <= 0:
            block_index = self.get_block_from_index(self.used)
            mem_block = mem_blocks[block_index]
            self.used += 1
            index = mem_block.add_data(1)
        else:
            block_index = free_blocks[0]
            mem_block = mem_blocks[block_index]
            self.free_count -= 1
            index = mem_block.add_data(1)
            if mem_block.free_block_count == 0:
                free_blocks.remove(block_index)
        return self.get_index_from_slot_index_and_block(index, block_index)


    cdef void free_slot(self, unsigned int index):
        cdef unsigned int block_index = self.get_block_from_index(index)
        cdef unsigned int slot_index = self.get_slot_index_from_index(index)
        cdef MemoryBlock mem_block
        cdef list mem_blocks = self.memory_blocks
        cdef list free_blocks = self.blocks_with_free_space
        mem_block = mem_blocks[block_index]
        mem_block.remove_data(slot_index, 1)
        self.free_count += 1
        if block_index not in free_blocks:
            free_blocks.append(block_index)
            

cdef class MemoryBlock(Buffer):
    cdef Buffer master_buffer
    cdef unsigned int master_index
    
    def __cinit__(self, unsigned int size_in_blocks, 
        unsigned int size_of_blocks, unsigned int type_size):
        self.master_index = 0

    cdef void allocate_memory_with_buffer(self, Buffer master_buffer):
        self.master_buffer = master_buffer
        cdef unsigned int index = master_buffer.add_data(self.size)
        self.master_index = index
        self.data = master_buffer.get_pointer(index)

    cdef void remove_from_buffer(self):
        cdef Buffer master_buffer = self.master_buffer
        master_buffer.remove_data(self.master_index, self.size)
        self.master_index = 0

    cdef void deallocate_memory(self):
        pass


cdef class Buffer:

    def __cinit__(self, unsigned int size_in_blocks, 
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

    def __dealloc__(self):
        self.free_blocks = None
        self.block_count = 0
        self.free_block_count = 0
        self.deallocate_memory()

    cdef void allocate_memory(self):
        self.data = PyMem_Malloc(self.real_size)

    cdef void deallocate_memory(self):
        if self.data != NULL:
            PyMem_Free(self.data)

    cdef unsigned int add_data(self, unsigned int block_count):
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
            print('Not enough room inside your buffer', 
                block_count, tail_count)
            raise MemoryError()
        return index

    cdef void remove_data(self, unsigned int block_index, 
        unsigned int block_count):
        self.free_blocks.append((block_index, block_count))
        self.data_in_free += block_count
        self.free_block_count += 1

    cdef void* get_pointer(self, unsigned int block_index):
        return &self.data[block_index*self.size_of_blocks]

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
        return self.block_count - self.used_count

    cdef bool can_fit_data(self, unsigned int block_count):
        cdef unsigned int blocks_on_tail = self.get_blocks_on_tail()
        cdef unsigned int largest_free = self.get_largest_free_block()
        if block_count < blocks_on_tail or block_count < largest_free:
            return True
        else:
            return False

    cdef void clear(self):
        '''Clear the whole buffer and mark all blocks as available.
        '''
        self.used_count = 0
        self.free_blocks = []
        self.free_block_count = 0

