from kivent_core.rendering.model cimport VertexModel
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


cdef class TileMap:
    '''
    TileMap stores tiles for all positions
    '''

    def  __cinit__(self, map_size, tile_size, layer_count,
                   tile_buffer, model_manager, animation_manager, name):
        self.size_x = map_size[0]
        self.size_y = map_size[1]
        self.tile_size = tile_size
        self.layer_count = layer_count
        self.name = name
        self.model_manager = model_manager
        self.animation_manager = animation_manager

        cdef MemoryBlock tiles_block = MemoryBlock(
            map_size[0] * map_size[1] * layer_count * sizeof(TileStruct), 
            layer_count * sizeof(TileStruct), 1)
        tiles_block.allocate_memory_with_buffer(tile_buffer)
        self.tiles_block = tiles_block

    def __dealloc__(self):
        if self.tiles_block is not None:
            self.tiles_block.remove_from_buffer()
            self.tiles_block = None

    def get_tile(self, unsigned int x, unsigned int y, bint empty=False):
        if x >= self.size_x and y >= self.size_y:
            raise IndexError()

        cdef Tile tile = Tile(self.model_manager, self.animation_manager, self.layer_count)
        tile._layers = <TileStruct*>self.tiles_block.get_pointer(x*self.size_x + y)

        cdef TileStruct tile_data
        if empty:
            for i in range(self.layer_count):
                tile_data = tile._layers[i]
                tile_data.model = NULL
                tile_data.texkey = 0
                tile_data.animation = NULL

        return tile

    def free_memory(self):
        if self.tiles_block is not None:
            self.tiles_block.remove_from_buffer()
            self.tiles_block = None

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


    property size:
        def __get__(self):
            return (self.size_x, self.size_y)

    property size_on_screen:
        def __get__(self):
            return (self.size_x * self.tile_size, self.size_y * self.tile_size)

    property tile_size:
        def __get__(self):
            return self.tile_size

    property name:
        def __get__(self):
            return self.name
