from kivy.core.audio import SoundLoader
from kivy._event cimport EventDispatcher
from kivy.clock import Clock

cdef class SoundManager(EventDispatcher):

    def __init__(self, **kwargs):
        super(SoundManager, self).__init__(**kwargs)
        self.sound_dict = {}
        self.sound_keys = {}
        self.sound_count = 0
        
    def load_sound(self, sound_name, file_address, track_count=4):
        count = self.sound_count
        sound_list = []
        self.sound_dict[count] = {
            'file_address': file_address,
            'sounds': sound_list,
        } 
        for x in range(track_count):
            sound = SoundLoader.load(file_address)
            sound_list.append(sound)
        self.sound_keys[sound_name] = count
        self.sound_count += 1

        return count

    cpdef play_direct(self, int sound_index, float volume):
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        for each in sounds:
            if each.state == 'play':
                continue
            else:
                each.volume = volume
                each.play()
                return each
        else:
            return None

    cpdef play_direct_loop(self, int sound_index, float volume):
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        for each in sounds:
            if each.state == 'play':
                continue
            else:
                each.volume = volume
                each.loop = True
                each.play()
                return each
        else:
            return None

    def stop_direct(self, sound_index):
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        for each in sounds:
            each.stop()
            each.loop = False

    def schedule_play(self, sound_name, volume, dt):
        self.play(sound_name, volume=volume)

    def play(self, sound_name, volume=1.):
        self.play_direct(self.sound_keys[sound_name], volume)

    def play_loop(self, sound_name, volume=1.):
        self.play_direct_loop(self.soud_keys[sound_name], volume)

    def stop(self, sound_name):
        self.stop_direct(self.sound_keys[sound_name])