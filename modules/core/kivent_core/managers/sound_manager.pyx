from kivy.core.audio import SoundLoader
from kivy._event cimport EventDispatcher
from kivy.clock import Clock
from kivy.properties import NumericProperty, StringProperty, BooleanProperty
from random import choice, uniform
from kivent_core.managers.game_manager cimport GameManager

cdef class SoundManager(GameManager):
    '''
    The SoundManager provides additional features on top of Kivy's Sound and
    SoundLoader classes, making it easier for you to integrate sounds into
    your game, and controlling the ability to play the same sound multiple
    times simultaneously.

    **Attributes:**
        **music_volume** (NumericProperty): The master volume from 0.0 to 1.0
        for music tracks.

        **sound_volume** (NumericProperty): The master volume from 0.0 to 1.0
        for sounds. Will be multiplied by the specified volume.

        **cutoff** (NumericProperty): If volume is below this level the sound
        will not be played at all.

        **current_track** (StringProperty): The name of the music track
        currently playing.

        **loop_music** (BooleanProperty): If True when one music track finishes
        playing another will be randomly chosen from the loaded music tracks
        and scheduled for playing between 0 and **max_wait_for_music** seconds
        from now.

        **max_wait_for_music** (NumericProperty): The maximum amount of time
        to wait before automatically playing another music track when
        **loop_music** is True.
        
        **music_dict** (dict): Dictionary containing all tracks loaded
        by **load_music**. 

    '''
    music_volume = NumericProperty(.6)
    sound_volume = NumericProperty(.6)
    cutoff = NumericProperty(.015)
    current_track = StringProperty(None, allownone=True)
    max_wait_for_music = NumericProperty(30.)
    loop_music = BooleanProperty(False)

    def __init__(self, **kwargs):
        super(SoundManager, self).__init__(**kwargs)
        self.sound_dict = {}
        self.music_dict = {}
        self.sound_keys = {}
        self.sound_count = 0

    property music_dict:
        def __get__(self):
            return self.music_dict

    def load_music(self, track_name, file_address):
        '''
        Loads a music track under the provided name from the provided address.
        The entry into **music_dict** will be a dict containing both the track
        object loaded by SoundLoader and the file_address, found under those 
        keys.

        Args:
            track_name (string): Name to load music under.

            file_address (string): Location of the file.

        Return:
            string: The name of the track that has been loaded, will be same
            as provided arg.

        '''
        track = SoundLoader.load(file_address)
        track.bind(on_stop=self.on_track_stop)
        self.music_dict[track_name] = {
            'file_address': file_address,
            'track': track
        }
        return track_name

    def on_track_stop(self, sound):
        '''
        Callback called when on_stop event is fired after a music track
        quites playing. If **loop_music** is True another music track will
        be chosen and begin playing in a randomized amount of time from
        0.0 to **max_wait_for_music** seconds later.

        Args:
            sound (Sound): The track object that just finished playing.

        Return:
            None

        '''
        if self.loop_music:
            Clock.schedule_once(
                lambda dt: self.play_track(
                    choice(list(self.music_dict.keys()))),
                uniform(0., self.max_wait_for_music)
                )
            
    def on_music_volume(self, instance, value):
        '''
        Callback called when music_volume is changed, will change volume for
        the **current_track** if it is not None.

        Args:
            instance (SoundManager): Should be same as self.

            value (float): The new value for the volume.

        Return:
            None

        '''
        if self.current_track is not None:
            self.music_dict[self.current_track]['track'].volume = value

    def play_track(self, track_name):
        '''
        Plays the track with the given name. If a previous track is playing,
        **current_track** is not None, then that track will be stopped.

        Args:
            track_name (string): The name of the track to play

        Return:
            None

        '''
        track = self.music_dict[track_name]['track']
        if self.current_track is not None:
            self.stop_current_track()
        track.volume = self.music_volume
        track.play()
        self.current_track = track_name

    def stop_current_track(self):
        '''
        Stops the current music track from playing.

        Return:
            None

        '''
        self.music_dict[self.current_track]['track'].stop()
        self.current_track = None

        
    def load_sound(self, sound_name, file_address, track_count=4):
        '''
        Loads a sound, will load track_count copies of the sound so that 
        up to that many sounds can be played at the same time. Actual number
        of sounds played will be limited by the number of sound channels
        available. Returns the integer identifier for the sound to be used
        with the higher performance **play_direct**, **play_direct_loop**, 
        and **stop_direct** functions as well as making it easier to 
        store sounds in high performance C components for your entities.

        Args:
            sound_name (str): The name to load the sound file under.

            file_address (Str): The actual location of the file in memory.

        Kwargs:
            track_count (int): The number of times to load the sound,
            equivalent to the maximum number of instances of this sound
            can be played simultaneously. Defaults to 4.

        Return:
            int: the integer identifier for the loaded sound.

        '''
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
        '''
        Plays the sound specified by the integer key given at the volume
        provided. If volume is below **cutoff**, the sound will not be played.
        If a sound is played, the specific instance of the sound will be
        returned, otherwise None.

        Args:
            sound_index (int): The integer key for the sound to be played.

            volume (float): The volume to play the sound at, will be
            multiplied by the **sound_volume**

        Return:
            Sound: The instance of the sound being played. Will be None if 
            no sound was played.

        '''
        if volume <= self.cutoff:
            return None
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        for each in sounds:
            if each.state == 'play':
                continue
            else:
                each.volume = volume * self.sound_volume
                each.play()
                return each
        else:
            return None

    cpdef play_direct_loop(self, int sound_index, float volume):
        '''
        Plays the sound specified by the integer key given at the volume
        provided. If volume is below **cutoff**, the sound will not be played.
        If a sound is played, the specific instance of the sound will be
        returned, otherwise None. The sound's loop property will be set to True

        Args:
            sound_index (int): The integer key for the sound to be played.

            volume (float): The volume to play the sound at, will be
            multiplied by the **sound_volume**

        Return:
            Sound: The instance of the sound being played. Will be None if no
            sound was played.

        '''
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        if volume <= self.cutoff:
            return None
        for each in sounds:
            if each.state == 'play':
                continue
            else:
                each.volume = volume * self.sound_volume
                each.loop = True
                each.play()
                return each
        else:
            return None

    cpdef stop_direct(self, int sound_index):
        '''
        Stops all instances of the sound being played. Sets loop to False
        Args:
            sound_index (int): The integer key for the sound to be played.

        Return:
            None

        '''
        cdef list sounds = self.sound_dict[sound_index]['sounds']
        for each in sounds:
            each.stop()
            each.loop = False

    def schedule_play(self, sound_name, volume, dt):
        '''
        Callback for playing a sound by string key for use with Clock.schedule.

        Args:
            sound_name (string): The string name of the sound.

            volume (float): The volume of sound, between 0.0 and 1.0.

            dt (float): The time passed since this function was clock 
            scheduled.

        Return:
            None

        '''
        self.play(sound_name, volume=volume)

    def play(self, sound_name, volume=1.):
        '''
        Wrapper over play_direct that uses the string key for a sound instead
        of integer key. 

        Args:
            sound_name (string): The string key for the sound to be played.

            volume (float): The volume of sound, between 0.0 and 1.0.

        Return:
            Sound: The instance of the sound being played. Will be None if no
            sound was played.

        '''
        return self.play_direct(self.sound_keys[sound_name], volume)

    def play_loop(self, sound_name, volume=1.):
        '''
        Wrapper over play_direct_loop that uses the string key for a sound
        instead of integer key. The sound will be set to looping.

        Args:
            sound_name (string): The string key for the sound to be played.

            volume (float): The volume of sound, between 0.0 and 1.0.

        Return:
            Sound: The instance of the sound being played. Will be None if no
            sound was played.
            
        '''
        self.play_direct_loop(self.sound_keys[sound_name], volume)

    def stop(self, sound_name):
        '''
        Wrapper over stop_direct that uses a string key for a sound instead of
        integer key. Stops all instances of the sound being played.
        Sets loop to False

        Args:
            sound_name (string): The string key for the sound to be played.

        Return:
            None
            
        '''
        self.stop_direct(self.sound_keys[sound_name])
