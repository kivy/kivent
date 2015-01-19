from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cpython cimport bool

ctypedef struct Test:
    float x
    float y

def test_buffer(size_in_kb):
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    
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
    cdef Test* mem_test
    for i in range(mem_block.block_count):
        mem_test = <Test*>mem_block.get_pointer(i)
        assert(mem_test.x==block_index)
        assert(mem_test.y==block_index)
    
def test_block(master_buffer, float block_index):
    cdef Test* mem_test
    mem_block_1 = MemoryBlock(1, 16, sizeof(Test))
    mem_block_1.allocate_memory_with_buffer(master_buffer)
    for i in range(mem_block_1.block_count):
        mem_test = <Test*>mem_block_1.get_pointer(i)
        mem_test.x = block_index
        mem_test.y = block_index
    
    return mem_block_1

def test_pool(size_in_kb, size_of_pool):
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef MemoryPool memory_pool = MemoryPool(
        size_of_pool, master_buffer, sizeof(Test), 10000)
    cdef Test* test_mem
    cdef Test* read_mem
    cdef unsigned int x
    indices = []
    i_a = indices.append
    for x in range(600):
        index = memory_pool.get_free_slot()
        i_a(index)
        test_mem = <Test*>memory_pool.get_pointer(index)
        test_mem.x = float(index)
        test_mem.y = float(index)
        #print(test_mem.x, test_mem.y)

    for x in range(350):
        memory_pool.free_slot(x)

    for x in range(350):
        index = memory_pool.get_free_slot()
        test_mem = <Test*>memory_pool.get_pointer(index)
        test_mem.x = float(index)
        test_mem.y = float(index)


    for index in indices:
        read_mem = <Test*>memory_pool.get_pointer(index)
        assert(read_mem.x==index)
        assert(read_mem.y==index)


def test_zone(size_in_kb, pool_block_size, general_count, test_count):
    reserved_spec = {
        'general': 5000,
        'test': 1000,
    }
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef MemoryZone memory_zone = MemoryZone(pool_block_size, master_buffer,
        sizeof(Test), reserved_spec)

    cdef int index
    cdef list indices = []
    i_a = indices.append
    cdef Test* test_mem
    cdef int i
    for x in range(general_count):
        index = memory_zone.get_free_slot('general')
        i_a(index)
        test_mem = <Test*>memory_zone.get_pointer(index)
        test_mem.x = float(index)
        test_mem.y = float(index)

    for x in range(test_count):
        index = memory_zone.get_free_slot('test')
        i_a(index)
        test_mem = <Test*>memory_zone.get_pointer(index)
        test_mem.x = float(index)
        test_mem.y = float(index)

    for i in indices:
        test_mem = <Test*>memory_zone.get_pointer(i)
        assert(test_mem.x==float(i))
        assert(test_mem.y==float(i))


cdef class MemoryZone:
    cdef unsigned int block_size_in_kb
    cdef dict memory_pools
    cdef list reserved_ranges
    cdef unsigned int count
    cdef list reserved_names
    cdef unsigned int reserved_count
    cdef Buffer master_buffer

    def __cinit__(self, unsigned int block_size_in_kb, Buffer master_buffer,
        unsigned int type_size, dict desired_counts):
        self.count = 0
        self.block_size_in_kb = block_size_in_kb
        self.reserved_count = 0
        self.master_buffer = master_buffer
        self.memory_pools = memory_pools = {}
        cdef str key
        self.reserved_names = reserved_names = []
        re_a = reserved_names.append
        cdef MemoryPool pool
        cdef unsigned int pool_count
        cdef unsigned int index
        self.reserved_ranges = reserved_ranges = []
        range_a = reserved_ranges.append
        for key in desired_counts:
            re_a(key)
            index = self.count
            memory_pools[self.reserved_count] = pool = MemoryPool(
                block_size_in_kb, master_buffer, type_size, 
                desired_counts[key])
            self.reserved_count += 1
            pool_count = pool.block_count * pool.slots_per_block
            range_a((index, index+pool_count-1))
            self.count += pool_count

    cdef unsigned int get_pool_index_from_index(self, unsigned int index):
        cdef list reserved_ranges = self.reserved_ranges
        cdef tuple reserve
        cdef unsigned int reserved_count = self.reserved_count
        cdef unsigned int i, start, end
        for i in range(reserved_count):
            reserve = reserved_ranges[i]
            start = reserve[0]
            end = reserve[1]
            if start <= index <= end:
                return i

    cdef unsigned int remove_pool_offset(self, unsigned int index,
        unsigned int pool_index):
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return index - start
        
    cdef unsigned int add_pool_offset(self, unsigned int index,
        unsigned int pool_index):
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return index + start

    cdef MemoryPool get_pool_from_pool_index(self, unsigned int pool_index):
        return self.memory_pools[pool_index]

    cdef unsigned int get_block_from_index(self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int uadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_block_from_index(uadjusted_index)

    cdef unsigned int get_slot_index_from_index(self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_slot_index_from_index(unadjusted_index)

    cdef MemoryBlock get_memory_block_from_index(self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_memory_block_from_index(unadjusted_index)

    cdef unsigned int get_index_from_slot_block_pool_index(self, 
        unsigned int slot_index, unsigned int block_index, 
        unsigned int pool_index):
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        cdef unsigned int adjusted = (pool.get_index_from_slot_index_and_block(
            slot_index, block_index))
        return self.add_pool_offset(adjusted, pool_index)
        
    cdef unsigned int get_free_slot(self, str reserved_hint) except -1:
        cdef unsigned int pool_index = self.reserved_names.index(reserved_hint)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        cdef unsigned int unadjusted_index = pool.get_free_slot()
        return self.add_pool_offset(unadjusted_index, pool_index)

    cdef void free_slot(self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        pool.free_slot(unadjusted_index)

    cdef void* get_pointer(self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_pointer(unadjusted_index)



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

    cdef void* get_pointer(self, unsigned int index):
        cdef MemoryBlock mem_block = self.get_memory_block_from_index(index)
        cdef unsigned int slot_index = self.get_slot_index_from_index(index)
        return mem_block.get_pointer(slot_index)

    cdef unsigned int get_free_slot(self) except -1:
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

    cdef void* get_pointer(self, unsigned int block_index):
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]


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

    cdef void* get_pointer(self, unsigned int block_index):
        cdef char* data = <char*>self.data
        return &data[block_index*self.size_of_blocks]

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

