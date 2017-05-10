---VERTEX SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs to the fragment shader */
varying vec4 frag_color;
varying vec2 tex_coord0;

/* vertex attributes */
attribute vec2     pos;
attribute vec2     uvs;
attribute vec2     center;
attribute vec4     v_color;

/* uniform variables */
uniform mat4       modelview_mat;
uniform mat4       projection_mat;
uniform vec4       color;
uniform float      opacity;

void main (void) {
  frag_color = v_color * color * vec4(1.0, 1.0, 1.0, opacity);
  tex_coord0 = uvs;
  mat4 trans_mat = mat4(1.0, 0.0, 0.0, center.x,
              0.0, 1.0, 0.0, center.y,
              0.0, 0.0, 1.0, 0.0,
              0.0, 0.0, 0.0, 1.0);
  vec4 new_pos = vec4(pos.xy, 0.0, 1.0);
  vec4 trans_pos = new_pos * trans_mat;
  gl_Position = projection_mat * modelview_mat * trans_pos;

}


---FRAGMENT SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs from the vertex shader */
varying vec4 frag_color;
varying vec2 tex_coord0;

/* uniform texture samplers */
uniform sampler2D texture0;

void main (void){
    gl_FragColor = frag_color * texture2D(texture0, tex_coord0);
}
