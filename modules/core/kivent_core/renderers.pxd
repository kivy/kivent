from cmesh cimport CMesh
from cpython cimport bool

cdef class TextureManager:
    cdef dict _textures
    cdef dict _keys
    cdef dict _sizes
    cdef dict _uvs
    cdef dict _groups

cdef class RenderComponent:
    cdef bool _render
    cdef str _texture_key
    cdef VertMesh _vert_mesh
    cdef int _attrib_count
    cdef int _batch_id
    cdef float _width
    cdef float _height

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
