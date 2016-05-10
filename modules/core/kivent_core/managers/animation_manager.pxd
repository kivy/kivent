from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.game_manager cimport GameManager


cdef class AnimationManager(GameManager):
    cdef MemoryBlock memory_block
    cdef ModelManager model_manager
    cdef unsigned int allocation_size
    cdef dict _animations
