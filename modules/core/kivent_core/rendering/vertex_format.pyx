from kivy.graphics.vertex cimport vertex_attr_t, VertexFormat
from kivy.graphics.vertex import VertexFormatException
from cython cimport Py_ssize_t
from cpython.mem cimport PyMem_Malloc, PyMem_Free
from kivy.graphics.shader cimport Shader
from kivy.graphics.c_opengl cimport (GL_FLOAT, GLfloat, GLsizei, GL_FALSE,
    glVertexAttribPointer, GLvoid)
from kivy.graphics.instructions cimport getActiveContext

cdef class KEVertexFormat(VertexFormat):
    '''VertexFormat is used to describe the layout of the vertex data stored 
    in vertex arrays/vbo's.

    .. versionadded:: 1.6.0
    '''
    def __cinit__(KEVertexFormat self, size_in_bytes, *fmt):
        self.attr_offsets = NULL

    def __dealloc__(KEVertexFormat self):
        if self.vattr != NULL:
            PyMem_Free(self.vattr)
            self.vattr = NULL
        if self.attr_offsets != NULL:
            PyMem_Free(self.attr_offsets)
            self.attr_offsets = NULL

    def __init__(KEVertexFormat self, size_in_bytes, *fmt):
        cdef vertex_attr_t *attr
        cdef Py_ssize_t* attr_offsets
        cdef int index, size
        cdef Py_ssize_t offset
        cdef unsigned int vbytesize
        if not fmt:
            raise VertexFormatException('No format specified')

        self.last_shader = None
        self.vattr_count = len(fmt)
        self.vattr = <vertex_attr_t *>PyMem_Malloc(
            sizeof(vertex_attr_t) * self.vattr_count)

        if self.vattr == NULL:
            raise MemoryError()
        self.attr_offsets = attr_offsets = <Py_ssize_t*>PyMem_Malloc(
            sizeof(Py_ssize_t)*self.vattr_count)
        if self.attr_offsets == NULL:
            raise MemoryError()

        index = 0
        for name, size, tp, offset in fmt:
            attr = &self.vattr[index]
            attr_offsets[index] = offset
            # fill the vertex format
            attr.per_vertex = 1
            attr.name = <bytes>name
            attr.index = 0 # will be set by the shader itself
            attr.size = size

            # only float is accepted as attribute format
            if tp == 'float':
                attr.type = GL_FLOAT
                attr.bytesize = sizeof(GLfloat) * size
            else:
                raise VertexFormatException('Unknow format type %r' % tp)

            # adjust the size, and prepare for the next iteration.
            index += 1
            self.vsize += attr.size
        self.vbytesize = size_in_bytes

    cdef void bind(KEVertexFormat self):
        cdef Shader shader = getActiveContext()._shader
        cdef vertex_attr_t *attr
        cdef vertex_attr_t* vattr = self.vattr
        cdef Py_ssize_t* offsets = self.attr_offsets
        cdef unsigned int vbytesize = self.vbytesize
        cdef int i
        shader.bind_vertex_format(self)
        for i in xrange(self.vattr_count):
            attr = &vattr[i]
            if attr.per_vertex == 0:
                continue
            glVertexAttribPointer(attr.index, attr.size, attr.type,
                    GL_FALSE, <GLsizei>vbytesize, 
                    <GLvoid*><long>offsets[i])
