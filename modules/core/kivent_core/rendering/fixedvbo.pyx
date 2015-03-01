from kivy.graphics.context cimport Context, get_context
from kivy.graphics.c_opengl cimport (GL_ARRAY_BUFFER, GL_STREAM_DRAW,
    GL_ELEMENT_ARRAY_BUFFER, glGenBuffers, glBindBuffer, glBufferData,
    glBufferSubData)
from kivent_core.memory_handlers.block cimport MemoryBlock
from vertex_format cimport KEVertexFormat

cdef short V_NEEDGEN = 1 << 0
cdef short V_NEEDUPLOAD = 1 << 1
cdef short V_HAVEID = 1 << 2

class VBOTargetException(Exception):
    pass

class VBOUsageException(Exception):
    pass

cdef class FixedVBO:
    '''
    This is a VBO that has a fixed size for the amount of vertex data.
    '''

    def __cinit__(FixedVBO self, KEVertexFormat vertex_format, 
        MemoryBlock memory_block, str usage, str target):
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
        self.memory_block = memory_block
        self.size_last_frame = 0
        self.data_size = memory_block.real_size
        
    def __dealloc__(FixedVBO self):
        cdef Context context = get_context()
        if self.have_id():
            arr = context.lr_vbo
            arr.append(self.id)
            context.trigger_gl_dealloc()

    cdef int have_id(FixedVBO self):
        return self.flags & V_HAVEID  

    cdef void generate_buffer(FixedVBO self):
        glGenBuffers(1, &self.id)
        glBindBuffer(self.target, self.id)
        glBufferData(self.target, self.memory_block.real_size, 
            NULL, self.usage)

    cdef void update_buffer(FixedVBO self):
        cdef unsigned int data_size = self.data_size
        if self.flags & V_NEEDGEN:
            self.generate_buffer()
            self.flags &= ~V_NEEDGEN
            self.flags |= V_HAVEID
        glBindBuffer(self.target, self.id)
        if data_size != self.size_last_frame:
            glBufferData(
                self.target, data_size, self.memory_block.data, self.usage)
        else:
            glBufferSubData(self.target, 0, data_size, self.memory_block.data)
        self.size_last_frame = data_size

    cdef void bind(FixedVBO self):
        self.update_buffer()
        self.vertex_format.bind()

    cdef void unbind(FixedVBO self):
        glBindBuffer(self.target, 0)

    cdef void return_memory(FixedVBO self):
        self.memory_block.remove_from_buffer()

    cdef void reload(FixedVBO self):
        self.flags = V_NEEDGEN
        self.size_last_frame = 0
        self.memory_block.clear()

    def __repr__(self):
        return '<FixedVBO at %x id=%r>' % (
                id(self), self.id if self.flags & V_HAVEID else None)