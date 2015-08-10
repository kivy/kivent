from kivy.graphics.c_opengl cimport GLfloat, GLubyte


ctypedef struct VertexFormat2F4UB:
    GLfloat[2] pos
    GLubyte[4] v_color