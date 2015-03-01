# cython: profile=True
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from fixedvbo cimport FixedVBO
from frame_objects cimport FixedFrameData
from vertex_format cimport KEVertexFormat
from cpython cimport bool
from cmesh cimport CMesh
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.systems.staticmemgamesystem cimport ComponentPointerAggregator
from kivy.logger import Logger
from kivy.graphics.c_opengl cimport (GLushort, GL_UNSIGNED_SHORT, GL_TRIANGLES,
    GL_POINTS, GL_LINES, GL_LINE_STRIP, GL_LINE_LOOP, GL_TRIANGLE_STRIP, 
    GL_TRIANGLE_FAN, glDrawElements, GLuint)
from kivent_core.gameworld import debug


cdef class IndexedBatch:

    def __cinit__(IndexedBatch self, int tex_key, unsigned int index_count,
        unsigned int vertex_count, unsigned int frame_count, list vbos,
        GLuint mode, ComponentPointerAggregator aggregator):
        self.frame_data = vbos
        self.tex_key = tex_key
        self.current_frame = 0
        self.frame_count = frame_count
        self.batch_id = -1
        self.mode = mode
        self.entity_components = aggregator
        self.mesh_instruction = None

    cdef tuple add_entity(IndexedBatch self, unsigned int entity_id, 
        unsigned int num_verts, unsigned int num_indices):
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        cdef unsigned int ind_index = indices_block.add_data(num_indices)
        cdef unsigned int vert_index = vertex_block.add_data(num_verts)
        batch_index = self.entity_components.add_entity(entity_id)
        if debug:
            Logger.debug('KivEnt: Entity: {entity_id} batched at vertex#: '
                '{vert_index} indices#: {ind_index}'.format(
                    entity_id=entity_id, vert_index=vert_index, 
                    ind_index=ind_index))
        return (vert_index, ind_index)

    cdef void remove_entity(IndexedBatch self, unsigned int entity_id, 
        unsigned int num_verts, unsigned int vert_index, 
        unsigned int num_indices, unsigned int ind_index):
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        indices_block.remove_data(ind_index, num_indices)
        vertex_block.remove_data(vert_index, num_verts)
        if debug:
            Logger.debug('KivEnt: Entity: {entity_id} removed from batch at '
                'vertex#: {vert_index} indices#: {ind_index}'.format(
                    entity_id=entity_id, vert_index=vert_index, 
                    ind_index=ind_index))
        self.entity_components.remove_entity(entity_id)

    cdef bool check_empty(IndexedBatch self):
        return self.entity_components.check_empty()

    cdef bool can_fit_data(IndexedBatch self, unsigned int num_verts, 
        unsigned int num_indices):
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        return (vertex_block.can_fit_data(num_verts) and 
            indices_block.can_fit_data(num_indices))

    cdef void* get_vbo_frame_to_draw(IndexedBatch self):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO vertices = frame_data.vertex_vbo
        cdef MemoryBlock vertex_block = vertices.memory_block
        return vertex_block.data

    cdef FixedFrameData get_current_vbo(IndexedBatch self):
        return self.frame_data[self.current_frame % self.frame_count]

    cdef void* get_indices_frame_to_draw(IndexedBatch self):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        cdef MemoryBlock index_block = indices.memory_block
        return index_block.data

    cdef void set_index_count_for_frame(IndexedBatch self, 
        unsigned int index_count):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        indices.data_size = index_count * sizeof(GLushort)

    cdef void draw_frame(IndexedBatch self):
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        cdef FixedVBO vertices = frame_data.vertex_vbo
        vertices.bind()
        indices.bind()
        glDrawElements(self.mode, indices.data_size // sizeof(GLushort), 
            GL_UNSIGNED_SHORT, NULL)
        vertices.unbind()
        indices.unbind()
        self.current_frame += 1

    cdef void clear_frames(IndexedBatch self):
        cdef FixedFrameData frame
        cdef list frame_data = self.frame_data
        self.entity_components.free()
        for frame in frame_data:
            frame.return_memory()
        del frame_data[:]


class MaxBatchException(Exception):
    pass


cdef class BatchManager:

    def __cinit__(BatchManager self, unsigned int vbo_size_in_kb, 
        unsigned int batch_count, unsigned int frame_count, 
        KEVertexFormat vertex_format, Buffer master_buffer, str mode_str, 
        object canvas, IndexedMemoryZone entities, list system_names,
        unsigned int smallest_vertex_count):
        cdef MemoryBlock batch_block, indices_block
        self.entities = entities
        self.system_names = system_names
        cdef unsigned int size_in_bytes = vbo_size_in_kb * 1024
        cdef unsigned int type_size = vertex_format.vbytesize
        cdef unsigned int vert_slots_per_block = size_in_bytes // type_size
        cdef unsigned int ent_per_batch = (
            vert_slots_per_block // smallest_vertex_count)
        self.ent_per_batch = ent_per_batch
        cdef unsigned int index_slots_per_block = size_in_bytes // sizeof(
            GLushort)
        cdef unsigned int block_count = frame_count*batch_count
        self.batch_block = batch_block = MemoryBlock(block_count*size_in_bytes, 
            size_in_bytes, 1)
        Logger.info('KivEnt: Batches for canvas: {canvas} will have ' 
            '{vert_slots_per_block} verts and VBO will be {vbo_size} in KiB per'
            ' frame with {count} total vbos, an estimated {ent_per_batch}' 
            ' enities fit in each batch with {verts} verts per entity'.format(
            canvas=str(canvas), vert_slots_per_block=vert_slots_per_block, 
            vbo_size=vbo_size_in_kb, count=block_count, 
            ent_per_batch=ent_per_batch, verts=smallest_vertex_count))
        batch_block.allocate_memory_with_buffer(master_buffer)
        self.master_buffer = master_buffer
        self.indices_block = indices_block = MemoryBlock(
            block_count*size_in_bytes, size_in_bytes, 1)
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

    cdef unsigned int get_size(self):
        cdef unsigned int pointer_size = self.get_size_of_component_pointers()
        return self.indices_block.real_size + self.batch_block.real_size + (
            pointer_size)

    cdef void set_mode(BatchManager self, str mode):
        # most common case in top;
        self.mode_str = mode
        if mode is 'triangles':
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

    cdef str get_mode(BatchManager self):
        return self.mode_str

    cdef unsigned int get_size_of_component_pointers(self):
        cdef ComponentPointerAggregator entity_components = (
            ComponentPointerAggregator(self.system_names, self.ent_per_batch, 
                self.entities, self.master_buffer))
        real_size = entity_components.get_size()
        entity_components.free()
        return real_size * self.max_batches

    cdef unsigned int create_batch(BatchManager self, int tex_key) except -1:
        if self.batch_count == self.max_batches:
            raise MaxBatchException(
                'Cannot allocate another batch: Max batches: ', 
                self.max_batches, """raise your batch_count for this renderer
                or pack your textures more appropriately to reduce number
                of batches""")
        cdef ComponentPointerAggregator entity_components = (
            ComponentPointerAggregator(self.system_names, self.ent_per_batch, 
                self.entities, self.master_buffer))
        cdef IndexedBatch batch = IndexedBatch(tex_key, 
            self.index_slots_per_block, self.slots_per_block, self.frame_count, 
            self.get_vbos(), self.mode, entity_components)
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
        return new_index
  
    cdef void remove_batch(BatchManager self, unsigned int batch_id):
        cdef IndexedBatch batch = self.batches[batch_id]
        cdef int tex_key = batch.tex_key
        self.canvas.remove(batch.mesh_instruction)
        batch.mesh_instruction = None
        self.batch_groups[tex_key].remove(batch)
        batch.clear_frames()
        self.batches[batch_id] = None
        self.free_batches.append(batch_id)

    cdef IndexedBatch get_batch_with_space(BatchManager self, int tex_key, 
        unsigned int num_verts, unsigned int num_indices):
        cdef dict batch_groups = self.batch_groups
        cdef IndexedBatch batch
        if tex_key not in batch_groups:
            return self.batches[self.create_batch(tex_key)]
        else:
            for batch in batch_groups[tex_key]:
                if batch.can_fit_data(num_verts, num_indices):
                    return batch
            else:
                return self.batches[self.create_batch(tex_key)]

    cdef tuple batch_entity(BatchManager self, unsigned int entity_id, 
        int tex_key, unsigned int num_verts, unsigned int num_indices):
        cdef IndexedBatch batch = self.get_batch_with_space(
            tex_key, num_verts, num_indices)
        cdef tuple indices = batch.add_entity(entity_id, num_verts, num_indices)
        return (batch.batch_id, indices[0], indices[1]) # batch, vert, ind

    cdef bint unbatch_entity(BatchManager self, unsigned int entity_id, 
        unsigned int batch_id, unsigned int num_verts, 
        unsigned int num_indices, unsigned int vert_index,
        unsigned int ind_index) except 0:
        cdef IndexedBatch batch = self.batches[batch_id]
        batch.remove_entity(entity_id, num_verts, vert_index, num_indices,
            ind_index)
        if batch.check_empty():
            self.remove_batch(batch_id)
        return 1

    cdef list get_vbos(BatchManager self):
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
            index_block = MemoryBlock(1, sizeof(GLushort), vbo_size*1024)
            index_block.allocate_memory_with_buffer(master_index)
            vertex_block = MemoryBlock(1, type_size, vbo_size*1024)
            vertex_block.allocate_memory_with_buffer(master_vertex)
            frame_data = FixedFrameData(index_block, vertex_block, 
                vertex_format)
            vbo_a(frame_data)
        return vbos