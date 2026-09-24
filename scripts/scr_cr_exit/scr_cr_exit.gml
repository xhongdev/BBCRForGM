function cr_exit_init() {
    var _g=global.bbcr,_lights=global.cr_map.lights;
    _g.exit_fx={active:false,red:array_create(array_length(_lights),false),on:array_create(array_length(_lights),true),
        pending:[],timer:.2,flicker_timer:0,dirty:true,colors:array_create(global.cr_map.size.x*global.cr_map.size.z,c_white),
        music_key:"",music_speed:1,chaos:-1,queue:[],chaos_key:"",flicker:false};
}
function cr_exit_music(_key,_speed) {
    var _g=global.bbcr,_fx=_g.exit_fx,_position=0;
    if(_fx.music_key==_key && _fx.music_speed==_speed && audio_is_playing(_g.game_music))return;
    if(audio_is_playing(_g.game_music) && _fx.music_key!="")_position=audio_sound_get_track_position(_g.game_music)*_fx.music_speed/_speed;
    if(_g.game_music>=0)audio_stop_sound(_g.game_music);
    _g.game_music=cr_sound(_key);_fx.music_key=_key;_fx.music_speed=_speed;
    if(_g.game_music>=0){audio_sound_loop(_g.game_music,true);audio_sound_set_track_position(_g.game_music,_position);}
}
function cr_exit_queue(_keys) {
    var _fx=global.bbcr.exit_fx;
    for(var _i=0;_i<array_length(_keys);_i++)array_push(_fx.queue,_keys[_i]);
    if(audio_is_playing(_fx.chaos))audio_sound_loop(_fx.chaos,false);
    cr_exit_audio_tick();
}
function cr_exit_stop_file() {
    var _fx=global.bbcr.exit_fx;
    _fx.queue=[];if(audio_is_playing(_fx.chaos))audio_stop_sound(_fx.chaos);_fx.chaos=-1;_fx.chaos_key="";
}
function cr_exit_audio_tick() {
    var _fx=global.bbcr.exit_fx;
    if(array_length(_fx.queue)>0 && !audio_is_playing(_fx.chaos)){
        _fx.chaos_key=array_shift(_fx.queue);_fx.chaos=cr_sound(_fx.chaos_key);
        if(_fx.chaos>=0)audio_sound_loop(_fx.chaos,array_length(_fx.queue)==0);
    }
}
function cr_exit_closed() {
    var _g=global.bbcr,_fx=_g.exit_fx,_lights=global.cr_map.lights;
    if(_g.mode!="story")return;
    switch(_g.exits_closed){
        case 1:
            _fx.active=true;_fx.pending=[];_fx.timer=.2;
            for(var _i=0;_i<array_length(_lights);_i++){
                if(_lights[_i].strength<=1)_fx.red[_i]=true;else array_push(_fx.pending,_i);
            }
            _fx.dirty=true;cr_exit_music("exit_slow",.1);break;
        case 2:
            cr_exit_queue(global.cr_ui_data.chaos.ChaosAmbience1);
            cr_exit_music("exit_slow_"+string(irandom_range(13,24)),.1);break;
        case 3:
            cr_exit_queue(global.cr_ui_data.chaos.ChaosAmbience2);
            if(_g.game_music>=0)audio_stop_sound(_g.game_music);_fx.music_key="";
            _fx.flicker=!_g.reduce_flashing;_fx.dirty=true;break;
    }
}
function cr_exit_step(_dt) {
    var _fx=global.bbcr.exit_fx;cr_exit_audio_tick();if(!_fx.active)return;
    if(array_length(_fx.pending)>0){
        _fx.timer-=_dt;
        while(_fx.timer<=0 && array_length(_fx.pending)>0){
            var _pick=irandom(array_length(_fx.pending)-1);_fx.red[_fx.pending[_pick]]=true;
            array_delete(_fx.pending,_pick,1);_fx.timer+=.2;_fx.dirty=true;
        }
    }
    if(_fx.flicker){
        _fx.flicker_timer-=_dt;
        if(_fx.flicker_timer<=0){
            var _pool=[];for(var _i=0;_i<array_length(global.cr_map.lights);_i++)if(global.cr_map.lights[_i].strength>1)array_push(_pool,_i);
            if(array_length(_pool)>0){var _i=_pool[irandom(array_length(_pool)-1)];_fx.on[_i]=!_fx.on[_i];_fx.dirty=true;}
            _fx.flicker_timer=.1;
        }
    }
}
function cr_exit_light_color(_index) {
    var _fx=global.bbcr.exit_fx,_m=global.cr_map,_sources=_m.lighting.influence[_index],_rgb=[0,0,0];
    for(var _i=0;_i<array_length(_sources);_i++){
        var _s=_sources[_i],_j=_s[0];if(!_fx.on[_j])continue;
        var _src=_m.lights[_j].color,_color=_fx.red[_j]?[1,0,0]:[_src.r,_src.g,_src.b];
        for(var _c=0;_c<3;_c++){
            var _v=_color[_c]*_s[1];
            if(_m.lighting.mode==1)_rgb[_c]=max(_rgb[_c],_v);
            else _rgb[_c]+=_v*(_m.lighting.mode==2?1-_rgb[_c]:1);
        }
    }
    var _dark=_m.lighting.dark,_base=_fx.flicker?[.2,0,0]:[_dark.r,_dark.g,_dark.b];
    return make_color_rgb(round(255*clamp(lerp(_base[0],1,_rgb[0]),0,1)),round(255*clamp(lerp(_base[1],1,_rgb[1]),0,1)),round(255*clamp(lerp(_base[2],1,_rgb[2]),0,1)));
}
function cr_exit_light_surface() {
    var _fx=global.bbcr.exit_fx,_m=global.cr_map;if(!_fx.active && !global.bbcr.lightsout)return;
    if(global.bbcr.lightsout)_fx.dirty=true;
    if(!surface_exists(global.cr_light_surface)){global.cr_light_surface=surface_create(_m.size.x,_m.size.z);_fx.dirty=true;}
    if(!_fx.dirty)return;
    var _world=matrix_get(matrix_world),_view=matrix_get(matrix_view),_proj=matrix_get(matrix_projection);
    surface_set_target(global.cr_light_surface);draw_clear(global.bbcr.lightsout?c_black:c_white);
    matrix_set(matrix_world,matrix_build_identity());matrix_set(matrix_view,matrix_build(-_m.size.x/2,-_m.size.z/2,16000,0,0,0,1,1,1));matrix_set(matrix_projection,matrix_build_projection_ortho(_m.size.x,-_m.size.z,1,32000));
    draw_set_alpha(1);
    for(var _i=0;_i<array_length(_m.tiles);_i++){
        var _t=_m.tiles[_i],_color=global.bbcr.lightsout?cr_lantern_color(_t.x*10+5,_t.z*10+5):cr_exit_light_color(_i);_fx.colors[_t.x+_t.z*_m.size.x]=_color;
        // Fill texel bounds explicitly; point rasterization lands on cell edges.
        cr_ui_fill([_t.x,_t.z,1,1],[color_get_red(_color),color_get_green(_color),color_get_blue(_color),255]);
    }
    draw_set_color(c_white);surface_reset_target();matrix_set(matrix_world,_world);matrix_set(matrix_view,_view);matrix_set(matrix_projection,_proj);_fx.dirty=false;
}
function cr_exit_color_at(_x,_z) {
    var _fx=global.bbcr.exit_fx;if(!_fx.active)return c_white;
    var _m=global.cr_map;return _fx.colors[clamp(floor(_x/10),0,_m.size.x-1)+clamp(floor(_z/10),0,_m.size.z-1)*_m.size.x];
}
function cr_exit_contact(_boxes) {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(_boxes);_i++)if(cr_box_overlap(_boxes[_i],_g.px,_g.pz,global.cr_catalog.movement.radius))return true;
    return false;
}
function cr_exit_unembed(_e) {
    var _g=global.bbcr,_w=_e.barrier,_r=global.cr_catalog.movement.radius+global.cr_catalog.movement.skin;
    if(cr_segment_distance(_g.px,_g.pz,_w[0],_w[1],_w[2],_w[3])>=_r)return;
    // A trigger and gate can update in the same step (or after a teleport).
    // Resolve the capsule toward the school, along the source exit direction.
    var _nx=round(sin(_e.dir*pi/2)),_nz=round(cos(_e.dir*pi/2));
    var _distance=(_g.px-(_w[0]+_w[2])/2)*_nx+(_g.pz-(_w[1]+_w[3])/2)*_nz;
    _g.px+=_nx*(_r-_distance);_g.pz+=_nz*(_r-_distance);
}
function cr_exits_trigger() {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(_g.exits);_i++){
        var _e=_g.exits[_i];if(_e.used)continue;
        if(_g.exits_closed<array_length(_g.exits)-1 && cr_exit_contact(_e.triggers)){
            cr_exit_unembed(_e);_e.used=true;_e.state=2;_e.prepared=false;_g.exits_closed++;
            cr_sound(_e.sound,_e.x,_e.z);cr_noise(_e.x+sin(_e.dir*pi/2)*10,_e.z+cos(_e.dir*pi/2)*10,global.cr_catalog.effects.exit_noise);cr_exit_closed();
            if(_g.exits_closed==array_length(_g.exits)-1)for(var _j=0;_j<array_length(_g.exits);_j++)if(!_g.exits[_j].used)_g.exits[_j].prepared=false;
        }else if(_g.exits_closed>=array_length(_g.exits)-1 && cr_exit_contact(_e.inside)){
            if(_g.style=="party")cr_party_final_exit();else cr_win_begin();return;
        }
    }
}
