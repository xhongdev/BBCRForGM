varying vec2 v_uv;
varying vec4 v_color;
uniform vec4 u_rect;
uniform vec4 u_tile;
uniform vec4 u_flags; // colour, alpha, chunk, scramble
uniform vec4 u_values; // seed, colour fraction, chunk threshold, full threshold
uniform float u_shift;
float hash(vec2 p){return fract(sin(dot(p,vec2(12.9898,78.233))+u_values.x)*43758.5453);}
void main(){
    vec2 uv=(v_uv-u_rect.xy)/(u_rect.zw-u_rect.xy);
    if(u_shift>0.0){
        uv.x+=(hash(vec2(floor(uv.y*256.0),0.0))-.5)*u_shift;
        if(uv.x<0.0 || uv.x>1.0)discard;
    }
    uv=fract(uv*u_tile.xy+u_tile.zw);
    vec2 cell=floor(uv*vec2(240.0,180.0)/16.0);
    float block=hash(cell),mask=1.0;
    if(u_flags.y>0.5 && u_flags.z>0.5){
        mask=1.0-step(u_values.w,block);
        if(block>=u_values.z && block<u_values.w)mask=1.0-u_values.y;
    }
    if(u_flags.w>0.5)uv=fract(uv+vec2(hash(cell+5.0),hash(cell+9.0)));
    vec4 src=texture2D(gm_BaseTexture,mix(u_rect.xy,u_rect.zw,uv))*v_color;
    if(u_flags.x>0.5 && hash(u_flags.z>0.5?cell:floor(uv*vec2(240.0,180.0)))<u_values.y){
        vec3 bits=step(vec3(.5),vec3(hash(cell+3.0),hash(cell+7.0),hash(cell+11.0)));
        src.rgb=mix(src.rgb,1.0-src.rgb,bits);
    }
    gl_FragColor=vec4(src.rgb,src.a*mask);
}
