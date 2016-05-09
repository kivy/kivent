from managers.resource_managers cimport ModelManager, texture_manager
from kivent_core.memory_handlers.membuffer cimport Buffer
from kivent_core.memory_handlers.block cimport MemoryBlock


cdef class Frame:
    cdef FrameStruct* frame_pointer
    cdef ModelManager model_manager

    def __cinit__(self, ModelManager model_manager):
        self.model_manager = model_manager

    property model:
        def __get__(self):
            return self.frame_pointer.model.name

        def __set__(self, value):
            self.frame_pointer.model = <void*>self.model_manager.models[value]

    property texture:
        def __get__(self):
            return texture_manager.get_texname_from_texkey(self.frame_pointer.texkey)

        def __set__(self, str value):
            self.frame_pointer.texkey = texture_manager.get_texkey_from_texname(value)

    property duration:
        def __get__(self):
            return self.frame_pointer.duration

        def __set__(self, unsigned int value):
            self.frame_pointer.duration = value


cdef class FrameList:
    cdef MemoryBlock frames_block
    cdef Buffer frame_buffer
    cdef ModelManager model_manager
    cdef unsigned int _frame_count

    def  __cinit__(self, frame_count, frame_buffer, model_manager):
        self._frame_count = frame_count
        self.model_manager = model_manager

        cdef MemoryBlock frames_block = MemoryBlock(
            frame_count*sizeof(FrameStruct), sizeof(FrameStruct), 1)
        frames_block.allocate_memory_with_buffer(frame_buffer)
        self.frames_block = frames_block

    def __dealloc__(self):
        if self.frames_block is not None:
            self.frames_block.remove_from_buffer()
            self.frames_block = None
        self.frame_buffer = None
        self.model_manager = None

    def __getitem__(self, unsigned int i):
        cdef unsigned int frame_count = self._frame_count
        if i < frame_count:
            raise IndexError()

        cdef Frame frame = Frame(self.model_manager)
        frame.frame_pointer = self.frames_block.get_pointer(i)
        return frame

    def free_memory(self):
        if self.frames_block is not None:
            self.frames_block.remove_from_buffer()
            self.frames_block = None

    property frames:
        def __get__(self):
            frame_list = []
            for i in range(self._frame_count):
                frame_list.append(self[i])
            return frame_list

        def __set__(self, list frames):
            cdef unsigned int frame_count = len(frames)
            cdef int i
            cdef dict data
            if frame_count + 1 != self._frame_count:
                raise Exception("Provided frames list doesn't match internal size")
            for i in range(frame_count + 1):
                data = frames[i]
                frame = self[i]
                frame.model = data['model']
                frame.texture = data['texture']
                frame.duration = data['duration']
