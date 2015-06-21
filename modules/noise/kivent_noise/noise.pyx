from kivent_noise cimport cnoise

def scaled_octave_noise_2d(float octaves, float persistence, float scale, 
	float lo_bound, float hi_bound, float x, float y):
	return cnoise.scaled_octave_noise_2d(octaves, persistence, scale, lo_bound,
		hi_bound, x, y)
