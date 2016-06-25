from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t
from kivent_core.rendering.vertex_formats cimport format_registrar

cdef VertexFormat2F4UB* tmp1 = <VertexFormat2F4UB*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.pos) - <Py_intptr_t>(tmp1))
color_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.v_color) - <Py_intptr_t>(tmp1))

vertex_format_2f4ub = [
    (b'pos', 2, b'float', pos_offset, False), 
    (b'v_color', 4, b'ubyte', color_offset, True),
    ]

format_registrar.register_vertex_format('vertex_format_2f4ub', 
	vertex_format_2f4ub, sizeof(VertexFormat2F4UB))