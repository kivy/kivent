from kivent_core.memory_handlers.block cimport MemoryBlock
from vertex_format cimport KEVertexFormat
from fixedvbo cimport FixedVBO
from simplevbo cimport SimpleVBO
from kivent_core.memory_handlers.membuffer cimport NoFreeBuffer
from kivy.graphics.cgl cimport GLushort

MAX_GL_VERTICES = 65535

cdef class SimpleFrameData:

    def __cinit__(self, KEVertexFormat vertex_format):
        cdef NoFreeBuffer vertex_buffer = NoFreeBuffer(
            MAX_GL_VERTICES*vertex_format.vbytesize, vertex_format.vbytesize, 1)
        vertex_buffer.allocate_memory()
        cdef NoFreeBuffer index_buffer = NoFreeBuffer(
            MAX_GL_VERTICES*vertex_format.vbytesize, sizeof(GLushort), 1)
        index_buffer.allocate_memory()
        self.index_vbo = SimpleVBO(vertex_format, index_buffer, 'stream',
                                   'elements')
        self.vertex_vbo = SimpleVBO(vertex_format, vertex_buffer, 'stream',
                                    'array')

    def __dealloc__(self):
        self.index_vbo.return_memory()
        self.vertex_vbo.return_memory()

    cdef void return_memory(self):
        self.index_vbo.return_memory()
        self.vertex_vbo.return_memory()

    cdef void clear(self):
        self.index_vbo.clear()
        self.vertex_vbo.clear()

    cdef void reload(self):
        self.index_vbo.reload()
        self.vertex_vbo.reload()

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
