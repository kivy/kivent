from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.pool cimport MemoryPool
from kivent_core.memory_handlers.block cimport MemoryBlock

cdef class MemoryZone:
    cdef unsigned int block_size_in_kb
    cdef dict memory_pools
    cdef list reserved_ranges
    cdef unsigned int count
    cdef list reserved_names
    cdef unsigned int reserved_count
    cdef Buffer master_buffer

    cdef unsigned int get_pool_index_from_index(self, unsigned int index)
    cdef unsigned int remove_pool_offset(self, unsigned int index,
        unsigned int pool_index)
    cdef unsigned int add_pool_offset(self, unsigned int index,
        unsigned int pool_index)
    cdef MemoryPool get_pool_from_pool_index(self, unsigned int pool_index)
    cdef unsigned int get_block_from_index(self, unsigned int index)
    cdef unsigned int get_slot_index_from_index(self, unsigned int index)
    cdef MemoryBlock get_memory_block_from_index(self, unsigned int index)
    cdef unsigned int get_index_from_slot_block_pool_index(self,
        unsigned int slot_index, unsigned int block_index,
        unsigned int pool_index)
    cdef tuple get_pool_block_slot_indices(self, unsigned int index)
    cdef unsigned int get_free_slot(self, str reserved_hint) except -1
    cdef int free_slot(self, unsigned int index) except -1
    cdef void* get_pointer(self, unsigned int index) except NULL
    cdef unsigned int get_pool_end_from_pool_index(self, unsigned int index)
    cdef tuple get_pool_range(self, unsigned int pool_index)
    cdef unsigned int get_pool_index_from_name(self, str zone_name) except <unsigned int>-1
    cdef unsigned int get_pool_offset(self, unsigned int pool_index)
    cdef unsigned int get_size(self)
    cdef unsigned int get_active_slot_count(self)
    cdef unsigned int get_active_slot_count_in_pool(self, unsigned int pool_index) except <unsigned int>-1