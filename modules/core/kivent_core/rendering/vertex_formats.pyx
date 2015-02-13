from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t

cdef VertexFormat4F* tmp
tmp = <VertexFormat4F*>NULL
cdef Py_ssize_t offset
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp.pos) - <Py_intptr_t>(tmp))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp.uvs) - <Py_intptr_t>(tmp))

vertex_format_4f = [
    ('pos', 2, 'float', pos_offset), 
    ('uvs', 2, 'float', uvs_offset),
    ]