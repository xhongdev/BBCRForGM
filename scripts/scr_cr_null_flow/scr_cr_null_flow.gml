/// NULL-specific routing, music and rendering; other managers keep their paths.
function cr_null_navigation_rebuild() {
    var _n=global.bbcr.npcs[0];if(global.cr_nav>=0)mp_grid_destroy(global.cr_nav);
    cr_build_navigation(_n);
    // Locked doors are navigation barriers; unlocked standard doors are opened
    // by NULL before movement. The world grid normally ignores moving doors.
    for(var _i=0;_i<array_length(global.bbcr.doors);_i++){
        var _d=global.bbcr.doors[_i];if(!_d.locked && _d.lock<=0)continue;
        for(var _z=floor((_d.cz-7)/2);_z<=floor((_d.cz+7)/2);_z++)for(var _x=floor((_d.cx-7)/2);_x<=floor((_d.cx+7)/2);_x++)
            if(cr_segment_distance(_x*2+1,_z*2+1,_d.cx-_d.tx*5,_d.cz-_d.tz*5,_d.cx+_d.tx*5,_d.cz+_d.tz*5)<2)mp_grid_add_cell(global.cr_nav,_x,_z);
    }
    path_clear_points(_n.path);_n.node=0;_n.route_timer=0;_n.route_x=-1;_n.route_z=-1;
}
function cr_null_spawn_step() {
    var _g=global.bbcr,_s=_g.null_mode;if(_s.spawn_left || _s.spawn_exit<0 || _s.time<1)return;
    var _e=_g.exits[_s.spawn_exit];if(cr_exit_contact(_e.triggers))return;
    // Leaving the rear of the spawn group must not trap a displaced player.
    var _a=_e.dir*pi/2;if((_g.px-_e.x)*sin(_a)+(_g.pz-_e.z)*cos(_a)<=5+global.cr_catalog.movement.radius)return;
    _s.spawn_left=true;_e.state=1;cr_null_navigation_rebuild();
}
function cr_null_destination_reached(_n) {
    var _count=path_get_number(_n.path),_end=cr_null_nav_cell(_n.gx,_n.gz);
    if(_count>0 && _n.node>=_count && array_length(_end)>0 && _n.route_x==_end[0] && _n.route_z==_end[1])return true;
    return point_distance(_n.px,_n.pz,_n.gx,_n.gz)<1;
}
function cr_null_nav_cell(_x,_z,_snap=true) {
    var _t=cr_tile(_x,_z);if(_snap && !is_undefined(_t) && _t.room==0){_x=_t.x*10+5;_z=_t.z*10+5;}
    var _cx=floor(_x/2),_cz=floor(_z/2),_best=[],_dist=1000000000;
    for(var _r=0;_r<=6;_r++){
        for(var _z0=max(0,_cz-_r);_z0<=min(global.cr_map.size.z*5-1,_cz+_r);_z0++)for(var _x0=max(0,_cx-_r);_x0<=min(global.cr_map.size.x*5-1,_cx+_r);_x0++){
            if(mp_grid_get_cell(global.cr_nav,_x0,_z0)<0)continue;
            var _d=sqr(_x0*2+1-_x)+sqr(_z0*2+1-_z);if(_d<_dist){_dist=_d;_best=[_x0*2+1,_z0*2+1];}
        }if(array_length(_best)>0)break;
    }return _best;
}
function cr_null_navigate(_n,_speed,_dt) {
    var _end=cr_null_nav_cell(_n.gx,_n.gz);if(array_length(_end)==0)return 0;
    var _count=path_get_number(_n.path);
    if(_count==0 || _n.node>=_count || _n.route_x!=_end[0] || _n.route_z!=_end[1]){
        var _start=cr_null_nav_cell(_n.px,_n.pz,false);if(array_length(_start)==0)return 0;
        if(mp_grid_get_cell(global.cr_nav,floor(_n.px/2),floor(_n.pz/2))>=0)_start=[_n.px,_n.pz];
        if(!mp_grid_path(global.cr_nav,_n.path,_start[0],_start[1],_end[0],_end[1],false)){path_clear_points(_n.path);return 0;}
        _n.node=0;_n.route_x=_end[0];_n.route_z=_end[1];_n.route_builds=cr_value(_n,"route_builds",0)+1;
        if(path_get_number(_n.path)>1 && cr_segment_distance(_n.px,_n.pz,path_get_point_x(_n.path,0),path_get_point_y(_n.path,0),path_get_point_x(_n.path,1),path_get_point_y(_n.path,1))<.001)_n.node=1;
    }
    var _remain=max(0,_speed*_dt),_total=0;
    while(_remain>.00001 && _n.node<path_get_number(_n.path)){
        var _x=path_get_point_x(_n.path,_n.node),_z=path_get_point_y(_n.path,_n.node),_dist=point_distance(_n.px,_n.pz,_x,_z);
        if(_dist<.001){_n.node++;continue;}
        for(var _i=0;_i<array_length(global.bbcr.doors);_i++){var _d=global.bbcr.doors[_i];if(point_distance(_n.px,_n.pz,_d.cx,_d.cz)<7 && !_d.locked && _d.lock<=0)cr_door_open(_d,false);}
        var _step=min(_remain,_dist),_ox=_n.px,_oz=_n.pz;cr_move(_n,(_x-_ox)/_dist*_step,(_z-_oz)/_dist*_step,_n.params.collision_radius);
        var _actual=point_distance(_ox,_oz,_n.px,_n.pz);_total+=_actual;_remain-=_step;
        if(_actual+.001<_step){path_clear_points(_n.path);break;}
        _n.yaw=arctan2(_n.px-_ox,_n.pz-_oz);if(_step>=_dist-.001)_n.node++;
    }
    return _total;
}
function cr_null_projectile_draw(_p) {
    var _old=matrix_get(matrix_world);
    // GM's Y rotation has the opposite sign to Unity's positive yaw.
    var _bob=cr_value(_p.spec,"bob",false)?sin(global.bbcr.time*5)/2:0;
    matrix_set(matrix_world,matrix_build(_p.x,5+_bob,_p.z,0,-radtodeg(_p.yaw)-(_p.state=="held"?_p.spec.rotation_offset:0),0,1,1,1));
    global.bbcr.billboard_yaw_override=cr_view_yaw()-_p.yaw-(_p.state=="held"?degtorad(_p.spec.rotation_offset):0);
    cr_geometry_draw(_p.spec.geometry);variable_struct_remove(global.bbcr,"billboard_yaw_override");matrix_set(matrix_world,_old);
}
function cr_null_held_draw() {
    var _s=global.bbcr.null_mode;if(!is_struct(_s) || _s.held<0)return;
    // Unity layer 29 is rendered by the overlay camera after world geometry.
    // The port's world surface is the equivalent of Unity's main camera plus
    // billboard overlay. Keep the real camera matrices and clear only depth,
    // so the held object is four units in front of that camera rather than an
    // object at the world's origin.
    draw_clear_depth(1);cr_null_projectile_draw(_s.projectiles[_s.held]);
}
function cr_null_music_position() {
    var _s=global.bbcr.null_mode;
    return audio_sound_get_track_position(global.bbcr.game_music)*cr_value(_s,"track_tempo",1);
}
function cr_null_music_seek(_position) {
    var _s=global.bbcr.null_mode,_time=_position/cr_value(_s,"track_tempo",1);
    audio_sound_set_track_position(global.bbcr.game_music,_time);
    if(audio_is_playing(cr_value(_s,"drum_track",-1)))audio_sound_set_track_position(_s.drum_track,_time);
    _s.beat_position=_position;_s.beat=0;
}
function cr_null_music_play(_name,_position,_loop) {
    var _g=global.bbcr,_s=_g.null_mode,_index=clamp(round((_s.music_speed-global.cr_map.null_mode.music_speed)/global.cr_map.null_mode.music_increment),0,8);
    var _track=global.cr_ui_data.boss_music.tracks[$ _name][_name=="BossIntro"?0:_index];
    if(audio_is_playing(_g.game_music))audio_stop_sound(_g.game_music);
    if(audio_is_playing(cr_value(_s,"drum_track",-1)))audio_stop_sound(_s.drum_track);
    if(variable_struct_exists(_s,"hold_tracks"))for(var _i=0;_i<array_length(_s.hold_tracks);_i++)if(audio_is_playing(_s.hold_tracks[_i]))audio_stop_sound(_s.hold_tracks[_i]);_s.hold_tracks=[];
    _s.track_tempo=_track.speed;_g.game_music=cr_sound(_track.melody.key,undefined,undefined,true);
    _s.drum_track=cr_sound(_track.drums.key,undefined,undefined,true);_s.music_sync=0;
    _g.exit_fx.music_key=_name;_g.exit_fx.music_speed=_track.speed;
    audio_sound_loop(_g.game_music,_loop);audio_sound_loop(_s.drum_track,_loop);cr_null_music_seek(_position);audio_sound_pitch(_g.game_music,1);audio_sound_pitch(_s.drum_track,1);
    cr_null_music_mix(0);
    if(_name=="BossLoop" && _s.health==1)cr_null_music_hold(_position);
}
function cr_null_music_hold(_position) {
    var _s=global.bbcr.null_mode,_src=global.cr_ui_data.boss_music.hold,_notes={},_program=array_create(16,0),_volume=array_create(16,100),_expression=array_create(16,127);
    for(var _i=0;_i<array_length(_src.score);_i++){
        var _e=_src.score[_i];if(_e[0]>_position)break;
        var _ch=_e[1] & 15,_kind=_e[1] & 240,_v=_e[2];
        if(_kind==192)_program[_ch]=_v[0];
        if(_kind==176){if(_v[0]==7)_volume[_ch]=_v[1];if(_v[0]==11)_expression[_ch]=_v[1];}
        if(_kind==128 || _kind==144){var _id=string(_ch)+"_"+string(_v[0]);
            if(_kind==128 || _v[1]==0){if(variable_struct_exists(_notes,_id))variable_struct_remove(_notes,_id);}
            else _notes[$ _id]={channel:_ch,preset:_program[_ch],note:_v[0],velocity:_v[1]};
        }
    }
    var _keys=variable_struct_get_names(_notes);
    for(var _i=0;_i<array_length(_keys);_i++){
        var _n=_notes[$ _keys[_i]],_key=string(_n.preset)+"_"+string(_n.note);if(!variable_struct_exists(_src.bank,_key))continue;
        var _h=cr_sound(_src.bank[$ _key].key,undefined,undefined,true);
        audio_sound_loop(_h,true);array_push(_s.hold_tracks,_h);
        var _entry=global.bbcr.sound_instances[array_length(global.bbcr.sound_instances)-1];
        _entry.mix=sqr(_n.velocity/100)*sqr(_volume[_n.channel]/100)*sqr(_expression[_n.channel]/127);cr_sound_apply(_entry);
    }
}
function cr_null_music_mix(_dt) {
    var _g=global.bbcr,_s=_g.null_mode;if(!variable_struct_exists(_s,"drum_track"))return;
    _s.drum_gain=_s.phase=="boss"?clamp(1-(point_distance(_g.px,_g.pz,_g.npcs[0].px,_g.npcs[0].pz)-75)/150,0,1):1;
    for(var _i=0;_i<array_length(_g.sound_instances);_i++){
        var _e=_g.sound_instances[_i];
        if(_e.handle==_s.drum_track){_e.mix=_s.drum_gain;if(audio_is_playing(_e.handle))cr_sound_apply(_e);}
        if(_e.handle==_g.game_music){_e.mix=_s.health==1?0:1;if(audio_is_playing(_e.handle))cr_sound_apply(_e);}
    }
    _s.music_sync+=_dt;
    if(_s.music_sync>=.25 && audio_is_playing(_g.game_music) && audio_is_playing(_s.drum_track)){
        _s.music_sync=0;var _pos=audio_sound_get_track_position(_g.game_music);
        if(abs(audio_sound_get_track_position(_s.drum_track)-_pos)>.025)audio_sound_set_track_position(_s.drum_track,_pos);
    }
}
function cr_null_beat_sample(_position) {
    var _s=global.bbcr.null_mode,_beats=global.cr_ui_data.boss_music.beats,_last=-100;
    for(var _i=0;_i<array_length(_beats);_i++){if(_beats[_i]>_position)break;_last=_beats[_i];}
    if(_last!=cr_value(_s,"last_beat",-100)){_s.last_beat=_last;_s.warp_seed=random(1000);}
    // Age the pulse from the actual sample clock, including a late render frame.
    _s.beat=max(0,1-(_position-_last)/_s.track_tempo*4);_s.beat_position=_position;
}
function cr_null_capture_draw() {
    var _g=global.bbcr;if(!_g.dead || !is_struct(_g.ending) || _g.ending.kind!="nullcaught" || _g.ending.time>=10)return;
    if(!variable_global_exists("cr_null_capture_surface"))global.cr_null_capture_surface=-1;
    var _w=max(1,window_get_width()),_h=max(1,window_get_height());
    if(!surface_exists(global.cr_null_capture_surface))global.cr_null_capture_surface=surface_create(_w,_h);
    else if(surface_get_width(global.cr_null_capture_surface)!=_w || surface_get_height(global.cr_null_capture_surface)!=_h)surface_resize(global.cr_null_capture_surface,_w,_h);
    surface_copy(global.cr_null_capture_surface,0,0,application_surface);
    var _oldw=matrix_get(matrix_world),_oldv=matrix_get(matrix_view),_oldp=matrix_get(matrix_projection);
    matrix_set(matrix_world,matrix_build_identity());matrix_set(matrix_view,matrix_build(-_w/2,-_h/2,16000,0,0,0,1,1,1));matrix_set(matrix_projection,matrix_build_projection_ortho(_w,-_h,1,32000));
    shader_set(shd_cr_null_capture);shader_set_uniform_f(shader_get_uniform(shd_cr_null_capture,"u_progress"),min(5,_g.ending.time*.5));shader_set_uniform_f(shader_get_uniform(shd_cr_null_capture,"u_seed"),_g.ending.glitch_seed);shader_set_uniform_f(shader_get_uniform(shd_cr_null_capture,"u_reduced"),_g.reduce_flashing?1:0);
    draw_surface_stretched(global.cr_null_capture_surface,0,0,_w,_h);shader_reset();matrix_set(matrix_world,_oldw);matrix_set(matrix_view,_oldv);matrix_set(matrix_projection,_oldp);
}
