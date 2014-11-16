__author__ = 'chozabu'

from kivy.core.audio import SoundLoader, Sound

click = SoundLoader.load('assets/wav/click.wav')
thack = SoundLoader.load('assets/wav/thack.wav')
jingle = SoundLoader.load('assets/wav/jingle.wav')
pitchraise = SoundLoader.load('assets/wav/pitchraise.wav')


def vol_pitchraise(vol=1.):
	pitchraise.volume = vol
def play_pitchraise(vol=1.):
	pitchraise.volume = vol
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
	thack.volume = vol
def play_thack(vol=1.):
	thack.volume = vol
	if thack.status == 'play':thack.stop()
	thack.play()

def vol_jingle(vol=1.):
	jingle.volume = vol
def play_jingle(vol=1.):
	jingle.volume = vol
	if jingle.status == 'play':jingle.stop()
	jingle.play()
