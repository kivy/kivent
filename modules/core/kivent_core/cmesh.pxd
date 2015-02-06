from kivy.graphics.vertex cimport VertexFormat, vertex_attr_t
from kivy.graphics.instructions cimport VertexInstruction
from kivy.graphics.c_opengl cimport *
from kivy.graphics.vbo cimport VBO, VertexBatch
from cpython cimport bool

ctypedef struct VertexFormat4F:
    GLfloat[2] pos
    GLfloat[2] uvs

cdef class KEVertexFormat(VertexFormat):
    cdef Py_ssize_t* attr_offsets
    cdef void bind(self)

cdef class FixedVBO:
    cdef object __weakref__
    cdef int _data_size
    cdef void* _data_pointer
    cdef int _size_last_frame
    cdef GLuint id
    cdef int usage
    cdef int target
    cdef short flags
    cdef KEVertexFormat vertex_format
    cdef int have_id(self)
    cdef void update_buffer(self)
    cdef void set_data(self, int data_size, void* data_ptr)
    cdef void clear_data(self)
    cdef void bind(self)
    cdef void unbind(self)
    cdef void reload(self)



# cdef class OrphaningVBO:
#     cdef object __weakref__
#     cdef int _data_size
#     cdef void* _data_pointer
#     cdef int _size_last_frame
#     cdef GLuint id
#     cdef int usage
#     cdef int target
#     cdef vertex_attr_t *format
#     cdef long format_count
#     cdef long format_size
#     cdef short flags
#     cdef VertexFormat vertex_format
#     cdef int have_id(self)
#     cdef void update_buffer(self)
#     cdef void set_data(self, int data_size, void* data_ptr)
#     cdef void clear_data(self)
#     cdef void bind(self)
#     cdef void unbind(self)
#     cdef void reload(self)

# cdef class OrphaningVertexBatch:
#     cdef object __weakref__
#     cdef int _data_size
#     cdef unsigned short* _data_pointer
#     cdef int _size_last_frame
#     cdef OrphaningVBO vbo
#     cdef GLuint mode
#     cdef str mode_str
#     cdef GLuint id
#     cdef int usage
#     cdef short flags
#     cdef int have_id(self)
#     cdef void reload(self)
#     cdef void clear_data(self)
#     cdef void set_data(self, void *vertices, int vertices_count,
#         unsigned short *indices, int indices_count)
#     cdef void draw(self)
#     cdef void set_mode(self, str mode)
#     cdef str get_mode(self)


# cdef class DoubleBufferingVertexBatch:
#     cdef object __weakref__
#     cdef int _data_size
#     cdef unsigned short* _data_pointer
#     cdef int _ivbo_1_size_last_frame
#     cdef int _ivbo_2_size_last_frame
#     cdef KEVBO _vbo_1
#     cdef KEVBO _vbo_2
#     cdef bool _last_vbo
#     cdef GLuint mode
#     cdef str mode_str
#     cdef GLuint* _ids
#     cdef int usage
#     cdef short flags
#     cdef int have_id(self)
#     cdef void reload(self)
#     cdef void clear_data(self)
#     cdef void set_data(self, void *vertices, int vertices_count,
#         unsigned short *indices, int indices_count)
#     cdef void draw(self)
#     cdef void set_mode(self, str mode)
#     cdef str get_mode(self)
#     cdef KEVBO get_current_vbo(self)
#     cdef int get_current_ivbo(self)

cdef class CMesh(VertexInstruction):
    cdef void* _vertices
    cdef void* _indices
    cdef VertexFormat vertex_format
    cdef long vcount
    cdef long icount
    cdef VertexBatch _obatch