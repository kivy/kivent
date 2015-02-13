from membuffer cimport Buffer
from pool cimport MemoryPool
from block cimport MemoryBlock

cdef class MemoryZone:

    def __cinit__(MemoryZone self, unsigned int block_size_in_kb, 
        Buffer master_buffer, unsigned int type_size, dict desired_counts):
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

    cdef unsigned int get_pool_index_from_name(MemoryZone self, str zone_name):
        return self.reserved_names.index(zone_name)

    cdef unsigned int get_pool_index_from_index(MemoryZone self, 
        unsigned int index):
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

    cdef unsigned int remove_pool_offset(MemoryZone self, unsigned int index,
        unsigned int pool_index):
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return index - start
        
    cdef unsigned int add_pool_offset(MemoryZone self, unsigned int index,
        unsigned int pool_index):
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return index + start

    cdef unsigned int get_pool_offset(MemoryZone self, unsigned int pool_index):
        return self.reserved_ranges[pool_index][0]

    cdef tuple get_pool_range(MemoryZone self, unsigned int pool_index):
        return self.reserved_ranges[pool_index]

    cdef unsigned int get_start_of_pool(MemoryZone self, 
        unsigned int pool_index):
        if pool_index >= self.reserved_count:
            return self.count + 1
        cdef list reserved_ranges = self.reserved_ranges
        cdef unsigned int start = reserved_ranges[pool_index][0]
        return start

    cdef unsigned int get_pool_end_from_pool_index(MemoryZone self, 
        unsigned int index):
        cdef unsigned int used = self.get_pool_from_pool_index(index).used
        return self.add_pool_offset(used, index)

    cdef MemoryPool get_pool_from_pool_index(MemoryZone self, 
        unsigned int pool_index):
        return self.memory_pools[pool_index]

    cdef unsigned int get_block_from_index(MemoryZone self, 
        unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int uadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_block_from_index(uadjusted_index)

    cdef unsigned int get_slot_index_from_index(MemoryZone self, 
        unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_slot_index_from_index(unadjusted_index)

    cdef MemoryBlock get_memory_block_from_index(MemoryZone self, 
        unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_memory_block_from_index(unadjusted_index)

    cdef unsigned int get_index_from_slot_block_pool_index(MemoryZone self, 
        unsigned int slot_index, unsigned int block_index, 
        unsigned int pool_index):
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        cdef unsigned int unadjusted = (
            pool.get_index_from_slot_index_and_block(slot_index, block_index))
        return self.add_pool_offset(unadjusted, pool_index)

    cdef tuple get_pool_block_slot_indices(MemoryZone self, 
        unsigned int index):
        return (self.get_pool_index_from_index(index), 
            self.get_block_from_index(index), 
            self.get_slot_index_from_index(index))
        
    cdef unsigned int get_free_slot(MemoryZone self, 
        str reserved_hint) except -1:
        cdef unsigned int pool_index = self.reserved_names.index(reserved_hint)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        cdef unsigned int unadjusted_index = pool.get_free_slot()
        return self.add_pool_offset(unadjusted_index, pool_index)

    cdef void free_slot(MemoryZone self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        pool.free_slot(unadjusted_index)

    cdef void* get_pointer(MemoryZone self, unsigned int index):
        cdef unsigned int pool_index = self.get_pool_index_from_index(index)
        cdef unsigned int unadjusted_index = self.remove_pool_offset(index,
            pool_index)
        cdef MemoryPool pool = self.get_pool_from_pool_index(pool_index)
        return pool.get_pointer(unadjusted_index)

