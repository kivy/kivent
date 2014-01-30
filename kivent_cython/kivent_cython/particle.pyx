
cdef class EmitterConfig:
    cdef char* texture
    cdef float life_span_variance
    cdef float start_size
    cdef float start_size_variance
    cdef float end_size
    cdef float end_size_variance
    cdef float emit_angle_variance
    cdef float start_rotation
    cdef float start_rotation_variance
    cdef float end_rotation
    cdef float end_rotation_variance
    cdef float emitter_x_variance
    cdef float emitter_y_variance
    cdef float gravity_x
    cdef float gravity_y
    cdef float speed
    cdef float speed_variance
    cdef float radial_acceleration
    cdef float radial_acceleration_variance
    cdef float tangential_acceleration
    cdef float tangential_acceleration_variance
    cdef float max_radius
    cdef float max_radius_variance
    cdef float min_radius
    cdef float rotate_per_second
    cdef float rotate_per_second_variance
    cdef list start_color
    cdef list start_color_variance
    cdef list end_color
    cdef list end_color_variance

    def __cinit__(self):
        life_span_variance = 0.0
        gravity_x = 0.0
        gravity_y = 0.0
        start_size = 10.0
        start_size_variance = 0.0
        end_size = 1.0
        end_size_variance = 0.0
        emit_angle_variance = 0.0
        start_rotation = 0.0
        start_rotation_variance = 0.0
        end_rotation = 0.0
        end_rotation_variance = 0.0
        emitter_x_variance = 0.0
        emitter_y_variance = 0.0
        speed = 10.0
        speed_variance = 0.0
        radial_acceleration = 0.0
        radial_acceleration_variance = 0.0
        tangential_acceleration = 0.0
        tangential_acceleration_variance = 0.0
        max_radius = 25.0
        max_radius_variance = 0.0
        min_radius = 0.0
        rotate_per_second = 0.0
        rotate_per_second_variance = 0.0
        start_color = [1.0, 1.0, 1.0, 1.0]
        start_color_variance = [0.0, 0.0, 0.0, 0.0]
        end_color = [1.0, 1.0, 1.0, 1.0]
        end_color_variance = [0.0, 0.0, 0.0, 0.0]
        emitter_type = 0.0


    property life_span_variance:
        def __get__(self):
            return self.life_span_variance
        def __set__(self, value):
            self.life_span_variance = value

    property gravity_x:
        def __get__(self):
            return self.gravity_x
        def __set__(self, value):
            self.gravity_x = value

    property gravity_y:
        def __get__(self):
            return self.gravity_y
        def __set__(self, value):
            self.gravity_y = value

    property start_size:
        def __get__(self):
            return self.start_size
        def __set__(self, value):
            self.start_size = value

    property start_size_variance:
        def __get__(self):
            return self.start_size_variance
        def __set__(self, value):
            self.start_size_variance = value

    property end_size:
        def __get__(self):
            return self.end_size
        def __set__(self, value):
            self.end_size = value

    property end_size_variance:
        def __get__(self):
            return self.end_size_variance
        def __set__(self, value):
            self.end_size_variance = value

    property emit_angle_variance:
        def __get__(self):
            return self.emit_angle_variance
        def __set__(self, value):
            self.emit_angle_variance = value

    property start_rotation:
        def __get__(self):
            return self.start_rotation
        def __set__(self, value):
            self.start_rotation = value

    property start_rotation_variance:
        def __get__(self):
            return self.start_rotation_variance
        def __set__(self, value):
            self.start_rotation_variance = value

    property end_rotation:
        def __get__(self):
            return self.end_rotation
        def __set__(self, value):
            self.end_rotation = value

    property end_rotation_variance:
        def __get__(self):
            return self.end_rotation_variance
        def __set__(self, value):
            self.end_rotation_variance = value

    property emitter_x_variance:
        def __get__(self):
            return self.emitter_x_variance
        def __set__(self, value):
            self.emitter_x_variance = value

    property emitter_y_variance:
        def __get__(self):
            return self.emitter_y_variance
        def __set__(self, value):
            self.emitter_y_variance = value

    property speed:
        def __get__(self):
            return self.speed
        def __set__(self, value):
            self.speed = value

    property speed_variance:
        def __get__(self):
            return self.speed_variance
        def __set__(self, value):
            self.speed_variance = value

    property radial_acceleration:
        def __get__(self):
            return self.radial_acceleration
        def __set__(self, value):
            self.radial_acceleration = value

    property radial_acceleration_variance:
        def __get__(self):
            return self.radial_acceleration_variance
        def __set__(self, value):
            self.radial_acceleration_variance = value

    property tangential_acceleration:
        def __get__(self):
            return self.tangential_acceleration
        def __set__(self, value):
            self.tangenialt_acceleration = value

    property tangential_acceleration_variance:
        def __get__(self):
            return self.tangential_acceleration_variance
        def __set__(self, value):
            self.tangential_acceleration_variance = value

    property max_radius:
        def __get__(self):
            return self.max_radius
        def __set__(self, value):
            self.max_radius = value

    property max_radius_variance:
        def __get__(self):
            return self.max_radius_variance
        def __set__(self, value):
            self.max_radius_variance = value

    property min_radius:
        def __get__(self):
            return self.min_radius
        def __set__(self, value):
            self.min_radius = value

    property rotate_per_second:
        def __get__(self):
            return self.rotate_per_second
        def __set__(self, value):
            self.rotate_per_second = value

    property rotate_per_second_variance:
        def __get__(self):
            return self.rotate_per_second_variance
        def __set__(self, value):
            self.rotate_per_second_variance = value

    property start_color:
        def __get__(self):
            return self.start_color
        def __set__(self, value):
            self.start_color = value

    property start_color_variance:
        def __get__(self):
            return self.start_color_variance
        def __set__(self, value):
            self.start_color_variance = value

    property end_color:
        def __get__(self):
            return self.end_color
        def __set__(self, value):
            self.end_color = value

    property end_color_variance:
        def __get__(self):
            return self.end_color_variance
        def __set__(self, value):
            self.end_color_variance = value


cdef class Particle:
    cdef float x
    cdef float y
    cdef float rotation
    cdef float current_time
    cdef float scale
    cdef float total_time
    cdef float start_x
    cdef float start_y
    cdef float velocity_x
    cdef float velocity_y
    cdef float radial_acceleration
    cdef float tangent_acceleration
    cdef float emit_radius
    cdef float emit_radius_delta
    cdef float emit_rotation
    cdef float emit_rotation_delta
    cdef float rotation_delta
    cdef float scale_delta
    cdef list color
    cdef list color_delta
    cdef char* texture

    def __cinit__(self):
        x, y, rotation, current_time = -256, -256, 0, 0
        scale, total_time = 1.0, 0.
        start_x, start_y, velocity_x, velocity_y = 0, 0, 0, 0
        radial_acceleration, tangent_acceleration = 0, 0
        emit_radius, emit_radius_delta = 0, 0
        emit_rotation, emit_rotation_delta = 0, 0
        rotation_delta, scale_delta = 0, 0
        color = [1.0, 1.0, 1.0, 1.0]
        color_delta = [0.0, 0.0, 0.0, 0.0]
        

    property color:
        def __get__(self):
            return self.color
        def __set__(self, value):
            self.color = value

    property color_delta:
        def __get__(self):
            return self.color_delta
        def __set__(self, value):
            self.color_delta = value

    property current_time:
        def __get__(self):
            return self.current_time
        def __set__(self, value):
            self.current_time = value

    property total_time:
        def __get__(self):
            return self.total_time
        def __set__(self, value):
            self.total_time = value

    property x:
        def __get__(self):
            return self.x
        def __set__(self, value):
            self.x = value

    property y:
        def __get__(self):
            return self.y
        def __set__(self, value):
            self.y = value

    property rotation:
        def __get__(self):
            return self.rotation
        def __set__(self, value):
            self.rotation = value

    property scale:
        def __get__(self):
            return self.scale
        def __set__(self, value):
            self.scale = value

    property start_x:
        def __get__(self):
            return self.start_x
        def __set__(self, value):
            self.start_x = value

    property start_y:
        def __get__(self):
            return self.start_y
        def __set__(self, value):
            self.start_y = value

    property velocity_x:
        def __get__(self):
            return self.velocity_x
        def __set__(self, value):
            self.velocity_x = value

    property velocity_y:
        def __get__(self):
            return self.velocity_y
        def __set__(self, value):
            self.velocity_y = value

    property radial_acceleration:
        def __get__(self):
            return self.radial_acceleration
        def __set__(self, value):
            self.radial_acceleration = value

    property tangent_acceleration:
        def __get__(self):
            return self.tangent_acceleration
        def __set__(self, value):
            self.tangent_acceleration = value

    property emit_radius:
        def __get__(self):
            return self.emit_radius
        def __set__(self, value):
            self.emit_radius = value

    property emit_radius_delta:
        def __get__(self):
            return self.emit_radius_delta
        def __set__(self, value):
            self.emit_radius_delta = value

    property emit_rotation:
        def __get__(self):
            return self.emit_rotation
        def __set__(self, value):
            self.emit_rotation = value

    property emit_rotation_delta:
        def __get__(self):
            return self.emit_rotation_delta
        def __set__(self, value):
            self.emit_rotation_delta = value
            
    property rotation_delta:
        def __get__(self):
            return self.rotation_delta
        def __set__(self, value):
            self.rotation_delta = value

    property scale_delta:
        def __get__(self):
            return self.scale_delta
        def __set__(self, value):
            self.scale_delta = value

    property texture:
        def __get__(self):
            return self.texture
        def __set__(self, value):
            self.texture = value