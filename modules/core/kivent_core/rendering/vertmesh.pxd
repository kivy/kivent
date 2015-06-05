cdef class VertMesh:
    cdef int _attrib_count
    cdef float* _data
    cdef int _vert_count
    cdef int _index_count
    cdef unsigned short* _indices
