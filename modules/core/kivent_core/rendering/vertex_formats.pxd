from kivy.graphics.c_opengl cimport GLfloat, GLubyte

ctypedef struct VertexFormat4F:
    GLfloat[2] pos
    GLfloat[2] uvs

ctypedef struct VertexFormat7F:
    GLfloat[2] pos
    GLfloat[2] uvs
    GLfloat rot
    GLfloat[2] center

ctypedef struct VertexFormat4F4UB:
    GLfloat[2] pos
    GLfloat[2] uvs
    GLubyte[4] vColor

cdef class FormatConfig:
    cdef unsigned int _size
    cdef list _format
    cdef str _name
    cdef dict _format_dict

cdef class VertexFormatRegister:
    cdef dict _vertex_formats

cdef VertexFormatRegister format_registrar
