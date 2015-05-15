from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t

cdef VertexFormat4F* tmp1 = <VertexFormat4F*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.pos) - <Py_intptr_t>(tmp1))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.uvs) - <Py_intptr_t>(tmp1))

vertex_format_4f = [
    (b'pos', 2, b'float', pos_offset), 
    (b'uvs', 2, b'float', uvs_offset),
    ]

cdef VertexFormat7F* tmp2 = <VertexFormat7F*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp2.pos) - <Py_intptr_t>(tmp2))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp2.uvs) - <Py_intptr_t>(tmp2))
rot_offset = <Py_ssize_t> (<Py_intptr_t>(&tmp2.rot) - <Py_intptr_t>(tmp2))
center_offset = <Py_ssize_t> (<Py_intptr_t>(tmp2.center) - <Py_intptr_t>(tmp2))


vertex_format_7f = [
    (b'pos', 2, b'float', pos_offset), 
    (b'uvs', 2, b'float', uvs_offset),
    (b'rot', 1, b'float', rot_offset),
    (b'center', 2, b'float', center_offset),
    ]
