# cython: embedsignature=True
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
cdef extern from "string.h":
    void *memcpy(void *dest, void *src, size_t n)
from vertex_formats cimport VertexFormat4F, FormatConfig
from vertex_formats import vertex_format_4f, vertex_format_7f
from kivy.graphics.c_opengl cimport (GLfloat, GLbyte, GLubyte, GLint, GLuint,
    GLshort, GLushort)
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock

def get_test_model():
    cdef Buffer index_buffer = Buffer(1024*10, 1, 1)
    index_buffer.allocate_memory()
    cdef Buffer vertex_buffer = Buffer(1024*10, 1, 1)
    vertex_buffer.allocate_memory()
    test_config = FormatConfig(vertex_format_4f, sizeof(VertexFormat4F))
    test_model = VertexModel(4, 6, test_config, index_buffer, vertex_buffer)
    return test_model

def get_test_vertex():
    format_dict = {}
    for each in vertex_format_7f:
        format_dict[each[0]] = each[1:]

    cdef void* data_p = PyMem_Malloc(sizeof(float)*4)
    if not data_p:
        raise MemoryError()
    cdef Vertex vertex = Vertex(format_dict)
    vertex.vertex_pointer = data_p
    return vertex

class AttributeCountError(Exception):
    pass

cdef class Vertex:

    def __cinit__(self, dict format):
        self.vertex_format = format 

    def __getattr__(self, name):
        cdef int count
        cdef unsigned int offset
        cdef bytes attr_type
        cdef char* data = <char*>self.vertex_pointer
        cdef GLfloat* f_data
        cdef GLint* i_data
        cdef GLuint* ui_data
        cdef GLshort* s_data
        cdef GLushort* us_data
        cdef GLbyte* b_data
        cdef GLubyte* ub_data
        if isinstance(name, unicode):
            name = bytes(name, 'utf-8')
        if name in self.vertex_format:
            attribute_tuple = self.vertex_format[name]
            count = attribute_tuple[0]
            attr_type = attribute_tuple[1]
            offset = attribute_tuple[2]
            if attr_type == b'float':
                f_data = <GLfloat*>&data[offset]
                ret = [<float>f_data[x] for x in range(count)]
            elif attr_type == b'int':
                i_data = <GLint*>&data[offset]
                ret = [<int>i_data[x] for x in range(count)]
            elif attr_type == b'uint':
                ui_data = <GLuint*>&data[offset]
                ret = [<unsigned int>ui_data[x] for x in range(count)]
            elif attr_type == b'short':
                s_data = <GLshort*>&data[offset]
                ret = [<short>s_data[x] for x in range(count)]
            elif attr_type == b'ushort':
                us_data = <GLushort*>&data[offset]
                ret = [<unsigned short>us_data[x] for x in range(count)]
            elif attr_type == b'byte':
                b_data = <GLbyte*>&data[offset]
                ret = [<char>b_data[x] for x in range(count)]
            elif attr_type == b'ubyte':
                ub_data = <GLubyte*>&data[offset]
                ret = [<unsigned char>ub_data[x] for x in range(count)]
            else:
                raise TypeError()
            if len(ret) == 1:
                return ret[0]
            else:
                return ret
        else:
            raise AttributeError()
        
    def __setattr__(self, name, value):
        cdef int count
        cdef unsigned int offset
        cdef bytes attr_type
        cdef char* data = <char*>self.vertex_pointer
        cdef GLfloat* f_data
        cdef GLint* i_data
        cdef GLuint* ui_data
        cdef GLshort* s_data
        cdef GLushort* us_data
        cdef GLbyte* b_data
        cdef GLubyte* ub_data
        if isinstance(value, tuple):
            value = list(value)
        if not isinstance(value, list):
            value = [value]
        if isinstance(name, unicode):
            name = bytes(name, 'utf-8')
        if name in self.vertex_format:
            attribute_tuple = self.vertex_format[name]
            count = attribute_tuple[0]
            attr_type = attribute_tuple[1]
            offset = attribute_tuple[2]
            if len(value) != count:
                raise AttributeCountError('Expected list of length {count} got'
                    'list of size {length}'.format(count=count, 
                    length=len(value)))
            for x in range(count):
                if attr_type == b'float':
                    f_data = <GLfloat*>&data[offset + x*sizeof(GLfloat)]
                    f_data[0] = <GLfloat>value[x]
                elif attr_type == b'int':
                    i_data = <GLint*>&data[offset + x*sizeof(GLint)]
                    i_data[0] = <GLint>value[x]
                elif attr_type == b'uint':
                    ui_data = <GLuint*>&data[offset + x*sizeof(GLuint)]
                    ui_data[0] = <GLuint>value[x]
                elif attr_type == b'short':
                    s_data = <GLshort*>&data[offset + x*sizeof(GLshort)]
                    s_data[0] = <GLshort>value[x]
                elif attr_type == b'ushort':
                    us_data = <GLushort*>&data[offset + x*sizeof(GLushort)]
                    us_data[0] = <GLushort>value[x]
                elif attr_type == b'byte':
                    b_data = <GLbyte*>&data[offset + x*sizeof(GLbyte)]
                    b_data[0] = <GLbyte>value[x]
                elif attr_type == b'ubyte':
                    ub_data = <GLubyte*>&data[offset + x*sizeof(GLubyte)]
                    ub_data[0] = <GLubyte>value[x]
                else:
                    raise TypeError()
        else:
            raise AttributeError()


cdef class VertexModel:
    
    def __cinit__(self, unsigned int vert_count, unsigned int index_count,
        FormatConfig config, Buffer index_buffer, Buffer vertex_buffer, 
        str name):
        self._format_config = config
        self._vertex_count = vert_count
        self._index_count = index_count
        self._name = name
        cdef MemoryBlock indices_block = MemoryBlock(
            index_count*sizeof(GLushort), sizeof(GLushort), 1)
        indices_block.allocate_memory_with_buffer(index_buffer)
        self.indices_block = indices_block
        cdef MemoryBlock vertices_block = MemoryBlock(
            vert_count*config._size, config._size, 1)
        vertices_block.allocate_memory_with_buffer(vertex_buffer)
        self.vertices_block = vertices_block
        self.index_buffer = index_buffer
        self.vertex_buffer = vertex_buffer

    def __dealloc__(self):
        if self.indices_block is not None:
            self.indices_block.remove_from_buffer()
            self.indices_block = None
        if self.vertices_block is not None:
            self.vertices_block.remove_from_buffer()
            self.vertices_block = None
        self.index_buffer = None
        self.vertex_buffer = None
        self._format_config = None

    def __getitem__(self, unsigned int index):
        cdef int vert_count = self._vertex_count
        if not index < vert_count:
            raise IndexError()
        cdef Vertex vertex = Vertex(self._format_config._format_dict)
        vertex.vertex_pointer = self.vertices_block.get_pointer(index)
        return vertex

    property index_count:

        def __set__(self, unsigned int new_count):
            cdef unsigned int old_count = self._index_count
            cdef MemoryBlock new_indices
            if new_count != old_count:
                self._index_count = new_count
                new_indices = MemoryBlock(
                    new_count*sizeof(GLushort), sizeof(GLushort), 1)
                new_indices.allocate_memory_with_buffer(self.index_buffer)
                if new_count < old_count:
                    old_count = new_count
                memcpy(<char*>new_indices.data, self.indices_block.data, 
                    old_count*sizeof(GLushort))
                self.indices_block.remove_from_buffer()
                self.indices_block = new_indices
 
        def __get__(self):
            return self._index_count

    property name:

        def __get__(self):
            return self._name

    property vertex_count:

        def __set__(self, unsigned int new_count):
            cdef unsigned int old_count = self._vertex_count
            cdef MemoryBlock new_vertices
            if new_count != old_count:
                self._vertex_count = new_count
                new_vertices = MemoryBlock(
                    new_count*self._format_config._size, 
                    self._format_config._size, 1)
                new_vertices.allocate_memory_with_buffer(self.vertex_buffer)
                if new_count < old_count:
                    old_count = new_count
                memcpy(<char*>new_vertices.data, self.vertices_block.data, 
                    old_count*self._format_config._size)
                self.vertices_block.remove_from_buffer()
                self.vertices_block = new_vertices

        def __get__(self):
            return self._vertex_count

    def copy_vertex_model(self, VertexModel to_copy):
        self.vertex_count = to_copy._vertex_count
        self.index_count = to_copy._index_count
        self._format_config = to_copy._format_config
        memcpy(<char *>self.indices_block.data, to_copy.indices_block.data, 
            self._index_count*sizeof(GLushort))
        memcpy(<char *>self.vertices_block.data, to_copy.vertices_block.data, 
            self._vertex_count * self._format_config._size)

    def set_all_vertex_attribute(self, str attribute_name, value):
        '''Set attribute number attribute_n of all vertices to value.
        '''
        cdef int vert_count = self._vertex_count
        if not attribute_name in self._format_config._format_dict:
            raise AttributeError()
        cdef Vertex vertex = Vertex(self._format_config._format_dict)
        for i from 0 <= i < vert_count:
            vertex.vertex_pointer = self.vertices_block.get_pointer(i)
            setattr(vertex, attribute_name, value)

    def add_all_vertex_attribute(self, str attribute_name, value):
        '''Add value to attribute number attribute_n of all vertices.
        '''
        cdef int vert_count = self._vertex_count
        if not attribute_name in self._format_config._format_dict:
            raise AttributeError()
        cdef Vertex vertex = Vertex(self._format_config._format_dict)
        for i from 0 <= i < vert_count:
            vertex.vertex_pointer = self.vertices_block.get_pointer(i)
            old_value = getattr(vertex, attribute_name)
            if isinstance(old_value, list) and isinstance(value, list):
                new_value = [x + y for x, y in zip(old_value, value)]
            elif isinstance(old_value, list) and not isinstance(value, list):
                new_value = [x + value for x in old_value]
            else:
                new_value = old_value + value
            setattr(vertex, attribute_name, new_value)

    def mult_all_vertex_attribute(self, str attribute_name, value):
        '''Multiply the value of attribute number attribute_n of all vertices 
        by value.
        '''
        cdef int vert_count = self._vertex_count
        if not attribute_name in self._format_config._format_dict:
            raise AttributeError()
        cdef Vertex vertex = Vertex(self._format_config._format_dict)
        for i from 0 <= i < vert_count:
            vertex.vertex_pointer = self.vertices_block.get_pointer(i)
            old_value = getattr(vertex, attribute_name)
            if isinstance(old_value, list) and isinstance(value, list):
                new_value = [x * y for x, y in zip(old_value, value)]
            elif isinstance(old_value, list) and not isinstance(value, list):
                new_value = [x * value for x in old_value]
            else:
                new_value = old_value * value
            setattr(vertex, attribute_name, new_value)

    def set_textured_rectangle(self, float width, float height, list uvs):
        '''Prepare a 4 vertex_count, 6 index_count textured quad (sprite) of 
        size: width x height. Normally called internally when creating sprites. 
        Will assume that the vertex format has a 'pos' and 'uvs' attribute that 
        are both lists of size 2'''
        self.vertex_count = 4
        self.index_count = 6
        self.indices = [0, 1, 2, 2, 3, 0]
        w = .5*width
        h = .5*height
        u0, v0, u1, v1 = uvs
        vertex1 = self[0]
        vertex1.pos = [-w, -h]
        vertex1.uvs = [u0, v0]
        vertex2 = self[1]
        vertex2.pos = [-w, h]
        vertex2.uvs = [u0, v1]
        vertex3 = self[2]
        vertex3.pos = [w, h]
        vertex3.uvs = [u1, v1]
        vertex4 = self[3]
        vertex4.pos = [w, -h]
        vertex4.uvs = [u1, v0]

    property vertices:

        def __get__(self):
            return_list = []
            cdef int i
            r_append = return_list.append
            for i in range(self._vertex_count):
                r_append(self[i])
            return return_list

    property format_config:

        def __get__(self):
            return self._format_config

    property indices:

        def __get__(self):
            cdef GLushort* indices = <GLushort*>self.indices_block.data
            cdef list return_list = []
            cdef int index_count = self._index_count
            r_append = return_list.append
            cdef int i
            cdef unsigned short index
            for i from 0 <= i < index_count:
                index = <unsigned short>indices[i]
                r_append(index)
            return return_list

        def __set__(self, list new_indices):
            cdef int index_count = self._index_count
            if len(new_indices) != index_count:
                raise Exception("Provided data doesn't match internal size")
            cdef GLushort* indices = <GLushort*>self.indices_block.data
            for i from 0 <= i < index_count:
                indices[i] = <GLushort>new_indices[i]


cdef class VertMesh:
    '''
    The VertMesh represents a collection of **vertex_count** vertices, 
    all having **attribute_count** floating point data fields. The 
    relationship between the vertices is kept in the form of a list of indices
    **index_count** in length corresponding to the triangles our mesh is made 
    up of. Typically you will want your vertex data to be centered around the
    origin, as the default rendering behavior will then obey the 
    PositionComponent of your entity.

    To work with an individual vertex you can:

        vert_mesh[vertex_number] = [1., 1., 1., 1.] #New vertex data 

    This will replace the first n attributes with the contents of the assigned
    list. Do not have length of assigned list exceed attribute_count.

    **Attributes:**

        **index_count** (int): Number of indices in the list of triangles.

        **attribute_count** (int): Number of attributes per vertex.

        **vertex_count** (int): Number of vertices in your mesh.

        **data** (list): Returns a copy of the VertMesh's vertex data. When 
        setting ensure your input list matches vertex_count * attribute_count 
        in size. To work with individual vertices use __setitem__ and 
        __getitem__ or other helper functions. 

        **indices** (list): Returns a copy of the VertMesh's index data. When 
        setting ensure your input list matches index_count in size. 

    '''

    def __cinit__(self, int attribute_count, int vert_count, int index_count):
        self._attrib_count = attribute_count
        self._vert_count = vert_count
        self._index_count = index_count
        self._data = data = <float *>PyMem_Malloc(
            vert_count * attribute_count * sizeof(float))
        if not data:
            raise MemoryError()
        cdef unsigned short* indices = <unsigned short*>PyMem_Malloc(
                index_count * sizeof(unsigned short))
        if not indices:
            raise MemoryError()
        self._indices = indices
        
    def __dealloc__(self):
        if self._data != NULL:
            PyMem_Free(self._data)
        if self._indices != NULL:
            PyMem_Free(self._indices)

    property index_count:

        def __set__(self, int new_count):
            if new_count == self._index_count:
                return
            cdef unsigned short* new_indices = <unsigned short*>PyMem_Realloc(
                self._indices, new_count * sizeof(unsigned short))
            if not new_indices:
                raise MemoryError()
            self._indices = new_indices
            self._index_count = new_count

        def __get__(self):
            return self._index_count

    property attribute_count:

        def __set__(self, int new_count):
            if new_count == self._attrib_count:
                return
            new_data = <float *>PyMem_Realloc(self._data, 
                new_count * self._vert_count * sizeof(float))
            if not new_data:
                raise MemoryError()
            self._data = new_data
            self._attrib_count = new_count

        def __get__(self):
            return self._attrib_count

    property vertex_count:

        def __set__(self, int new_count):
            if new_count == self._vert_count:
                return
            new_data = <float *>PyMem_Realloc(self._data, 
                new_count * self._attrib_count * sizeof(float))
            if not new_data:
                raise MemoryError()
            self._data = new_data
            self._vert_count = new_count

        def __get__(self):
            return self._vert_count

    property data:

        def __get__(self):
            cdef float* data = self._data
            cdef list return_list = []
            cdef int length = len(self)
            r_append = return_list.append
            cdef int i
            for i from 0 <= i < length:
                r_append(data[i])
            return return_list

        def __set__(self, list new_data):
            cdef int vert_count = self._vert_count
            cdef int attrib_count = self._attrib_count
            if len(new_data) != len(self):
                raise Exception("Provided data doesn't match internal size")
            cdef float* data = self._data
            for i from 0 <= i < attrib_count * vert_count:
                data[i] = new_data[i]

    property indices:

        def __get__(self):
            cdef unsigned short* indices = self._indices
            cdef list return_list = []
            cdef int index_count = self._index_count
            r_append = return_list.append
            cdef int i
            cdef int index
            for i from 0 <= i < index_count:
                index = indices[i]
                r_append(index)
            return return_list

        def __set__(self, list new_indices):
            cdef int index_count = self._index_count
            if len(new_indices) != index_count:
                raise Exception("Provided data doesn't match internal size")
            cdef unsigned short* indices = self._indices
            for i from 0 <= i < index_count:
                indices[i] = new_indices[i]

    def __setitem__(self, int index, list values):
        cdef int vert_count = self._vert_count
        if not index < vert_count:
            raise IndexError()
        cdef int attrib_count = self._attrib_count
        cdef int start = attrib_count * index
        cdef int set_count = len(values)
        if not set_count <= attrib_count:
            raise Exception("Provided data doesn't match internal size")
        cdef int i
        cdef float* data = self._data
        cdef int vert_offset
        for i from 0 <= i < set_count:
            vert_offset = start + i
            data[vert_offset] = values[i]

    def __getitem__(self, int index):
        cdef int vert_count = self._vert_count
        if not index < vert_count:
            raise IndexError()
        cdef float* data = self._data
        cdef int attrib_count = self._attrib_count
        cdef int start = attrib_count * index
        cdef int i
        cdef return_list = []
        r_append = return_list.append
        for i from start <= i < start + attrib_count:
            r_append(data[i])
        return return_list

    def __len__(self):
        cdef int vert_count = self._vert_count
        cdef int attrib_count = self._attrib_count
        return vert_count * attrib_count

    def copy_vert_mesh(self, VertMesh vert_mesh):
        cdef float* from_data = vert_mesh._data
        self.vertex_count = vert_mesh._vert_count
        self.attribute_count = vert_mesh._attrib_count
        self.index_count = vert_mesh._index_count
        cdef float* data = self._data
        cdef unsigned short* indices = self._indices
        cdef unsigned short* from_indices = vert_mesh._indices
        memcpy(<char *>indices, <void *>from_indices, self._index_count*sizeof(
            unsigned short))
        memcpy(<char *>data, <void *>from_data, len(self) * sizeof(float))


    def set_vertex_attribute(self, int vertex_n, int attribute_n, float value):
        '''Set attribute number attribute_n of vertex number vertex_n to value.
        '''
        if not vertex_n < self._vert_count:
            raise IndexError()
        cdef int attrib_count = self._attrib_count
        if not attribute_n < attrib_count:
            raise Exception('Attribute out of bounds')
        cdef int start = attrib_count * vertex_n
        cdef float* data = self._data
        data[start + attribute_n] = value

    def add_vertex_attribute(self, int vertex_n, 
        int attribute_n, float value):
        '''Add value to attribute number attribute_n of vertex number vertex_n.
        '''
        if not vertex_n < self._vert_count:
            raise IndexError()
        cdef int attrib_count = self._attrib_count
        if not attribute_n < attrib_count:
            raise Exception('Attribute out of bounds')
        cdef int start = attrib_count * vertex_n
        cdef float* data = self._data
        cdef index = start + attribute_n
        data[index] = data[index] + value

    def mult_vertex_attribute(self, int vertex_n, 
        int attribute_n, float value):
        '''Multiply the value of attribute number attribute_n of vertex number 
        vertex_n by value.
        '''
        if not vertex_n < self._vert_count:
            raise IndexError()
        cdef int attrib_count = self._attrib_count
        if not attribute_n < attrib_count:
            raise Exception('Attribute out of bounds')
        cdef int start = attrib_count * vertex_n
        cdef float* data = self._data
        cdef int index = start + attribute_n
        data[index] = data[index] * value

    def set_all_vertex_attribute(self, int attribute_n, float value):
        '''Set attribute number attribute_n of all vertices to value.
        '''
        cdef int attrib_count = self._attrib_count
        cdef int vert_count = self._vert_count
        if not attribute_n < attrib_count:
            raise Exception('Attribute out of bounds')
        cdef int start
        cdef float* data = self._data
        cdef int i
        cdef int index
        for i from 0 <= i < vert_count:
            start = attrib_count * i
            index = start + attribute_n
            data[index] = value

    def add_all_vertex_attribute(self, int attribute_n, float value):
        '''Add value to attribute number attribute_n of all vertices.
        '''
        cdef int attrib_count = self._attrib_count
        cdef int vert_count = self._vert_count
        if not attribute_n < attrib_count:
            raise Exception('Attribute out of bounds')
        cdef int start
        cdef float* data = self._data
        cdef int i
        cdef int index
        for i from 0 <= i < vert_count:
            start = attrib_count * i
            index = start + attribute_n
            data[index] = data[index] + value

    def mult_all_vertex_attribute(self, int attribute_n, float value):
        '''Multiply the value of attribute number attribute_n of all vertices 
        by value.
        '''
        cdef int attrib_count = self._attrib_count
        cdef int vert_count = self._vert_count
        if not attribute_n < attrib_count:
            raise Exception('Attribute out of bounds')
        cdef int start
        cdef float* data = self._data
        cdef int i
        cdef int index
        for i from 0 <= i < vert_count:
            start = attrib_count * i
            index = start + attribute_n
            data[index] = data[index] * value

    def set_textured_rectangle(self, float width, float height, list uvs):
        '''Prepare a 4 vertex_count, 6 index_count textured quad of size:
        width x height. Normally called internally when creating a VertMesh 
        using size and texture property. The first two attributes will be
        used to store the coordinate of the quad offset from the origin, and 
        the next two will store the UV coordinate data for each vertex.'''
        self.vertex_count = 4
        self.index_count = 6
        self.indices = [0, 1, 2, 2, 3, 0]
        w = .5*width
        h = .5*height
        u0, v0, u1, v1 = uvs
        self[0] = [-w, -h, u0, v0]
        self[1] = [-w, h, u0, v1]
        self[2] = [w, h, u1, v1]
        self[3] = [w, -h, u1, v0]
