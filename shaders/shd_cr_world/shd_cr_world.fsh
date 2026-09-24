varying vec2 v_uv;
varying vec4 v_color;
varying vec2 v_world;
uniform vec4 u_rect;
uniform vec2 u_texel;
uniform float u_lit;
uniform vec2 u_mapsize;
uniform vec2 u_camera;
uniform sampler2D u_lightmap;
uniform float u_fog;
uniform float u_sprite;
uniform float u_cutoff;
uniform vec3 u_fog_color;
uniform float u_color_glitch;
uniform float u_color_seed;
uniform float u_personal;
uniform vec2 u_tiling;
uniform vec2 u_offset;
void main() {
    // Runtime sprite textures can contain page padding. Unity UVs address only
    // the image, including repeated furniture UVs outside the unit square.
    vec2 uv = clamp(fract(v_uv),u_texel * 0.5,vec2(1.0)-u_texel * 0.5);
    vec2 spriteUV=v_uv;
    if(u_personal>0.5 && (u_tiling.x!=1.0 || u_tiling.y!=1.0 || u_offset.x!=0.0 || u_offset.y!=0.0)) {
        vec2 local=(v_uv-u_rect.xy)/(u_rect.zw-u_rect.xy);
        spriteUV=mix(u_rect.xy,u_rect.zw,fract(local*u_tiling+u_offset));
    }
    gl_FragColor = v_color * texture2D(gm_BaseTexture,u_sprite > 0.5 ? spriteUV : mix(u_rect.xy,u_rect.zw,uv));
    if (u_lit > 0.5) {
        // Source wall/door quads sit on tile borders. Sample their visible room,
        // not an absent cell on the other side of the exact integer boundary.
        vec2 samplePos = v_world + sign(u_camera-v_world)*0.005;
        vec2 cell = clamp(floor(samplePos / 10.0),vec2(0.0),u_mapsize-vec2(1.0));
        gl_FragColor.rgb *= texture2D(u_lightmap,(cell+vec2(0.5))/u_mapsize).rgb;
    }
    if (gl_FragColor.a < u_cutoff) discard;
    gl_FragColor.rgb = mix(gl_FragColor.rgb,u_fog_color,clamp((distance(v_world,u_camera)-5.0)/95.0,0.0,1.0)*u_fog);
    float corrupt=fract(sin(dot(floor(v_uv*128.0),vec2(12.9898,78.233))+u_color_seed)*43758.5453);
    if(corrupt<u_color_glitch)gl_FragColor.rgb=vec3(1.0)-gl_FragColor.rgb;
}
