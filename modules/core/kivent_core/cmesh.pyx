# cython: profile=True
from kivy.graphics.vertex cimport VertexFormat, vertex_attr_t
from kivy.graphics.instructions cimport VertexInstruction, getActiveContext
# from kivy.graphics.c_opengl cimport *
from kivy.graphics.vbo cimport VBO, VertexBatch
from kivy.logger import Logger
from kivy.graphics.c_opengl cimport *
from kivy.graphics.context cimport Context, get_context
from kivy.graphics.shader cimport Shader
from kivy.graphics.vbo cimport default_vertex

include "opcodes.pxi"

cdef short V_NEEDGEN = 1 << 0
cdef short V_NEEDUPLOAD = 1 << 1
cdef short V_HAVEID = 1 << 2


cdef class OrphaningVBO:
    '''
    .. versionchanged:: 1.6.0
        VBO now no longer has a fixed vertex format. If no VertexFormat is given
        at initialization, the default vertex format is used.
    '''

    def __cinit__(self, VertexFormat vertex_format=None):
        self.usage  = GL_STREAM_DRAW
        self.target = GL_ARRAY_BUFFER
        if vertex_format is None:
            vertex_format = default_vertex
        self.vertex_format = vertex_format
        self.format = vertex_format.vattr
        self.format_count = vertex_format.vattr_count
        self.format_size = vertex_format.vbytesize
        self.flags = V_NEEDGEN | V_NEEDUPLOAD
        self._data_size = 0
        self._size_last_frame = 0

    def __dealloc__(self):
        get_context().dealloc_vbo(self)


    cdef int have_id(self):
        return self.flags & V_HAVEID

    cdef void update_buffer(self):
        # generate VBO if not done yet
        if self.flags & V_NEEDGEN:
            glGenBuffers(1, &self.id)
            self.flags &= ~V_NEEDGEN
            self.flags |= V_HAVEID
        cdef int data_size = self._data_size * self.format_size
        cdef void* data_ptr = self._data_pointer
        cdef int size_last_frame = self._size_last_frame
        # if the size doesn't match, we need to reupload the whole data
        if data_size != size_last_frame:
            glBindBuffer(GL_ARRAY_BUFFER, self.id)
            glBufferData(GL_ARRAY_BUFFER, data_size, data_ptr, self.usage)
            self.flags &= ~V_NEEDUPLOAD


        # if size match, update only what is needed
        elif self.flags & V_NEEDUPLOAD:
            glBindBuffer(GL_ARRAY_BUFFER, self.id)
            glBufferData(GL_ARRAY_BUFFER, data_size, NULL, self.usage)
            glBufferData(GL_ARRAY_BUFFER, data_size, data_ptr, self.usage)
            self.flags &= ~V_NEEDUPLOAD
        self._size_last_frame = data_size

    cdef void set_data(self, int data_size, void* data_ptr):
        self.flags |= V_NEEDUPLOAD
        self._data_size = data_size
        self._data_pointer = data_ptr

    cdef void clear_data(self):
        self._data_size = 0
        self._size_last_frame = 0
        self._data_pointer = NULL

    cdef void bind(self):
        cdef Shader shader = getActiveContext()._shader
        cdef vertex_attr_t *attr
        cdef int offset = 0, i
        self.update_buffer()
        glBindBuffer(GL_ARRAY_BUFFER, self.id)
        shader.bind_vertex_format(self.vertex_format)
        for i in xrange(self.format_count):
            attr = &self.format[i]
            if attr.per_vertex == 0:
                continue
            glVertexAttribPointer(attr.index, attr.size, attr.type,
                    GL_FALSE, <GLsizei>self.format_size, <GLvoid*><long>offset)
            offset += attr.bytesize

    cdef void unbind(self):
        glBindBuffer(GL_ARRAY_BUFFER, 0)


    cdef void reload(self):
        self.flags = V_NEEDUPLOAD | V_NEEDGEN
        self.vbo_size = 0

    def __repr__(self):
        return '<VBO at %x id=%r count=%d size=%d>' % (
                id(self), self.id if self.flags & V_HAVEID else None,
                self.data.count(), self.data.size())

cdef class OrphaningVertexBatch:

    def __init__(self, **kwargs):
        self.usage  = GL_STREAM_DRAW
        self.vbo = kwargs.get('vbo')
        if self.vbo is None:
            self.vbo = OrphaningVBO()
        self.flags = V_NEEDGEN | V_NEEDUPLOAD

        self.set_data(NULL, 0, NULL, 0)
        self.set_mode(kwargs.get('mode'))

    def __dealloc__(self):
        get_context().dealloc_vertexbatch(self)

    cdef int have_id(self):
        return self.flags & V_HAVEID

    cdef void reload(self):
        self.flags = V_NEEDGEN | V_NEEDUPLOAD
        self._size_last_frame = 0

    cdef void clear_data(self):
        self._data_size = 0
        self._size_last_frame = 0
        self._data_pointer = NULL
        self.vbo.clear_data()

    cdef void set_data(self, void *vertices, int vertices_count,
        unsigned short *indices, int indices_count):
        self.vbo.set_data(vertices_count, vertices)
        self._data_size = indices_count
        self._data_pointer = indices
        self.flags |= V_NEEDUPLOAD

    cdef void draw(self):
        cdef int count = self._data_size * sizeof(unsigned short)
        cdef int last_frame_count = self._size_last_frame
        cdef unsigned short* data_ptr = self._data_pointer
        print('drawing vbo', count)
        if count == 0:
            return

        # create when needed
        if self.flags & V_NEEDGEN:
            glGenBuffers(1, &self.id)
            self.flags &= ~V_NEEDGEN
            self.flags |= V_HAVEID

        # bind to the current id
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.id)


        # cache indices in a gpu buffer too
        if self.flags & V_NEEDUPLOAD:
            if count == last_frame_count:
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, NULL, self.usage)
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, data_ptr, 
                    self.usage)
            else:
                glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, data_ptr, 
                    self.usage)
            self.flags &= ~V_NEEDUPLOAD
            self._size_last_frame = count

        self.vbo.bind()

        # draw the elements pointed by indices in ELEMENT ARRAY BUFFER.
        glDrawElements(self.mode, count, GL_UNSIGNED_SHORT, NULL)

    cdef void set_mode(self, str mode):
        # most common case in top;
        self.mode_str = mode
        if mode is None:
            self.mode = GL_TRIANGLES
        elif mode == 'points':
            self.mode = GL_POINTS
        elif mode == 'line_strip':
            self.mode = GL_LINE_STRIP
        elif mode == 'line_loop':
            self.mode = GL_LINE_LOOP
        elif mode == 'lines':
            self.mode = GL_LINES
        elif mode == 'triangle_strip':
            self.mode = GL_TRIANGLE_STRIP
        elif mode == 'triangle_fan':
            self.mode = GL_TRIANGLE_FAN
        else:
            self.mode = GL_TRIANGLES

    cdef str get_mode(self):
        return self.mode_str

    def __repr__(self):
        return '<VertexBatch at %x id=%r vertex=%d size=%d mode=%s vbo=%x>' % (
                id(self), self.id if self.flags & V_HAVEID else None,
                self.elements.count(), self.elements.size(), self.get_mode(),
                id(self.vbo))

cdef class CMesh(VertexInstruction):
    

    def __init__(self, **kwargs):
        VertexInstruction.__init__(self, **kwargs)
        fmt = kwargs.get('fmt')
        if fmt is not None:
            self.vertex_format = VertexFormat(*fmt)
            self._obatch = OrphaningVertexBatch(vbo=OrphaningVBO(
                self.vertex_format))
        self.mode = kwargs.get('mode') or 'points'

    def __dealloc__(self):
        self._obatch.clear_data()
            

    cdef void build(self):
        cdef float* vertices
        cdef OrphaningVertexBatch batch = self._obatch
        cdef unsigned short* indices
        vertices = <float *>self._vertices
        indices = <unsigned short*>self._indices
        cdef long vcount = self.vcount
        cdef vsize = batch.vbo.vertex_format.vsize
        cdef long icount = self.icount
        batch.set_data(vertices, <int>(vcount / vsize), indices, <int>icount)

    cdef void apply(self):
        if self.flags & GI_NEEDS_UPDATE:
            self.build()
            self.flag_update_done()
        self._obatch.draw()



    property mode:
        '''VBO Mode used for drawing vertices/indices. Can be one of 'points',
        'line_strip', 'line_loop', 'lines', 'triangle_strip' or 'triangle_fan'.
        '''
        def __get__(self):
            self._obatch.get_mode()
        def __set__(self, mode):
            self._obatch.set_mode(mode)






