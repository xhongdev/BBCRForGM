function cr_rope_begin(_n) {
    var _g=global.bbcr,_src=global.cr_ui_data.jumprope;
    _g.rope=true;_g.rope_npc=_n;_g.jumps=0;_g.rope_time=0;_g.rope_anim=-1;
    _g.rope_phase=0;_g.rope_timer=_src.ropeDelay;_g.rope_anchor=[_g.px,_g.pz];
    _g.rope_max=_g.hard?10:_src.maxJumps;_g.jump_height=0;_g.jump_velocity=0;
    _n.playing=true;_n.speed=0;_n.angry=false;path_clear_points(_n.path);
    var _dx=_n.px-_g.px,_dz=_n.pz-_g.pz,_len=point_distance(0,0,_dx,_dz);
    if(_len>.001)cr_move(_n,_dx/_len*10,_dz/_len*10,_n.params.radius);
    cr_npc_sound(_n,_n.params.audGo);
}
function cr_rope_end(_success) {
    var _g=global.bbcr;if(!_g.rope)return;
    _g.rope=false;_g.jump_height=0;_g.jump_velocity=0;_g.rope_anim=-1;
    if(is_struct(_g.rope_npc)){
        var _n=_g.rope_npc;_n.playing=false;_n.cooldown=_n.params.initialCooldown;_n.speed=_n.params.normSpeed;
        _n.sad=!_success;_n.anim_time=0;
        cr_npc_sound(_n,_success?_n.params.audCongrats:_n.params.audSad);cr_wander(_n);
    }
    _g.rope_npc=undefined;
}
function cr_playtime_cooldown_step(_n,_dt) {
    if(_n.cooldown<=0)return;
    _n.cooldown=max(0,_n.cooldown-_dt);
    if(_n.cooldown<=0){_n.sad=false;_n.anim_time=0;}
}
function cr_rope_step(_dt,_jump) {
    var _g=global.bbcr;if(!_g.rope)return;
    var _src=global.cr_ui_data.jumprope,_modifier=_g.hard?1.6:1;
    if(point_distance(_g.px,_g.pz,_g.rope_anchor[0],_g.rope_anchor[1])>10){cr_rope_end(false);return;}
    if(_jump && _g.jump_height<=0)_g.jump_velocity=_src.initVelocity;
    if(_g.jump_velocity!=0 || _g.jump_height>0){
        _g.jump_height+=_g.jump_velocity*_dt+.5*_src.accel*_dt*_dt*_modifier;
        _g.jump_velocity+=_src.accel*_dt*_modifier;
        if(_g.jump_height<=0){_g.jump_height=0;_g.jump_velocity=0;_g.rope_anchor=[_g.px,_g.pz];}
    }
    if(_g.rope_anim>=0)_g.rope_anim+=_dt*_modifier;
    if(_g.jumps>=_g.rope_max){if(_g.jump_height<=0)cr_rope_end(true);return;}
    _g.rope_timer-=_dt*_modifier;_g.rope_time+=_dt*_modifier;
    if(_g.rope_timer<=0){
        if(_g.rope_phase==0){_g.rope_phase=1;_g.rope_timer=_src.ropeTime;_g.rope_anim=0;}
        else {
            var _n=_g.rope_npc;
            if(_g.jump_height>_src.jumpBuffer){_g.jumps++;cr_npc_sound(_n,_n.params.audCount[_g.jumps-1]);}
            else {_g.jumps=0;cr_npc_sound(_n,_n.params.audOops);}
            _g.rope_phase=0;_g.rope_timer=_src.ropeDelay;_g.rope_time=0;
        }
    }
}
function cr_rope_move_scale() {return global.bbcr.rope?(global.bbcr.jump_height>0?.25:0):1;}
function cr_rope_draw() {
    var _g=global.bbcr;if(!_g.rope)return;
    var _old=global.cr_ui;global.cr_ui=global.cr_rope_ui;
    var _src=global.cr_ui_data.jumprope,_anim=global.cr_ui_data.animations[$ (_g.rope_anim<0?"Entry":"Jumprope")];
    var _node=cr_ui_node("Jumprope/RopeCanvas/Jumprope_0"),_key=cr_ui_animation_sprite(_anim,max(0,_g.rope_anim));
    var _s=global.cr_ui_data.images[$ _key],_w=_s.source_size[0]/_s.ppu,_h=_s.source_size[1]/_s.ppu;
    _node.image_override=_key;_node.rect=[240-_w*_s.pivot.x,180-_h*(1-_s.pivot.y),_w,_h];
    cr_ui_set_text(cr_ui_node(_src.instructionsTmp),string_replace_all(global.cr_text.Hud_Playtime_Instructions,"{0}","SPACE"));
    cr_ui_set_text(cr_ui_node(_src.countTmp),string(_g.jumps)+"/"+string(_g.rope_max));
    cr_ui_draw_nodes();global.cr_ui=_old;
}
function cr_rule_break(_rule,_linger) {
    var _g=global.bbcr;if(_linger>=_g.guilt_time){_g.guilt=_rule;_g.guilt_time=_linger;}
}
function cr_principal_notice(_n,_seen,_dt) {
    var _g=global.bbcr;
    if(!_seen){_n.sight=0;return;}
    // Principal.PlayerLost resets sight time. Briefly obeying while still seen does not.
    if(_g.guilt_time>0 && !_n.angry){
        _n.sight+=_dt;
        if(_n.sight>=_n.params.timeToScold){
            _n.angry=true;_n.route_timer=0;_n.target_npc=-1;
            if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);
            var _key=cr_value(_n.params,"audNo"+_g.guilt,"");_n.voice=cr_npc_sound(_n,_key);
        }
    }
}
function cr_bully_hide(_n) {
    _n.hidden=true;_n.cooldown=random_range(_n.params.minDelay,_n.params.maxDelay);
    _n.stay=0;_n.spoken=false;_n.contact=false;_n.bully_guilt=0;
}
function cr_bully_edge(_a,_b) {
    var _tiles=global.cr_map.tiles,_p=_tiles[_a],_q=_tiles[_b],_cx=(_p.x+_q.x)*5+5,_cz=(_p.z+_q.z)*5+5;
    for(var _i=0;_i<array_length(global.bbcr.doors);_i++){
        var _d=global.bbcr.doors[_i];if(abs(_d.cx-_cx)<.01 && abs(_d.cz-_cz)<.01 && (_d.lock>0 || _d.locked))return false;
    }return true;
}
function cr_bully_trap(_index) {
    var _tiles=global.cr_map.tiles,_neighbors=[];
    for(var _d=0;_d<4;_d++){var _j=_tiles[_index].nav[_d];if(_j>=0 && cr_bully_edge(_index,_j))array_push(_neighbors,_j);}
    if(array_length(_neighbors)<2)return false;
    var _seen=array_create(array_length(_tiles),false),_queue=[_neighbors[0]],_head=0;_seen[_index]=true;_seen[_neighbors[0]]=true;
    while(_head<array_length(_queue)){
        var _i=_queue[_head++];
        for(var _d=0;_d<4;_d++){
            var _j=_tiles[_i].nav[_d];if(_j>=0 && !_seen[_j] && cr_bully_edge(_i,_j)){_seen[_j]=true;array_push(_queue,_j);}
        }
    }
    for(var _i=1;_i<array_length(_neighbors);_i++)if(!_seen[_neighbors[_i]])return true;
    return false;
}
function cr_bully_spawn(_n) {
    var _g=global.bbcr,_choices=array_create(array_length(global.cr_map.bully_candidates));array_copy(_choices,0,global.cr_map.bully_candidates,0,array_length(_choices));
    while(array_length(_choices)>0){
        var _pick=irandom(array_length(_choices)-1),_index=_choices[_pick];array_delete(_choices,_pick,1);
        var _t=global.cr_map.tiles[_index],_x=_t.x*10+5,_z=_t.z*10+5;
        if(point_distance(_x,_z,_g.px,_g.pz)<=_n.params.playerBuffer || cr_bully_trap(_index))continue;
        _n.px=_x;_n.pz=_z;_n.intended=[_x,_z];_n.hidden=false;_n.stay=_n.params.maxStay;_n.cooldown=0;_n.contact=false;_n.spawn_tile=_index;return true;
    }
    // Retry next second if dynamic locks/player placement leave no candidate.
    _n.cooldown=1;return false;
}
function cr_bully_step(_n,_dt) {
    var _g=global.bbcr,_p=_n.params;
    if(_n.spawn_pending){
        var _dx=abs(_n.hx-_g.px),_dz=abs(_n.hz-_g.pz);
        if(!_p.ignorePlayerOnSpawn && (sqrt(sqr(_dx)+sqr(_dz)+25)<=75 || _dx<=15 || _dz<=15))return;
        _n.spawn_pending=false;cr_bully_hide(_n);return;
    }
    if(_n.hidden){_n.cooldown=max(0,_n.cooldown-_dt);if(_n.cooldown<=0)cr_bully_spawn(_n);return;}
    _n.stay-=_dt;_n.bully_guilt=max(0,_n.bully_guilt-_dt);
    if(_n.stay<=0 || point_distance(_n.px,_n.pz,_n.intended[0],_n.intended[1])>.0001){cr_bully_hide(_n);cr_npc_sound(_n,_p.bored);return;}
    for(var _i=0;_i<array_length(_g.projectiles);_i++){
        var _s=_g.projectiles[_i];if(point_distance(_n.px,_n.pz,_s.px,_s.pz)<5){cr_npc_push(_n,_s.dx*30*_dt,_s.dz*30*_dt);return;}
    }
    var _seen=point_distance(_n.px,_n.pz,_g.px,_g.pz)<=_p.sight_distance && cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_p.sight_mask);
    if(_seen){_n.bully_guilt=10;if(!_n.spoken){cr_npc_sound(_n,_p.callouts[irandom(array_length(_p.callouts)-1)]);_n.spoken=true;}}
    var _r=global.cr_catalog.movement.radius,_dx=max(0,abs(_g.px-_n.px)-_p.trigger_half[0]),_dz=max(0,abs(_g.pz-_n.pz)-_p.trigger_half[2]),_contact=_dx*_dx+_dz*_dz<_r*_r;
    if(_contact && !_n.contact){
        var _slots=[];for(var _i=0;_i<3;_i++)if(_g.inventory[_i]!="" && !array_contains(_p.reject_types,global.cr_catalog.items[$ _g.inventory[_i]].type))array_push(_slots,_i);
        if(array_length(_slots)>0){_g.inventory[_slots[irandom(array_length(_slots)-1)]]="";cr_bully_hide(_n);cr_npc_sound(_n,_p.takeouts[irandom(array_length(_p.takeouts)-1)]);return;}
        cr_npc_sound(_n,_p.noItems);
    }_n.contact=_contact;
}
function cr_principal_bully(_n) {
    var _list=global.bbcr.npcs;
    // Keep the targeted NPC until trigger contact, even after sight/guilt expires.
    // Principal.OnTriggerStay is independent of this frame's Looker result.
    if(_n.target_npc>=0){
        var _b=_list[_n.target_npc];
        if(_b.hidden)_n.target_npc=-1;
        else if(cr_principal_bully_contact(_n,_b)){cr_principal_evict(_n,_b);return;}
    }
    for(var _i=0;_i<array_length(_list);_i++){
        var _b=_list[_i];if(_b.name!="Bully" || _b.hidden || _b.bully_guilt<=0)continue;
        if(point_distance(_n.px,_n.pz,_b.px,_b.pz)>_n.params.sight_distance || !cr_clear_line(_n.px,_n.pz,_b.px,_b.pz,_n.params.sight_mask))break;
        if(_n.target_npc!=_i){
            _n.target_npc=_i;if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);
            _n.voice=cr_npc_sound(_n,_n.params.audNoBullying);
        }
        _n.gx=_b.px;_n.gz=_b.pz;_n.route_timer=0;
        if(cr_principal_bully_contact(_n,_b))cr_principal_evict(_n,_b);
        break;
    }
}
function cr_principal_bully_contact(_n,_b) {
    var _x=max(0,abs(_n.px-_b.px)-_b.params.trigger_half[0]),_z=max(0,abs(_n.pz-_b.pz)-_b.params.trigger_half[2]);
    return _x*_x+_z*_z<sqr(_n.params.collision_radius);
}
function cr_principal_evict(_n,_b) {
    var _m=global.cr_map,_offices=[];
    for(var _i=0;_i<array_length(_m.rooms);_i++)if(_m.rooms[_i].category==3)array_push(_offices,_i);
    if(array_length(_offices)==0)return;
    var _room=_offices[irandom(array_length(_offices)-1)],_xmin=1000000,_zmin=1000000,_xmax=0,_zmax=0;
    for(var _i=0;_i<array_length(_m.tiles);_i++){var _t=_m.tiles[_i];if(_t.room!=_room)continue;_xmin=min(_xmin,_t.x);_xmax=max(_xmax,_t.x);_zmin=min(_zmin,_t.z);_zmax=max(_zmax,_t.z);}
    _b.px=(_xmin+_xmax+1)*5;_b.pz=(_zmin+_zmax+1)*5;_b.bully_guilt=0;_n.target_npc=-1;_n.bully_evictions=cr_value(_n,"bully_evictions",0)+1;
}

function cr_baldi_clear_sounds(_n) {
    for(var _i=0;_i<128;_i++)_n.sound_locations[_i]=undefined;
    _n.current_sound=0;_n.priority=0;_n.targeting_sound=false;
}
function cr_baldi_update_sound(_n) {
    for(var _i=127;_i>=0;_i--){
        var _p=_n.sound_locations[_i];if(is_undefined(_p))continue;
        _n.sound_locations[_i]=undefined;_n.gx=_p[0];_n.gz=_p[1];_n.current_sound=_i;_n.priority=_i;_n.targeting_sound=true;
        _n.route_timer=0;
        // NULL receives priority 127 every boss frame. Keep its current route
        // until the destination grid cell changes; rebuilding it discards travel.
        if(!is_struct(global.bbcr.null_mode) && path_exists(_n.path))path_clear_points(_n.path);return true;
    }
    _n.current_sound=0;_n.priority=0;_n.targeting_sound=false;return false;
}
function cr_baldi_hear(_n,_x,_z,_value,_indicator=true) {
    var _g=global.bbcr,_level=clamp(round(_value),0,127);
    _n.sound_locations[_level]=[_x,_z];_n.targeting_sound=true;
    if(_indicator){
        _g.indicator_state=_level>=_n.current_sound?"Baldicator_Look":"Baldicator_Think";
        _g.indicator=global.cr_ui_data.animations[$ _g.indicator_state].length;
    }
    if(_level>=_n.current_sound)cr_baldi_update_sound(_n);
}
function cr_baldi_destination(_n) {
    if(!cr_baldi_update_sound(_n))cr_wander(_n);
}
function cr_npc_voice_tick(_n) {
    if(!audio_is_playing(_n.voice) && array_length(_n.voice_queue)>0)_n.voice=cr_npc_sound(_n,array_shift(_n.voice_queue));
}
function cr_room_mid(_room) {
    var _m=global.cr_map,_xmin=1000000,_zmin=1000000,_xmax=-1,_zmax=-1;
    for(var _i=0;_i<array_length(_m.tiles);_i++){var _t=_m.tiles[_i];if(_t.room!=_room)continue;_xmin=min(_xmin,_t.x);_xmax=max(_xmax,_t.x);_zmin=min(_zmin,_t.z);_zmax=max(_zmax,_t.z);}
    return [(_xmin+_xmax+1)*5,(_zmin+_zmax+1)*5];
}
function cr_detention_begin(_time,_room=-1) {
    var _g=global.bbcr;_g.detention=_time;_g.detention_escape=_time;_g.detention_room=_room;_g.detention_inside=_room>=0;
    if(variable_global_exists("cr_detention_ui"))cr_ui_dispose(global.cr_detention_ui);
    global.cr_detention_ui=cr_ui_context("Detention");
}
function cr_detention_step(_dt) {
    var _g=global.bbcr;_g.detention=max(0,_g.detention-_dt);_g.detention_escape=max(0,_g.detention_escape-_dt*1.25);
    if(_g.detention_room<0 || _g.detention_escape<=0)return;
    var _tile=cr_tile(_g.px,_g.pz),_inside=!is_undefined(_tile) && _tile.room==_g.detention_room;
    if(_g.detention_inside && !_inside)cr_rule_break("Escaping",_g.detention_escape);
    _g.detention_inside=_inside;
}
function cr_detention_draw() {
    var _g=global.bbcr;if(_g.detention<=0)return;
    var _old=global.cr_ui;global.cr_ui=global.cr_detention_ui;
    cr_ui_set_text(cr_ui_node(global.cr_ui_data.detention.timer),string(ceil(_g.detention)));
    cr_ui_draw_nodes();global.cr_ui=_old;
}
function cr_principal_detain(_n) {
    var _g=global.bbcr,_m=global.cr_map,_offices=[];
    for(var _i=0;_i<array_length(_m.rooms);_i++)if(_m.rooms[_i].category==3)array_push(_offices,_i);
    if(array_length(_offices)==0)return;
    var _room=_offices[irandom(array_length(_offices)-1)],_mid=cr_room_mid(_room),_p=_n.params;
    _g.px=_mid[0];_g.pz=_mid[1];cr_rope_end(false);_g.guilt="";_g.guilt_time=0;
    _n.px=_g.px+sin(_g.yaw)*10;_n.pz=_g.pz+cos(_g.yaw)*10;
    var _last=max(0,array_length(_p.audTimes)-1),_level=min(_g.detention_level,_last);
    var _time=_p.detentionInit+_p.detentionInc*_g.detention_level;if(_g.detention_level>=_last)_time=99;
    cr_detention_begin(_time,_room);
    for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(_d.a_room==_room || _d.b_room==_room){_d.lock=_time;_d.open=0;}}
    if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);_n.voice=-1;
    _n.voice_queue=[_p.audTimes[_level],_p.audDetention,_p.audScolds[irandom(array_length(_p.audScolds)-1)]];cr_npc_voice_tick(_n);
    _g.detention_level=min(_last,_g.detention_level+(_g.hard?3:1));
    _n.angry=false;_n.sight=0;_n.cooldown=3;_n.speed=0;_n.target_npc=-1;
    cr_noise(_g.px,_g.pz,_p.detentionNoise);cr_wander(_n);
}
function cr_crafters_camera_visible(_n) {
    var _g=global.bbcr,_d=point_distance(_g.px,_g.pz,_n.px,_n.pz);if(_d<=.0001)return true;
    var _yaw=cr_view_yaw(),_dot=((_n.px-_g.px)*sin(_yaw)+(_n.pz-_g.pz)*cos(_yaw))/_d;
    var _vfov=global.cr_catalog.camera.vertical_fov,_hfov=radtodeg(2*arctan(tan(degtorad(_vfov)*.5)*(640/480)));
    return _dot>=cos(degtorad(_hfov*.5+_n.params.visibility_buffer));
}
function cr_crafters_run_from(_n) {
    var _g=global.bbcr,_tiles=global.cr_map.tiles,_best=-1,_distance=-1;
    for(var _i=0;_i<array_length(_tiles);_i++){var _t=_tiles[_i];if(_t.room!=0)continue;var _d=point_distance(_g.px,_g.pz,_t.x*10+5,_t.z*10+5);if(_d>_distance){_distance=_d;_best=_i;}}
    if(_best>=0){var _t=_tiles[_best];_n.gx=_t.x*10+5;_n.gz=_t.z*10+5;_n.route_timer=0;}
    _n.running=true;_n.speed=_n.params.normSpeed;_n.run_time=random_range(_n.params.minSightTime,_n.params.maxSightTime);
}
function cr_crafters_get_angry(_n) {
    _n.angry=true;_n.running=false;_n.crafters_state="angry";_n.speed=0;_n.route_timer=0;if(path_exists(_n.path))path_clear_points(_n.path);
    if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);_n.voice=cr_npc_sound(_n,_n.params.audIntro);_n.voice_phase=0;
}
function cr_crafters_audio_tick(_n) {
    if((_n.crafters_state=="angry" || _n.crafters_state=="attack") && _n.voice_phase==0 && !audio_is_playing(_n.voice)){
        _n.voice=cr_npc_sound(_n,_n.params.audLoop);if(_n.voice>=0)audio_sound_loop(_n.voice,true);_n.voice_phase=1;
    }
}
function cr_map_tile_path(_start,_end) {
    var _tiles=global.cr_map.tiles,_parents=array_create(array_length(_tiles),-2),_queue=[_start],_head=0;_parents[_start]=-1;
    while(_head<array_length(_queue) && _parents[_end]==-2){
        var _i=_queue[_head++],_nav=_tiles[_i].nav;
        for(var _d=0;_d<4;_d++){var _j=_nav[_d];if(_j>=0 && _parents[_j]==-2){_parents[_j]=_i;array_push(_queue,_j);}}
    }
    if(_parents[_end]==-2)return [];
    var _reverse=[],_out=[],_cur=_end;while(_cur>=0){array_push(_reverse,_cur);_cur=_parents[_cur];}
    for(var _i=array_length(_reverse)-1;_i>=0;_i--)array_push(_out,_reverse[_i]);return _out;
}
function cr_crafters_finish(_n,_forced_exit=-1,_forced_hall=-1) {
    var _g=global.bbcr,_p=_n.params,_exits=[],_halls=[],_path=[];
    for(var _i=0;_i<array_length(_g.exits);_i++)if(!_g.exits[_i].used && _g.exits[_i].state==0)array_push(_exits,_i);
    if(array_length(_exits)==0)for(var _i=0;_i<array_length(_g.exits);_i++)array_push(_exits,_i);
    for(var _i=0;_i<array_length(global.cr_map.tiles);_i++)if(global.cr_map.tiles[_i].room==0)array_push(_halls,_i);
    var _baldi_distance=_g.hard?12:_p.baldiSpawnDistance;
    var _exit_index=_forced_exit>=0?_forced_exit:_exits[irandom(array_length(_exits)-1)],_e=_g.exits[_exit_index];
    var _start=cr_tile(_e.door_tile[0]*10+5,_e.door_tile[1]*10+5);
    repeat(32){
        if(array_length(_exits)==0 || array_length(_halls)==0 || is_undefined(_start))break;
        var _hall=_forced_hall>=0?_forced_hall:_halls[irandom(array_length(_halls)-1)];
        _path=cr_map_tile_path(_start.index,_hall);if(array_length(_path)>_baldi_distance)break;_path=[];
        if(_forced_hall>=0)break;
    }
    if(array_length(_path)>_baldi_distance){
        var _pt=global.cr_map.tiles[_path[_p.playerSpawnDistance]];_g.px=_pt.x*10+5;_g.pz=_pt.z*10+5;
        cr_noise(_g.px,_g.pz,_p.noiseValue);
        var _b=_g.npcs[0],_bt=global.cr_map.tiles[_path[_baldi_distance]];_b.px=_bt.x*10+5;_b.pz=_bt.z*10+5;_b.route_timer=0;
    }
    _n.teleport_exit=_exit_index;_n.teleport_path=_path;
    if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);_n.voice=-1;_n.hidden=true;_n.angry=false;_n.crafters_state="gone";_n.echoes=[];
}
function cr_crafters_attack_begin(_n) {
    var _g=global.bbcr;_n.crafters_state="attack";_n.attack_time=0;_n.attack_spin=_n.params.attackSpinSpeed;_n.echo_distance=0;
    _n.attack_angle=_g.yaw+pi;_n.px=_g.px+sin(_g.yaw)*8;_n.pz=_g.pz+cos(_g.yaw)*8;_n.echoes=[];
    if(path_exists(_n.path))path_clear_points(_n.path);
}
function cr_crafters_trigger_step(_n) {
    if(_n.angry || _n.crafters_state=="attack" || _n.crafters_state=="gone" || _n.spawn_target>=0)return;
    var _tile=cr_tile(global.bbcr.px,global.bbcr.pz),_index=is_undefined(_tile)?-1:_tile.index;
    if(_index==_n.trigger_tile)return;_n.trigger_tile=_index;
    for(var _i=0;_i<array_length(global.cr_map.crafters_triggers);_i++){
        var _tr=global.cr_map.crafters_triggers[_i];if(_tr.trigger!=_index || random(1)>_n.params.spawnChance)continue;
        // SpawnAt interrupts running and waits for both the old and new
        // renderer positions to leave the camera before revealing Crafters.
        _n.spawn_target=_tr.target;_n.spawn_phase=0;_n.running=false;_n.speed=0;
        if(path_exists(_n.path))path_clear_points(_n.path);return;
    }
}
function cr_crafters_teleport_step(_n) {
    if(_n.spawn_target<0)return false;
    if(_n.spawn_phase==0){
        if(cr_crafters_camera_visible(_n))return true;
        _n.hidden=true;var _target=global.cr_map.tiles[_n.spawn_target];
        _n.px=_target.x*10+5;_n.pz=_target.z*10+5;_n.gx=_n.px;_n.gz=_n.pz;_n.spawn_phase=1;return true;
    }
    if(_n.spawn_phase==1){_n.spawn_phase=2;return true;}
    if(!cr_crafters_camera_visible(_n)){
        _n.hidden=false;_n.crafters_state="idle";_n.spawn_target=-1;_n.spawn_phase=0;_n.viewtime=0;_n.sight=0;
    }
    return true;
}
function cr_crafters_step(_n,_dt,_seen) {
    var _g=global.bbcr,_p=_n.params;if(_n.crafters_state=="gone")return;
    cr_crafters_trigger_step(_n);if(cr_crafters_teleport_step(_n))return;
    if(_n.hidden || _n.crafters_state=="hidden")return;
    cr_crafters_audio_tick(_n);
    if(_n.crafters_state=="attack"){
        _n.attack_angle+=degtorad(_n.attack_spin*_dt);_n.px=_g.px+sin(_n.attack_angle)*_p.spinDistance;_n.pz=_g.pz+cos(_n.attack_angle)*_p.spinDistance;
        _n.echoes=[];for(var _i=0;_i<_p.echo_count;_i++){var _a=_n.attack_angle-degtorad(_n.echo_distance*_i*_dt),_r=_p.spinDistance+_i+1;array_push(_n.echoes,[_g.px+sin(_a)*_r,_g.pz+cos(_a)*_r]);}
        _n.attack_spin+=_p.attackSpinAccel*_dt;_n.echo_distance+=_p.echoIncrease*_dt;_n.attack_time+=_dt;if(_n.attack_time>=_p.attackTime)cr_crafters_finish(_n);return;
    }
    for(var _i=0;_i<array_length(_g.projectiles);_i++){var _s=_g.projectiles[_i];if(point_distance(_s.px,_s.pz,_n.px,_n.pz)<5){cr_npc_push(_n,_s.dx*30*_dt,_s.dz*30*_dt);_n.route_timer=0;return;}}
    var _viewed=_seen && cr_crafters_camera_visible(_n);
    if(_seen)_n.viewtime+=_dt;else {if(_n.was_seen)_n.viewtime=0;else _n.viewtime=max(0,_n.viewtime-_dt);_n.sight=0;}
    if(_viewed)_n.sight+=_dt;else _n.sight=max(0,_n.sight-_dt);
    _n.was_seen=_seen;
    if(_g.notebooks>=_g.needed && _n.sight>=_p.angerTime && !_n.angry && !_n.running)cr_crafters_get_angry(_n);
    if(!_n.angry && !_n.running && _n.viewtime>=_n.run_time)cr_crafters_run_from(_n);
    if(_n.angry){
        if(_seen){_n.gx=_g.px;_n.gz=_g.pz;_n.route_timer=0;}
        _n.speed=min(_p.angryMaxSpeed,_n.speed+_p.angryAccel*_dt);cr_npc_move(_n,_n.speed,_dt);
        if(point_distance(_n.px,_n.pz,_g.px,_g.pz)<4){cr_crafters_attack_begin(_n);return;}
        if(!_seen && point_distance(_n.px,_n.pz,_n.gx,_n.gz)<3)cr_wander(_n);return;
    }
    if(_n.running){cr_npc_move(_n,_p.normSpeed,_dt);if(point_distance(_n.px,_n.pz,_n.gx,_n.gz)<3){_n.running=false;_n.speed=0;_n.viewtime=0;}}
}
