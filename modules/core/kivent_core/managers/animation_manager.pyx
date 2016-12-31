from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.memory_handlers.block cimport MemoryBlock
from kivent_core.rendering.animation cimport FrameList
from kivent_core.managers.game_manager cimport GameManager
from kivy.compat import PY2

import json
import os


cdef class AnimationManager(GameManager):
    '''
    AnimationManager is responsible for loading and managing animation
    sequences for the GameWorld. Each animation sequence is a list of frames
    which stores texture and model for that frame and the duration for which
    the frame should be displayed in milliseconds

    Animation data takes the form:
    {
        'texture': texture name for animation,
        'model' : model name for animation,
        'duration' : time 
    }

    Attributes:
        animations: Dictionary of loaded animations, keyed by name
    '''

    def __init__(self, allocation_size=1024*10):
        self.allocation_size = allocation_size
        self.memory_block = None
        self._animations = {}

    def allocate(self, master_buffer, gameworld):
        '''
        Allocate memory to store frame lists. Called internally during
        gameworld init.
        '''

        self.model_manager = gameworld.managers["model_manager"]

        cdef MemoryBlock memory_block = MemoryBlock(self.allocation_size, 1, 1)
        memory_block.allocate_memory_with_buffer(master_buffer)
        self.memory_block = memory_block

        return self.allocation_size

    def load_animation(self, name, frame_count, frames=None):
        '''
        Responsible for creating a FrameList from a python
        list specifying frames and storing it in static memory.

        Args:
            name (str): The name by which to store this animation

            frame_count (int): Number of frames in the sequence

            frames (list): The list of frames, each item in the list
            is a dict containing 'texture','model' and 'duration'.
        '''

        if PY2:
            name = name.encode('utf-8')

        cdef FrameList frame_list = FrameList(frame_count,
                                            self.memory_block,
                                            self.model_manager,
                                            name)

        if frames:
            frame_list.frames = frames
        self._animations[name] = frame_list

    def load_json(self, filename):
        '''
        Parser for a json file containing animation
        '''
        with open(filename) as anim_file:
            animations = json.load(anim_file)
            for name in animations:
                frames = animations[name]
                self.load_animation(name, len(frames), frames)

    def save_to_json(self, names, filename):
        '''
        Saves the animation specified by items in `names` to `filename`

        Parameters:
            names (list): List of animation names to be stored in
            the json file

            filename (str): Path to json file
        '''
        if os.path.isfile(filename):
            with open(filename) as json_file:
                json_obj = json.load(json_file)
        else:
            json_obj = {}

        for name in names:
            json_obj[name] = [{'model':frame.model,
                            'texture':frame.texture,
                            'duration':frame.duration}
                            for frame in self.animations[name].frames]

        with open(filename, 'w+') as json_file:
            json.dump(json_obj, json_file)

    property animations:
        def __get__(self):
            return self._animations
