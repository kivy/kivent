__author__ = 'chozabu'

from kivy.core.audio import SoundLoader, Sound

click = SoundLoader.load('assets/wav/click.ogg')
thack = SoundLoader.load('assets/wav/thack.ogg')
jingle = SoundLoader.load('assets/wav/jingle.ogg')
pitchraise = SoundLoader.load('assets/wav/pitchraise.ogg')
spawnpuck = SoundLoader.load('assets/wav/spawnpuck.ogg')
hitlow = SoundLoader.load('assets/wav/hitlow.ogg')
hitmid = SoundLoader.load('assets/wav/hitmid.ogg')
hithigh = SoundLoader.load('assets/wav/hithigh.ogg')


def vol_spawnpuck(vol=1.):
	spawnpuck.volume = vol*.5
def play_spawnpuck(vol=1.):
	spawnpuck.volume = vol*.5
	#if spawnpuck.status != 'play':spawnpuck.play()
	if spawnpuck.status == 'play':spawnpuck.stop()
	spawnpuck.play()

def vol_pitchraise(vol=1.):
	pitchraise.volume = vol*.5
def play_pitchraise(vol=1.):
	pitchraise.volume = vol*.5
	#if pitchraise.status != 'play':pitchraise.play()
	if pitchraise.status == 'play':pitchraise.stop()
	pitchraise.play()

def vol_click(vol=1.):
	click.volume = vol
def play_click(vol=1.):
	click.volume = vol
	#if click.status != 'play':click.play()
	if click.status == 'play':click.stop()
	click.play()

def vol_thack(vol=1.):
	thack.volume = vol*.5
def play_thack(vol=1.):
	thack.volume = vol*.5
	if thack.status == 'play':thack.stop()
	thack.play()
    
def vol_hithigh(vol=1.):
	hithigh.volume = vol*.5
def play_hithigh(vol=1.):
	hithigh.volume = vol*.5
	if hithigh.status == 'play':hithigh.stop()
	hithigh.play()
    
def vol_hitmid(vol=1.):
	hitmid.volume = vol*.5
def play_hitmid(vol=1.):
	hitmid.volume = vol*.5
	if hitmid.status == 'play':hitmid.stop()
	hitmid.play()
    
def vol_hitlow(vol=1.):
	hitlow.volume = vol*.5
def play_hitlow(vol=1.):
	hitlow.volume = vol*.5
	if hitlow.status == 'play':hitlow.stop()
	hitlow.play()

def vol_jingle(vol=1.):
	jingle.volume = vol*.6
def play_jingle(vol=1.):
	jingle.volume = vol*.6
	if jingle.status == 'play':jingle.stop()
	jingle.play()
