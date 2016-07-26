from kivent_core.rendering.model cimport VertexModel
from kivent_core.rendering.vertex_formats cimport VertexFormat2F4UB
from kivent_core.rendering.animation cimport FrameList
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_maps.map_manager cimport MapManager


cdef class LayerTile:
    '''
    LayerTile represents data for one layer of a Tile - position and texture
    '''

    def __cinit__(self, 
                  ModelManager model_manager, 
                  AnimationManager animation_manager, 
                  unsigned int layer):
        self.model_manager = model_manager
        self.animation_manager = animation_manager
        self.layer = layer

    property model:
        def __get__(self):
            cdef VertexModel model = <VertexModel>self.tile_pointer.model
            return model.name

        def __set__(self, value):
            self.tile_pointer.model = <void*>self.model_manager.models[value]

    property texture:
        def __get__(self):
            return texture_manager.get_texname_from_texkey(self.tile_pointer.texkey)

        def __set__(self, value):
            self.tile_pointer.texkey = texture_manager.get_texkey_from_name(value)

    property animation:
        def __get__(self):
            cdef FrameList animation
            if self.tile_pointer.animation != NULL:
                animation = <FrameList>self.tile_pointer.animation
                return animation.name
            else:
                return False

        def __set__(self, str value):
            if value is not None:
                self.tile_pointer.animation = <void*>self.animation_manager.animations[value]
            else:
                self.tile_pointer.animation = NULL

    property layer:
        def __get__(self):
            return self.layer


cdef class Tile:
    '''
    Tile represents the layer data for a tile on the map
    '''

    def __cinit__(self, ModelManager model_manager,
                  AnimationManager animation_manager,
                  unsigned int layer_count):
        self.model_manager = model_manager
        self.animation_manager = animation_manager
        self.layer_count = layer_count

    def get_layer_tile(self, unsigned int layer):
        tile = LayerTile(self.model_manager, self.animation_manager, layer)
        tile.tile_pointer = &(self._layers[layer])

        return tile

    property layers:
        def __get__(self):
            l = []
            cdef LayerTile tile

            for i in range(self.layer_count):
                tile = LayerTile(self.model_manager, self.animation_manager, i)
                tile.tile_pointer = &(self._layers[i])                    
                if (tile.tile_pointer.model != NULL 
                    or tile.tile_pointer.animation != NULL):
                    l.append(tile)
            return l


cdef class LayerObject:
    '''
    LayerObject represents data for one of ObjectGroup - position and texture
    '''

    def __cinit__(self, ModelManager model_manager):
        self.model_manager = model_manager

    property model:
        def __get__(self):
            cdef VertexModel model = <VertexModel>self.obj_pointer.model
            return model.name

        def __set__(self, value):
            self.obj_pointer.model = <void*>self.model_manager.models[value]

    property texture:
        def __get__(self):
            if self.obj_pointer.texkey > 0:
                return texture_manager.get_texname_from_texkey(
                                            self.obj_pointer.texkey)
            else:
                return None

        def __set__(self, value):
            self.obj_pointer.texkey = texture_manager.get_texkey_from_name(value)

    property position:
        def __get__(self):
            return (self.obj_pointer.x, self.obj_pointer.y)
        def __set__(self, value):
            self.obj_pointer.x = value[0]
            self.obj_pointer.y = value[1]

    property layer:
        def __get__(self):
            return self.layer

    property color:
        def __get__(self):
            cdef VertexModel model = <VertexModel>self.obj_pointer.model
            cdef VertexFormat2F4UB* vertex = \
                    <VertexFormat2F4UB*>model.vertices_block.data
            return (vertex.v_color[0], vertex.v_color[1], vertex.v_color[2], vertex.v_color[3])


cdef class TileMap:
    '''
    TileMap stores tiles for all positions
    '''

    def  __cinit__(self, unsigned int size_x, unsigned int size_y,
                   unsigned int tile_layer_count, unsigned int object_count,
                   MemoryBlock tile_buffer,
                   ModelManager model_manager,
                   AnimationManager animation_manager,
                   str name):
        self.size_x = size_x
        self.size_y = size_y
        self.tile_layer_count = tile_layer_count
        self.object_count = object_count
        self.name = name
        self.model_manager = model_manager
        self.animation_manager = animation_manager

        cdef MemoryBlock tiles_block = MemoryBlock(
            size_x * size_y * tile_layer_count * sizeof(TileStruct), 
            tile_layer_count * sizeof(TileStruct), 1)
        tiles_block.allocate_memory_with_buffer(tile_buffer)
        self.tiles_block = tiles_block

        cdef MemoryBlock objects_block = MemoryBlock(
            object_count * sizeof(ObjStruct), 
            sizeof(ObjStruct), 1)
        objects_block.allocate_memory_with_buffer(tile_buffer)
        self.objects_block = objects_block

    def __dealloc__(self):
        if self.tiles_block is not None:
            self.tiles_block.remove_from_buffer()
            self.tiles_block = None
        if self.objects_block is not None:
            self.objects_block.remove_from_buffer()
            self.objects_block = None

    def get_tile(self, unsigned int x, unsigned int y, bint empty=False):
        if x >= self.size_x and y >= self.size_y:
            raise IndexError()

        cdef Tile tile = Tile(self.model_manager, self.animation_manager,
                                self.tile_layer_count)
        tile._layers = <TileStruct*>self.tiles_block.get_pointer(x*self.size_x + y)

        cdef TileStruct tile_data
        if empty:
            for i in range(self.tile_layer_count):
                tile_data = tile._layers[i]
                tile_data.model = NULL
                tile_data.texkey = 0
                tile_data.animation = NULL

        return tile

    def get_object(self, unsigned int n, bint empty=False):
        if n >= self.object_count:
            raise IndexError()

        cdef LayerObject obj = LayerObject(self.model_manager)
        obj_data = <ObjStruct*>self.objects_block.get_pointer(n)

        if empty:
            obj_data.model = NULL
            obj_data.texkey = 0

        obj.obj_pointer = obj_data
        return obj

    def free_memory(self):
        if self.tiles_block is not None:
            self.tiles_block.remove_from_buffer()
            self.tiles_block = None
        if self.objects_block is not None:
            self.objects_block.remove_from_buffer()
            self.objects_block = None

    property tiles:
        def __get__(self):
            tile_list = []
            for i in range(self.size_x):
                tile_row = []
                for j in range(self.size_y):
                    tile_row.append(self.get_tile(i,j))
                tile_list.append(tile_row)

        def __set__(self, list tiles):
            cdef unsigned int size_x = len(tiles)
            cdef unsigned int size_y = len(tiles[0])
            cdef FrameList frames

            if size_x != self.size_x or size_y != self.size_y:
                raise Exception("Provided tiles list does not match internal size")
            for i in range(size_x):
                for j in range(size_y):
                    tile_layers = self.get_tile(i,j, True)
                    layer_data = tiles[i][j]

                    for data in layer_data:
                        tile = tile_layers.get_layer_tile(data['layer'])
                        if 'animation' in data:
                            frames = self.animation_manager.animations[data['animation']]
                            tile.animation = data['animation']
                            tile.texture = frames[0].texture
                            tile.model = frames[0].model
                        else:
                            tile.texture = data['texture']
                            tile.model = data['model']

    property objects:
        def __set__(self, list objs):
            cdef unsigned int layers = len(objs)
            cdef unsigned int obj_count = 0
            cdef LayerObject obj

            self._obj_layers_index = []

            for i in range(layers):
                self._obj_layers_index.append(obj_count)

                for obj_data in objs[i]:
                    obj = self.get_object(obj_count, True)
                    if 'texture' in obj_data:
                        obj.texture = obj_data['texture']
                    obj.model = obj_data['model']
                    obj.position = obj_data['position']
                    obj.layer = i + self.tile_layer_count

                    obj_count += 1
            self.obj_layer_count = layers
            self._obj_layers_index.append(obj_count)
        def __get__(self):
            cdef unsigned int layer_size
            cdef unsigned int pos
            cdef LayerObject obj

            objs = []
            for i in range(self.obj_layer_count):
                obj_layer = []
                layer_size = (self._obj_layers_index[i+1] - 
                                self._obj_layers_index[i])

                for j in range(layer_size):
                    pos = self._obj_layers_index[i] + j
                    obj = self.get_object(pos)
                    obj.layer = i + self.tile_layer_count
                    obj_layer.append(obj)

                objs.append(obj_layer)
            return objs

    property z_index_map:
        def __get__(self):
            return self._z_index_map
        def __set__(self, list value):
            self._z_index_map = value

    property size:
        def __get__(self):
            return (self.size_x, self.size_y)

    property size_on_screen:
        def __get__(self):
            sx, sy = self.size_x, self.size_y
            tw, th = self.tile_size_x, self.tile_size_y
            o = self.orientation
            sa = self.stagger_axis

            if o == 'orthogonal':
                return (sx * tw,
                        sy * th)
            elif o in ('staggered', 'hexagonal'):
                ts = (self.hex_side_length if o == 'hexagonal' else 0)
                if sa:
                    return ((sx - 1) * (tw + ts)/2 + tw,
                            sy * th + th/2)
                else:
                    return (sx * tw + tw/2,
                            (sy - 1) * (th + ts)/2 + th)
            elif o == 'isometric':
                s = max(sx, sy)
                return (s * tw, s * th) 

    property tile_size:
        def __get__(self):
            return (self.tile_size_x, self.tile_size_y)
        def __set__(self, tuple value):
            self.tile_size_x = value[0]
            self.tile_size_y = value[1]

    property name:
        def __get__(self):
            return self.name

    property orientation:
        def __get__(self):
            return self.orientation
        def __set__(self, str value):
            self.orientation = value

    property hex_side_length:
        def __get__(self):
            return self.hex_side_length
        def __set__(self, unsigned int value):
            self.hex_side_length = value

    property stagger_index:
        def __get__(self):
            return 'even' if self.stagger_index else 'odd'
        def __set__(self, str value):
            self.stagger_index = value == 'even'

    property stagger_axis:
        def __get__(self):
            return 'x' if self.stagger_axis else 'y'
        def __set__(self, str value):
            self.stagger_axis = value == 'x'

    
