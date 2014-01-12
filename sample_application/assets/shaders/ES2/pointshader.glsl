---VERTEX SHADER---
#version 100
#ifdef GL_ES
    precision highp float;
#endif


/* Outputs to the fragment shader */
varying vec4 frag_color;
varying float a_sin;
varying float a_cos;

/* vertex attributes */
attribute vec2     vPosition;
attribute float    vSize;
attribute float    vRotation;
attribute vec4     vColor;


/* uniform variables */
uniform mat4       modelview_mat;
uniform mat4       projection_mat;
uniform vec4       color;
uniform float      opacity;

void main (void) {
  frag_color = color * vColor * vec4(1.0, 1.0, 1.0, opacity);
  float rot = radians(vRotation);
  a_sin = sin(rot);
  a_cos = cos(rot);
  vec4 pos = vec4(vPosition.xy, 0.0, 1.0);
  gl_Position = projection_mat * modelview_mat * pos;
  gl_PointSize = vSize*2.;

}


---FRAGMENT SHADER---
#version 100
#ifdef GL_ES
    precision highp float;
#endif


/* Outputs from the vertex shader */
varying vec4 frag_color;
varying float a_sin;
varying float a_cos;

/* uniform texture samplers */
uniform sampler2D texture0;

void main (void){
    vec2 pos = gl_PointCoord;
    mat2 rot_mat = mat2(a_cos, -a_sin,
                      a_sin, a_cos);
    vec2 offset = vec2(0.5, 0.5);
    pos -= offset;
    vec2 tex_coord = rot_mat * pos;
    vec2 new_tex_coord = tex_coord.xy + offset;
    gl_FragColor = frag_color * texture2D(texture0, new_tex_coord);
}