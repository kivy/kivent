from cpython cimport bool


cdef class IndexedMemoryZone:
    cdef MemoryZone memory_zone
    cdef ZoneIndex zone_index

    cdef void* get_pointer_to_component(self, unsigned int index)

cdef class memrange_iter:
    cdef IndexedMemoryZone memory_index
    cdef unsigned int current
    cdef unsigned int end

cdef class memrange:
    cdef unsigned int start
    cdef unsigned int end
    cdef IndexedMemoryZone memory_index

cdef class Buffer:
    cdef unsigned int block_count
    cdef unsigned int size
    cdef void* data
    cdef unsigned int used_count
    cdef list free_blocks
    cdef unsigned int free_block_count
    cdef unsigned int type_size
    cdef unsigned int data_in_free
    cdef unsigned int real_size
    cdef unsigned int size_of_blocks

    cdef unsigned int add_data(self, unsigned int block_count) except -1
    cdef void remove_data(self, unsigned int block_index, 
        unsigned int block_count)
    cdef unsigned int get_largest_free_block(self)
    cdef unsigned int get_first_free_block_that_fits(self, 
        unsigned int block_count)
    cdef unsigned int get_blocks_on_tail(self)
    cdef bool can_fit_data(self, unsigned int block_count)
    cdef void clear(self)
    cdef void* get_pointer(self, unsigned int block_index)
    cdef void deallocate_memory(self)
    cdef void allocate_memory(self)


cdef class MemoryBlock(Buffer):
    cdef Buffer master_buffer
    cdef unsigned int master_index
    
    cdef void allocate_memory_with_buffer(self, Buffer master_buffer)
    cdef void remove_from_buffer(self)
    cdef void deallocate_memory(self)
    cdef void* get_pointer(self, unsigned int block_index)


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
    
    cdef unsigned int get_block_from_index(self, unsigned int index)
    cdef unsigned int get_slot_index_from_index(self, unsigned int index)
    cdef MemoryBlock get_memory_block_from_index(self, unsigned int index)
    cdef unsigned int get_index_from_slot_index_and_block(self, 
        unsigned int slot_index, unsigned int block_index)
    cdef void* get_pointer(self, unsigned int index)
    cdef unsigned int get_free_slot(self) except -1
    cdef void free_slot(self, unsigned int index)
    cdef void clear(self)


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
    cdef void free_slot(self, unsigned int index)
    cdef void* get_pointer(self, unsigned int index)
    cdef unsigned int get_pool_end_from_pool_index(self, unsigned int index)
    cdef unsigned int get_start_of_pool(self, unsigned int pool_index)
    cdef tuple get_pool_range(self, unsigned int pool_index)
    cdef unsigned int get_pool_index_from_name(self, str zone_name)
    cdef unsigned int get_pool_offset(self, unsigned int pool_index)


cdef class MemComponent:
    cdef void* pointer
    cdef unsigned int _id


cdef class BlockIndex:
    cdef list block_objects


cdef class PoolIndex:
    cdef list _block_indices


cdef class ZoneIndex:
    cdef dict _pool_indices
    cdef MemoryZone memory_zone





