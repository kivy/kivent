from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivent_core.memory_handlers.pool cimport MemoryPool
from kivent_core.memory_handlers.utils cimport memrange
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone, ZoneIndex, BlockIndex

ctypedef struct Test:
    float x
    float y


cdef class TestComponent:
    cdef void* pointer
    cdef unsigned int index

    def __cinit__(self, MemoryBlock memory_block, unsigned int index,
            unsigned int offset):
        self.index = index + offset
        self.pointer = memory_block.get_pointer(index)

    property x:
        def __get__(self):
            cdef Test* pointer = <Test*>self.pointer
            return pointer.x
        def __set__(self, float new_value):
            cdef Test* pointer = <Test*>self.pointer
            pointer.x = new_value

    property y:
        def __get__(self):
            cdef Test* pointer = <Test*>self.pointer
            return pointer.y
        def __set__(self, float new_value):
            cdef Test* pointer = <Test*>self.pointer
            pointer.y = new_value

def test_buffer_allocations(self, tmin, tmax):
    for x in range(tmin, tmax):
        try:
            test_buffer(x)
        except Exception as e:
            print(x, e)

def test_multi_buffer(self, num_buffers, size_in_kb):
    buffers = []
    for x in range(num_buffers):
        new_buffer = Buffer(size_in_kb, 1, 1)
        new_buffer.allocate_memory()
        buffers.append(new_buffer)
    return buffers


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

def test_block_index(size_in_kb, block_size):
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef MemoryBlock mem_block = MemoryBlock(1, block_size, sizeof(Test))
    mem_block.allocate_memory_with_buffer(master_buffer)
    block_index = BlockIndex(mem_block, 0, TestComponent)
    block_objects = block_index.blocks
    block_count = mem_block.block_count
    for x in range(block_count):
        block = block_objects[x]
        block.x = block_count - x
        block.y = block_count - x

    for x in range(block_count):
        real_index = block_count - (x+1)
        block = block_objects[real_index]
        assert(block.x==x+1)
        assert(block.y==x+1)


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


def test_zone_index(size_in_kb, pool_block_size, general_count, test_count):
    reserved_spec = {
        'general': 5000,
        'test': 1000,
    }
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef MemoryZone memory_zone = MemoryZone(pool_block_size, master_buffer,
        sizeof(Test), reserved_spec)
    cdef ZoneIndex zone_index = ZoneIndex(memory_zone, TestComponent)
    cdef int index
    cdef list indices = []
    i_a = indices.append
    cdef TestComponent test_mem
    cdef int i
    for x in range(general_count):
        index = memory_zone.get_free_slot('general')
        i_a(index)
        test_mem = zone_index.get_component_from_index(index)
        test_mem.x = float(index)
        test_mem.y = float(index)

    for x in range(test_count):
        index = memory_zone.get_free_slot('test')
        i_a(index)
        test_mem = zone_index.get_component_from_index(index)
        test_mem.x = float(index)
        test_mem.y = float(index)

    for i in indices:
        test_mem = zone_index.get_component_from_index(i)
        assert(test_mem.x==float(i))
        assert(test_mem.y==float(i))

def test_indexed_memory_zone(size_in_kb, pool_block_size,
    general_count, test_count):
    reserved_spec = {
        'general': 200,
        'test': 200,
    }
    master_buffer = Buffer(size_in_kb, 1024, 1)
    master_buffer.allocate_memory()
    cdef IndexedMemoryZone memory_index = IndexedMemoryZone(master_buffer,
        pool_block_size, sizeof(int)*8, reserved_spec, TestComponent)
    cdef IndexedMemoryZone memory_index_2 = IndexedMemoryZone(master_buffer,
        pool_block_size, sizeof(Test), {'general': 200}, TestComponent)
    cdef unsigned int index
    cdef list indices = []
    i_a = indices.append
    cdef TestComponent entity
    cdef MemoryZone memory_zone = memory_index.memory_zone
    cdef MemoryZone memory_zone_2 = memory_index_2.memory_zone
    cdef int x
    cdef int* pointer
    cdef int i
    for x in range(general_count):
        index = memory_zone.get_free_slot('test')
        i_a(index)
        pointer = <int*>memory_zone.get_pointer(index)
        for i in range(8):
            print(pointer[i])
        entity = memory_index[index]
        print(entity._id, index, 'in creation')

    for x in range(test_count):
        index = memory_zone.get_free_slot('general')
        i_a(index)
        index2 = memory_zone_2.get_free_slot('general')
        entity = memory_index[index]
        print(entity._id, index, 'in creation')
        entity = memory_index_2[index2]
        print(entity._id, index, 'in creation 2')

    for entity in memrange(memory_index):
        print(entity._id)

    for entity in memrange(memory_index, zone='test'):
        print(entity._id)
