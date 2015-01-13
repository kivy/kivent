import json
from os import path
from kivy.core.image import Image as CoreImage
from vertmesh cimport VertMesh

cdef class ModelManager:

    def __init__(self):
        self._meshes = []
        self._keys = {}
        self._mesh_count = 0
        self._unused = []

    property meshes:
        def __get__(self):
            return self._meshes  

    def load_textured_rectangle(self, attribute_count, 
        width, height, texture_key, name):
        cdef dict keys = self._keys
        assert(name not in keys)
        vert_mesh = VertMesh(attribute_count, 4, 6)
        uvs = texture_manager.get_uvs(texture_key)
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
    '''The TextureManager handles the loading of all image resources into our
    game engine. Use **load_image** for image files and **load_atlas** for
    .atlas files. Do not load 2 images with the same name even in different
    atlas files. Prefer to access kivent.renderers.texture_manager than
    making your own instance.'''

    def __init__(self):
        self._textures = {}
        self._keys = {}
        self._key_index = {}
        self._texkey_index = {}
        self._key_count = 0
        self._sizes = {}
        self._uvs = {}
        self._groups = {}

    def load_image(self, source):
        texture = CoreImage(source, nocache=True).texture
        name = path.splitext(path.basename(source))[0]
        name = str(name)
        if name not in self._textures:
            key_count = self._key_count
            self._textures[name] = texture
            self._keys[name] = name
            self._key_index[key_count] = name
            self._texkey_index[name] = key_count
            self._uvs[name] = [0., 0., 1., 1.]
            self._groups[name] = [name]
            self._key_count += 1
        else:
            raise KeyError()

    def load_texture(self, name, texture):
        name = str(name)
        if name in self._textures:
            raise KeyError()
        else:
            key_count = self._key_count
            self._textures[name] = texture
            self._keys[name] = name
            self._key_index[key_count] = name
            self._texkey_index[name] = key_count
            self._uvs[name] = [0., 0., 1., 1.]
            self._groups[name] = [name]
            self._key_count += 1

    def unload_texture(self, name):
        if name not in self._textures:
            raise KeyError()
        else:
            texture_keys = self._groups[name]
            for key in texture_keys:
                key_index = self._keys[name]
                del self._key_index[key_index]
                del self._uvs[key]
                del self._texkey_index[name]
                del self._keys[key]
            del self._groups[name]
            del self._textures[name]

    def get_uvs(self, tex_key):
        try:
            return self._uvs[tex_key]
        except:
            return [0., 0., 1., 1.]

    def get_size(self,tex_key):
        return self._sizes[tex_key]

    def get_texture(self, tex_name):
        return self._textures[tex_name]

    def get_texture_from_key(self, tex_key):
        return self._textures[self._keys[tex_key]]

    def get_texkey_from_index_key(self, index_key):
        return self._key_index[index_key]

    def get_index_key_from_texkey(self, texkey):
        return self._texkey_index[texkey]

    def get_texname_from_texkey(self, tex_key):
        return self._keys[tex_key]

    def get_texkey_in_group(self, tex_key, atlas_name):
        if tex_key is None and atlas_name is None:#should this be or?
            return True
        else:
            return atlas_name in self._groups and tex_key in (
                self._groups[atlas_name])

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
            group_list = []
            group_list_a = group_list.append
            atlas_content = atlas_data[imgname]

            if name in self._textures:
                raise KeyError("'%s' already in textures"%name)
            self._textures[name] = texture
            for key in atlas_content:
                key = str(key)
                kx,ky,kw,kh = atlas_content[key]
                key_index = self._key_count
                self._keys[key] = name
                self._key_index[key_index] = key
                self._texkey_index[key] = key_index
                self._sizes[key] = kw, kh
                x1, y1 = kx, ky
                x2, y2 = x1 + kw, y1 + kh
                self._uvs[key] = [x1/w, 1.-y1/h, x2/w, 1.-y2/h] 
                self._key_count += 1
                group_list_a(str(key))
            self._groups[name] = group_list

texture_manager = TextureManager()
model_manager = ModelManager()