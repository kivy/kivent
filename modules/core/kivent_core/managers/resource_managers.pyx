import json
from os import path
from kivy.core.image import Image as CoreImage
from kivent_core.rendering.vertmesh cimport VertMesh

cdef class ModelManager:

    def __init__(ModelManager self):
        self._meshes = []
        self._keys = {}
        self._mesh_count = 0
        self._unused = []

    property meshes:
        def __get__(ModelManager self):
            return self._meshes  

    def load_textured_rectangle(ModelManager self, attribute_count, 
        width, height, texture_key, name):
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

    def does_key_exist(ModelManager self, key):
        return key in self._keys

    def vert_mesh_from_key(ModelManager self, key):
        return self._meshes[self.get_mesh_index(key)]

    def get_mesh_index(ModelManager self, key):
        return self._keys[key]

    def load_mesh(ModelManager self, attribute_count, vert_count, index_count, 
        key):
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

    def copy_mesh(ModelManager self, mesh_key, new_key):
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
        
    def unload_mesh(ModelManager self, mesh_key):
        mesh_index = self._keys[mesh_key]
        self._unused.append(mesh_index)
        self._meshes[mesh_index] = None
        del self._keys[mesh_key]



cdef class TextureManager:
    '''The TextureManager handles the loading of all image resources into our
    game engine. Use **load_image** for image files and **load_atlas** for
    .atlas files. Do not load 2 images with the same name even in different
    atlas files. Prefer to access kivent.renderers.texture_manager than
    making your own instance.'''

    def __init__(TextureManager self):
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

    def load_image(TextureManager self, source):
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

    def load_texture(TextureManager self, name, texture):
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

    def unload_texture(TextureManager self, name):
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

    def get_texkey_from_name(TextureManager self, name):
        return self._keys[name]


    def get_uvs(TextureManager self, tex_key):
        return self._uvs[tex_key]

    def get_size(TextureManager self, tex_key):
        return self._sizes[tex_key]

    def get_texture(TextureManager self, tex_key):
        return self._textures[tex_key]

    def get_groupkey_from_texkey(TextureManager self, tex_key):
        return self._texkey_index[tex_key]

    def get_texname_from_texkey(TextureManager self, tex_key):
        return self._key_index[tex_key]

    def get_texkey_in_group(TextureManager self, tex_key, group_key):
        return tex_key in self._groups[group_key]

    def load_atlas(TextureManager self, source):
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