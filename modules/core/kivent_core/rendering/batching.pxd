from kivy.graphics.c_opengl cimport GLuint
from kivent_core.memory_handlers.block cimport MemoryBlock
from vertex_format cimport KEVertexFormat
from cpython cimport bool
from frame_objects cimport FixedFrameData
from kivent_core.managers.resource_managers import texture_manager


cdef class IndexedBatch:
    cdef list frame_data
    cdef list entity_ids
    cdef unsigned int current_frame
    cdef unsigned int frame_count
    cdef int tex_key
    cdef unsigned int batch_id
    cdef GLuint mode
    cdef object mesh_instruction

    cdef tuple add_entity(IndexedBatch self, unsigned int entity_id, 
        unsigned int num_verts, unsigned int num_indices)
    cdef void remove_entity(IndexedBatch self, unsigned int entity_id, 
        unsigned int num_verts, unsigned int vert_index, 
        unsigned int num_indices, unsigned int ind_index)
    cdef bool check_empty(IndexedBatch self)
    cdef bool can_fit_data(IndexedBatch self, unsigned int num_verts, 
        unsigned int num_indices)
    cdef void* get_vbo_frame_to_draw(IndexedBatch self)
    cdef FixedFrameData get_current_vbo(IndexedBatch self)
    cdef void* get_indices_frame_to_draw(IndexedBatch self)
    cdef void set_index_count_for_frame(IndexedBatch self, 
        unsigned int index_count)
    cdef void draw_frame(IndexedBatch self)
    cdef void clear_frames(IndexedBatch self)


cdef class BatchManager:
    cdef MemoryBlock batch_block
    cdef MemoryBlock indices_block
    cdef list batches
    cdef list free_batches
    cdef dict batch_groups
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

    cdef void set_mode(self, str mode)
    cdef str get_mode(self)
    cdef IndexedBatch create_batch(self, int tex_key)
    cdef void remove_batch(self, unsigned int batch_id)
    cdef IndexedBatch get_batch_with_space(self, int tex_key, 
        unsigned int num_verts, unsigned int num_indices)
    cdef tuple batch_entity(self, unsigned int entity_id, int tex_key,
        unsigned int num_verts, unsigned int num_indices)
    cdef void unbatch_entity(self, unsigned int entity_id, 
        unsigned int batch_id, unsigned int num_verts, 
        unsigned int num_indices, unsigned int vert_index,
        unsigned int ind_index)
    cdef list get_vbos(self)