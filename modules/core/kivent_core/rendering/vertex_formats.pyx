from cython cimport Py_ssize_t
cdef extern from "Python.h":
    ctypedef int Py_intptr_t


cdef class FormatConfig:

    def __cinit__(self, str format_name, list format, unsigned int size):
        self._name = format_name
        self._format = format
        self._size = size
        format_dict = {}
        for each in format:
            format_dict[each[0]] = each[1:]
        self._format_dict = format_dict

    property format_dict:
        def __get__(self):
            return self._format_dict

    property size:
        def __get__(self):
            return self._size

    property format:
        def __get__(self):
            return self._format

    property name:
        def __get__(self):
            return self._name


cdef class VertexFormatRegister:

    def __cinit__(self):
        self._vertex_formats = {}

    def register_vertex_format(self, str format_name, list format, 
        unsigned int size):
        self._vertex_formats[format_name] = FormatConfig(format_name, format,
            size)

    property vertex_formats:

        def __get__(self):
            return self._vertex_formats

format_registrar = VertexFormatRegister()

cdef VertexFormat4F* tmp1 = <VertexFormat4F*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.pos) - <Py_intptr_t>(tmp1))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp1.uvs) - <Py_intptr_t>(tmp1))

vertex_format_4f = [
    (b'pos', 2, b'float', pos_offset), 
    (b'uvs', 2, b'float', uvs_offset),
    ]

format_registrar.register_vertex_format('vertex_format_4f', vertex_format_4f,
    sizeof(VertexFormat4F))

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

format_registrar.register_vertex_format('vertex_format_7f', vertex_format_7f,
    sizeof(VertexFormat7F))

cdef VertexFormat8F* tmp3 = <VertexFormat8F*>NULL
pos_offset = <Py_ssize_t> (<Py_intptr_t>(tmp3.pos) - <Py_intptr_t>(tmp3))
uvs_offset = <Py_ssize_t> (<Py_intptr_t>(tmp3.uvs) - <Py_intptr_t>(tmp3))
color_offset = <Py_ssize_t> (<Py_intptr_t>(tmp3.vColor) - <Py_intptr_t>(tmp3))

vertex_format_8f = [
    (b'pos', 2, b'float', pos_offset), 
    (b'uvs', 2, b'float', uvs_offset),
    (b'vColor', 4, b'float', color_offset),
    ]

format_registrar.register_vertex_format('vertex_format_8f', vertex_format_8f,
    sizeof(VertexFormat8F))
