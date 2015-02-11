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
from kivy.graphics.c_opengl cimport GL_FLOAT, GLfloat, GLushort
from resource_managers import texture_manager
from membuffer cimport MemoryBlock, Buffer

include "opcodes.pxi"
include "common.pxi"
cdef short V_NEEDGEN = 1 << 0
cdef short V_NEEDUPLOAD = 1 << 1
cdef short V_HAVEID = 1 << 2

#equivalent of the offsetof macro in cython
cdef VertexFormat4F* tmp
tmp = <VertexFormat4F*>NULL
cdef Py_ssize_t offset
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp.pos) - <Py_intptr_t>(tmp))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp.uvs) - <Py_intptr_t>(tmp))

vertex_format = [
    ('pos', 2, 'float', pos_offset), 
    ('uvs', 2, 'float', uvs_offset),
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

    def __cinit__(self, int tex_key, unsigned int index_count,
        unsigned int vertex_count, unsigned int frame_count, list vbos,
        GLuint mode):
        self.frame_data = vbos
        self.entity_ids = []
        self.tex_key = tex_key
        self.current_frame = 0
        self.frame_count = frame_count
        self.batch_id = -1
        self.mode = mode
        self.mesh_instruction = None

    cdef tuple add_entity(self, unsigned int entity_id, unsigned int num_verts, 
        unsigned int num_indices):
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        cdef unsigned int ind_index = indices_block.add_data(num_indices)
        cdef unsigned int vert_index = vertex_block.add_data(num_verts)
        self.entity_ids.append(entity_id)
        return (vert_index, ind_index)

    cdef void remove_entity(self, unsigned int entity_id, 
        unsigned int num_verts, unsigned int vert_index, 
        unsigned int num_indices, unsigned int ind_index):
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        indices_block.remove_data(ind_index, num_indices)
        vertex_block.remove_data(vert_index, num_verts)
        self.entity_ids.remove(entity_id)

    cdef bool check_empty(self):
        return len(self.entity_ids) == 0

    cdef bool can_fit_data(self, unsigned int num_verts, 
        unsigned int num_indices):
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        return (vertex_block.can_fit_data(num_verts) and 
            indices_block.can_fit_data(num_indices))

    cdef void* get_vbo_frame_to_draw(self):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO vertices = frame_data.vertex_vbo
        cdef MemoryBlock vertex_block = vertices.memory_block
        return vertex_block.data

    cdef FixedFrameData get_current_vbo(self):
        return self.frame_data[self.current_frame % self.frame_count]

    cdef void* get_indices_frame_to_draw(self):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        cdef MemoryBlock index_block = indices.memory_block
        return index_block.data

    cdef void set_index_count_for_frame(self, unsigned int index_count):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        indices.data_size = index_count * sizeof(GLushort)


    cdef void draw_frame(self):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        cdef FixedVBO vertices = frame_data.vertex_vbo
        vertices.bind()
        indices.bind()
        glDrawElements(self.mode, indices.data_size, GL_UNSIGNED_SHORT, NULL)
        self.current_frame += 1

    cdef void clear_frames(self):
        cdef FixedFrameData frame
        cdef list frame_data = self.frame_data
        for frame in frame_data:
            frame.return_memory()
        del frame_data[:]

class MaxBatchException(Exception):
    pass

cdef class BatchManager:

    def __cinit__(self, unsigned int vbo_size_in_kb, unsigned int batch_count,
        unsigned int frame_count, KEVertexFormat vertex_format, 
        Buffer master_buffer, str mode_str, object canvas):
        cdef MemoryBlock batch_block, indices_block
        cdef unsigned int size_in_bytes = vbo_size_in_kb * 1024
        cdef unsigned int type_size = vertex_format.vbytesize
        cdef unsigned int vert_slots_per_block = size_in_bytes // type_size
        cdef unsigned int index_slots_per_block = size_in_bytes // sizeof(
            GLushort)
        cdef unsigned int block_count = frame_count*batch_count
        self.batch_block = batch_block = MemoryBlock(block_count,
            vbo_size_in_kb, size_in_bytes)
        batch_block.allocate_memory_with_buffer(master_buffer)
        self.indices_block = indices_block = MemoryBlock(block_count,
            vbo_size_in_kb, size_in_bytes)
        indices_block.allocate_memory_with_buffer(master_buffer)
        self.vertex_format = vertex_format
        self.slots_per_block = vert_slots_per_block
        self.index_slots_per_block = index_slots_per_block
        self.batch_groups = {}
        self.batches = []
        self.free_batches = []
        self.batch_count = 0
        self.vbo_size_in_kb = vbo_size_in_kb
        self.frame_count = frame_count
        self.max_batches = batch_count
        self.set_mode(mode_str)
        self.canvas = canvas

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

    cdef Batch create_batch(self, int tex_key):
        if self.batch_count == self.max_batches:
            raise MaxBatchException(
                'Cannot allocate another batch: Max batches: ', 
                self.max_batches, """raise your batch_count for this renderer
                or pack your textures more appropriately to reduce number
                of batches""")
        cdef Batch batch = Batch(tex_key, self.index_slots_per_block, 
            self.slots_per_block, self.frame_count, self.get_vbos(),
            self.mode)
        cdef list free_batches = self.free_batches
        cdef unsigned int new_index
        if len(free_batches) > 0:
            new_index = free_batches.pop(0)
            self.batches[new_index] = batch
        else:
            self.batches.append(batch)
            new_index = self.batch_count
            self.batch_count += 1
        batch.batch_id = new_index
        cdef dict batch_groups = self.batch_groups

        if tex_key not in batch_groups:
            batch_groups[tex_key] = [batch]
        else:
            batch_groups[tex_key].append(batch)
        cdef CMesh new_cmesh
        with self.canvas:
            new_cmesh = CMesh(texture=texture_manager.get_texture(tex_key), 
                batch=batch)
            batch.mesh_instruction = new_cmesh
        return batch
  
    cdef void remove_batch(self, unsigned int batch_id):
        cdef Batch batch = self.batches[batch_id]
        cdef int tex_key = batch.tex_key
        self.canvas.remove(batch.mesh_instruction)
        batch.mesh_instruction = None
        self.batch_groups[tex_key].remove(batch)
        batch.clear_frames()
        self.batches[batch_id] = None
        self.free_batches.append(batch_id)

    cdef Batch get_batch_with_space(self, int tex_key, 
        unsigned int num_verts, unsigned int num_indices):
        cdef dict batch_groups = self.batch_groups
        cdef Batch batch
        if tex_key not in batch_groups:
            return self.create_batch(tex_key)
        else:
            for batch in batch_groups[tex_key]:
                if batch.can_fit_data(num_verts, num_indices):
                    return batch
            else:
                return self.create_batch(tex_key)

    cdef tuple batch_entity(self, unsigned int entity_id, int tex_key,
        unsigned int num_verts, unsigned int num_indices):
        cdef Batch batch = self.get_batch_with_space(
            tex_key, num_verts, num_indices)
        cdef tuple indices = batch.add_entity(
            entity_id, num_verts, num_indices)
        return (batch.batch_id, indices[0], indices[1]) # batch, vert, ind

    cdef void unbatch_entity(self, unsigned int entity_id, 
        unsigned int batch_id, unsigned int num_verts, 
        unsigned int num_indices, unsigned int vert_index,
        unsigned int ind_index):
        cdef Batch batch = self.batches[batch_id]
        batch.remove_entity(entity_id, num_verts, vert_index, num_indices,
            ind_index)

    cdef list get_vbos(self):
        cdef unsigned int i
        cdef MemoryBlock index_block, vertex_block
        cdef MemoryBlock master_vertex = self.batch_block
        cdef MemoryBlock master_index = self.indices_block
        cdef unsigned int vbo_size = self.vbo_size_in_kb
        cdef KEVertexFormat vertex_format = self.vertex_format
        cdef FixedFrameData frame_data
        cdef unsigned int type_size = vertex_format.vbytesize
        cdef list vbos = []
        vbo_a = vbos.append
        for i in range(self.frame_count):
            index_block = MemoryBlock(1, vbo_size, sizeof(GLushort))
            index_block.allocate_memory_with_buffer(master_index)
            vertex_block = MemoryBlock(1, vbo_size, type_size)
            vertex_block.allocate_memory_with_buffer(master_vertex)
            frame_data = FixedFrameData(index_block, vertex_block, 
                vertex_format)
            vbo_a(frame_data)
        return vbos

cdef class FixedFrameData: 

    def __cinit__(self, MemoryBlock index_block, MemoryBlock vertex_block,
        KEVertexFormat vertex_format):
        self.index_vbo = FixedVBO(
            vertex_format, index_block, 'stream', 'elements')
        self.vertex_vbo = FixedVBO(
            vertex_format, vertex_block, 'stream', 'array')

    cdef void return_memory(self):
        self.index_vbo.return_memory()
        self.vertex_vbo.return_memory()


class VBOTargetException(Exception):
    pass

class VBOUsageException(Exception):
    pass

cdef class FixedVBO:
    '''
    This is a VBO that has a fixed size for the amount of vertex data.
    '''

    def __cinit__(self, VertexFormat vertex_format, MemoryBlock memory_block,
        str usage, str target):
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
        
    def __dealloc__(self):
        get_context().dealloc_vbo(self)

    cdef int have_id(self):
        return self.flags & V_HAVEID  

    cdef void generate_buffer(self):
        glGenBuffers(1, &self.id)
        glBindBuffer(self.target, self.id)
        glBufferData(self.target, self.memory_block.real_size, 
            NULL, self.usage)

    cdef void update_buffer(self):
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

    cdef void bind(self):
        self.update_buffer()
        glBindBuffer(self.target, self.id)
        self.vertex_format.bind()

    cdef void unbind(self):
        glBindBuffer(self.target, 0)

    cdef void return_memory(self):
        self.memory_block.remove_from_buffer()

    cdef void reload(self):
        self.flags = V_NEEDGEN
        self.size_last_frame = 0
        self.memory_block.clear()

    def __repr__(self):
        return '<FixedVBO at %x id=%r>' % (
                id(self), self.id if self.flags & V_HAVEID else None)

cdef class CMesh(VertexInstruction):

    def __init__(self, **kwargs):
        VertexInstruction.__init__(self, **kwargs)
        cdef Batch batch = kwargs.get('batch')
        self._batch = batch

    def __dealloc__(self):
        self._batch.clear_frames()

    cdef void apply(self):
        if self.flags & GI_NEEDS_UPDATE:
            self.flag_update_done()
        self._batch.draw_frame()







