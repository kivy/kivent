from kivy._event cimport EventDispatcher

cdef class CWidget(EventDispatcher):
    cdef object _context
    cdef object canvas
