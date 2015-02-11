from kivy.graphics.vertex cimport VertexFormat, vertex_attr_t
from kivy.graphics.instructions cimport VertexInstruction
from kivy.graphics.c_opengl cimport *
from kivy.graphics.vbo cimport VBO, VertexBatch
from cpython cimport bool
from membuffer cimport MemoryBlock

cdef class Batch:
    cdef list frame_data
    cdef list entity_ids
    cdef unsigned int current_frame
    cdef unsigned int frame_count
    cdef int tex_key
    cdef unsigned int batch_id
    cdef GLuint mode
    cdef object mesh_instruction

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
    cdef void* get_indices_frame_to_draw(self)
    cdef void set_index_count_for_frame(self, unsigned int index_count)
    cdef void draw_frame(self)
    cdef void clear_frames(self)

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
    cdef Batch create_batch(self, int tex_key)
    cdef void remove_batch(self, unsigned int batch_id)
    cdef Batch get_batch_with_space(self, int tex_key, 
        unsigned int num_verts, unsigned int num_indices)
    cdef tuple batch_entity(self, unsigned int entity_id, int tex_key,
        unsigned int num_verts, unsigned int num_indices)
    cdef void unbatch_entity(self, unsigned int entity_id, 
        unsigned int batch_id, unsigned int num_verts, 
        unsigned int num_indices, unsigned int vert_index,
        unsigned int ind_index)
    cdef list get_vbos(self)

ctypedef struct VertexFormat4F:
    GLfloat[2] pos
    GLfloat[2] uvs

cdef class KEVertexFormat(VertexFormat):
    cdef Py_ssize_t* attr_offsets

    cdef void bind(self)

cdef class CMesh(VertexInstruction):
    cdef Batch _batch

cdef class FixedFrameData: #think about name
    cdef FixedVBO index_vbo
    cdef FixedVBO vertex_vbo

    cdef void return_memory(self)

cdef class FixedVBO:
    cdef MemoryBlock memory_block
    cdef int usage
    cdef GLuint id
    cdef short flags
    cdef int target
    cdef unsigned int size_last_frame
    cdef unsigned int data_size
    cdef KEVertexFormat vertex_format

    cdef int have_id(self)
    cdef void generate_buffer(self)
    cdef void update_buffer(self)
    cdef void bind(self)
    cdef void unbind(self)
    cdef void return_memory(self)
    cdef void reload(self)