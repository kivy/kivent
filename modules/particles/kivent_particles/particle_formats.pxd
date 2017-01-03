from kivy.graphics.cgl cimport GLfloat, GLubyte


ctypedef struct VertexFormat9F4UB:
    GLfloat[2] pos
    GLfloat[2] uvs
    GLfloat[2] center
    GLfloat[2] scale
    GLubyte[4] v_color
    GLfloat rotate