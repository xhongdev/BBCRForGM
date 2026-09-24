varying vec2 v_uv;
varying vec4 v_color;
uniform float u_progress;
uniform float u_seed;
uniform float u_reduced;
float noise(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233))+u_seed)*43758.5453);}
void main(){
    // Screen-space reconstruction: no original shader body survived export.
    float intensity=u_reduced>0.5?u_progress*2.0:pow(u_progress,2.2);
    vec2 cell=floor(v_uv*vec2(32.0,24.0));
    vec2 delta=vec2(noise(cell),noise(cell+17.0))*2.0-1.0;
    vec2 uv=clamp(v_uv+delta*intensity/vec2(480.0,360.0),vec2(0.0),vec2(1.0));
    vec4 color=texture2D(gm_BaseTexture,uv)*v_color;
    if(noise(floor(v_uv*vec2(480.0,360.0)))<u_progress*(u_reduced>0.5?0.25:0.05))color.rgb=vec3(1.0)-color.rgb;
    gl_FragColor=color;
}
