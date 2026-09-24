attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
varying vec2 v_uv;
varying vec4 v_color;
varying vec2 v_world;
uniform float u_warp;
uniform float u_warp_seed;
void main() {
    vec3 p=(gm_Matrices[MATRIX_WORLD] * vec4(in_Position,1.0)).xyz;
    vec3 n=fract(sin(vec3(dot(p,vec3(12.9898,78.233,37.71)),dot(p,vec3(53.13,9.33,21.81)),dot(p,vec3(7.17,41.27,83.23)))+u_warp_seed)*43758.5453)*2.0-1.0;
    p+=n*u_warp;
    gl_Position = gm_Matrices[MATRIX_PROJECTION] * gm_Matrices[MATRIX_VIEW] * vec4(p,1.0);
    v_uv = in_TextureCoord;
    v_color = in_Colour;
    v_world = (gm_Matrices[MATRIX_WORLD] * vec4(in_Position,1.0)).xz;
}
