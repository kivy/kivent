from kivy._event cimport EventDispatcher

cdef class SoundManager(EventDispatcher):
    cdef dict sound_dict
    cdef dict sound_keys
    cdef int sound_count
    cpdef play_direct(self, int sound_index)