from kivent_core.memory_handlers.block cimport MemoryBlock
from vertex_format cimport KEVertexFormat
from fixedvbo cimport FixedVBO

cdef class FixedFrameData: 

    def __cinit__(FixedFrameData self, MemoryBlock index_block, 
    	MemoryBlock vertex_block, KEVertexFormat vertex_format):
        self.index_vbo = FixedVBO(
            vertex_format, index_block, 'stream', 'elements')
        self.vertex_vbo = FixedVBO(
            vertex_format, vertex_block, 'stream', 'array')

    cdef void return_memory(FixedFrameData self):
        self.index_vbo.return_memory()
        self.vertex_vbo.return_memory()