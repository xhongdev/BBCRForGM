/// Source phase envelopes, mapped independently into Unity-sized world units.
/// Shader source is unavailable; retain reduced flashing without flattening
/// the normal roar and beat into the same tiny displacement cap.
function cr_null_visual_warp(_value,_phase="beat") {
    if(global.bbcr.reduce_flashing)return min(.12,max(0,_value)*.025);
    switch(_phase){
        case "anger":return max(0,_value)*.35;
        case "finale":return max(0,_value)*.2;
        default:return max(0,_value)*.2;
    }
}
function cr_null_effect_data() {
    if(variable_global_exists("cr_null_effects"))return;
    global.cr_null_effects=cr_json("bbcr/null_effects.json");
    var _keys=variable_struct_get_names(global.cr_null_effects.images);
    for(var _i=0;_i<array_length(_keys);_i++)global.cr_catalog.sprites[$ _keys[_i]]=global.cr_null_effects.images[$ _keys[_i]];
}
function cr_null_anger_visual() {
    var _g=global.bbcr,_s=_g.null_mode;
    _s.glitch=_s.beat*3;_s.warp_phase="beat";_s.color_glitch=0;
    if(_s.phase!="boss")return;
    var _t=(_s.hit_time-9.5)/(_g.progress.flags[4]?2:1);
    if(_t>0 && _t<3){
        _s.warp_phase="anger";_s.glitch=_g.reduce_flashing?_t*2:sqr(_t);
        _s.color_glitch=_t*(_g.reduce_flashing?.25:.05);_s.warp_seed=random(1000);
    }
}
function cr_null_blocker_draw(_b) {
    var _frames=_b.effect.frames,_frame=min(array_length(_frames)-1,floor(_b.anim_time*_b.effect.fps));
    var _old=matrix_get(matrix_world);matrix_set(matrix_world,matrix_build(_b.x,0,_b.z,0,-_b.dir*90,0,1,1,1));
    cr_geometry_draw(_frames[_frame]);matrix_set(matrix_world,_old);
}
function cr_finale_visual_init() {
    cr_null_effect_data();global.bbcr.secret_route.visual={cursor:0,times:0,shake:0,offset:[0,0,0],seed:0,
        color_on:false,color:0,chunk:false,threshold:1,full_threshold:1,alpha:false,tiling:[1,1],uv_offset:[0,0],warp:0,world_color:0,time:0};
}
function cr_finale_signal(_v,_on) {
    _v.color_on=_on;if(!_on)return;
    _v.color=clamp(_v.times*.05,0,1);_v.seed=random(4096);
    _v.chunk=random(1)<=_v.times*.05;_v.threshold=clamp(1-_v.times*.05,0,1);_v.full_threshold=clamp(1-_v.times*.025,0,1);
    _v.shake+=.25;_v.times++;
}
function cr_finale_visual_step() {
    var _g=global.bbcr,_s=_g.secret_route,_v=_s.visual,_t=_s.time;
    _v.time=_t;_v.warp=0;_v.world_color=0;
    if(!_s.active || _s.finished || _g.progress.flags[4]){_v.shake=0;_v.offset=[0,0,0];return;}
    var _events=global.cr_null_effects.finale.signals;
    while(_v.cursor<array_length(_events) && _events[_v.cursor].time<=_t){cr_finale_signal(_v,_events[_v.cursor].on);_v.cursor++;}
    if(_t>12 && _t<14){_v.shake=sqr(_t-12);_v.warp=power(_t-12,4);_v.seed=random(1000);}
    else if(_t>69){_v.shake=30;_v.seed=random(4096);_v.alpha=random(1)<=.5;_v.color=_v.alpha?clamp((_t-69)*.1,0,1):1;}
    else if(_v.times==0)_v.shake=0;
    if(_v.times>0){
        if(random(1)<=.02){_v.tiling=[random(10),random(10)];_v.uv_offset=[random(10),random(10)];}
        else if(random(1)<=.2){_v.tiling=[1,1];_v.uv_offset=[0,0];}
    }
    var _x=random_range(-1,1),_y=random_range(-1,1),_z=random_range(-1,1),_r=random(_v.shake)/max(.00001,sqrt(sqr(_x)+sqr(_y)+sqr(_z)));
    if(_g.reduce_flashing)_r*=.1;
    _v.offset=[_x*_r,_y*_r,_z*_r];
}
function cr_fx_hash(_x,_y,_seed) {
    var _n=sin(_x*12.9898+_y*78.233+_seed)*43758.5453;return _n-floor(_n);
}
function cr_finale_null_draw() {
    var _g=global.bbcr,_v=_g.secret_route.visual,_geo=global.cr_map.secret_manager.null;
    // Sprite-local shader reconstruction: chunk displacement/UV repetition and
    // alpha corruption affect NULL alone, never the room or HUD.
    _g.render_final_null=true;gpu_set_cullmode(cull_noculling);
    for(var _i=0;_i<array_length(_geo.decorations);_i++){
        var _d=_geo.decorations[_i],_spr=cr_sprite(_d.sprite),_uv=sprite_get_uvs(_spr,0),_yaw=cr_view_yaw();
        var _p=_v.time>69?[55,4,65]:_d.p,_base=[_p[0]+_v.offset[0],_p[1]+_v.offset[1],_p[2]+_v.offset[2]],_steps=16;
        var _vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
        for(var _y=0;_y<_steps;_y++)for(var _x=0;_x<_steps;_x++){
            var _r=cr_fx_hash(_x,_y,_v.seed),_split=_v.chunk && _r>_v.threshold;
            if(_v.alpha && _r<_v.color)continue;
            var _dx=0,_dy=0,_dz=0;
            if(_split){var _spread=_v.time>69?4:1.5;if(_r>_v.full_threshold)_spread*=2;_dx=(cr_fx_hash(_x+17,_y,_v.seed)-.5)*_spread;_dy=(cr_fx_hash(_x,_y+9,_v.seed)-.5)*_spread;_dz=(_r-.5)*_spread;}
            var _order=[0,1,2,0,2,3];for(var _j=0;_j<6;_j++){
                var _k=_order[_j],_u=(_x+((_k==1 || _k==2)?1:0))/_steps,_vv=(_y+(_k>=2?1:0))/_steps;
                var _lx=(_u-_d.pivot.x)*_d.w+_dx,_ly=(_vv-_d.pivot.y)*_d.h+_dy;
                cr_vertex(_vb,_base[0]+cos(_yaw)*_lx+sin(_yaw)*_dz,_base[1]+_ly,_base[2]-sin(_yaw)*_lx+cos(_yaw)*_dz,lerp(_uv[0],_uv[2],_u),lerp(_uv[3],_uv[1],_vv));
            }
        }vertex_end(_vb);cr_submit(_vb,_d.sprite,true);
    }
    _g.render_final_null=false;
}
function cr_rotators_draw() {
    if(!variable_struct_exists(global.cr_map,"rotators"))return;
    for(var _i=0;_i<array_length(global.cr_map.rotators);_i++){
        var _s=global.cr_map.rotators[_i],_a=degtorad(global.bbcr.time*_s.speed),_c=cos(_a),_sn=sin(_a),_axis=_s.axis,_p=_s.position;
        for(var _j=0;_j<array_length(_s.batches);_j++){
            var _b=_s.batches[_j],_v=_b.vertices,_vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
            for(var _k=0;_k<array_length(_v);_k+=5){
                var _x=_v[_k]-_p[0],_y=_v[_k+1]-_p[1],_z=_v[_k+2]-_p[2],_dot=_x*_axis[0]+_y*_axis[1]+_z*_axis[2];
                cr_vertex(_vb,_p[0]+_x*_c+(_axis[1]*_z-_axis[2]*_y)*_sn+_axis[0]*_dot*(1-_c),
                    _p[1]+_y*_c+(_axis[2]*_x-_axis[0]*_z)*_sn+_axis[1]*_dot*(1-_c),
                    _p[2]+_z*_c+(_axis[0]*_y-_axis[1]*_x)*_sn+_axis[2]*_dot*(1-_c),_v[_k+3],_v[_k+4]);
            }
            vertex_end(_vb);cr_submit(_vb,_b.texture);
        }
    }
}
