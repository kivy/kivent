from cpython.mem cimport PyMem_Malloc, PyMem_Realloc, PyMem_Free
from kivy.core.image import Image as CoreImage
from os import path
cdef extern from "string.h":
    void *memcpy(void *dest, void *src, size_t n)

cdef class TextureManager:
    cdef dict _textures
    cdef dict _keys
    cdef dict _uvs
    cdef dict _groups

    def __init__(self):
        self._textures = {}
        self._keys = {}
        self._uvs = {}
        self._groups = {}

    def load_image(self, source):
        texture = CoreImage(source, nocache=True).texture
        name = path.splitext(path.basename(source))[0]
        if name not in self._textures:
            self._textures[name] = texture
            self._keys[name] = name
            self._uvs[name] = [0., 0., 1., 1.]
            self._groups[name] = [name]
        else:
            raise KeyError()

    def unload_texture(self, name):
        if name not in self._textures:
            raise KeyError()
        else:
            texture_keys = self._groups[name]
            for key in texture_keys:
                del self._uvs[key]
                del self._keys[key]
            del self._groups[name]
            del self._textures[name]


    def get_uvs(self, tex_key):
        return self._uvs[tex_key]

    def get_texture(self, tex_name):
        return self._textures[tex_name]

    def get_texture_from_key(self, tex_key):
        return self._textures[self._keys[tex_key]]

    def get_texname_from_texkey(self, tex_key):
        return self._keys[tex_key]

    def get_texkey_in_group(self, tex_key, atlas_name):
        return tex_key in self._groups[atlas_name]

    def load_atlas(self, source):
        texture = CoreImage(
            path.splitext(source)[0]+'-0.png', nocache=True).texture
        name = path.splitext(path.basename(source))[0]
        size = texture.size
        cdef float w = <float>size[0]
        cdef float h = <float>size[1]
        with open(source, 'r') as data:
             atlas_data = json.load(data)
        cdef dict keys = self._keys
        cdef dict uvs = self._uvs
        cdef list group_list = []
        group_list_a = group_list.append
        atlas_content = atlas_data[name+'-0.png']
        cdef float x1, y1, x2, y2
        if name not in self._textures:
            self._textures[name] = texture
            for key in atlas_content:
                key = <str>key
                uv_data = atlas_content[key]
                self._keys[key] = name
                x1, y1 = uv_data[0], uv_data[1]
                x2, y2 = x1 + uv_data[2], y1 + uv_data[3]
                self._uvs[key] = [x1/w, 1.-y1/h, x2/w, 1.-y2/h] 
                group_list_a(str(key))
            self._groups[name] = group_list
        else:
            raise KeyError()

texture_manager = TextureManager()


cdef class NRenderComponent:
    cdef bool _render
    cdef str _texture_key
    cdef NVertMesh _vert_mesh
    cdef int _attrib_count
    cdef int _batch_id

    def __cinit__(self, bool render, str texture_key, 
        int attribute_count, width=None, height=None, 
        vert_mesh=None, copy=False):
        self._render = render
        self._texture_key = texture_key
        self._attrib_count = attribute_count
        if width is not None and height is not None:
            self._vert_mesh = vert_mesh = NVertMesh(attribute_count, 4, 6)
            vert_mesh.set_textured_rectangle(width, height, 
                texture_manager.get_uvs(texture_key))
        elif vert_mesh != None:
            if not copy:
                self._vert_mesh = vert_mesh
            else:
                self._vert_mesh = new_vert_mesh = NVertMesh(attribute_count, 
                    vert_mesh._vert_count, vert_mesh._index_count)
                new_vert_mesh.copy_vert_mesh(vert_mesh)

    property batch_id:
        def __get__(self):
            return self._batch_id

    property attribute_count:
        def __get__(self):
            return self._attrib_count

        def __set__(self, int value):
            self._attrib_count = value

    property texture_key:
        def __get__(self):
            return self._texture_key
        def __set__(self, str value):
            self._texture_key = value

    property render:
        def __get__(self):
            return self._render
        def __set__(self, bool value):
            self._render = value

    property vertex_count:
        def __get__(self):
            return self._vert_mesh._vert_count

    property index_count:
        def __get__(self):
            return self._vert_mesh._index_count

    property vert_mesh:
        def __get__(self):
            return self._vert_mesh

        def __set__(self, NVertMesh vert_mesh):
            self._vert_mesh = vert_mesh


class NRenderer(GameSystem):
    '''The basic KivEnt renderer it draws every entity every frame.

    **Attributes:**
        **do_rotate** (BooleanProperty): Determines whether or not vertex 
        format will have a float for rotate

        **do_color** (BooleanProperty): Determines whether or not vertex 
        format will have 4 floats for rgba color

        **do_scale** (BooleanProperty): Determines whether or not vertex 
        format will have a float for scale

        **shader_source** (StringProperty): Path to the .glsl to be used, do 
        include '.glsl' in the name. You must ensure that your shader matches 
        your vertex format or you will have problems

        **vertex_format** (dict): describes format of data sent to shaders,
        generated automatically based on do_rotate, do_scale, do_color

    '''
    system_id = StringProperty('renderer')
    updateable = BooleanProperty(True)
    renderable = BooleanProperty(True)
    do_rotate = BooleanProperty(False)
    do_color = BooleanProperty(False)
    do_scale = BooleanProperty(False)
    attribute_count = NumericProperty(4)
    maximum_vertices = NumericProperty(20000)
    shader_source = StringProperty('positionshader.glsl')


    def __init__(self, **kwargs):
        self.canvas = RenderContext(use_parent_projection=True)
        if 'shader_source' in kwargs:
            self.canvas.shader.source = kwargs.get('shader_source')
        super(NRenderer, self).__init__(**kwargs)
        self.vertex_format = self.calculate_vertex_format()
        self.batches = []
        self._do_r_index = -1
        self._do_g_index = -1
        self._do_b_index = -1
        self._do_a_index = -1
        self._do_rot_index = -1
        self._do_scale_index = -1
        self._do_center_x = 4
        self._do_center_y = 5

    def on_shader_source(self, instance, value):
        self.canvas.shader.source = value

    def on_do_rotate(self, instance, value):
        self.vertex_format = self.calculate_vertex_format()

    def on_do_scale(self, instance, value):
        self.vertex_format = self.calculate_vertex_format()

    def on_do_color(self, instance, value):
        self.vertex_format = self.calculate_vertex_format()

    def calculate_vertex_format(self):
        '''Function used internally to calculate the vertex_format'''
        vertex_format = [
            ('vPosition', 2, 'float'),
            ('vTexCoords0', 2, 'float'),
            ('vCenter', 2, 'float'),
            ]
        attribute_count = 6
        if self.do_rotate:
            vertex_format.append(('vRotation', 1, 'float'))
            self._do_rot_index = attribute_count
            attribute_count += 1
        if self.do_color:
            vertex_format.append(('vColor', 4, 'float'))
            self._do_r_index = attribute_count
            self._do_g_index = attribute_count + 1
            self._do_b_index = attribute_count + 2
            self._do_a_index = attribute_count + 3
            attribute_count += 4
        if self.do_scale:
            self._do_scale_index = attribute_count
            vertex_format.append(('vScale', 1, 'float'))
            attribute_count += 1
        self.attribute_count = attribute_count
        return vertex_format

    def update(self, dt):
        cdef list batches = self.batches
        cdef str system_id = self.system_id
        cdef RenderBatch batch
        cdef object gameworld = self.gameworld
        cdef object entity
        cdef int entity_id
        cdef list entities = gameworld.entities
        cdef list entity_ids
        cdef NRenderComponent render_comp
        cdef PositionComponent pos_comp
        cdef RotateComponent rot_comp
        cdef ScaleComponent scale_comp
        cdef ColorComponent color_comp
        cdef int vert_offset
        cdef int attribute_count = self.attribute_count
        cdef int vertex_count
        cdef int index_count
        cdef int index_offset
        cdef int mesh_index_offset
        cdef int n
        cdef int attr_ind
        cdef int i
        cdef float rot
        cdef float s
        cdef float r
        cdef float g
        cdef float b
        cdef float a
        cdef bool do_rotate = self.do_rotate
        cdef bool do_scale = self.do_scale
        cdef bool do_color = self.do_color
        cdef int center_x_index = self._do_center_x
        cdef int center_y_index = self._do_center_y
        cdef int rot_index = self._do_rot_index
        cdef int r_index = self._do_r_index
        cdef int g_index = self._do_g_index
        cdef int b_index = self._do_b_index
        cdef int a_index = self._do_a_index
        cdef int scale_index = self._do_scale_index
        cdef float x, y
        cdef NVertMesh vert_mesh
        cdef float* batch_data
        cdef float* mesh_data
        cdef unsigned short* batch_indices
        cdef unsigned short* mesh_indices
        cdef int data_index
        cdef int mesh_index
        for batch in batches:
            batch.update_batch()
            batch_data = batch._batch_data
            batch_indices = batch._batch_indices
            entity_ids = batch._entity_ids
            index_offset = 0
            vert_offset = 0
            mesh_index_offset = 0
            for entity_id in entity_ids:
                entity = entities[entity_id]
                render_comp = getattr(entity, system_id)
                pos_comp = entity.position
                x = pos_comp._x
                y = pos_comp._y
                if do_rotate:
                    rot_comp = entity.rotate
                    rot = rot_comp._r
                if do_scale:
                    scale_comp = entity.scale
                    s = scale_comp._s
                if do_color:
                    color_comp = entity.color
                    r = color_comp._r
                    g = color_comp._g
                    b = color_comp._b
                    a = color_comp._a
                vertex_count = render_comp.vertex_count
                index_count = render_comp.index_count
                vert_mesh = render_comp._vert_mesh
                mesh_data = vert_mesh._data
                mesh_indices = vert_mesh._indices
                for i from 0 <= i < index_count:
                    batch_indices[i+index_offset] = (
                        mesh_indices[i] + mesh_index_offset)
                for n from 0 <= n < vertex_count:
                    for attr_ind from 0 <= attr_ind < attribute_count:
                        mesh_index = n*attribute_count + attr_ind
                        data_index = mesh_index + vert_offset
                        if attr_ind == center_x_index:
                            batch_data[data_index] = x
                        elif attr_ind == center_y_index:
                            batch_data[data_index] = y
                        elif attr_ind == rot_index:
                            batch_data[data_index] = rot
                        elif attr_ind == r_index:
                            batch_data[data_index] = r
                        elif attr_ind == b_index:
                            batch_data[data_index] = b
                        elif attr_ind == g_index:
                            batch_data[data_index] = g
                        elif attr_ind == a_index:
                            batch_data[data_index] = a
                        elif attr_ind == scale_index:
                            batch_data[data_index] = s
                        else:
                            batch_data[data_index] = mesh_data[mesh_index]
                vert_offset += vertex_count * attribute_count
                mesh_index_offset += vertex_count
                index_offset += index_count
            batch._cmesh.flag_update()


    def clear_mesh(self):
        '''Used internally when redraw is called'''
        pass

    def remove_entity(self, int entity_id):
        super(NRenderer, self).remove_entity(entity_id)


    def create_component(self, object entity, args):
        cdef NRenderComponent render_comp = self.generate_component(args)
        setattr(entity, self.system_id, render_comp)
        cdef int entity_id = entity.entity_id
        self.entity_ids.append(entity_id)
        cdef int vertex_count = render_comp.vertex_count
        cdef int index_count = render_comp.index_count
        cdef str texture_key = render_comp._texture_key
        if not self.add_to_existing_batch(entity_id, vertex_count, 
            index_count, texture_key):
            self.create_new_batch(entity_id, self.maximum_vertices, 
                self.attribute_count, vertex_count, index_count, texture_key)


    def create_new_batch(self, int entity_id, int max_verts, 
        int attribute_count, int vertex_count, int index_count, 
        str texture_key):
        texture_name = texture_manager.get_texname_from_texkey(texture_key)
        texture = texture_manager.get_texture(texture_name)
        cdef CMesh cmesh
        with self.canvas:
            cmesh = CMesh(fmt=self.vertex_format, mode='triangles',
                    texture=texture)
        cdef RenderBatch new_batch = RenderBatch(max_verts, attribute_count, 
            cmesh, texture_name)
        self.batches.append(new_batch)
        added = new_batch.add_entity(entity_id, vertex_count, index_count, 
            texture_key)
        if not added:
            raise Exception(
                'Entity: ' + str(entity_id) + ' not added to batch')

    def add_to_existing_batch(self, int entity_id, int vertex_count, 
        int index_count, str texture_key):
        cdef list batches = self.batches
        for batch in batches:
            if batch.add_entity(entity_id, vertex_count, 
                index_count, texture_key):
                return True
        return False

    def generate_component(self, dict entity_component_dict):
        '''Renderers take in a dict containing a string 'texture' corresponding
        to the name of the texture in the atlas, and a size tuple of width, 
        height. NRenderComponent's have a texture string, a render boolean 
        that controls whether or not they will be drawn, an on_screen boolean.
        on_screen returns True always for Renderer and StaticQuadRenderer.
        For DynamicRenderer, on_screen only returns True if that entity is
        within Window bounds.'''
        cdef str texture = entity_component_dict['texture']
        w, h = entity_component_dict['size']
        new_component = NRenderComponent.__new__(NRenderComponent, True, 
            texture, self.attribute_count, width=w, height=h)
        return new_component


cdef class RenderBatch:
    cdef list _entity_ids
    cdef int _vert_count
    cdef dict _entity_counts
    cdef int _maximum_verts
    cdef float* _batch_data
    cdef unsigned short* _batch_indices
    cdef int _index_count
    cdef int _r_index_count
    cdef int _r_vert_count
    cdef int _attrib_count
    cdef str _texture
    cdef CMesh _cmesh


    def __cinit__(self, int maximum_verts, int attribute_count, CMesh cmesh,
            str texture_name):
        self._entity_ids = []
        self._entity_counts = {}
        self._maximum_verts = maximum_verts
        self._batch_data = NULL
        self._batch_indices = NULL
        self._r_index_count = 0
        self._r_vert_count = 0
        self._vert_count = 0
        self._index_count = 0
        self._attrib_count = attribute_count
        self._cmesh = cmesh
        self._texture = texture_name

    def update_batch(self):
        cdef int vert_count = self._vert_count
        cdef int r_vert_count = self._r_vert_count
        cdef int index_count = self._index_count
        cdef int r_index_count = self._r_index_count
        cdef float* batch_data = self._batch_data
        cdef int attribute_count = self._attrib_count
        cdef CMesh cmesh = self._cmesh
        cdef unsigned short* batch_indices = self._batch_indices
        something_updated = False
        if vert_count != r_vert_count:
            if not batch_data:
                batch_data = <float *>PyMem_Malloc(
                    vert_count * attribute_count * sizeof(float))
            else:
                batch_data = <float *>PyMem_Realloc(batch_data, 
                    attribute_count * vert_count * sizeof(float))
                if not batch_data:
                    raise MemoryError()
            self._r_vert_count = vert_count
            self._batch_data = batch_data
            cmesh._vertices = batch_data
            cmesh.vcount = vert_count*attribute_count
        if index_count != r_index_count:
            if not batch_indices:
                batch_indices = <unsigned short*>PyMem_Malloc(
                    index_count * sizeof(unsigned short))
            else:
                batch_indices = <unsigned short*>PyMem_Realloc(
                    batch_indices, index_count * sizeof(unsigned short))
                if not batch_indices:
                    raise MemoryError()
            self._r_index_count = index_count
            self._batch_indices = batch_indices
            cmesh._indices = batch_indices
            cmesh.icount = index_count


    def __dealloc__(self):
        if self._batch_data != NULL:
            PyMem_Free(self._batch_data)
        if self._batch_indices != NULL:
            PyMem_Free(self._batch_indices)

    def add_entity(self, int entity_id, int num_verts, int num_indices,
        str texture_key):
        if num_verts + self._vert_count > self._maximum_verts or not (
            texture_manager.get_texkey_in_group(texture_key, self._texture)):
            return False
        else:
            self._vert_count += num_verts
            self._index_count += num_indices
            self._entity_ids.append(entity_id)
            self._entity_counts[entity_id] = (num_verts, num_indices)
            return True

    def remove_entity(self, int entity_id):
        self._entity_ids.remove(entity_id)
        entity_counts = self._entity_counts
        num_verts, num_indices = entity_counts[entity_id]
        self._vert_count -= num_verts
        self._index_count -= num_indices
        del entity_counts[entity_id]

    def update_entity_counts(self, int entity_id, int new_vert_count, 
        int new_indices_count):
        entity_counts = self._entity_counts
        num_verts, num_indices = entity_counts[entity_id]
        vert_change = new_vert_count - num_verts
        index_change = new_indices_count - num_indices
        self._vert_count += vert_change
        self._index_count += index_change
        entity_counts[entity_id] = (new_vert_count, new_indices_count)


cdef class NVertMesh:
    cdef int _attrib_count
    cdef float* _data
    cdef int _vert_count
    cdef int _index_count
    cdef unsigned short* _indices


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

    def copy_vert_mesh(self, NVertMesh vert_mesh):
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



