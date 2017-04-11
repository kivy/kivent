from kivy.graphics.cgl cimport GLenum, cgl
from kivy.logger import Logger

cdef void gl_log_debug_message(str name, object data=None):
    cdef GLenum ret = cgl.glGetError()
    if ret:
        Logger.error(
            "OpenGL Error (%s) %d / %x for %s" % (name, ret, ret, data)
            )
