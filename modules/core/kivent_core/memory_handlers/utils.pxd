from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone

cdef class memrange_iter:
    cdef IndexedMemoryZone memory_index
    cdef unsigned int current
    cdef unsigned int end

cdef class memrange:
    cdef IndexedMemoryZone memory_index
    cdef unsigned int start
    cdef unsigned int end
