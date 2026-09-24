varying vec2 v_uv;
varying vec4 v_color;
uniform vec2 u_size;
uniform float u_stage;
uniform float u_reveal;
void main() {
    vec2 p = mod(vec2(floor(v_uv.x*u_size.x), u_size.y-1.0-floor(v_uv.y*u_size.y)),4.0);
    float rank = 16.0;
    if(p.y<0.5) { if(p.x<0.5) rank=7.0; else if(p.x<1.5) rank=11.0; else if(p.x<2.5) rank=4.0; }
    else if(p.y<1.5) { if(p.x<0.5) rank=13.0; else if(p.x<1.5) rank=0.0; else if(p.x<2.5) rank=14.0; else rank=3.0; }
    else if(p.y<2.5) { if(p.x<0.5) rank=5.0; else if(p.x<1.5) rank=8.0; else if(p.x<2.5) rank=6.0; else rank=10.0; }
    else { if(p.x<0.5) rank=9.0; else if(p.x<1.5) rank=2.0; else if(p.x<2.5) rank=12.0; else rank=1.0; }
    // The repeated (0,3) in GlobalCam.cs is intentional source behavior.
    if(u_reveal > 0.5 ? rank >= u_stage : rank < u_stage) discard;
    gl_FragColor = texture2D(gm_BaseTexture,v_uv)*v_color;
}
