from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.rendering.vertex_format cimport KEVertexFormat
from kivent_core.rendering.fixedvbo cimport FixedVBO

cdef class FixedFrameData:
    '''The FixedFrameData manages 2 FixedVBO, suitable for rendering using the
    GL_TRIANGLES mode. One FixedVBO will hold the indices data and the other
    the actual vertex data.

    **Attributes: (Cython Access Only)**
        **index_vbo** (FixedVBO): The FixedVBO holding indices data. Will
        have the target: GL_ELEMENTS_ARRAY_BUFFER.

        **vertex_vbo** (FixedVBO): The FixedVBO holding vertex data. Will
        have the target: GL_ARRAY_BUFFER.
    '''

    def __cinit__(self, MemoryBlock index_block, MemoryBlock vertex_block,
        KEVertexFormat vertex_format):
        '''When initializing a FixedFrameData we must pass in the MemoryBlock
        that will be used to store the data, and the KEVertexFormat specifying
        the format of the data.

        Args:
            index_block (MemoryBlock): Container for holding the indices data.

            vertex_block (MemoryBlock): Container for holding the vertex data.

            vertex_format (KEVertexFormat): Format of the vertex data.
        '''
        self.index_vbo = FixedVBO(
            vertex_format, index_block, 'stream', 'elements')
        self.vertex_vbo = FixedVBO(
            vertex_format, vertex_block, 'stream', 'array')

    cdef void return_memory(self):
        '''Returns the memory held by **index_vbo** and **vertex_vbo** by
        calling their respective return_memory functions'''
        self.index_vbo.return_memory()
        self.vertex_vbo.return_memory()

    cdef void clear(self):
        self.index_vbo.reload()
        self.vertex_vbo.reload()
