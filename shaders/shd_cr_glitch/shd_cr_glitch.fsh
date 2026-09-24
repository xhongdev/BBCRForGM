varying vec2 v_uv;
varying vec4 v_color;
uniform float u_seed;
uniform float u_shift;
float hash(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233))+u_seed)*43758.5453); }
void main() {
    if(u_shift>0.0){
        float shift=(hash(vec2(floor(v_uv.y*360.0),0.0))-0.5)*u_shift;
        gl_FragColor=texture2D(gm_BaseTexture,vec2(clamp(v_uv.x+shift,0.0,1.0),v_uv.y))*v_color;
        return;
    }
    vec2 cell=floor(v_uv*vec2(240.0,180.0)/16.0);
    float chunk=hash(cell);
    // Original shader code is absent. Keep its serialized chunk threshold
    // and corruption percentage; the spatial noise is a port approximation.
    // Preserve the source sprite silhouette; colour corruption must not make
    // arbitrary displaced duplicates of its face or wrap transparent margins.
    vec4 src=texture2D(gm_BaseTexture,v_uv)*v_color;
    float channel=hash(chunk>0.4?cell:floor(v_uv*vec2(240.0,180.0)));
    if(channel<0.5){
        vec3 bits=step(vec3(0.5),vec3(hash(cell+3.0),hash(cell+7.0),hash(cell+11.0)));
        src.rgb=mix(src.rgb,vec3(1.0)-src.rgb,bits);
    }
    gl_FragColor=src;
}
