from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.pool cimport MemoryPool
from kivent_core.memory_handlers.block cimport MemoryBlock

cdef class MemoryZone:
    '''The MemoryZone splits one type of data storage up into several zones
    that are layed out contiguously using multiple MemoryPool. This way we can
    ensure all objects with one processing pattern are stored together. Like
    MemoryPool data storage will appear contiguous, however internally there
    may be some space in between each zone's MemoryPool.

    **Attributes: (Cython Access Only)**
        **block_size_in_kb** (unsigned int): The size of each MemoryBlock that
        makes up the pools.

        **memory_pools** (dict): dict storing the MemoryPool for each zone.
        key is the index of the MemoryPool (the order in which it was
        initialized).

        **reserved_ranges** (list): list of tuples representing the start
        and ending indices of each individual MemoryPool.

        **count** (unsigned int): The total number of slots available across
        all MemoryPool.

        **reserved_names** (list): List storing the name of each pool, ordered
        by index of pool.

        **reserved_count** (unsigned int): The total number of MemoryPool
        reserved.

        **master_buffer** (Buffer):  The Buffer from which all MemoryPool will
        be allocated.
    '''
    def __cinit__(self, unsigned int block_size_in_kb, Buffer master_buffer,
        unsigned int type_size, dict desired_counts):
        '''Will create len(desired_counts) MemoryPools numbered 0...len(
        desired_counts)-1 having space for each count.

        Args:
            block_size_in_kb (unsigned int): The size in kibibytes of each
            MemoryBlock in the pools.

            master_buffer (Buffer): The Buffer we should allocate the pools
            from.

            type_size (unsigned int): The size of the data to be stored.

            desired_counts (dict): Dict of key, val pair of zone_name,
            zone_count.
        '''
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

    cdef unsigned int get_pool_index_from_name(self, str zone_name) except <unsigned int>-1:
        '''Gets the index of the pool from the zone_name
        Arg:
            zone_name (str): Name of the zone as passed into the desired_counts
            arg on initialization.
        Return:
            unsigned int: The index of the MemoryPool for this zone.
        '''
        return self.reserved_names.index(zone_name)

    cdef unsigned int get_pool_index_from_index(self, unsigned int index):
        '''Returns the index of the MemoryPool that contains the data from the
        slot index of the data in the Zone.
        Arg:
            index (unsigned int): Slot index of the data, same as returned by
            **get_free_slot**.
        Return:
            unsigned int: The index of the MemoryPool for this zone.
        '''
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
        '''Returns the index of the slot in the MemoryPool from the index of the
        slot in the MemoryZone.
        Args:
            index (unsigned int): Slot index of the data, same as returned by
            **get_free_slot**.

            pool_index (unsigned int): Index of the MemoryPool containing the
            data.
        Return:
            unsigned int: Slot index of the data in the MemoryPool.
        '''
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return index - start

    cdef unsigned int add_pool_offset(self, unsigned int index,
        unsigned int pool_index):
        '''Takes the slot index of the data in the MemoryPool and adds the
        offset of the pool in the MemoryZone to get the slot index of the
        data in the MemoryZone.
        Args:
            index (unsigned int): Slot index of the data, same as returned by
            **get_free_slot**.

            pool_index (unsigned int): Index of the MemoryPool containing the
            data.
        Return:
            unsigned int: Slot index of the data in the MemoryZone.
        '''
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return index + start

    cdef unsigned int get_pool_offset(self, unsigned int pool_index):
        '''Returns the offset of the slots in the MemoryPool given by the index.
        Args:
            pool_index (unsigned int): Index of the MemoryPool.
        Return:
            unsigned int: Offset of the slots in this MemoryPool.
        '''
        return self.reserved_ranges[pool_index][0]

    cdef tuple get_pool_range(self, unsigned int pool_index):
        '''Get the range of slot indices for a particular pool.
        Args:
            pool_index (unsigned int): Index of the MemoryPool.
        Return:
            tuple: (starting_index, final_index) of this MemoryPool.
        '''
        return self.reserved_ranges[pool_index]

    cdef unsigned int get_pool_end_from_pool_index(self, unsigned int index):
        '''Returns the tail of the MemoryPool adjusted into the MemoryZone
        slots.
        Args:
            index (unsigned int): Index of the pool to find the tail of.
        Return:
            unsigned int: The slot index of the slot on the tail of this
            MemoryPool.
        '''
        cdef unsigned int used = self.get_pool_from_pool_index(index).used
        return self.add_pool_offset(used, index)

    cdef MemoryPool get_pool_from_pool_index(self, unsigned int pool_index):
        '''Returns the MemoryPool found at the provided index
        Args:
            pool_index (unsigned int): Index of the pool to lookup
        Return:
            MemoryPool: The pool at this index.
        '''
        return self.memory_pools[pool_index]

    cdef unsigned int get_block_from_index(self, unsigned int index):
        '''Returns the index in the MemoryPool of the MemoryBlock containing
        the data at the provided slot index in the MemoryZone.
        Args:
            index (unsigned int): The slot index in the MemoryZone as provided
            by **get_free_slot**.
        Return:
            unsigned int: The block index of the MemoryBlock in its MemoryPool.
        '''
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_block_from_index(unadjusted_index)

    cdef unsigned int get_slot_index_from_index(self, unsigned int index):
        '''Returns the index of the data in the MemoryBlock from the slot index
        of the data in the MemoryZone.
        Args:
            index (unsigned int): The slot index in the MemoryZone as provided
            by **get_free_slot**.
        Return:
            unsigned int: The index of the data in its specific MemoryBlock.
        '''
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_slot_index_from_index(unadjusted_index)

    cdef MemoryBlock get_memory_block_from_index(self, unsigned int index):
        '''Returns the MemoryBlock containing the data at the provided slot
        index.
        Args:
            index (unsigned int): The slot index in the MemoryZone as provided
            by **get_free_slot**.
        Return:
            MemoryBlock: The MemoryBlock that contains this data.
        '''
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_memory_block_from_index(unadjusted_index)

    cdef unsigned int get_index_from_slot_block_pool_index(self,
        unsigned int slot_index, unsigned int block_index,
        unsigned int pool_index):
        '''Returns the slot index in the MemoryZone from its constituent
        slot, block, and pool indices.
        Args:
            slot_index (unsigned int): The index of the data in its MemoryBlock.

            block_index (unsigned int): The index of the MemoryBlock in its
            MemoryPool.

            pool_index (unsigned int): The index of the MemoryPool in the
            MemoryZone.

        Return:
            unsigned int: The slot index of the data in the MemoryZone.
        '''
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        cdef unsigned int unadjusted = (
            pool.get_index_from_slot_index_and_block(slot_index, block_index))
        return self.add_pool_offset(unadjusted, pool_index)

    cdef tuple get_pool_block_slot_indices(self, unsigned int index):
        '''Opposite of **get_index_from_slot_block_pool_index**, returns the
        separate slot, block, and pool indices from the slot index in the
        MemoryZone.
        Args:
            index (unsigned int): The slot index in the MemoryZone as provided
            by **get_free_slot**.
        Return:
            tuple: (pool_index, block_index, slot_index)

        '''
        return (self.get_pool_index_from_index(index),
            self.get_block_from_index(index),
            self.get_slot_index_from_index(index))

    cdef unsigned int get_free_slot(self, str reserved_hint) except -1:
        '''Returns a free slot found in the zone name
        Arg:
            reserved_hint (str): The name of the MemoryPool to get the slot in.
        Return:
            unsigned int: The slot index of the data in the MemoryZone.
        '''
        cdef unsigned int pool_index = self.reserved_names.index(reserved_hint)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        cdef unsigned int unadjusted_index = pool.get_free_slot()
        return self.add_pool_offset(unadjusted_index, pool_index)

    cdef int free_slot(self, unsigned int index) except -1:
        '''Returns a slot for reuse after being acquired with **get_free_slot**.
        Args:
            index (unsigned int): The slot index in the MemoryZone as provided
            by **get_free_slot**.
        '''
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        pool.free_slot(unadjusted_index)
        return 1

    cdef void* get_pointer(self, unsigned int index) except NULL:
        '''Returns a pointer to the data held in the slot at index.
        Args:
            index (unsigned int): Slot index of the data you want.
        Return:
            void*: Pointer to the data.
        '''
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_pointer(unadjusted_index)

    cdef unsigned int get_size(self):
        '''Returns the combined size of all the MemoryPool.
        Return:
            unsigned int: size in bytes of all MemoryPool in the MemoryZone.
        '''
        cdef dict pools = self.memory_pools
        cdef MemoryPool pool
        cdef unsigned int size = 0
        for key in pools:
            pool = pools[key]
            size += pool.get_size()
        return size

    cdef unsigned int get_active_slot_count_in_pool(self, unsigned int pool_index) except <unsigned int>-1:
        ''' Returns the amount of active (non freed) slots for the given pool.

            Args:
                pool_index (unsigned int): The pool index for a zone
                aquired f.e. by `memory_zone.get_pool_index_from_name(zone)`.

            Return:
                unsigned int: the slot count. 
        '''
        cdef MemoryPool pool = self.memory_pools[pool_index]
        return pool.used - pool.free_count

    cdef unsigned int get_active_slot_count(self):
        '''Returns the combined amount of all active
        (non freed) slots from all the MemoryPools in this MemoryZone.

        Return:
            unsigned int: the slot count.
        '''
        cdef dict pools = self.memory_pools
        cdef MemoryPool pool
        cdef unsigned int count = 0
        for key in pools:
            pool = pools[key]
            count += pool.used - pool.free_count
        return count