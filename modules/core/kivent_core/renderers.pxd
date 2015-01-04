from cmesh cimport CMesh

cdef class TextureManager:
    cdef dict _textures
    cdef dict _keys
    cdef dict _sizes
    cdef dict _uvs
    cdef dict _groups
    cdef dict _key_index
    cdef dict _texkey_index
    cdef int _key_count

cdef class ModelManager:
    cdef list _meshes
    cdef dict _keys
    cdef list _unused
    cdef int _mesh_count

cdef class RenderComponent:
    cdef int _component_index
    cdef RenderProcessor _processor

ctypedef struct RenderStruct:
    int tex_index_key
    int vert_index_key
    bint render
    int attrib_count
    int batch_id
    float width
    float height

cdef class RenderProcessor:
    cdef int _count
    cdef RenderStruct* _components
    cdef RenderComponent generate_component(self)
    cdef void clear_component(self, int component_index)
    cdef void init_component(self, int component_index, 
        float x, float y, float z)

cdef class RenderBatch:
    cdef list _entity_ids
    cdef int _vert_count
    cdef dict _entity_counts
    cdef int _maximum_verts
    cdef float* _batch_data
    cdef unsigned short* _batch_indices
    cdef int _index_count
    cdef int _r_index_count
    cdef int _r_vert_count
    cdef int _attrib_count
    cdef int _r_attrib_count
    cdef str _texture
    cdef CMesh _cmesh
    cdef int _batch_id

cdef class VertMesh:
    cdef int _attrib_count
    cdef float* _data
    cdef int _vert_count
    cdef int _index_count
    cdef unsigned short* _indices
