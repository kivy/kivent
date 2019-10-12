from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.rendering.vertex_format cimport KEVertexFormat
from kivy.graphics.cgl cimport GLuint

cdef class FixedVBO:
    cdef MemoryBlock memory_block
    cdef int usage
    cdef GLuint id
    cdef short flags
    cdef int target
    cdef unsigned int size_last_frame
    cdef unsigned int data_size
    cdef KEVertexFormat vertex_format

    cdef int have_id(self)
    cdef void generate_buffer(self)
    cdef void update_buffer(self)
    cdef void bind(self)
    cdef void unbind(self)
    cdef void return_memory(self)
    cdef void reload(self)
