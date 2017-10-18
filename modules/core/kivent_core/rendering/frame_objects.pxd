from fixedvbo cimport FixedVBO
from simplevbo cimport SimpleVBO

MAX_GL_VERTICES = 65535

cdef class SimpleFrameData:
    cdef SimpleVBO index_vbo
    cdef SimpleVBO vertex_vbo

    cdef void return_memory(self)
    cdef void clear(self)
    cdef void reload(self)


cdef class FixedFrameData:
    cdef FixedVBO index_vbo
    cdef FixedVBO vertex_vbo

    cdef void return_memory(self)
    cdef void clear(self)
