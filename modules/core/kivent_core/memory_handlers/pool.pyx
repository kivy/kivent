from membuffer cimport Buffer
from block cimport MemoryBlock

cdef class MemoryPool:

    def __cinit__(MemoryPool self, unsigned int block_size_in_kb, 
        Buffer master_buffer, unsigned int type_size, 
        unsigned int desired_count):
        self.blocks_with_free_space = []
        self.memory_blocks = mem_blocks = []
        self.used = 0
        self.free_count = 0
        self.type_size = type_size
        cdef unsigned int size_in_bytes = (block_size_in_kb * 1024)
        cdef unsigned int slots_per_block = size_in_bytes // type_size
        cdef unsigned int block_count = (desired_count//slots_per_block) + 1
        self.count = slots_per_block * block_count
        self.slots_per_block = slots_per_block
        self.block_count = block_count
        print('pool has ', block_count, 'taking up', 
            block_size_in_kb*block_count)
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

    cdef unsigned int get_block_from_index(MemoryPool self, 
        unsigned int index):
        return index // self.slots_per_block 

    cdef unsigned int get_slot_index_from_index(MemoryPool self, 
        unsigned int index):
        return index % self.slots_per_block

    cdef MemoryBlock get_memory_block_from_index(MemoryPool self,
        unsigned int index):
        return self.memory_blocks[self.get_block_from_index(index)]

    cdef unsigned int get_index_from_slot_index_and_block(MemoryPool self, 
        unsigned int slot_index, unsigned int block_index):
        return (block_index * self.slots_per_block) + slot_index

    cdef void* get_pointer(MemoryPool self, unsigned int index):
        cdef MemoryBlock mem_block = self.get_memory_block_from_index(index)
        cdef unsigned int slot_index = self.get_slot_index_from_index(index)
        return mem_block.get_pointer(slot_index)

    cdef unsigned int get_free_slot(MemoryPool self) except -1:
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

    cdef void free_slot(MemoryPool self, unsigned int index):
        cdef unsigned int block_index = self.get_block_from_index(index)
        cdef unsigned int slot_index = self.get_slot_index_from_index(index)
        cdef MemoryBlock mem_block
        cdef list mem_blocks = self.memory_blocks
        cdef list free_blocks = self.blocks_with_free_space
        mem_block = mem_blocks[block_index]
        mem_block.remove_data(slot_index, 1)
        self.free_count += 1
        if self.free_count == self.used:
            self.clear()
        if block_index not in free_blocks:
            free_blocks.append(block_index)

    cdef void clear(MemoryPool self):
        self.blocks_with_free_space = []
        self.used = 0
        self.free_count = 0  