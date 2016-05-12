from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.rendering.animation cimport FrameList
from kivent_core.managers.game_manager cimport GameManager


cdef class AnimationManager(GameManager):

    def __init__(self, allocation_size=1024*10):
        self.allocation_size = allocation_size
        self.memory_block = None
        self._animations = {}

    def allocate(self, master_buffer, gameworld):
        self.model_manager = gameworld.managers["model_manager"]

        cdef MemoryBlock memory_block = MemoryBlock(self.allocation_size, 1, 1)
        memory_block.allocate_memory_with_buffer(master_buffer)
        self.memory_block = memory_block

        return self.allocation_size

    def load_animation(self, name, frame_count, frames=None):
        cdef FrameList frame_list = FrameList(frame_count,
                                            self.memory_block,
                                            self.model_manager,
                                            name)

        if frames:
            frame_list.frames = frames
        self._animations[name] = frame_list

    property animations:
        def __get__(self):
            return self._animations
