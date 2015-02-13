from kivy.graphics.c_opengl cimport GLfloat

ctypedef struct VertexFormat4F:
    GLfloat[2] pos
    GLfloat[2] uvs
