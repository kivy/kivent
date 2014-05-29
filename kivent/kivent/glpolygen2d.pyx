
cdef struct Triangle:
    int a, b, c

cdef struct Vertex4:
    float v0, v1, v2, v3

cdef struct Vertex8:
    float v0, v1, v2, v3
    float v4, v5, v6, v7

cdef struct Vertex12:
    float v0, v1, v2, v3
    float v4, v5, v6, v7
    float v8, v9, v10, v11

cdef struct Vertex16:
    float v0, v1, v2, v3
    float v4, v5, v6, v7
    float v8, v9, v10, v11
    float v12, v13, v14, v15

cdef inline Triangle triangle_from_tuple(tuple triangle_data):
    cdef Triangle tri
    print triangle_data
    tri.a = triangle_data[0]
    tri.b = triangle_data[1]
    tri.c = triangle_data[2]
    return tri

cdef inline Vertex4 vertex4_from_tuple(tuple vertex_data):
    cdef Vertex4 vert
    data_count = len(vertex_data)
    vert.v0 = vertex_data[0]
    vert.v1 = vertex_data[1]
    if data_count > 3:
        vert.v2 = vertex_data[2]
        vert.v3 = vertex_data[3]
    elif data_count > 2:
        vert.v2 = vertex_data[2]
    return vert

cdef inline Vertex8 vertex8_from_list(list vertex_data):
    cdef Vertex8 vert
    data_count = len(vertex_data)
    vert.v0 = vertex_data[0]
    vert.v1 = vertex_data[1]
    vert.v2 = vertex_data[2]
    vert.v3 = vertex_data[3]
    vert.v4 = vertex_data[4]
    if data_count > 7:
        vert.v5 = vertex_data[5]
        vert.v6 = vertex_data[6]
        vert.v7 = vertex_data[7]
    elif data_count > 6:
        vert.v5 = vertex_data[5]
        vert.v6 = vertex_data[6]
    elif data_count > 5:
        vert.v5 = vertex_data[5]
    return vert

cdef inline Vertex12 vertex12_from_list(list vertex_data):
    cdef Vertex12 vert
    data_count = len(vertex_data)
    vert.v0 = vertex_data[0]
    vert.v1 = vertex_data[1]
    vert.v2 = vertex_data[2]
    vert.v3 = vertex_data[3]
    vert.v4 = vertex_data[4]
    vert.v5 = vertex_data[5]
    vert.v6 = vertex_data[6]
    vert.v7 = vertex_data[7]
    vert.v8 = vertex_data[8]
    if data_count > 11:
        vert.v9 = vertex_data[9]
        vert.v10 = vertex_data[10]
        vert.v11 = vertex_data[11]
    elif data_count > 10:
        vert.v9 = vertex_data[9]
        vert.v10 = vertex_data[10]
    elif data_count > 9:
        vert.v9 = vertex_data[9]
    return vert

cdef inline Vertex16 vertex16_from_list(list vertex_data):
    cdef Vertex16 vert
    data_count = len(vertex_data)
    vert.v0 = vertex_data[0]
    vert.v1 = vertex_data[1]
    vert.v2 = vertex_data[2]
    vert.v3 = vertex_data[3]
    vert.v4 = vertex_data[4]
    vert.v5 = vertex_data[5]
    vert.v6 = vertex_data[6]
    vert.v7 = vertex_data[7]
    vert.v8 = vertex_data[8]
    vert.v9 = vertex_data[9]
    vert.v10 = vertex_data[10]
    vert.v11 = vertex_data[11]
    vert.v12 = vertex_data[12]
    if data_count > 15:
        vert.v13 = vertex_data[13]
        vert.v14 = vertex_data[14]
        vert.v15 = vertex_data[15]
    elif data_count > 14:
        vert.v13 = vertex_data[13]
        vert.v14 = vertex_data[14]
    elif data_count > 13:
        vert.v13 = vertex_data[13]
    return vert


cdef class VertMesh:
    cdef int vert_count
    cdef void* _vertices
    cdef Triangle* _triangles
    cdef int tri_count
    cdef int vert_data_count
    cdef object _load_verts
    cdef float* _gl_verts
    cdef unsigned short* _gl_indices
    cdef int _real_count

    property load_verts:
        def __get__(self):
            return self.load_verts

    def __cinit__(self, int vert_data_count, int vert_count, list vertices, 
        int tri_count, list triangles):
        cdef void* vert_ptr
        cdef Triangle* triangles_ptr
        if vert_data_count <= 4:
            self._vertices = vert_ptr = <void *>calloc(
                vert_count, sizeof(Vertex4))
            self._real_count = 4
            self._load_verts = self.load_verts4
        elif vert_data_count <= 8:
            self._vertices = vert_ptr = <void *>calloc(
                vert_count, sizeof(Vertex8))
            self._load_verts = self.load_verts8
            self._real_count = 8
        elif vert_data_count <= 12:
            self._vertices = vert_ptr = <void *>calloc(
                vert_count, sizeof(Vertex12))
            self._real_count = 12
            self._load_verts = self.load_verts12
        elif vert_data_count <= 16:
            self._vertices = vert_ptr = <void *>calloc(
                vert_count, sizeof(Vertex16))
            self._real_count = 16
            self._load_verts = self.load_verts16
        else:
            print('Too large vert_data_count, 16 fields supported at most.')
        self.vert_data_count = vert_data_count
        self.vert_count = vert_count
        self.tri_count = tri_count
        self._triangles = triangles_ptr = <Triangle*>calloc(
            tri_count, sizeof(Triangle))
        self._load_verts(vertices, vert_count)
        self.load_triangles(triangles, tri_count)

        if not vert_ptr or not triangles_ptr:
            raise MemoryError()

    def __dealloc__(self):
        cdef void* vertices = self._vertices
        cdef Triangle* triangles = self._triangles
        cdef float* gl_verts = self._gl_verts
        cdef unsigned short* gl_indices = self._gl_indices
        if vertices != NULL:
            free(vertices)
            vertices = NULL
        if triangles != NULL:
            free(triangles)
            triangles = NULL
        if gl_verts != NULL:
            free(gl_verts)
            gl_verts = NULL
        if gl_indices != NULL:
            free(gl_indices)
            gl_indices = NULL

    def generate_gl_verts(self):
        cdef int vert_data_count = self.vert_data_count
        cdef float* gl_verts = self._gl_verts
        if gl_verts != NULL:
            free(gl_verts)
            gl_verts = NULL
        if vert_data_count <= 4:
            self._gl_verts = self.get_vert4_float_array()
        elif vert_data_count <= 8:
            self._gl_verts = self.get_vert8_float_array()
        elif vert_data_count <= 12:
            self._gl_verts = self.get_vert12_float_array()
        else:
            self._gl_verts = self.get_vert16_float_array()

    def generate_gl_indices(self):
        cdef unsigned short* gl_indices = self._gl_indices
        if gl_indices != NULL:
            free(gl_indices)
            gl_indices = NULL
        self._gl_indices = self.get_triangle_indices()

    cdef unsigned short* get_triangle_indices(self):
        cdef Triangle* triangles = self._triangles
        cdef Triangle tri
        cdef int tri_count = self.tri_count
        cdef int i
        cdef unsigned short* gl_indices = <unsigned short*>calloc(
            tri_count*3, sizeof(unsigned short*))
        cdef int a
        for a in range(tri_count):
            tri = triangles[a]
            i = a * 3
            gl_indices[i] = tri.a
            gl_indices[i+1] = tri.b
            gl_indices[i+2] = tri.c
        cdef int x
        print 'IN GET TRIANLGE INDICES'
        for x in range(tri_count*3):
            print gl_indices[x]
        return gl_indices

    cdef float* get_vert4_float_array(self):
        cdef Vertex4* vert_data = <Vertex4*>self._vertices
        cdef Vertex4 vert
        cdef int vert_count = self.vert_count
        cdef float* gl_verts = <float*>calloc(vert_count*4, sizeof(float))
        cdef int a
        cdef int i
        for a in range(vert_count):
            vert = vert_data[a]
            i = a * 4
            gl_verts[i] = vert.v0
            gl_verts[i+1] = vert.v1
            gl_verts[i+2] = vert.v2
            gl_verts[i+3] = vert.v3
        return gl_verts

    cdef float* get_vert8_float_array(self):
        cdef Vertex8* vert_data = <Vertex8*>self._vertices
        cdef Vertex8 vert
        cdef int vert_count = self.vert_count
        cdef float* gl_verts = <float*>calloc(vert_count*8, sizeof(float))
        cdef int a
        cdef int i
        cdef int x
        for a in range(vert_count):
            i = a * 8
            vert = vert_data[a]
            gl_verts[i] = vert.v0
            gl_verts[i+1] = vert.v1
            gl_verts[i+2] = vert.v2
            gl_verts[i+3] = vert.v3
            gl_verts[i+4] = vert.v4
            gl_verts[i+5] = vert.v5
            gl_verts[i+6] = vert.v6
            gl_verts[i+7] = vert.v7
        return gl_verts

    cdef float* get_vert12_float_array(self):
        cdef Vertex12* vert_data = <Vertex12*>self._vertices
        cdef Vertex12 vert
        cdef int vert_count = self.vert_count
        cdef float* gl_verts = <float*>calloc(vert_count*12, sizeof(float))
        cdef int i
        cdef int a
        for a in range(vert_count):
            i = a * 12
            vert = vert_data[a]
            gl_verts[i] = vert.v0
            gl_verts[i+1] = vert.v1
            gl_verts[i+2] = vert.v2
            gl_verts[i+3] = vert.v3
            gl_verts[i+4] = vert.v4
            gl_verts[i+5] = vert.v5
            gl_verts[i+6] = vert.v6
            gl_verts[i+7] = vert.v7
            gl_verts[i+8] = vert.v8
            gl_verts[i+9] = vert.v9
            gl_verts[i+10] = vert.v10
            gl_verts[i+11] = vert.v11
        return gl_verts

    cdef float* get_vert16_float_array(self):
        cdef Vertex16* vert_data = <Vertex16*>self._vertices
        cdef Vertex16 vert
        cdef int vert_count = self.vert_count
        cdef float* gl_verts = <float*>calloc(vert_count*16, sizeof(float))
        cdef int i
        cdef int a
        for a in range(vert_count):
            i = a * 16
            vert = vert_data[a]
            gl_verts[i] = vert.v0
            gl_verts[i+1] = vert.v1
            gl_verts[i+2] = vert.v2
            gl_verts[i+3] = vert.v3
            gl_verts[i+4] = vert.v4
            gl_verts[i+5] = vert.v5
            gl_verts[i+6] = vert.v6
            gl_verts[i+7] = vert.v7
            gl_verts[i+8] = vert.v8
            gl_verts[i+9] = vert.v9
            gl_verts[i+10] = vert.v10
            gl_verts[i+11] = vert.v11
            gl_verts[i+12] = vert.v12
            gl_verts[i+13] = vert.v13
            gl_verts[i+14] = vert.v14
            gl_verts[i+15] = vert.v15
        return gl_verts

    def load_verts4(self, list vertices, int vert_count):
        cdef Vertex4 vert
        cdef tuple t_vertex
        cdef int i
        cdef Vertex4* vert_data = <Vertex4*>self._vertices
        for i in range(vert_count):
            t_vertex = vertices[i]
            vert_data[i] = vertex4_from_tuple(t_vertex)

    def load_verts8(self, list vertices, int vert_count):
        cdef Vertex8 vert
        cdef list l_vertex
        cdef int i
        cdef Vertex8* vert_data = <Vertex8*>self._vertices
        for i in range(vert_count):
            l_vertex = vertices[i]
            vert_data[i] = vertex8_from_list(l_vertex)

    def load_verts12(self, list vertices, int vert_count):
        cdef Vertex12 vert
        cdef list l_vertex
        cdef int i
        cdef Vertex12* vert_data = <Vertex12*>self._vertices
        for i in range(vert_count):
            l_vertex = vertices[i]
            vert_data[i] = vertex12_from_list(l_vertex)

    def load_verts16(self, list vertices, int vert_count):
        cdef Vertex16 vert
        cdef list l_vertex
        cdef int i
        cdef Vertex16* vert_data = <Vertex16*>self._vertices
        for i in range(vert_count):
            l_vertex = vertices[i]
            vert_data[i] = vertex16_from_list(l_vertex)

    def load_triangles(self, list triangles, int tri_count):
        cdef tuple t_tri
        cdef int i
        cdef Triangle* triangle_data = self._triangles
        for i in range(tri_count):
            t_tri = triangles[i]
            triangle_data[i] = triangle_from_tuple(t_tri)


