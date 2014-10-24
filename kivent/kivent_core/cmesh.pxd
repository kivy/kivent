from kivy.graphics.vertex cimport VertexFormat
from kivy.graphics.instructions cimport VertexInstruction

cdef class CMesh(VertexInstruction):
    cdef void* _vertices
    cdef void* _indices
    cdef VertexFormat vertex_format
    cdef long vcount
    cdef long icount