# cython: embedsignature=True
from kivy.graphics.context cimport Context, get_context
from kivy.graphics.cgl cimport (GL_ARRAY_BUFFER, GL_STREAM_DRAW,
    GL_ELEMENT_ARRAY_BUFFER, cgl)
from kivent_core.rendering.gl_debug cimport gl_log_debug_message
from kivent_core.memory_handlers.membuffer cimport NoFreeBuffer
from vertex_format cimport KEVertexFormat
from vbo_definitions cimport (V_NEEDGEN, V_HAVEID, V_NEEDUPLOAD,
                              VBOTargetException, VBOUsageException)


cdef class SimpleVBO:
    '''
    '''

    def __cinit__(self, KEVertexFormat vertex_format,
                  NoFreeBuffer memory_buffer, str usage, str target):
        '''
        '''
        if target == 'array':
            self.target = GL_ARRAY_BUFFER
        elif target == 'elements':
            self.target = GL_ELEMENT_ARRAY_BUFFER
        else:
            raise VBOTargetException('Unknown type for VBO target:', target,
                "Only accepts: 'array', 'elements'")
        if usage == 'stream':
            self.usage  = GL_STREAM_DRAW
        else:
            raise VBOUsageException('Unknown type for VBO usage:', usage,
                "Only accepts: 'stream',")
        self.vertex_format = vertex_format
        self.flags = V_NEEDGEN
        self.memory_buffer = memory_buffer
        self.size_last_frame = 0
        self.data_size = memory_buffer.real_size

    def __dealloc__(self):
        cdef Context context = get_context()
        if self.have_id():
            arr = context.lr_vbo
            arr.append(self.id)
            context.trigger_gl_dealloc()

    cdef int have_id(self):
        '''Used during deallocation to determine whether or not this
        VBO need to have gl deallocation run on it.
        Return:
            int: 1 if the buffer have been assigned an id from GL else 0.'''
        return self.flags & V_HAVEID

    cdef void generate_buffer(self):
        '''Generates the glBuffer by calling glGenBuffers and glBindBuffer
        the buffer will initially be made the entire size of **memory_block**
        and pointed at a NULL data.'''
        #commentout for sphinx
        cgl.glGenBuffers(1, &self.id)
        gl_log_debug_message('SimpleVBO.generate_buffer-glGenBuffer')
        cgl.glBindBuffer(self.target, self.id)
        gl_log_debug_message('SimpleVBO.generate_buffer-glBindBuffer')
        cgl.glBufferData(self.target, self.memory_buffer.real_size,
            NULL, self.usage)
        gl_log_debug_message('SimpleVBO.generate_buffer-glBufferData')

    cdef void update_buffer(self):
        '''Updates the buffer, uploading the latest data from **memory_block**
        If the data is the same size as the last call of **update_buffer**
        glBufferSubData will be used, if it is different glBufferData will be
        used. If V_NEEDGEN has been set for **flags**, **generate_buffer**
        will be called.
        '''
        #commontout for sphinx
        cdef unsigned int data_size = self.data_size
        if self.flags & V_NEEDGEN:
            self.generate_buffer()
            self.flags &= ~V_NEEDGEN
            self.flags |= V_HAVEID
        cgl.glBindBuffer(self.target, self.id)
        gl_log_debug_message('SimpleVBO.update_buffer-glBindBuffer')
        if data_size != self.size_last_frame:
            cgl.glBufferData(
                self.target, data_size, self.memory_buffer.data, self.usage)
            gl_log_debug_message('SimpleVBO.update_buffer-glBufferData')
        else:
            cgl.glBufferSubData(self.target, 0, data_size,
                                self.memory_buffer.data)
            gl_log_debug_message('SimpleVBO.update_buffer-glBufferSubData')
        self.size_last_frame = data_size

    cdef void bind(self):
        '''Binds this buffer for rendering, calling **update_buffer** in the
        process. Will call the bind function of **vertex_format** if
        target is GL_ARRAY_BUFFER.'''
        self.update_buffer()
        if self.target == GL_ARRAY_BUFFER:
            self.vertex_format.bind()

    cdef void unbind(self):
        '''Unbinds the buffer after rendering'''
        #commentout for sphinx
        cgl.glBindBuffer(self.target, 0)
        gl_log_debug_message('SimpleVBO.unbind-glBindBuffer')

    cdef void return_memory(self):
        '''Will return the memory claimed by this VBO's **memory_block**.'''
        self.memory_buffer.deallocate_memory()

    cdef void reload(self):
        '''Will flag this VBO as V_NEEDGEN, set the **size_last_frame** to 0,
        and clear the **memory_block**.'''
        self.size_last_frame = 0
        cdef Context context = get_context()
        if self.have_id():
            arr = context.lr_vbo
            arr.append(self.id)
            context.trigger_gl_dealloc()
        self.flags = V_NEEDGEN
        if self.target == GL_ELEMENT_ARRAY_BUFFER:
            self.data_size = 0
        self.memory_buffer.clear()

    def __repr__(self):
        return '<SimpleVBO at %x id=%r>' % (
                id(self), self.id if self.flags & V_HAVEID else None)