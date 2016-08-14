from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.animation_manager cimport AnimationManager
from kivent_core.memory_handlers.block cimport MemoryBlock


ctypedef struct TileStruct:
    void* model
    unsigned int texkey
    void* animation

ctypedef struct ObjStruct:
    void* model
    unsigned int texkey
    unsigned int x
    unsigned int y

cdef class LayerTile:
    cdef TileStruct* tile_pointer
    cdef ModelManager model_manager
    cdef AnimationManager animation_manager
    cdef unsigned int layer

cdef class LayerObject:
    cdef ObjStruct* obj_pointer
    cdef ModelManager model_manager
    cdef unsigned int layer

cdef class Tile:
    cdef TileStruct* _layers
    cdef ModelManager model_manager
    cdef AnimationManager animation_manager
    cdef unsigned int layer_count

cdef class TileMap:
    cdef MemoryBlock tiles_block
    cdef MemoryBlock objects_block
    cdef ModelManager model_manager
    cdef AnimationManager animation_manager
    cdef str name
    cdef unsigned int size_x
    cdef unsigned int size_y
    cdef unsigned int tile_size_x
    cdef unsigned int tile_size_y
    cdef unsigned int tile_layer_count
    cdef unsigned int obj_layer_count
    cdef unsigned int object_count
    cdef list _z_index_map
    cdef list _obj_layers_index

cdef class StaggeredTileMap(TileMap):
    cdef bint _stagger_index # True for Even, False for Odd
    cdef bint _stagger_axis # True for X, False for Y

cdef class HexagonalTileMap(StaggeredTileMap):
    cdef unsigned int hex_side_length

cdef class IsometricTileMap(TileMap):
    pass

