from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.animation_manager cimport AnimationManager
from kivent_core.memory_handlers.block cimport MemoryBlock


ctypedef struct TileStruct:
    void* model
    unsigned int texkey
    void* animation

cdef class LayerTile:
    cdef TileStruct* tile_pointer
    cdef ModelManager model_manager
    cdef AnimationManager animation_manager
    cdef unsigned int layer

cdef class Tile:
    cdef TileStruct* _layers
    cdef ModelManager model_manager
    cdef AnimationManager animation_manager
    cdef unsigned int layer_count

cdef class TileMap:
    cdef MemoryBlock tiles_block
    cdef ModelManager model_manager
    cdef AnimationManager animation_manager
    cdef str name
    cdef unsigned int size_x
    cdef unsigned int size_y
    cdef unsigned int tile_size
    cdef unsigned int layer_count
