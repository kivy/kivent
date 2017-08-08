from kivent_core.uix.cwidget cimport CWidget

cdef class GameSystem(CWidget):
    cdef float _frame_time
    cdef list py_components
    cdef unsigned int component_count
    cdef object free_indices
    cdef dict copied_components
    cpdef unsigned int get_active_component_count(self) except <unsigned int>-1
    cpdef unsigned int get_active_component_count_in_zone(self, str zone) except <unsigned int>-1
