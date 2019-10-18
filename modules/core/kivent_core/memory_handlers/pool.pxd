from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock

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
    cdef void* get_pointer(self, unsigned int index) except NULL
    cdef unsigned int get_free_slot(self) except -1
    cdef void free_slot(self, unsigned int index)
    cdef void clear(self)
    cdef unsigned int get_size(self)
