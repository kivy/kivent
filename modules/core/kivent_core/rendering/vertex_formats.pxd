from kivy.graphics.c_opengl cimport GLfloat

ctypedef struct VertexFormat4F:
    GLfloat[2] pos
    GLfloat[2] uvs

ctypedef struct VertexFormat7F:
    GLfloat[2] pos
    GLfloat[2] uvs
    GLfloat rot
    GLfloat[2] center