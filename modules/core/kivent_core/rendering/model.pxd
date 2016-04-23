from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock
from vertex_formats cimport FormatConfig


cdef class Vertex:
    cdef dict vertex_format
    cdef void* vertex_pointer


cdef class VertexModel:
    cdef MemoryBlock vertices_block
    cdef MemoryBlock indices_block
    cdef FormatConfig _format_config
    cdef unsigned int _vertex_count
    cdef unsigned int _index_count
    cdef Buffer index_buffer
    cdef Buffer vertex_buffer
    cdef str _name
