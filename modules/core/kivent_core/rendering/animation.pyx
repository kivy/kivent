from kivent_core.managers.resource_managers cimport ModelManager
from kivent_core.managers.resource_managers import texture_manager
from kivent_core.rendering.model cimport VertexModel
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock


cdef class Frame:
    '''
    The Frame class allows you to access the render information
    for one frame of the animation sequence from python.
    It internally stores a pointer to a FrameStruct and provides
    python apis to access model and texture names of the frame.

    Attributes:
        model (str): The model name to be rendered for this frame
        texture (str): The texture name of the texture to be rendered for this frame.
        duration (int): The duration of this frame.
    '''

    def __cinit__(self, ModelManager model_manager):
        self.model_manager = model_manager

    property model:
        def __get__(self):
            cdef VertexModel model = <VertexModel>self.frame_pointer.model
            return model.name

        def __set__(self, value):
            self.frame_pointer.model = <void*>self.model_manager.models[value]

    property texture:
        def __get__(self):
            return texture_manager.get_texname_from_texkey(self.frame_pointer.texkey)

        def __set__(self, value):
            self.frame_pointer.texkey = texture_manager.get_texkey_from_name(value)

    property duration:
        def __get__(self):
            return self.frame_pointer.duration

        def __set__(self, float value):
            self.frame_pointer.duration = value


cdef class FrameList:
    '''
    The FrameList class is used to store the animation as an
    array of FrameStructs in memory.

    Attributes:
        frames (list): Array of Frame objects corresponding to
        each frame in the sequence.
    '''

    def  __cinit__(self, frame_count, frame_buffer, model_manager, str name):
        self.frame_count = frame_count
        self.model_manager = model_manager
        self.name = name

        cdef MemoryBlock frames_block = MemoryBlock(
            frame_count*sizeof(FrameStruct), sizeof(FrameStruct), 1)
        frames_block.allocate_memory_with_buffer(frame_buffer)
        self.frames_block = frames_block

    def __dealloc__(self):
        if self.frames_block is not None:
            self.frames_block.remove_from_buffer()
            self.frames_block = None
        self.model_manager = None

    def __getitem__(self, unsigned int i):
        cdef unsigned int frame_count = self.frame_count
        if i >= frame_count:
            raise IndexError()

        cdef Frame frame = Frame(self.model_manager)
        frame.frame_pointer = <FrameStruct*>self.frames_block.get_pointer(i)
        return frame

    def free_memory(self):
        if self.frames_block is not None:
            self.frames_block.remove_from_buffer()
            self.frames_block = None

    property frames:
        def __get__(self):
            frame_list = []
            for i in range(self.frame_count):
                frame_list.append(self[i])
            return frame_list

        def __set__(self, list frames):
            cdef unsigned int frame_count = len(frames)
            cdef int i
            cdef dict data
            if frame_count != self.frame_count:
                raise Exception("Provided frames list doesn't match internal size")
            for i in range(frame_count):
                data = frames[i]
                frame = self[i]
                frame.model = data['model']
                frame.texture = data['texture']
                frame.duration = data['duration']
