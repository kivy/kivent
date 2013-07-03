from kivy.clock import Clock
from kivy.properties import StringProperty
import random
from kivy.core.audio import SoundLoader
from kivy.uix.widget import Widget

class MusicController(Widget):
    music_dir = StringProperty('assets/music/final/')
    def __init__(self, **kwargs):
        super(MusicController, self).__init__(**kwargs)
        self.music_dict = {}
        self.track_names = ['track1', 'track2', 'track3', 'track4', 'track5']
        Clock.schedule_once(self.load_music)
        
    def load_music(self, dt):
        print 'loading music'
        print self.music_dir
        track_names = self.track_names
        music_dict = self.music_dict
        for track_name in track_names:
            music_dict[track_name] = SoundLoader.load(self.music_dir + track_name + '.ogg')
            music_dict[track_name].seek(0)

    def play_new_song(self, dt):
        self.play(random.choice(self.track_names))

    def schedule_choose_new_song(self, value):
        value.seek(0)
        start_delay = random.random() * 20.0
        print start_delay, 'start delay'
        Clock.schedule_once(self.play_new_song, start_delay)

    def play(self, sound_name):
        if sound_name in self.music_dict:
            self.music_dict[sound_name].play()
            self.music_dict[sound_name].bind(on_stop=self.schedule_choose_new_song)
        else:
            print "file",sound_name,"not found in", self.music_dir

    def stop(self, sound_name):
        if sound_name in self.music_dict:
            self.music_dict[sound_name].stop()
        else:
            print "file", sound_name, "not found in", self.music_dir

