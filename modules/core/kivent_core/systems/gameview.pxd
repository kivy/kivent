from gamesystem cimport GameSystem
from kivy.graphics.transformation cimport Matrix


cdef class GameView(GameSystem):
	cdef Matrix matrix
	cdef list _touches
	cdef int _touch_count
