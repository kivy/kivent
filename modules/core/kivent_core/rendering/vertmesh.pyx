# cython: embedsignature=True
from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
cdef extern from "string.h":
    void *memcpy(void *dest, void *src, size_t n)

    
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
