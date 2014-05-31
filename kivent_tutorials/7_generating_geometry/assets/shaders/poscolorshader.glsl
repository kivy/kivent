---VERTEX SHADER---
#ifdef GL_ES
    precision highp float;
#endif

/* Outputs to the fragment shader */
varying vec4 frag_color;

/* vertex attributes */
attribute float     v0;
attribute float     v1;
attribute float     v2;
attribute float     v3;
attribute float     v4;
attribute float     v5;
attribute float     v6;
attribute float     v7;


/* uniform variables */
uniform mat4       modelview_mat;
uniform mat4       projection_mat;
uniform vec4       color;
uniform float      opacity;

void main (void) {
  frag_color = vec4(v2, v3, v4, v5);
  vec4 pos = vec4(v0, v1, 0.0, 1.0);
  gl_Position = projection_mat * pos;

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
