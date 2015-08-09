from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t
from kivent_core.rendering.vertex_formats cimport format_registrar

cdef VertexFormat9F4UB* tmp1 = <VertexFormat9F4UB*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.pos) - <Py_intptr_t>(tmp1))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.uvs) - <Py_intptr_t>(tmp1))
center_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.center) - <Py_intptr_t>(tmp1))
rotate_offset = <Py_ssize_t> (<Py_intptr_t>(&tmp1.rotate) - <Py_intptr_t>(tmp1))
scale_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.scale) - <Py_intptr_t>(tmp1))
color_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.v_color) - <Py_intptr_t>(tmp1))

vertex_format_9f4ub = [
    (b'pos', 2, b'float', pos_offset, False),
    (b'uvs', 2, b'float', uvs_offset, False),
    (b'center', 2, b'float', center_offset, False),
    (b'rotate', 1, b'float', rotate_offset, False),
    (b'scale', 2, b'float', scale_offset, False),
    (b'v_color', 4, b'ubyte', color_offset, True),
    ]

format_registrar.register_vertex_format('vertex_format_9f4ub', 
	vertex_format_9f4ub, sizeof(VertexFormat9F4UB))