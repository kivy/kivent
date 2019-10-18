from kivent_core.rendering.fixedvbo cimport FixedVBO

cdef class FixedFrameData:
    cdef FixedVBO index_vbo
    cdef FixedVBO vertex_vbo

    cdef void return_memory(self)
    cdef void clear(self)
