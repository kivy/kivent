from kivy.graphics.cgl cimport GLuint
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.indexing cimport IndexedMemoryZone
from kivent_core.memory_handlers.membuffer cimport Buffer
from vertex_format cimport KEVertexFormat
from cpython cimport bool
from frame_objects cimport FixedFrameData, SimpleFrameData
from kivent_core.systems.staticmemgamesystem cimport ComponentPointerAggregator
from kivent_core.managers.resource_managers import texture_manager

cdef class SimpleBatch:
    cdef list frame_data
    cdef unsigned int current_frame
    cdef unsigned int frame_count
    cdef unsigned int batch_id
    cdef unsigned int tex_key
    cdef GLuint mode
    cdef KEVertexFormat vertex_format
    cdef object mesh_instruction

    cdef void* get_current_vertex_location(self)
    cdef void* get_current_index_location(self)
    cdef void commit_data(self, unsigned int num_verts,
                          unsigned int num_indices)

    cdef bool can_fit_data(self, unsigned int num_verts,
                           unsigned int num_indices)
    cdef SimpleFrameData get_current_vbo(self)
    cdef SimpleFrameData get_next_vbo(self)
    cdef void draw_frame(self)
    cdef void reload_frames(self)
    cdef void commit_frame(self)
    cdef void prepare_frame(self)
    cdef size_t get_max_vertices(self)
    cdef size_t get_max_indices(self)
    cdef bool is_frame_empty(self)
    cdef bool is_attached_to_canvas(self)

cdef class IndexedBatch:
    cdef list frame_data
    cdef unsigned int current_frame
    cdef unsigned int frame_count
    cdef unsigned int tex_key
    cdef unsigned int batch_id
    cdef GLuint mode
    cdef object mesh_instruction
    cdef ComponentPointerAggregator entity_components

    cdef tuple add_entity(self, unsigned int entity_id, unsigned int num_verts,
        unsigned int num_indices)
    cdef void remove_entity(self, unsigned int entity_id,
        unsigned int num_verts, unsigned int vert_index,
        unsigned int num_indices, unsigned int ind_index)
    cdef bool check_empty(self)
    cdef bool can_fit_data(self, unsigned int num_verts,
        unsigned int num_indices)
    cdef void* get_vbo_frame_to_draw(self)
    cdef FixedFrameData get_current_vbo(self)
    cdef FixedFrameData get_next_vbo(self)
    cdef void* get_indices_frame_to_draw(self)
    cdef void set_index_count_for_frame(self,
        unsigned int index_count)
    cdef void draw_frame(self)
    cdef void clear_frames(self)

cdef class SimpleBatchManager:
    cdef list batches
    cdef unsigned int max_batches
    cdef unsigned int frame_count
    cdef dict batch_groups
    cdef list free_batches
    cdef object gameworld
    cdef str mode_str
    cdef GLuint mode
    cdef KEVertexFormat vertex_format
    cdef object canvas

    cdef void set_mode(self, str mode)
    cdef str get_mode(self)
    cdef void assign_batch_to_canvas(self, unsigned int tex_key,
                                     SimpleBatch batch)
    cdef void remove_batch_from_canvas(self, SimpleBatch batch)
    cdef SimpleBatch get_batch_with_space(self, unsigned int tex_key,
                                          unsigned int num_verts,
                                          unsigned int num_indices)
    cdef void prepare_frames(self)
    cdef void cleanup_empty_frames(self)
    cdef void recycle_batch(self, SimpleBatch batch)
    cdef SimpleBatch get_free_batch(self)


cdef class BatchManager:
    cdef MemoryBlock batch_block
    cdef MemoryBlock indices_block
    cdef list batches
    cdef list free_batches
    cdef dict batch_groups
    cdef object gameworld
    cdef unsigned int batch_count
    cdef unsigned int max_batches
    cdef unsigned int frame_count
    cdef unsigned int slots_per_block
    cdef unsigned int index_slots_per_block
    cdef unsigned int vbo_size_in_kb
    cdef str mode_str
    cdef GLuint mode
    cdef KEVertexFormat vertex_format
    cdef object canvas
    cdef list system_names
    cdef Buffer master_buffer
    cdef unsigned int ent_per_batch

    cdef void set_mode(self, str mode)
    cdef str get_mode(self)
    cdef unsigned int get_size(self)
    cdef unsigned int get_size_of_component_pointers(self)
    cdef unsigned int create_batch(self, unsigned int tex_key) except -1
    cdef int remove_batch(self, unsigned int batch_id) except 0
    cdef IndexedBatch get_batch_with_space(self, unsigned int tex_key,
        unsigned int num_verts, unsigned int num_indices)
    cdef tuple batch_entity(self, unsigned int entity_id, unsigned int tex_key,
        unsigned int num_verts, unsigned int num_indices)
    cdef bint unbatch_entity(self, unsigned int entity_id,
        unsigned int batch_id, unsigned int num_verts,
        unsigned int num_indices, unsigned int vert_index,
        unsigned int ind_index) except 0
    cdef list get_vbos(self)
