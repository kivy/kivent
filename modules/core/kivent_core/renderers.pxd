from cmesh cimport CMesh
from cpython cimport bool
from gamesystems cimport StaticMemGameSystem
from membuffer cimport MemComponent

cdef class RenderComponent(MemComponent):
    pass

ctypedef struct RenderStruct:
    unsigned int entity_id
    unsigned int texkey
    unsigned int vert_index_key
    unsigned int attrib_count
    unsigned int batch_id
    int vert_index
    int ind_index
    bint render
