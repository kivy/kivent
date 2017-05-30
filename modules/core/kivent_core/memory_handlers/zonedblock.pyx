from cpython cimport bool
from kivent_core.memory_handlers.membuffer cimport Buffer

cdef class BlockZone:
    '''A BlockZone manages a specific subsection of the ZonedBlock for a single
    zone of the data. It will store data from index **start** to index **start**
    + **total**.

    **Attributes: (Cython Access Only)**
        **used_count** (unsigned int): The number of memory blocks used up.

        **total** (unsigned int): The total number of memory blocks found in
        this BlockZone.

        **start** (unsigned int): The starting index of this zone in the overall
        ZonedBlock. The index in a specific BlockZone will be index in the
        ZonedBlock - this value.

        **data_in_free** (unsigned int): The total number of blocks currently
        reclaimed and ready for reuse.

        **free_blocks** (list): List managing the reclaimed blocks in the zone.
        Will be stored as tuples (block_index, block_count).

        **name** (str): The name of the zone this BlockZone represents.
    '''

    def __cinit__(self, str name, unsigned int start, unsigned int total):
        '''To initialize a BlockZone we just need to know the name, starting
        index, and the total count for the memory blocks it will represent.
        Note: This does not mean the data has been allocated this will not
        happen until ZonedBlock.allocate_memory_with_buffer has been called.
        Args:
            name (str): The name of this zone.

            start (unsigned int): The starting index for this zone.

            total (unsigned int): The amount of slots in the zone.
        '''
        self.used_count = 0
        self.data_in_free
        self.start = start
        self.free_blocks = []
        self.total = total
        self.name = name

    cdef unsigned int add_data(self, unsigned int block_count) except -1:
        '''Adds data of block_count slots to the zone. Typically called by
        ZonedBlock.add_data rather than used directly.
        Args:
            block_count (unsigned int): The number of contiguous slots to
            take up.
        Return:
            unsigned int: The index of the first slot (adjusted for location in
            the ZonedBlock by adding **start**)
        '''
        cdef unsigned int largest_free_block = 0
        cdef unsigned int index
        cdef unsigned int data_in_free = self.data_in_free
        cdef unsigned int tail_count = self.get_blocks_on_tail()
        if data_in_free >= block_count:
            index = self.get_first_free_block_that_fits(block_count)
            if index != <unsigned int>-1:
                self.data_in_free -= block_count
                return index + self.start
        if block_count <= tail_count:
            index = self.used_count
            self.used_count += block_count
        else:
            raise MemoryError()
        return index + self.start

    cdef void remove_data(self, unsigned int block_index,
        unsigned int block_count):
        '''Frees data previously allocated, marking it for reuse by adding it
        to **free_blocks**.
        Args:
            block_index (unsigned int): The index of the starting slot to free.

            block_count (unsigned int): The number of contiguous slots to free.
        '''
        cdef unsigned int real_index = block_index - self.start
        self.free_blocks.append((real_index, block_count))
        self.data_in_free += block_count
        if self.data_in_free >= self.used_count:
            self.clear()

    cdef unsigned int get_largest_free_block(self):
        '''Returns the largest block in **free_blocks**.
        Return:
            unsigned int: Number of blocks in the largest free block.
        '''
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, block_count
        cdef list free_blocks = self.free_blocks
        cdef unsigned int free_block_count = len(free_blocks)
        cdef unsigned int largest_block_count = 0
        for i in range(free_block_count):
            free_block = free_blocks[i]
            index, block_count = free_block
            if block_count > largest_block_count:
                largest_block_count = block_count
        return largest_block_count

    cdef unsigned int get_first_free_block_that_fits(self,
        unsigned int block_count):
        '''Get the first free block that will have the appropriate space
        to fit the number of blocks required. If the free block is larger than
        required it will be split up and the remainder will be readded to the
        **free_blocks** list.
        Args:
            block_count (unsigned int): The number of blocks to look for space
            for.
        Return:
            unsigned int: Slot index of the free block to use.
        '''
        cdef unsigned int i
        cdef tuple free_block
        cdef unsigned int index, free_block_size
        cdef list free_blocks = self.free_blocks
        cdef unsigned int free_block_count = len(free_blocks)
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
                return index
        return <unsigned int>-1

    cdef unsigned int get_blocks_on_tail(self):
        '''Gets the number of unused blocks on the tail.
        Return:
            unsigned int: Number of blocks.
        '''
        return self.total - self.used_count

    cdef bool can_fit_data(self, unsigned int block_count):
        '''Returns whether or not the BlockZone can fit the data you want
        Args:
            block_count (unsigned int): Number of blocks you want to store.
        Return:
            bool: True if the data will fit, else False.
        '''
        return (block_count <= self.get_blocks_on_tail() or (
            block_count <= self.get_largest_free_block()))


    cdef void clear(self):
        '''Clear the whole BlockZone and mark all blocks as available.
        '''
        self.used_count = 0
        self.free_blocks = []
        self.data_in_free = 0


cdef class ZonedBlock:
    '''The ZonedBlock is like a MemoryBlock in that the data is stored
    contiguously. It is also somewhat like a MemoryZone in that the data is
    split into several regions each of which keep track of their own free list.
    This allows for a single contiguous block of memory that can be iterated
    through efficiently while still separating the memory appropriately to
    allow processing all data of a certain type at the same time. there will be
    no extra space unlike in MemoryZone and the counts for each zone will be
    exact.

    **Attributes: (Cython Access Only)**
        **zones** (dict): Dict containing the BlockZones, keyed by the name of
        the zone.

        **master_buffer** (Buffer): The Buffer from which this ZonedBlock will
        allocate its memory.

        **master_index** (unsigned int): The location of the data in the
        **master_buffer**

        **size** (unsigned int): The size in bytes of the whole ZonedBlock
        allocation.

        **type_size** (unsigned int): The size of each slot in the ZonedBlock
        in bytes.

        **count** (unsigned int): The number of slots in the ZonedBlock, each
        slot will be **type_size** in bytes.

        **data** (void*): Pointer to the actual data in memory.
    '''

    def __cinit__(self, unsigned int type_size, dict zone_dict):
        '''
        Sets up the ZonedBlock and each individual BlockZone. Note that memory
        has not been allocated until **allocate_memory_with_buffer** is called.
        Args:
            type_size (unsigned int): The size in bytes of the data to fit in
            each slot. Typically the result of a sizeof().

            zone_dict (dict): Dict of zone_name, zone_count key, val pairs.
            Space int he ZonedBlock will be made for the sum of all zone_counts.
        '''
        cdef unsigned int zone_index = 0
        cdef dict zones = {}
        for zone_name in zone_dict:
            count = zone_dict[zone_name]
            zones[zone_name] = BlockZone(zone_name, zone_index, count)
            zone_index += count
        self.zones = zones
        cdef unsigned int size_in_bytes = zone_index * type_size
        self.data = NULL
        self.master_buffer = None
        self.size = size_in_bytes
        self.master_index = 0
        self.count = zone_index
        self.type_size = type_size

    cdef bool check_empty(self):
        '''Determines whether the entire ZonedBlock is empty by checking the
        used count of each individual BlockZone.
        Return:
            bool: True if used_count for every BlockZone is 0 else False.'''
        cdef unsigned int used = 0
        cdef dict zones = self.zones
        cdef BlockZone zone
        for key in zones:
            zone = zones[key]
            used += zone.used_count
        return used == 0

    cdef void* allocate_memory_with_buffer(self,
        Buffer master_buffer) except NULL:
        '''Allocates the memory for storing the ZonedBlock from the Buffer.
        Args:
            master_buffer (Buffer): Buffer to allocate from
        Return:
            void*: Pointer to the newly allocated data or NULL if allocation
            has failed. (An exception will be raised if this is the case)
        '''
        self.master_buffer = master_buffer
        cdef unsigned int index = master_buffer.add_data(self.size)
        self.master_index = index
        self.data = master_buffer.get_pointer(index)
        return self.data

    cdef void remove_from_buffer(self):
        '''Free the memory allocated by this ZonedBlock, returning it for
        reuse to the **master_buffer**'''
        self.master_buffer.remove_data(self.master_index, self.size)
        self.master_index = 0

    cdef unsigned int add_data(self, unsigned int block_count,
        str zone_name) except -1:
        '''Claims a contiguous amount of data block_count in size from the
        appropriate zone.
        Args:
            block_count (unsigned int): The number of blocks of **type_size**
            data we will need.

            zone_name (str): The name of the zone to add the data to.
        Return:
            unsigned int: The index of the slot that holds the start of the
            data. Will be <unsigned int>-1 if allocate fails (an exception will
            be raised in this case).
        '''
        cdef BlockZone zone = self.zones[zone_name]
        return zone.add_data(block_count)

    cdef void remove_data(self, unsigned int block_index,
        unsigned int block_count):
        '''Frees data previously allocated, adding it back to the BlockZone
        free list.
        Args:
            block_index (unsigned int): The slot index of the data as returned
            by **add_data**.

            block_count (unsigned int): The number of blocks to free.
        '''
        cdef BlockZone zone = self.get_zone_from_index(block_index)
        zone.remove_data(block_index, block_count)

    cdef BlockZone get_zone_from_index(self, unsigned int block_index):
        '''Returns the BlockZone that contains a slot at block_index.
        Args:
            block_index (unsigned int): The slot index of your data as returned
            by **add_data**.
        Return:
            BlockZone: the zone containing the actual data.
        '''
        cdef dict zones = self.zones
        cdef BlockZone zone
        cdef str key
        for key in zones:
            zone = zones[key]
            if zone.start <= block_index < zone.start + zone.total:
                return zone
        else:
            raise IndexError()

    cdef void* get_pointer(self, unsigned int block_index) except NULL:
        '''Returns a pointer to the data contained at the specific index.
        Args:
            block_index (unsigned int): The index of the data to return.
        Return:
            void*: pointer to the data.
        '''
        cdef char* data = <char*>self.data
        return &data[block_index*self.type_size]

    cdef void clear(self):
        '''Clear the whole buffer and mark all blocks as available.
        '''
        cdef dict zones = self.zones
        cdef BlockZone zone
        cdef str key
        for key in zones:
            zone = zones[key]
            zone.clear()
