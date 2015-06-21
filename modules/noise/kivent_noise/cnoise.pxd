cdef extern from "simplexnoise.h":
	cdef float scaled_octave_noise_2d(float octaves, float persistence,
        float scale, float loBound, float hiBound, float x, float y)