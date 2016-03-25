from cpython cimport bool
from kivent_core.memory_handlers.membuffer cimport Buffer


cdef class BlockZone:
    cdef unsigned int used_count
    cdef unsigned int total
    cdef unsigned int start
    cdef unsigned int data_in_free
    cdef list free_blocks
    cdef str name

    cdef unsigned int add_data(self, unsigned int block_count) except -1
    cdef void remove_data(self, unsigned int block_index,
        unsigned int block_count)
    cdef unsigned int get_largest_free_block(self)
    cdef unsigned int get_first_free_block_that_fits(self,
        unsigned int block_count)
    cdef unsigned int get_blocks_on_tail(self)
    cdef bool can_fit_data(self, unsigned int block_count)
    cdef void clear(self)


cdef class ZonedBlock:
    cdef dict zones
    cdef Buffer master_buffer
    cdef unsigned int master_index
    cdef unsigned int size
    cdef unsigned int type_size
    cdef unsigned int count
    cdef void* data

    cdef bool check_empty(self)
    cdef void* allocate_memory_with_buffer(self,
        Buffer master_buffer) except NULL
    cdef void remove_from_buffer(self)
    cdef unsigned int add_data(self, unsigned int block_count,
        str zone) except -1
    cdef void remove_data(self, unsigned int block_index,
        unsigned int block_count)
    cdef BlockZone get_zone_from_index(self, unsigned int block_index)
    cdef void* get_pointer(self, unsigned int block_index) except NULL
    cdef void clear(self)
