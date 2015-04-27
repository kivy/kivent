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
    '''The IndexedBatch represents a collection of FixedFrameData vbos, 
    suitable for rendering using GL_TRIANGLES mode. Data will be split into 
    both an indices VBO and a vertices VBO, and explicit multibuffering
    will be performed. Drawing will be performed by calling glDrawElements. 
    Each frame the FixedFrameData at position **current_frame** % 
    **frame_count** in the **frame_data** list will be used for rendering.

    **Attributes: (Cython Access Only)**

        **frame_data** (list): List of FixedFrameData objects for this 
        batch.

        **current_frame** (unsigned int): Every frame rendered (calling 
        **draw_frame**) will increment this by 1.

        **frame_count** (unsigned int): Number of FixedFrameData objects 
        in the **frame_data** list. The number of buffers to use.

        **tex_key** (int): Identifier for the texture resource that will 
        be used when drawing the entities in this batch. All entities must 
        share the same texture.

        **batch_id** (unsigned int): The identifier for this batch, will be 
        set by the **BatchManager** controlling this batch. Defaults to 
        <unsigned int>-1.

        **mode** (GLuint): The drawing mode for this batch. Will be one of 
        GL_TRIANGLES, GL_LINES, GL_POINTS, GL_TRIANGLE_FAN, GL_LINE_STRIP,
        GL_LINE_LOOP, GL_TRIANGLE_STRIP.

        **mesh_instruction** (object): Reference to the actual instruction 
        that will be added to the canvas of the parent renderer.

        **entity_components** (ComponentPointerAggregator): Helper object 
        for retrieving pointers to the components of entities added to this 
        batch.

    '''

    def __cinit__(self, int tex_key, unsigned int index_count,
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

    cdef tuple add_entity(self, unsigned int entity_id, unsigned int num_verts, 
        unsigned int num_indices):
        '''Adds an entity to the batch. The components will be inserted into 
        the **entity_components** aggregator for ease of access.

        Args:
            entity_id (unsigned int): The identity of the entity to add.

            num_verts (unsigned int): The number of vertices for this entity.

            num_indices (unsigned int): The number of indices for this entity.

        Return:
            tuple: index of vertices, index of indices in the batch memory.
        '''
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

    cdef void remove_entity(self, unsigned int entity_id, 
        unsigned int num_verts, unsigned int vert_index, 
        unsigned int num_indices, unsigned int ind_index):
        '''Removes an entity from the batch. 
        Args:
            entity_id (unsigned int): The identity of the entity to add.

            num_verts (unsigned int): The number of vertices for this entity.

            vert_index (unsigned int): The index of the vertices in memory, 
            returned from **add_entity**.

            num_indices (unsigned int): The number of indices for this entity.

            ind_index (unsigned int): The index of the indices in memory, 
            returned from **add_entity**.
        '''
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

    cdef bool check_empty(self):
        '''Checks whether the batch is empty by inspecting 
        **entity_components**.
        Return:
            bool: True if **entity_components** is empty, else False.
        '''
        return self.entity_components.check_empty()

    cdef bool can_fit_data(self, unsigned int num_verts, 
        unsigned int num_indices):
        '''Checks whether the batch can fit the data for an entity we hope to 
        add.
        Args:
            num_verts (unsigned int): The number of vertices we want to add.

            num_indices (unsigned int): The number of indices we want to add.

        Return:
            bool: True if there is room in this batch, else False.
        '''
        cdef FixedFrameData primary_frame = self.frame_data[0]
        cdef FixedVBO indices = primary_frame.index_vbo
        cdef FixedVBO vertices = primary_frame.vertex_vbo
        cdef MemoryBlock indices_block = indices.memory_block
        cdef MemoryBlock vertex_block = vertices.memory_block
        return (vertex_block.can_fit_data(num_verts) and 
            indices_block.can_fit_data(num_indices))

    cdef void* get_vbo_frame_to_draw(self):
        '''Returns a pointer to the vertex data for the next frame for writing
        data to.

        Return:
            void*: Pointer to the data in the vertex FixedVBO's MemoryBlock.
        '''
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO vertices = frame_data.vertex_vbo
        cdef MemoryBlock vertex_block = vertices.memory_block
        return vertex_block.data

    cdef FixedFrameData get_current_vbo(self):
        '''Returns the next VBO pairing of indices and vertices VBO to use.

        Return:
            FixedFrameData: VBO at position **current_frame** % **frame_count**
        '''
        return self.frame_data[self.current_frame % self.frame_count]

    cdef void* get_indices_frame_to_draw(self):
        '''Returns a pointer to the indices data for the next frame for writing
        data to.

        Return:
            void*: Pointer to the data in the indices FixedVBO's MemoryBlock.
        '''
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        cdef MemoryBlock index_block = indices.memory_block
        return index_block.data

    cdef void set_index_count_for_frame(self, unsigned int index_count):
        '''Sets the number of indices to be rendered on next **draw_frame**.'''
        cdef FixedFrameData frame_data = self.get_current_vbo()
        cdef FixedVBO indices = frame_data.index_vbo
        indices.data_size = index_count * sizeof(GLushort)

    cdef void draw_frame(self):
        '''Actually triggers the drawing of a frame by calling glDrawElements.
        The current FixedFrameData as returned by **get_current_vbo** will be 
        drawn. **current_frame** will be incremented after drawing.
        '''
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

    cdef void clear_frames(self):
        '''Clears all frames, returning their memory and deleting the members 
        of **frame_data**.
        '''
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
        object canvas, list system_names,
        unsigned int smallest_vertex_count, object gameworld):
        cdef MemoryBlock batch_block, indices_block
        self.gameworld = gameworld
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
                self.gameworld, self.master_buffer))
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
                self.gameworld, self.master_buffer))
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