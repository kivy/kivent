---VERTEX SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs to the fragment shader */
varying vec4 frag_color;

/* vertex attributes */
attribute vec2     vPosition;
attribute vec2     vCenter;
attribute vec4     vColor;

/* uniform variables */
uniform mat4       modelview_mat;
uniform mat4       projection_mat;
uniform vec4       color;
uniform float      opacity;

void main (void) {
  frag_color = vColor * color * vec4(1.0, 1.0, 1.0, opacity);
  mat4 trans_mat = mat4(1.0, 0.0, 0.0, vCenter.x,
              0.0, 1.0, 0.0, vCenter.y,
              0.0, 0.0, 1.0, 0.0,
              0.0, 0.0, 0.0, 1.0);
  vec4 pos = vec4(vPosition.xy*.5, 0.0, 1.0);
  vec4 trans_pos = pos * trans_mat;
  gl_Position = projection_mat * modelview_mat * trans_pos;

}


---FRAGMENT SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs from the vertex shader */
varying vec4 frag_color;

/* uniform texture samplers */

void main (void){
    gl_FragColor = frag_color;
}
