from kivy.graphics.vertex cimport VertexFormat
from kivy.graphics.instructions cimport VertexInstruction
# from kivy.graphics.c_opengl cimport *
from kivy.graphics.vbo cimport VBO, VertexBatch
from kivy.logger import Logger


cdef class CMesh(VertexInstruction):

    def __init__(self, **kwargs):
        VertexInstruction.__init__(self, **kwargs)
        fmt = kwargs.get('fmt')
        if fmt is not None:
            self.vertex_format = VertexFormat(*fmt)
            self.batch = VertexBatch(vbo=VBO(self.vertex_format))
        self.mode = kwargs.get('mode') or 'points'

    def __dealloc__(self):
        self.batch.clear_data()
            

    cdef void build(self):
        cdef float* vertices
        cdef VertexBatch batch = self.batch
        cdef unsigned short* indices
        vertices = <float *>self._vertices
        indices = <unsigned short*>self._indices
        cdef long vcount = self.vcount
        cdef vsize = batch.vbo.vertex_format.vsize
        cdef long icount = self.icount
        batch.set_data(vertices, <int>(vcount / vsize), indices, <int>icount)


    property mode:
        '''VBO Mode used for drawing vertices/indices. Can be one of 'points',
        'line_strip', 'line_loop', 'lines', 'triangle_strip' or 'triangle_fan'.
        '''
        def __get__(self):
            self.batch.get_mode()
        def __set__(self, mode):
            self.batch.set_mode(mode)

