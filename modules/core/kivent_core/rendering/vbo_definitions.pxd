cdef short V_NEEDGEN = 1 << 0
cdef short V_NEEDUPLOAD = 1 << 1
cdef short V_HAVEID = 1 << 2

cdef class VBOTargetException(Exception):
    pass

cdef class VBOUsageException(Exception):
    pass
