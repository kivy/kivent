from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock

cdef class MemoryPool:
    '''The MemoryPool is suitable for pooling C data of the same type.
    Memory for the objects will be allocated only once during initialization.
    A MemoryPool collects several MemoryBlock of the same size together to
    store more data than could be held in a single MemoryBlock. A position in
    these MemoryBlocks is referred to as a 'slot' and the index of this 'slot'
    gives both which block it lives in index at index // **slots_per_block**,
    and the actual index of that MemoryBlock's data at
    index % **slots_per_block**. The data will appear contiguosly from the
    outside, but most likely contain a small area of excess memory in between
    the end of one MemoryBlock and the beginning of the next. The blocks
    themselves will sit contigiously. The technical size of the gap is:
        MemoryBlock.real_size - MemoryBlock.count * MemoryBlock.type_size

    The actual amount of slots allocated will be higher than the number the
    pool is initialized with to account for matching the desired size of each
    block.

    **Attributes: (Cython Access Only)**
        **count** (unsigned int): The number of total slots in the pool.
        Equivalent to **slots_per_block** * **block_count**.

        **memory_blocks** (list): A list of the MemoryBlock objects. Position
        in this list determines which indices a MemoryBlock holds:
        start = **slots_per_block** * index in memory_blocks
        end = (**slots_per_block** * (index in memory_blocks + 1)) - 1

        **blocks_with_free_space** (list): A list of the MemoryBlock that have
        open slots.

        **used** (unsigned int): Total number of used slots, will include both
        active slots and slots sitting in the free list of their respective
        MemoryBlock.

        **free_count** (unsigned int): Total number of slots current in the
        free list.

        **master_buffer** (Buffer): The Buffer passed in on initialization that
        we will allocate the **master_block** from.

        **type_size** (unsigned int): The size in bytes of a single slot in the
        pool.

        **master_block** (MemoryBlock): The large MemoryBlock from which we will
        allocate the individual blocks in the pool.

        **block_count** (unsigned int): The number of MemoryBlock this pool will
        have. Will be calculated on initialization using the desired_count arg:
        (desired_count // slots_per_block) + 1.

        **slots_per_block** (unsigned int): The number of slots of **type_size**
        that will fit in each MemoryBlock in the pool.
    '''

    def __cinit__(self, unsigned int block_size_in_kb, Buffer master_buffer,
        unsigned int type_size, unsigned int desired_count):
        '''During initialization we determine how many MemoryBlock we will need
        of block_size_in_kb kibibytes to fit desired_count in data taking up
        type_size. A single large MemoryBlock with type_size:
        block_size_in_kb*1024 and a size of block_count * that calculated
        type_size. From this MemoryBlock we will than allocate the individual
        MemoryBlock that will make up your pool.

        Args:
            block_size_in_kb (unsigned int): The number of kibibytes to make
            the individual MemoryBlock that make upt he pool.

            master_buffer (Buffer): The buffer from which we should allocate
            this pool.

            type_size (unsigned int): The size of the individual slots in each
            MemoryBlock.

            desired_count (unsigned int): The desired minimum number of slots
            to allocate. The actual size of the pool will be greater accounting
            for the size of the individual MemoryBlock.
        '''
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
        self.master_buffer = master_buffer
        cdef MemoryBlock master_block
        self.master_block = master_block = MemoryBlock(
            block_count*size_in_bytes, size_in_bytes, 1)
        master_block.allocate_memory_with_buffer(master_buffer)
        mem_blocks_a = mem_blocks.append
        cdef MemoryBlock mem_block
        for x in range(block_count):
            mem_block = MemoryBlock(1, type_size, size_in_bytes)
            mem_block.allocate_memory_with_buffer(master_block)
            mem_blocks_a(mem_block)

    cdef unsigned int get_block_from_index(self, unsigned int index):
        '''Takes the slot index received from **get_free_slot** and retrieves
        the index of the block that contains that slot.
        Args:
            index (unsigned int): The index of the slot.
        Return:
            unsigned int: index of the MemoryBlock containing the slot.
        '''
        return index // self.slots_per_block

    cdef unsigned int get_slot_index_from_index(self, unsigned int index):
        '''Returns the index in the MemoryBlock of the slot index received
        from **get_free_slot**.
        Args:
            index (unsigned int): The index of the slot.
        Return:
            unsigned int: index in the MemoryBlock containing the slot.
        '''
        return index % self.slots_per_block

    cdef MemoryBlock get_memory_block_from_index(self, unsigned int index):
        '''Returns the actual MemoryBlock object containing the slot index
        Args:
            index (unsigned int): The index of the slot.
        Return:
            MemoryBlock: The MemoryBlock that contains the data.
        '''
        return self.memory_blocks[self.get_block_from_index(index)]

    cdef unsigned int get_index_from_slot_index_and_block(self,
        unsigned int slot_index, unsigned int block_index):
        '''Returns the slot index if you have instead the index of the block
        and the index of the slot in the block
        Args:
            slot_index (unsigned int): Index in the MemoryBlock

            block_index (unsigned int): Index of the MemoryBlock
        Return:
            unsigned int: The slot index in the pool.
        '''
        return (block_index * self.slots_per_block) + slot_index

    cdef void* get_pointer(self, unsigned int index) except NULL:
        '''Returns a pointer to the data for the particular slot.
        Args:
            index (unsigned int): The index of the slot.
        Return:
            void*: Pointer to the data for that slot.
        '''
        cdef MemoryBlock mem_block = self.get_memory_block_from_index(index)
        cdef unsigned int slot_index = self.get_slot_index_from_index(index)
        return mem_block.get_pointer(slot_index)

    cdef unsigned int get_free_slot(self) except -1:
        '''Returns the first available slot in the pool. Use **get_pointer**
        to retrieve the actual location in memory if you want to access your
        data.
        Return:
            unsigned int: The slot index where your data will be stored.
        '''
        cdef unsigned int index
        cdef unsigned int block_index
        cdef MemoryBlock mem_block
        cdef list mem_blocks = self.memory_blocks
        cdef list free_blocks = self.blocks_with_free_space
        if self.used == self.count and len(free_blocks) <= 0:
            raise MemoryError()
        if len(free_blocks) == 0:
            block_index = self.get_block_from_index(self.used)
            mem_block = mem_blocks[block_index]
            self.used += 1
            index = mem_block.add_data(1)
        else:
            block_index = free_blocks[0]
            mem_block = mem_blocks[block_index]
            index = mem_block.add_data(1)
            if block_index == self.get_block_from_index(self.used) and (
                    self.get_index_from_slot_index_and_block(
                    index, block_index) >= self.used):
                self.used += 1
            else:
                self.free_count -= 1


            if mem_block.free_block_count == 0 and (
                    mem_block.get_blocks_on_tail() == 0):
                free_blocks.remove(block_index)
        return self.get_index_from_slot_index_and_block(index, block_index)

    cdef void free_slot(self, unsigned int index):
        '''Frees a previously acquired slot for reuse. Does not handle
        clearing data. If all used slots have been freed we will clear the whole
        pool.
        Args:
            index (unsigned int): The index of the slot in the pool.
        '''
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
        if self.free_count >= self.used:
            self.clear()


    cdef unsigned int get_size(self):
        '''Returns the size in bytes of the entire MemoryPool.
        Return:
            unsigned int: Size in bytes of the pool.
        '''
        return self.master_block.real_size

    cdef void clear(self):
        '''Marks all slots as free, effectively 'clearing' the entire pool.
        Resets to the initialized state of the MemoryPool.'''
        self.blocks_with_free_space = []
        self.used = 0
        self.free_count = 0
        cdef MemoryBlock block
        for block in self.memory_blocks:
            if not block.check_empty():
                block.clear()
