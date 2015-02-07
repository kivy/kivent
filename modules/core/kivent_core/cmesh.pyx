# cython: profile=True
from kivy.graphics.vertex cimport vertex_attr_t, VertexFormat
from kivy.graphics.vertex import VertexFormatException
from kivy.graphics.instructions cimport VertexInstruction, getActiveContext
from kivy.graphics.vbo cimport VBO, VertexBatch
from kivy.logger import Logger
from kivy.graphics.c_opengl cimport *
from kivy.graphics.context cimport Context, get_context
from kivy.graphics.shader cimport Shader
from kivy.graphics.vbo cimport default_vertex
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t
from kivy.graphics.c_opengl cimport GL_FLOAT, GLfloat

include "opcodes.pxi"
include "common.pxi"
cdef short V_NEEDGEN = 1 << 0
cdef short V_NEEDUPLOAD = 1 << 1
cdef short V_HAVEID = 1 << 2

cdef VertexFormat4F* tmp
tmp = <VertexFormat4F*>NULL
cdef Py_ssize_t offset
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp.pos) - <Py_intptr_t>(tmp))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp.uvs) - <Py_intptr_t>(tmp))

vertex_format = [
    ('pos', '2', 'float', pos_offset), 
    ('uvs', '2', 'float', uvs_offset),
    ]


cdef class KEVertexFormat(VertexFormat):
    '''VertexFormat is used to describe the layout of the vertex data stored 
    in vertex arrays/vbo's.

    .. versionadded:: 1.6.0
    '''
    def __cinit__(self, size_in_bytes, *fmt):
        self.attr_offsets = NULL

    def __dealloc__(self):
        if self.vattr != NULL:
            PyMem_Free(self.vattr)
            self.vattr = NULL
        if self.attr_offsets != NULL:
            PyMem_Free(self.attr_offsets)
            self.attr_offsets = NULL

    def __init__(self, size_in_bytes, *fmt):
        cdef vertex_attr_t *attr
        cdef Py_ssize_t* attr_offsets
        cdef int index, size
        cdef Py_ssize_t offset

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

    cdef void bind(self):
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

cdef class Batch:
    cdef list frame_data
    cdef unsigned int current_frame
    cdef unsigned int frame_count


    def get_vbo_frame_to_draw(self):
        pass

    def get_index_vbo_frame_to_draw(self):
        pass

    def draw_frame(self):
        pass


cdef class BatchManager:
    cdef MemoryBlock batch_block
    cdef MemoryBlock indices_block
    cdef list batches
    cdef dict batch_groups
    cdef unsigned int active_batches
    cdef unsgined int max_batches
    cdef unsigned int slots_per_block
    cdef KEVertexFormat vertex_format

    def __cinit__(self, unsigned int vbo_size_in_kb, unsigned int batch_count,
        unsigned int frame_count, KEVertexFormat vertex_format, 
        Buffer master_buffer):
        cdef MemoryBlock batch_block, indices_block
        cdef unsigned int size_in_bytes = vbo_size_in_kb * 1024
        cdef unsigned int type_size = vertex_format.vbytesize
        cdef unsigned int slots_per_block = size_in_bytes // type_size
        cdef unsigned int block_count = frame_count*batch_count
        cdef unsigned int indices_size_in_kb = (
            slots_per_block * sizeof(unsigned int))
        cdef unsigned int indices_size_in_bytes = indices_size_in_kb * 1024
        self.batch_block = batch_block = MemoryBlock(block_count,
            vbo_size_in_kb, size_in_bytes)
        self.indices_block = indices_block = MemoryBlock(block_count,
            indices_size_in_kb, indices_size_in_bytes)
        self.vertex_format = vertex_format
        self.slots_per_block = slots_per_block
        self.batch_groups = {}
        self.batches = []
        self.active_batches = 0
        self.max_batches = batch_count

cdef class FixedFrameData: #think about name

    #has 2 fixedvbo, one for index, one for vertices
    #


cdef class FixedVBO:
    cdef MemoryBlock memory_block
    '''
    This is a VBO that has a fixed size for the amount of vertex data.
    '''

    def __cinit__(self, VertexFormat vertex_format, MemoryBlock memory_block):
        self.usage  = GL_STREAM_DRAW
        self.target = GL_ARRAY_BUFFER
        self.vertex_format = vertex_format
        self.flags = V_NEEDGEN | V_NEEDUPLOAD
        self.memory_block = memory_block
        
    def __dealloc__(self):
        get_context().dealloc_vbo(self)


    cdef int have_id(self):
        return self.flags & V_HAVEID

    cdef void generate_buffer(self):
        glGenBuffers(1, &self.id)
        glBindBuffer(GL_ARRAY_BUFFER, self.id)
        glBufferData(
            GL_ARRAY_BUFFER, self.memory_block.real_size, NULL, self.usage)

    cdef void update_buffer(self):
        # generate VBO if not done yet
        if self.flags & V_NEEDGEN:
            self.generate_buffer()
            self.flags &= ~V_NEEDGEN
            self.flags |= V_HAVEID
        cdef int data_size = self._data_size * self.format_size
        cdef void* data_ptr = self._data_pointer
        cdef int size_last_frame = self._size_last_frame
        # if the size doesn't match, we need to reupload the whole data
        glBindBuffer(GL_ARRAY_BUFFER, self.id)
        if data_size != size_last_frame:
            glBufferData(GL_ARRAY_BUFFER, data_size, data_ptr, self.usage)
            self.flags &= ~V_NEEDUPLOAD
        # if size match, update only what is needed
        elif self.flags & V_NEEDUPLOAD:
            glBufferSubData(GL_ARRAY_BUFFER, 0, data_size, data_ptr)
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

        self.update_buffer()
        glBindBuffer(GL_ARRAY_BUFFER, self.id)
        self.vertex_format.bind()

    cdef void unbind(self):
        glBindBuffer(GL_ARRAY_BUFFER, 0)


    cdef void reload(self):
        self.flags = V_NEEDUPLOAD | V_NEEDGEN
        self._size_last_frame = 0

    def __repr__(self):
        return '<VBO at %x id=%r>' % (
                id(self), self.id if self.flags & V_HAVEID else None)

# cdef class OrphaningVBO:
#     '''
#     .. versionchanged:: 1.6.0
#         VBO now no longer has a fixed vertex format. If no VertexFormat is given
#         at initialization, the default vertex format is used.
#     '''

#     def __cinit__(self, VertexFormat vertex_format=None):
#         self.usage  = GL_STREAM_DRAW
#         self.target = GL_ARRAY_BUFFER
#         if vertex_format is None:
#             vertex_format = default_vertex
#         self.vertex_format = vertex_format
#         self.format = vertex_format.vattr
#         self.format_count = vertex_format.vattr_count
#         self.format_size = vertex_format.vbytesize
#         self.flags = V_NEEDGEN | V_NEEDUPLOAD
#         self._data_size = 0
#         self._size_last_frame = 0

#     def __dealloc__(self):
#         get_context().dealloc_vbo(self)


#     cdef int have_id(self):
#         return self.flags & V_HAVEID

#     cdef void update_buffer(self):
#         # generate VBO if not done yet
#         if self.flags & V_NEEDGEN:
#             glGenBuffers(1, &self.id)
#             self.flags &= ~V_NEEDGEN
#             self.flags |= V_HAVEID
#         cdef int data_size = self._data_size * self.format_size
#         cdef void* data_ptr = self._data_pointer
#         cdef int size_last_frame = self._size_last_frame
#         # if the size doesn't match, we need to reupload the whole data
#         if data_size != size_last_frame:
#             glBindBuffer(GL_ARRAY_BUFFER, self.id)
#             glBufferData(GL_ARRAY_BUFFER, data_size, data_ptr, self.usage)
#             self.flags &= ~V_NEEDUPLOAD


#         # if size match, update only what is needed
#         elif self.flags & V_NEEDUPLOAD:
#             glBindBuffer(GL_ARRAY_BUFFER, self.id)
#             glBufferData(GL_ARRAY_BUFFER, data_size, NULL, self.usage)
#             glBufferData(GL_ARRAY_BUFFER, data_size, data_ptr, self.usage)
#             self.flags &= ~V_NEEDUPLOAD
#         self._size_last_frame = data_size

#     cdef void set_data(self, int data_size, void* data_ptr):
#         self.flags |= V_NEEDUPLOAD
#         self._data_size = data_size
#         self._data_pointer = data_ptr

#     cdef void clear_data(self):
#         self._data_size = 0
#         self._size_last_frame = 0
#         self._data_pointer = NULL

#     cdef void bind(self):
#         cdef Shader shader = getActiveContext()._shader
#         cdef vertex_attr_t *attr
#         cdef int offset = 0, i
#         glBindBuffer(GL_ARRAY_BUFFER, self.id)
#         shader.bind_vertex_format(self.vertex_format)
#         for i in xrange(self.format_count):
#             attr = &self.format[i]
#             if attr.per_vertex == 0:
#                 continue
#             glVertexAttribPointer(attr.index, attr.size, attr.type,
#                     GL_FALSE, <GLsizei>self.format_size, <GLvoid*><long>offset)
#             offset += attr.bytesize

#     cdef void unbind(self):
#         glBindBuffer(GL_ARRAY_BUFFER, 0)


#     cdef void reload(self):
#         self.flags = V_NEEDUPLOAD | V_NEEDGEN
#         self._size_last_frame = 0

#     def __repr__(self):
#         return '<VBO at %x id=%r count=%d size=%d>' % (
#                 id(self), self.id if self.flags & V_HAVEID else None,
#                 self.data.count(), self.data.size())


# cdef class DoubleBufferingVertexBatch:

#     def __init__(self, **kwargs):
#         self.usage  = GL_STREAM_DRAW
#         self._vbo_1 = kwargs.get('vbo_1')
#         if self._vbo_1 is None:
#             self._vbo_1 = KEVBO()
#         self._vbo_2 = kwargs.get('vbo_2')
#         if self._vbo_2 is None:
#             self._vbo_2 = KEVBO()
#         self.flags = V_NEEDGEN | V_NEEDUPLOAD
#         cdef GLuint* ids = <GLuint*>PyMem_Malloc(2 * sizeof(GLuint))
#         if not ids:
#             raise MemoryError()
#         self._ids = ids
#         self._last_vbo = True
#         self.set_data(NULL, 0, NULL, 0)
#         self.set_mode(kwargs.get('mode'))

#     def __dealloc__(self):
#         get_context().dealloc_vertexbatch(self)
#         if self._ids != NULL:
#             PyMem_Free(self._ids)

#     cdef int have_id(self):
#         return self.flags & V_HAVEID

#     cdef KEVBO get_current_vbo(self):
#         if self._last_vbo:
#             return self._vbo_1
#         else:
#             return self._vbo_2

#     cdef int get_current_ivbo(self):
#         if self._last_vbo:
#             return 0
#         else:
#             return 1

#     cdef void reload(self):
#         self.flags = V_NEEDGEN | V_NEEDUPLOAD
#         self._vbo_1_size_last_frame = 0
#         self._vbo_2_size_last_frame = 0

#     cdef void clear_data(self):
#         self._data_size = 0
#         self._ivbo_1_size_last_frame = 0
#         self._ivbo_2_size_last_frame = 0
#         self._data_pointer = NULL
#         self._vbo_1.clear_data()
#         self._vbo_2.clear_data()

#     cdef void set_data(self, void *vertices, int vertices_count,
#         unsigned short *indices, int indices_count):
#         cdef KEVBO vbo = self.get_current_vbo()
#         vbo.set_data(vertices_count, vertices)
#         vbo.update_buffer()
#         vbo.unbind()
#         print('updated vbo', vbo)
#         self._data_size = indices_count
#         self._data_pointer = indices
#         self.flags |= V_NEEDUPLOAD

#     cdef void draw(self):
#         cdef int count = self._data_size * sizeof(unsigned short)
#         cdef int current_ivbo_id = self.get_current_ivbo()
#         cdef unsigned short* data_ptr = self._data_pointer
#         cdef int last_frame_count

      
#         if count == 0:
#             return
#         if current_ivbo_id == 0:
#             last_frame_count = self._ivbo_1_size_last_frame
#         else:
#             last_frame_count = self._ivbo_2_size_last_frame

#         # create when needed
#         if self.flags & V_NEEDGEN:
#             glGenBuffers(2, self._ids)
#             self.flags &= ~V_NEEDGEN
#             self.flags |= V_HAVEID
#         # bind to the current id
#         print('updating indices', self._ids[current_ivbo_id])
#         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self._ids[current_ivbo_id])


#         # cache indices in a gpu buffer too
#         if self.flags & V_NEEDUPLOAD:
#             if count == last_frame_count:
#                 glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, count, data_ptr)
#             else:
#                 glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, data_ptr, 
#                     self.usage)
#             self.flags &= ~V_NEEDUPLOAD
#             if current_ivbo_id == 0:
#                 self._ivbo_1_size_last_frame = count
#             else:
#                 self._ivbo_2_size_last_frame = count
#         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

#         self._last_vbo = not self._last_vbo
#         current_ivbo_id = self.get_current_ivbo()
#         cdef KEVBO vbo = self.get_current_vbo()
        
#         print('drawing vbo', vbo)
#         print('drawing indices', self._ids[current_ivbo_id])
#         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self._ids[current_ivbo_id])
#         vbo.bind()
#         # draw the elements pointed by indices in ELEMENT ARRAY BUFFER.
#         glDrawElements(self.mode, count, GL_UNSIGNED_SHORT, NULL)
#         vbo.unbind()
#         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

#     cdef void set_mode(self, str mode):
#         # most common case in top;
#         self.mode_str = mode
#         if mode is None:
#             self.mode = GL_TRIANGLES
#         elif mode == 'points':
#             self.mode = GL_POINTS
#         elif mode == 'line_strip':
#             self.mode = GL_LINE_STRIP
#         elif mode == 'line_loop':
#             self.mode = GL_LINE_LOOP
#         elif mode == 'lines':
#             self.mode = GL_LINES
#         elif mode == 'triangle_strip':
#             self.mode = GL_TRIANGLE_STRIP
#         elif mode == 'triangle_fan':
#             self.mode = GL_TRIANGLE_FAN
#         else:
#             self.mode = GL_TRIANGLES

#     cdef str get_mode(self):
#         return self.mode_str

#     def __repr__(self):
#         return '<VertexBatch at %x id=%r vertex=%d size=%d mode=%s vbo=%x>' % (
#                 id(self), self.id if self.flags & V_HAVEID else None,
#                 self.elements.count(), self.elements.size(), self.get_mode(),
#                 id(self.vbo))

# cdef class OrphaningVertexBatch:

#     def __init__(self, **kwargs):
#         self.usage  = GL_STREAM_DRAW
#         self.vbo = kwargs.get('vbo')
#         if self.vbo is None:
#             self.vbo = OrphaningVBO()
#         self.flags = V_NEEDGEN | V_NEEDUPLOAD
#         self.set_data(NULL, 0, NULL, 0)
#         self.set_mode(kwargs.get('mode'))

#     def __dealloc__(self):
#         get_context().dealloc_vertexbatch(self)

#     cdef int have_id(self):
#         return self.flags & V_HAVEID

#     cdef void reload(self):
#         self.flags = V_NEEDGEN | V_NEEDUPLOAD
#         self._size_last_frame = 0

#     cdef void clear_data(self):
#         self._data_size = 0
#         self._size_last_frame = 0
#         self._data_pointer = NULL
#         self.vbo.clear_data()

#     cdef void set_data(self, void *vertices, int vertices_count,
#         unsigned short *indices, int indices_count):
#         self.vbo.set_data(vertices_count, vertices)
#         self._data_size = indices_count
#         self._data_pointer = indices
#         self.flags |= V_NEEDUPLOAD

#     cdef void draw(self):
#         cdef int count = self._data_size * sizeof(unsigned short)
#         cdef int last_frame_count = self._size_last_frame
#         cdef unsigned short* data_ptr = self._data_pointer
#         if count == 0:
#             return

#         # create when needed
#         if self.flags & V_NEEDGEN:
#             glGenBuffers(1, &self.id)
#             self.flags &= ~V_NEEDGEN
#             self.flags |= V_HAVEID

#         # bind to the current id
#         glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, self.id)


#         # cache indices in a gpu buffer too
#         if self.flags & V_NEEDUPLOAD:
#             if count == last_frame_count:
#                 glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, NULL, self.usage)
#                 glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, data_ptr, 
#                     self.usage)
#             else:
#                 glBufferData(GL_ELEMENT_ARRAY_BUFFER, count, data_ptr, 
#                     self.usage)
#             self.flags &= ~V_NEEDUPLOAD
#             self._size_last_frame = count

#         self.vbo.bind()

#         # draw the elements pointed by indices in ELEMENT ARRAY BUFFER.
#         glDrawElements(self.mode, count, GL_UNSIGNED_SHORT, NULL)

#     cdef void set_mode(self, str mode):
#         # most common case in top;
#         self.mode_str = mode
#         if mode is None:
#             self.mode = GL_TRIANGLES
#         elif mode == 'points':
#             self.mode = GL_POINTS
#         elif mode == 'line_strip':
#             self.mode = GL_LINE_STRIP
#         elif mode == 'line_loop':
#             self.mode = GL_LINE_LOOP
#         elif mode == 'lines':
#             self.mode = GL_LINES
#         elif mode == 'triangle_strip':
#             self.mode = GL_TRIANGLE_STRIP
#         elif mode == 'triangle_fan':
#             self.mode = GL_TRIANGLE_FAN
#         else:
#             self.mode = GL_TRIANGLES

#     cdef str get_mode(self):
#         return self.mode_str

#     def __repr__(self):
#         return '<VertexBatch at %x id=%r vertex=%d size=%d mode=%s vbo=%x>' % (
#                 id(self), self.id if self.flags & V_HAVEID else None,
#                 self.elements.count(), self.elements.size(), self.get_mode(),
#                 id(self.vbo))

cdef class CMesh(VertexInstruction):
    

    def __init__(self, **kwargs):
        VertexInstruction.__init__(self, **kwargs)
        fmt = kwargs.get('fmt')
        if fmt is not None:
            self.vertex_format = KEVertexFormat(24, *fmt)
            print('using KEVertexFormat')
            self._obatch = VertexBatch(vbo=VBO(self.vertex_format))
            #, vbo_2=VBO(                self.vertex_format))
        self.mode = kwargs.get('mode') or 'points'

    def __dealloc__(self):
        self._obatch.clear_data()
            

    cdef void build(self):
        cdef float* vertices
        cdef VertexBatch batch = self._obatch
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






