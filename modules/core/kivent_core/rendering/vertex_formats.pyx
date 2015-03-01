from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t

cdef VertexFormat4F* tmp1 = <VertexFormat4F*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.pos) - <Py_intptr_t>(tmp1))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.uvs) - <Py_intptr_t>(tmp1))

vertex_format_4f = [
    ('pos', 2, 'float', pos_offset), 
    ('uvs', 2, 'float', uvs_offset),
    ]

print(vertex_format_4f)
cdef VertexFormat7F* tmp2 = <VertexFormat7F*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp2.pos) - <Py_intptr_t>(tmp2))
print(pos_offset)
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp2.uvs) - <Py_intptr_t>(tmp2))
print(uvs_offset)
rot_offset = <Py_ssize_t> (<Py_intptr_t>(tmp2.rot) - <Py_intptr_t>(tmp2))
print(rot_offset)

vertex_format_7f = [
    ('pos', 2, 'float', pos_offset), 
    ('uvs', 2, 'float', uvs_offset),
    ('rot', 3, 'float', rot_offset),
    ]
print(vertex_format_7f)