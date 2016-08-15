from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.animation_manager cimport AnimationManager
from kivent_core.managers.game_manager cimport GameManager
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_maps.map_data cimport TileMap, StaggeredTileMap, \
        HexagonalTileMap, IsometricTileMap
from kivy.compat import PY2


cdef class MapManager(GameManager):
    '''
    Manages memory allocation and assigment of map data like the TileStructs
    and ObjStructs.

    **Attributes:**
        **maps** (dict): A dictionary matching names of the map to TileMaps

    **Attributes (Cython Access Only):**
        **maps_block** (MemoryBlock): The memory block which stores the structs
        for a TileMap.

        **animation_manager** (AnimationManager): instance of the gameworld's
        animation_manager to be used by TileMaps for obtaining animation info.

        **model_manager** (ModelManager): instance of the gameworld's
        model_manager for obtaining rendering info.

        **allocation_size** (unsigned int): Size of maps_block
    '''

    def __init__(self, ModelManager model_manager,
                 AnimationManager animation_manager, allocation_size=1024*500):
        self.model_manager = model_manager
        self.animation_manager = animation_manager
        self.allocation_size = allocation_size
        self._maps = {}

    def allocate(self, master_buffer, gameworld):
        cdef MemoryBlock maps_block = MemoryBlock(self.allocation_size, 1, 1)
        maps_block.allocate_memory_with_buffer(master_buffer)
        self.maps_block = maps_block

        return self.allocation_size

    def load_map(self, str name,
                 unsigned int map_size_x, unsigned int map_size_y,
                 tiles=None, unsigned int tile_layers=1,
                 objects=None, unsigned int object_count=0,
                 str orientation='orthogonal'):
        '''
        Loads a TileMap object from tiles and objects in the specified list of
        dicts format. If they aren't specified it just allocates space in
        maps_block for the required tile layers amd objects.

        Args:
            map_size_x (unsigned int): number of rows

            map_size_y (unsigned int): number of cols

            tiles (list): 3d list of dicts containg data of the tiles. See
            TileMap for the format. Will not be set in the TileMap if None.

            tile_layers (unsigned int): the number of layers.
            
            objects (list): 3d list of dicts containg data of the tiles. See
            TileMap for the format. Will not be set in the TileMap if None.

            object_count (unsigned int): number of objects which would be added

            orientation (str): Orientation of the map tiles. Can be one of
            'orthogonal', 'staggered', 'hexagonal', 'isometric'
        '''
        if PY2:
            name = name.encode('utf-8')
        cdef TileMap tile_map
        cdef list largs = [map_size_x, map_size_y,
                           tile_layers, object_count,
                           self.maps_block, 
                           self.model_manager, 
                           self.animation_manager, 
                           name]
        
        if orientation == 'orthogonal':
            tile_map = TileMap(*largs)
        elif orientation == 'staggered':
            tile_map = StaggeredTileMap(*largs)
        elif orientation == 'hexagonal':
            tile_map = HexagonalTileMap(*largs)
        elif orientation == 'isometric':
            tile_map = IsometricTileMap(*largs)

        if tiles:
            tile_map.tiles = tiles
        if objects:
            tile_map.objects = objects
        self._maps[name] = tile_map

    property maps:
        def __get__(self):
            return self._maps
