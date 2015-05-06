__author__ = 'chozabu'

from kivy.core.audio import SoundLoader, Sound

volume_multi = .75

click = SoundLoader.load('assets/wav/click.ogg')
thack = SoundLoader.load('assets/wav/thack.ogg')
jingle = SoundLoader.load('assets/wav/jingle.ogg')
beeeew = SoundLoader.load('assets/wav/beeeew.ogg')
pitchraise = SoundLoader.load('assets/wav/pitchraise.ogg')
spawnpuck = SoundLoader.load('assets/wav/spawnpuck.ogg')
hitlow = SoundLoader.load('assets/wav/hitlow.ogg')
hitmid = SoundLoader.load('assets/wav/hitmid.ogg')
hithigh = SoundLoader.load('assets/wav/hithigh.ogg')

def play_beeeew(vol=1.):
	beeeew.volume = vol*volume_multi
	#if beeeew.status != 'play':beeeew.play()
	if beeeew.status == 'play':beeeew.stop()
	beeeew.play()

def vol_spawnpuck(vol=1.):
	spawnpuck.volume = vol*volume_multi
def play_spawnpuck(vol=1.):
	spawnpuck.volume = vol*volume_multi
	#if spawnpuck.status != 'play':spawnpuck.play()
	if spawnpuck.status == 'play':spawnpuck.stop()
	spawnpuck.play()

def vol_pitchraise(vol=1.):
	pitchraise.volume = vol*volume_multi
def play_pitchraise(vol=1.):
	pitchraise.volume = vol*volume_multi
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
	thack.volume = vol*volume_multi
def play_thack(vol=1.):
	thack.volume = vol*volume_multi
	if thack.status == 'play':thack.stop()
	thack.play()
    
def vol_hithigh(vol=1.):
	hithigh.volume = vol*volume_multi
def play_hithigh(vol=1.):
	hithigh.volume = vol*volume_multi
	if hithigh.status == 'play':hithigh.stop()
	hithigh.play()
    
def vol_hitmid(vol=1.):
	hitmid.volume = vol*volume_multi
def play_hitmid(vol=1.):
	hitmid.volume = vol*volume_multi
	if hitmid.status == 'play':hitmid.stop()
	hitmid.play()
    
def vol_hitlow(vol=1.):
	hitlow.volume = vol*volume_multi
def play_hitlow(vol=1.):
	hitlow.volume = vol*volume_multi
	if hitlow.status == 'play':hitlow.stop()
	hitlow.play()

def vol_jingle(vol=1.):
	jingle.volume = vol*volume_multi
def play_jingle(vol=1.):
	jingle.volume = vol*volume_multi
	if jingle.status == 'play':jingle.stop()
	jingle.play()
