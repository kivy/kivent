ctypedef struct keColor:
    float r
    float g
    float b
    float a


ctypedef struct keTexInfo:
    float u0
    float v0
    float u1
    float v1
    float w
    float h


ctypedef struct keRenderInfo:
    float x
    float y
    float scale
    float rotation
    keColor color
    keTexInfo tex_info


ctypedef struct keParticle:
    keRenderInfo render_info
    float current_time
    float total_time
    float start_x
    float start_y
    float velocity_x
    int particle_id
    float velocity_y
    float radial_acceleration
    float tangent_acceleration
    float emit_radius
    float emit_radius_delta
    float emit_rotation
    float emit_rotation_delta
    float rotation_delta
    keColor color_delta
    float scale_delta
    void* emitter_ptr