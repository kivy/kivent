---VERTEX SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs to the fragment shader */
varying vec4 frag_color;

/* vertex attributes */
attribute vec2     pos;
attribute float    rot;
attribute vec2     center;
attribute vec4     v_color;


/* uniform variables */
uniform mat4       modelview_mat;
uniform mat4       projection_mat;
uniform vec4       color;
uniform float      opacity;

void main (void) {
  frag_color = v_color * color * vec4(1.0, 1.0, 1.0, opacity);
  float a_sin = sin(rot);
  float a_cos = cos(rot);
  mat4 rot_mat = mat4(a_cos, -a_sin, 0.0, 0.0,
                a_sin, a_cos, 0.0, 0.0,
                0.0, 0.0, 1.0, 0.0,
                0.0, 0.0, 0.0, 1.0 );
  mat4 trans_mat = mat4(1.0, 0.0, 0.0, center.x,
              0.0, 1.0, 0.0, center.y,
              0.0, 0.0, 1.0, 0.0,
              0.0, 0.0, 0.0, 1.0);
  vec4 new_pos = vec4(pos.xy, 0.0, 1.0);
  vec4 trans_pos = new_pos * rot_mat * trans_mat;
  gl_Position = projection_mat * modelview_mat * trans_pos;
}


---FRAGMENT SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs from the vertex shader */
varying vec4 frag_color;

void main (void){
    gl_FragColor = frag_color;
}