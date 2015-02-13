from kivent_core.memory_handlers.block cimport MemoryBlock
from vertex_format cimport KEVertexFormat
from kivy.graphics.c_opengl cimport GLuint

cdef class FixedVBO:
    cdef MemoryBlock memory_block
    cdef int usage
    cdef GLuint id
    cdef short flags
    cdef int target
    cdef unsigned int size_last_frame
    cdef unsigned int data_size
    cdef KEVertexFormat vertex_format

    cdef int have_id(FixedVBO self)
    cdef void generate_buffer(FixedVBO self)
    cdef void update_buffer(FixedVBO self)
    cdef void bind(FixedVBO self)
    cdef void unbind(FixedVBO self)
    cdef void return_memory(FixedVBO self)
    cdef void reload(FixedVBO self)
