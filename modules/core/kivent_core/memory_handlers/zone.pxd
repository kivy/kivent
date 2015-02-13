from membuffer cimport Buffer
from pool cimport MemoryPool
from block cimport MemoryBlock

cdef class MemoryZone:
    cdef unsigned int block_size_in_kb
    cdef dict memory_pools
    cdef list reserved_ranges
    cdef unsigned int count
    cdef list reserved_names
    cdef unsigned int reserved_count
    cdef Buffer master_buffer

    cdef unsigned int get_pool_index_from_index(MemoryZone self, 
        unsigned int index)
    cdef unsigned int remove_pool_offset(MemoryZone self, unsigned int index,
        unsigned int pool_index)
    cdef unsigned int add_pool_offset(MemoryZone self, unsigned int index,
        unsigned int pool_index)
    cdef MemoryPool get_pool_from_pool_index(MemoryZone self, 
        unsigned int pool_index)
    cdef unsigned int get_block_from_index(MemoryZone self, unsigned int index)
    cdef unsigned int get_slot_index_from_index(MemoryZone self, 
        unsigned int index)
    cdef MemoryBlock get_memory_block_from_index(MemoryZone self, 
        unsigned int index)
    cdef unsigned int get_index_from_slot_block_pool_index(MemoryZone self, 
        unsigned int slot_index, unsigned int block_index, 
        unsigned int pool_index)
    cdef tuple get_pool_block_slot_indices(MemoryZone self, unsigned int index)
    cdef unsigned int get_free_slot(MemoryZone self,
        str reserved_hint) except -1
    cdef void free_slot(MemoryZone self, unsigned int index)
    cdef void* get_pointer(MemoryZone self, unsigned int index)
    cdef unsigned int get_pool_end_from_pool_index(MemoryZone self,
        unsigned int index)
    cdef unsigned int get_start_of_pool(MemoryZone self, 
        unsigned int pool_index)
    cdef tuple get_pool_range(MemoryZone self, unsigned int pool_index)
    cdef unsigned int get_pool_index_from_name(MemoryZone self, str zone_name)
    cdef unsigned int get_pool_offset(MemoryZone self, unsigned int pool_index)






