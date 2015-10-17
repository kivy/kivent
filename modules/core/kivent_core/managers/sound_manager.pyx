from kivy.core.audio import SoundLoader
from kivy._event cimport EventDispatcher
from kivy.clock import Clock

cdef class SoundManager(EventDispatcher):

    def __init__(self, **kwargs):
        super(SoundManager, self).__init__(**kwargs)
        self.sound_dict = {}
        self.sound_keys = {}
        self.sound_count = 0
        
    def load_sound(self, sound_name, file_address, count=5):
        count = self.sound_count
        sound_list = []
        self.sound_dict[count] = {
            'file_address': file_address,
            'sounds': sound_list,
        } 
        for x in range(count):
            sound = SoundLoader.load(file_address)
            sound.seek(0)
            sound.bind(on_stop=self.reset_sound_position)
            sound_list.append(sound)
        self.sound_keys[sound_name] = count
        self.sound_count += 1

        return count

    cpdef play_direct(self, int sound_index):
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        for each in sounds:
            if each.state == 'play':
                continue
            else:
                each.play()
                return

    def stop_direct(self, sound_index):
        self.sound_dict[sound_index].stop()

    def reset_sound_position(self, sound):
        sound.seek(0)

    def schedule_play(self, sound_name, dt):
        self.play(sound_name)

    def play(self, sound_name):
        self.sound_dict[self.sound_keys[sound_name]].play()

    def stop(self, sound_name):
        self.sound_dict[self.sound_keys[sound_name]].stop()
