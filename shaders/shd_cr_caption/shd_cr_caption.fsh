varying vec2 v_uv;
varying vec4 v_color;
void main(){
    float distance=texture2D(gm_BaseTexture,v_uv).a;
    float edge=max(fwidth(distance),1.0/255.0);
    float coverage=clamp((distance-0.5)/edge+0.5,0.0,1.0);
    gl_FragColor=vec4(v_color.rgb,v_color.a*coverage);
}
