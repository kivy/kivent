# cython: embedsignature=True
import json
from os import path
from kivy.core.image import Image as CoreImage
from kivent_core.rendering.vertmesh cimport VertMesh, VertexModel
from kivent_core.rendering.vertex_formats cimport format_registrar, FormatConfig
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivy.logger import Logger


class ModelNameInUse(Exception):
    pass

cdef class ModelManager:

    def __init__(self, allocation_size=100*1024):
        self._meshes = []
        self._keys = {}
        self.allocation_size = allocation_size
        self._mesh_count = 0
        self._unused = []

        self.memory_blocks = {}
        self._models = {}
        self._key_counts = {}
        self._model_register = {}

    property models:
        def __get__(self):
            return self._models

    property key_counts:
        def __get__(self):
            return self._key_counts

    property model_register:
        def __get__(self):
            return self._model_register

    property meshes:
        def __get__(self):
            return self._meshes

    def register_entity_with_model(self, unsigned int entity_id, str system_id,
        str model_name):
        if model_name not in self._model_register:
            self._model_register[model_name] = {entity_id: system_id}
        else: 
            self._model_register[model_name][entity_id] = system_id

    def unregister_entity_with_model(self, unsigned int entity_id, 
        str model_name):
        del self._model_register[model_name][entity_id]

    def allocate(self, Buffer master_buffer, dict formats_to_allocate):
        #Either for each format in formats to allocate, or use default behavior
        #Load 10 mb of space for each registered vertex format. 
        #(index space, vertex_space) for val at format_name key.
        cdef MemoryBlock indices_block
        cdef MemoryBlock vertices_block
        cdef FormatConfig format_config
        vertex_formats = format_registrar._vertex_formats
        cdef dict memory_blocks = self.memory_blocks
        cdef unsigned int total_count = 0
        if formats_to_allocate == {}:
            for key in vertex_formats:
                formats_to_allocate[key] = (
                    self.allocation_size - self.allocation_size // 4, 
                    self.allocation_size // 4)
        for format in formats_to_allocate:
            vertex_size, index_size = formats_to_allocate[format]
            format_config = vertex_formats[format]
            indices_block = MemoryBlock(self.allocation_size//2, 1, 1)
            vertices_block = MemoryBlock(self.allocation_size//2, 1, 1)
            vertices_block.allocate_memory_with_buffer(master_buffer)
            indices_block.allocate_memory_with_buffer(master_buffer)
            memory_blocks[format] = {'indices_block': indices_block,
                'vertices_block': vertices_block}
            total_count += vertex_size + index_size
            Logger.info('KivEnt: Model Manager reserved space for vertex '
                'format: {name}. {space} KiB was reserved for vertices, '
                'fitting a total of {vert_count}. {ind_space} KiB was reserved '
                'for indices fitting a total of {ind_count}.'.format(
                name=format,
                space=str(vertex_size//1024),
                vert_count=str(vertex_size//format_config._size),
                ind_space=str(index_size//1024),
                ind_count=str(index_size//sizeof(unsigned short)),))
        return total_count

    def load_model(self, str format_name, unsigned int vertex_count, 
        unsigned int index_count, str name, do_copy=False):
        vertex_formats = format_registrar._vertex_formats
        cdef FormatConfig format_config = vertex_formats[format_name]
        if name not in self._key_counts:
            self._key_counts[name] = 0
        elif name in self._key_counts and not do_copy:
            return name
        elif name in self._key_counts and do_copy:
            name = name + str(self._key_counts[name])
            self._key_counts[name] += 1
        cdef MemoryBlock vertex_block = self.memory_blocks[format_name][
            'vertices_block']
        cdef MemoryBlock index_block = self.memory_blocks[format_name][
            'indices_block']
        cdef VertexModel model = VertexModel(vertex_count, index_count, 
            format_config, index_block, vertex_block, name)
        self._models[name] = model
        return name

    def copy_model(self, str model_to_copy, str model_name=None):
        cdef VertexModel copy_model = self._models[model_to_copy]
        cdef str format_name = copy_model._format_config._name
        if model_name is None:
            model_name = model_to_copy
        real_name = self.load_model(format_name, copy_model._vertex_count,
            copy_model._index_count, model_name, do_copy=True)
        self._models[real_name].copy_vertex_model(copy_model)
        return real_name

    def new_load_textured_rectangle(self, str format_name, float width, 
        float height, str texture_key, str name, do_copy=False):
        model_name = self.load_model(format_name, 4, 6, name, do_copy=do_copy)
        cdef VertexModel model = self._models[model_name]
        texkey = texture_manager.get_texkey_from_name(texture_key)
        uvs = texture_manager.get_uvs(texkey)
        model.set_textured_rectangle(width, height, uvs)
        return model_name


    def load_textured_rectangle(self, attribute_count, width, height, 
        texture_key, name):
        cdef dict keys = self._keys
        assert(name not in keys)
        vert_mesh = VertMesh(attribute_count, 4, 6)
        texkey = texture_manager.get_texkey_from_name(texture_key)
        uvs = texture_manager.get_uvs(texkey)
        vert_mesh.set_textured_rectangle(width, height, uvs)
        try:
            free = self._unused.pop()
            self._meshes[free] = vert_mesh
            index = free
        except:
            self._meshes.append(vert_mesh)
            index = self._mesh_count
            self._mesh_count += 1
        keys[name] = index

    def does_key_exist(self, key):
        return key in self._keys

    def vert_mesh_from_key(self, key):
        return self._meshes[self.get_mesh_index(key)]

    def get_mesh_index(self, key):
        return self._keys[key]

    def load_mesh(self, attribute_count, vert_count, index_count, key):
        cdef dict keys = self._keys
        assert(key not in keys)
        vert_mesh = VertMesh(attribute_count, vert_count, index_count)
        try:
            free = self._unused.pop()
            self._meshes[free] = vert_mesh
            index = free
        except:
            self._meshes.append(vert_mesh)
            index = self._mesh_count
            self._mesh_count += 1
        keys[key] = index

    def copy_mesh(self, mesh_key, new_key):
        cdef dict keys = self._keys
        assert(new_key not in keys)
        cdef VertMesh vert_mesh = self.meshes[keys[mesh_key]]
        cdef VertMesh copy_mesh = VertMesh(vert_mesh._attrib_count, 
            vert_mesh._vert_count, vert_mesh._index_count)
        copy_mesh.copy_vert_mesh(vert_mesh)
        try:
            free = self._unused.pop()
            self._meshes[free] = vert_mesh
            index = free
        except:
            self._meshes.append(vert_mesh)
            index = self._mesh_count
            self._mesh_count += 1
        keys[new_key] = index
        
    def unload_mesh(self, mesh_key):
        mesh_index = self._keys[mesh_key]
        self._unused.append(mesh_index)
        self._meshes[mesh_index] = None
        del self._keys[mesh_key]


cdef class TextureManager:
    '''
    The TextureManager handles the loading of all image resources into our
    game engine. Use **load_image** for image files and **load_atlas** for
    .atlas files. Do not load 2 images with the same name even in different
    atlas files. Prefer to access kivent.renderers.texture_manager than
    making your own instance.'''

    def __init__(self):
        #maps texkey to textures
        self._textures = {}
        #maps string names to texkeys
        self._keys = {}
        #maps texkey to string names
        self._key_index = {}
        #maps texkey to actual texture key (for atlas)
        self._texkey_index = {}
        self._key_count = 0
        #map texkey to w, h of texture
        self._sizes = {}
        #maps texkey to list of uvs
        self._uvs = {}
        #maps actual texture key to all subtexture texkey (for atlas)
        self._groups = {}

    def load_image(self, source):
        texture = CoreImage(source, nocache=True).texture
        name = path.splitext(path.basename(source))[0]
        name = str(name)
        if name in self._keys:
            raise KeyError()
        else:
            key_count = self._key_count
            size = texture.size
            self._textures[key_count] = texture
            self._keys[name] = key_count
            self._sizes[key_count] = size
            self._key_index[key_count] = name
            self._texkey_index[key_count] = key_count
            self._uvs[key_count] = [0., 0., 1., 1.]
            self._groups[key_count] = [key_count]
            self._key_count += 1
        return key_count

    def load_texture(self, name, texture):
        name = str(name)
        if name in self._keys:
            raise KeyError()
        else:
            key_count = self._key_count
            self._textures[key_count] = texture
            size = texture.size
            self._sizes[key_count] = size
            self._keys[name] = key_count
            self._key_index[key_count] = name
            self._texkey_index[key_count] = key_count
            self._uvs[key_count] = [0., 0., 1., 1.]
            self._groups[key_count] = [key_count]
            self._key_count += 1
        return key_count

    def unload_texture(self, name):
        if name not in self._keys:
            raise KeyError()
        else:
            key_index = self._keys[name]
            texture_keys = self._groups[key_index]
            for key in texture_keys:
                name = self._key_index[key]
                del self._key_index[key]
                del self._uvs[key]
                del self._texkey_index[key]
                del self._keys[name]
                del self._sizes[key]
            del self._groups[key_index]
            del self._textures[key_index]

    def get_texkey_from_name(self, name):
        return self._keys[name]

    def get_uvs(self, tex_key):
        return self._uvs[tex_key]

    def get_size(self, tex_key):
        return self._sizes[tex_key]

    def get_texture(self, tex_key):
        return self._textures[tex_key]

    def get_groupkey_from_texkey(self, tex_key):
        return self._texkey_index[tex_key]

    def get_texname_from_texkey(self, tex_key):
        return self._key_index[tex_key]

    def get_texkey_in_group(self, tex_key, group_key):
        return tex_key in self._groups[group_key]

    def load_atlas(self, source):
        dirname = path.dirname(source)
        with open(source, 'r') as data:
             atlas_data = json.load(data)

        for imgname in atlas_data:
            texture = CoreImage(
                path.join(dirname,imgname), nocache=True).texture
            name = str(path.basename(imgname))
            size = texture.size
            w = <float>size[0]
            h = <float>size[1]
            keys = self._keys
            uvs = self._uvs
            atlas_content = atlas_data[imgname]
            atlas_key = self.load_texture(name, texture)
            group_list = self._groups[atlas_key]
            group_list_a = group_list.append
            for key in atlas_content:
                key = str(key)
                kx,ky,kw,kh = atlas_content[key]
                key_index = self._key_count
                self._keys[key] = key_index
                self._key_index[key_index] = key
                self._texkey_index[key_index] = atlas_key
                self._sizes[key_index] = kw, kh
                x1, y1 = kx, ky
                x2, y2 = x1 + kw, y1 + kh
                self._uvs[key_index] = [x1/w, 1.-y1/h, x2/w, 1.-y2/h] 
                self._key_count += 1
                group_list_a(key_index)

texture_manager = TextureManager()
model_manager = ModelManager()
