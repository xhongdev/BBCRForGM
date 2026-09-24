function cr_build_navigation(_actor=undefined) {
    var _m=global.cr_map;global.cr_nav=mp_grid_create(0,0,_m.size.x*5,_m.size.z*5,2,2);
    for(var _z=0;_z<_m.size.z*5;_z++)for(var _x=0;_x<_m.size.x*5;_x++){
        var _t=cr_tile(_x*2+1,_z*2+1);
        if(cr_blocked(_x*2+1,_z*2+1,2,false,true,_actor) || (!is_undefined(_t) && _t.room==0 && _x mod 5!=2 && _z mod 5!=2))mp_grid_add_cell(global.cr_nav,_x,_z);
    }
}
function cr_nav_point(_x,_z) {
    var _tile=cr_tile(_x,_z);if(!is_undefined(_tile) && _tile.room==0){_x=_tile.x*10+5;_z=_tile.z*10+5;}
    if(!cr_blocked(_x,_z,2,false))return [_x,_z];
    for(var _r=2;_r<=12;_r+=2)for(var _a=0;_a<360;_a+=30){var _px=_x+lengthdir_x(_r,_a),_pz=_z+lengthdir_y(_r,_a),_t=cr_tile(_px,_pz);if(!is_undefined(_t) && _t.room==0){_px=_t.x*10+5;_pz=_t.z*10+5;}if(!cr_blocked(_px,_pz,2,false))return [_px,_pz];}
    return [_x,_z];
}
function cr_nav_start(_x,_z) {
    var _tile=cr_tile(_x,_z);
    if(!is_undefined(_tile) && !cr_blocked(_x,_z,2,false) && (_tile.room!=0 || abs(_x-(_tile.x*10+5))<.001 || abs(_z-(_tile.z*10+5))<.001))return [_x,_z];
    var _best=[],_distance=1000000000;
    for(var _z0=max(0,floor(_z/2)-6);_z0<=min(global.cr_map.size.z*5-1,floor(_z/2)+6);_z0++)for(var _x0=max(0,floor(_x/2)-6);_x0<=min(global.cr_map.size.x*5-1,floor(_x/2)+6);_x0++){
        if(mp_grid_get_cell(global.cr_nav,_x0,_z0)<0)continue;
        var _px=_x0*2+1,_pz=_z0*2+1,_d=point_distance(_x,_z,_px,_pz);
        if(_d<_distance){_distance=_d;_best=[_px,_pz];}
    }return array_length(_best)>0?_best:cr_nav_point(_x,_z);
}
function cr_npc_push(_n,_dx,_dz) {
    var _t=cr_tile(_n.px,_n.pz),_budget=point_distance(0,0,_dx,_dz);
    if(_budget<=.000001)return;
    if(!is_undefined(_t) && _t.room==0){
        // Spend displacement on centering first, including while BSODA is active.
        // Keep cardinal travel in halls even when a spray arrives at an angle.
        var _vertical=abs(_dz)>abs(_dx);if((_t.walls & 10)==10)_vertical=true;else if((_t.walls & 5)==5)_vertical=false;
        var _offset=_vertical?_t.x*10+5-_n.px:_t.z*10+5-_n.pz,_correction=clamp(_offset,-_budget,_budget);
        cr_move(_n,_vertical?_correction:0,_vertical?0:_correction,_n.params.collision_radius);_budget-=abs(_correction);
        if(abs(_offset)>abs(_correction)+.0001)return;
        if(_vertical){_dx=0;_dz=sign(_dz)*min(abs(_dz),_budget);}else{_dz=0;_dx=sign(_dx)*min(abs(_dx),_budget);}
    }
    cr_move(_n,_dx,_dz,_n.params.collision_radius);
}
function cr_baldi_tick(_n,_dt) {
    if(cr_value(_n,"math_pause",0)>0){_n.math_pause=max(0,_n.math_pause-_dt);return;}
    var _g=global.bbcr,_p=_n.params,_delay=cr_curve(_p.slapCurve,_g.anger+_g.extra_anger);
    _n.slap_distance+=(cr_curve(_p.speedCurve,_g.anger)+_p.baseSpeed+_g.extra_anger)*_dt;
    _n.slap_timer-=_dt;_n.slap_frame=max(0,_n.slap_frame-_dt);
    if(_n.slap_timer<=0){
        _n.slap_timer=_delay;_n.slap_left=_n.slap_distance;_n.slap_distance=0;
        var _portion=is_struct(_g.null_mode) && _g.null_mode.phase!="collect"?1:max(.1,_g.anger/(_g.anger+50));
        _n.slap_speed=_n.slap_left/(_delay*_portion);
        _n.slap_frame=.4;_n.slap_count++;
        if(_g.style=="demo" && _g.demo.ruler){if(_g.demo.ruler_break){cr_npc_sound(_n,_p.rulerBreak);_g.demo.ruler_break=false;}}
        else if(cr_value(_p,"slap","")!="")cr_npc_sound(_n,_p.slap);
    }
}
function cr_wander(_n) {
    var _tiles=global.cr_map.tiles;
    repeat(100){var _t=_tiles[irandom(array_length(_tiles)-1)];if(_t.room==0 && !cr_blocked(_t.x*10+5,_t.z*10+5,1.6,false)){_n.gx=_t.x*10+5;_n.gz=_t.z*10+5;_n.route_timer=0;return;}}
}
function cr_npc_move(_n,_speed,_dt) {
    if(is_struct(global.bbcr.null_mode))return cr_null_navigate(_n,_speed,_dt);
    _n.route_timer-=_dt;
    if(_n.route_timer<=0){
        var _start=cr_nav_start(_n.px,_n.pz),_end=cr_nav_point(_n.gx,_n.gz);
        if(path_get_number(_n.path)==0 || _n.node>=path_get_number(_n.path) || cr_value(_n,"route_x",-1)!=_end[0] || cr_value(_n,"route_z",-1)!=_end[1]){
            if(mp_grid_path(global.cr_nav,_n.path,_start[0],_start[1],_end[0],_end[1],false)){
                _n.node=0;
                if(path_get_number(_n.path)>1){
                    var _ax=path_get_point_x(_n.path,0),_az=path_get_point_y(_n.path,0),_bx=path_get_point_x(_n.path,1),_bz=path_get_point_y(_n.path,1);
                    // A replan must not walk backwards to its quantized start.
                    // Skip it only on the same segment, never across a corner.
                    if(cr_segment_distance(_n.px,_n.pz,_ax,_az,_bx,_bz)<.001)_n.node=1;
                }
            }else path_clear_points(_n.path);
            _n.route_x=_end[0];_n.route_z=_end[1];
        }
        _n.route_timer=.7+random(.2);
    }
    var _remain=_speed*_dt*cr_demo_move_scale(_n),_ox=_n.px,_oz=_n.pz,_total=0;
    while(_remain>.001 && _n.node<path_get_number(_n.path)){
        var _x=path_get_point_x(_n.path,_n.node),_z=path_get_point_y(_n.path,_n.node),_dist=point_distance(_n.px,_n.pz,_x,_z);
        if(_dist<=.05){_n.node++;continue;}
        for(var _i=0;_i<array_length(global.bbcr.doors);_i++) {var _d=global.bbcr.doors[_i];if(cr_box_overlap(_d.trigger,_n.px,_n.pz,1.5)){
            if(!_d.locked && _d.lock<=0)cr_door_open(_d,false);
        }}
        var _travel=min(_remain,_dist),_before_x=_n.px,_before_z=_n.pz;cr_move(_n,(_x-_n.px)/_dist*_travel,(_z-_n.pz)/_dist*_travel,_n.params.collision_radius);_remain-=_travel;
        _total+=point_distance(_before_x,_before_z,_n.px,_n.pz);
        if(point_distance(_n.px,_n.pz,_x,_z)<.1)_n.node++;else break;
    }
    if(point_distance(_ox,_oz,_n.px,_n.pz)>.001)_n.yaw=arctan2(_n.px-_ox,_n.pz-_oz);
    if(point_distance(_ox,_oz,_n.px,_n.pz)<=.001 && _speed>0)_n.timer+=_dt;else _n.timer=0;
    // Beans' DestinationEmpty dispatch is also where he begins SpitSequence.
    // Silently wandering here prevented it whenever a snapped endpoint or a
    // failed path differed from the unsnapped target.
    if(_n.name=="Beans" && (_n.node>=path_get_number(_n.path) || _n.timer>2))_n.destination_empty=true;
    else if(_n.timer>2){if(_n.target_npc<0)cr_wander(_n);else{path_clear_points(_n.path);_n.route_timer=0;}_n.timer=0;}
    return _total;
}
function cr_curve(_keys,_time) {
    if(_time<=_keys[0].time)return _keys[0].value;
    for(var _i=1;_i<array_length(_keys);_i++){
        var _b=_keys[_i],_a=_keys[_i-1];if(_time>_b.time)continue;
        var _span=_b.time-_a.time,_t=(_time-_a.time)/_span,_t2=_t*_t,_t3=_t2*_t;
        if((cr_value(_a,"weightedMode",0) & 2)!=0 || (cr_value(_b,"weightedMode",0) & 1)!=0){
            var _wa=(cr_value(_a,"weightedMode",0) & 2)!=0?_a.outWeight:1/3,_wb=(cr_value(_b,"weightedMode",0) & 1)!=0?_b.inWeight:1/3;
            var _lo=0,_hi=1,_u=0;
            repeat(30){_u=(_lo+_hi)/2;var _v=1-_u,_x=3*_v*_v*_u*_wa+3*_v*_u*_u*(1-_wb)+_u*_u*_u;if(_x*1000000<_t*1000000)_lo=_u;else _hi=_u;}
            var _v=1-_u;return _v*_v*_v*_a.value+3*_v*_v*_u*(_a.value+_a.outSlope*_span*_wa)+3*_v*_u*_u*(_b.value-_b.inSlope*_span*_wb)+_u*_u*_u*_b.value;
        }
        return (2*_t3-3*_t2+1)*_a.value+(_t3-2*_t2+_t)*_a.outSlope*_span+(-2*_t3+3*_t2)*_b.value+(_t3-_t2)*_b.inSlope*_span;
    }return _keys[array_length(_keys)-1].value;
}
function cr_doors_step(_dt) {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(_g.doors);_i++){
        var _d=_g.doors[_i];_d.lock=max(0,_d.lock-_dt);var _was=_d.open;_d.open=max(0,_d.open-_dt);
        if(_was>0 && _d.open<=0 && !_d.swing && _d.silent<=0)cr_sound("Doors_StandardShut",_d.cx,_d.cz);
        if(_d.swing){
            var _inside=cr_box_overlap(_d.trigger,_g.px,_g.pz,global.cr_catalog.movement.radius);
            if(_inside && !_d.player_inside && _g.notebooks<2 && _g.mode!="free" && _d.need_sound!=""){
                if(audio_is_playing(_d.need_voice))audio_stop_sound(_d.need_voice);_d.need_voice=cr_sound(_d.need_sound,_d.cx,_d.cz);
            }
            if(_inside)cr_door_open(_d,true);_d.player_inside=_inside;
        }
    }
}
function cr_world_step(_dt) {
    var _g=global.bbcr;_g.boots=max(0,_g.boots-_dt);_g.deaf=max(0,_g.deaf-_dt);_g.indicator=max(0,_g.indicator-_dt);_g.guilt_time=max(0,_g.guilt_time-_dt);
    cr_detention_step(_dt);cr_doors_step(_dt);cr_style_step(_dt);cr_extra_items_step(_dt);
    if(is_struct(_g.null_mode)){cr_alarm_step(_dt);cr_world_item_step(_dt);cr_null_step(_dt);return;}
    if(is_struct(_g.secret_route)){cr_alarm_step(_dt);cr_secret_route_step(_dt);return;}
    if(_g.secret_level){_g.projectiles=[];_g.alarms=[];_g.boots=0;cr_secret_step();return;}
    cr_world_item_step(_dt);
    if(!_g.spoop && _g.mode!="free" && is_struct(global.cr_map.happy)){
        var _h=global.cr_map.happy;_g.happy_time+=_dt;
        var _state=_h.states.BAL_Wave,_anim=global.cr_catalog.animations[$ _state.clip];
        for(var _i=0;_i<array_length(_anim.events);_i++)if(!_g.happy_spoke && _anim.events[_i].functionName=="PlayIntroAudio" && _g.happy_time*_state.speed>=_anim.events[_i].time){_g.happy_voice=cr_sound(_h.sound);_g.happy_spoke=true;}
        if(_g.scene=="math" && _g.hard && is_struct(_g.world_voice))cr_saved_voice_tick(_g.world_voice);
    }
    var _pt=cr_tile(_g.px,_g.pz);if(!is_undefined(_pt) && global.cr_map.rooms[_pt.room].category==4)cr_rule_break("Faculty",1);
    for(var _i=0;_i<array_length(_g.books);_i++)if(_g.mode=="endless" && _g.books[_i].done){_g.books[_i].reset-=_dt;if(_g.books[_i].reset<=0)_g.books[_i].done=false;}
    cr_alarm_step(_dt);
    cr_exit_step(_dt);
    if(_g.spoop && _g.mode!="free"){
        if(_g.mode=="endless"){
            _g.anger_tick-=_dt;while(_g.anger_tick<=0){_g.anger+=_g.anger_rate;_g.anger_rate+=.00025;_g.anger_tick+=1;}
        }
        _g.extra_anger=max(0,_g.extra_anger-_g.npcs[0].params.extraAngerDrain*_dt);
        for(var _i=0;_i<array_length(_g.npcs);_i++){cr_npc_step(_g.npcs[_i],_dt);if(_g.dead)return;}
    }
    if(_g.notebooks>=_g.needed && _g.mode=="story")cr_exits_trigger();
}
function cr_world_item_step(_dt) {
    var _g=global.bbcr;
    for(var _i=array_length(_g.boot_effects)-1;_i>=0;_i--){var _e=_g.boot_effects[_i];_e.time+=_dt;if(_e.time>=_e.duration+2)array_delete(_g.boot_effects,_i,1);}
    for(var _i=array_length(_g.projectiles)-1;_i>=0;_i--){var _s=_g.projectiles[_i];_s.px+=_s.dx*30*_dt;_s.pz+=_s.dz*30*_dt;_s.life-=_dt;if(_s.life<=0)array_delete(_g.projectiles,_i,1);}
}
function cr_npc_step(_n,_dt) {
    if(cr_cheat_flag("freeze_npcs"))return;
    if(is_struct(global.bbcr.demo) && cr_demo_actor_pending(_n))return;
    if(_n.name=="Bully"){cr_bully_step(_n,_dt);return;}
    var _g=global.bbcr,_dist=point_distance(_g.px,_g.pz,_n.px,_n.pz);
    if(_n.name=="Playtime")cr_playtime_cooldown_step(_n,_dt);else _n.cooldown=max(0,_n.cooldown-_dt);
    if(_n.name=="ChalkFace"){cr_demo_chalk(_n,_dt);return;}
    if(_n.name=="Cumulo"){cr_demo_cloud(_n,_dt);return;}
    if(_n.name=="ArtsAndCrafters"){
        var _craft_seen=_dist<_n.params.sight_distance && cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask);
        cr_crafters_step(_n,_dt,_craft_seen);return;
    }
    if(_n.hidden){if(_n.cooldown<=0){_n.hidden=false;cr_wander(_n);_n.px=_n.gx;_n.pz=_n.gz;_n.run_time=random_range(1,6);_n.viewtime=0;}return;}
    cr_npc_voice_tick(_n);
    if(_n.name=="Baldi")cr_baldi_tick(_n,_dt);
    for(var _j=0;_j<array_length(_g.projectiles);_j++){
        var _s=_g.projectiles[_j];if(point_distance(_s.px,_s.pz,_n.px,_n.pz)<5){cr_npc_push(_n,_s.dx*30*_dt,_s.dz*30*_dt);_n.route_timer=0;path_clear_points(_n.path);return;}
    }
    var _sight=_g.style=="demo"?min(_n.params.sight_distance,_g.demo.max_sight):_n.params.sight_distance;
    var _seen=_dist<_sight && cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask),_speed=10;
    switch(_n.name){
        case "Beans":cr_demo_beans(_n,_dt,_seen);return;
        case "Baldi":
            if(_seen){cr_baldi_clear_sounds(_n);cr_baldi_hear(_n,_g.px,_g.pz,127,false);_n.aggroed=true;}
            else {if(_n.was_seen)_n.aggroed=false;if(point_distance(_n.px,_n.pz,_n.gx,_n.gz)<3)cr_baldi_destination(_n);}
            _n.was_seen=_seen;
            _speed=cr_value(_n,"math_pause",0)>0?0:min(_n.slap_speed,_n.slap_left/max(.000001,_dt));
            if(_dist<3 && !cr_cheat_flag("god") && cr_demo_can_touch(_n) && !(is_struct(_g.demo) && _g.demo.ruler) && cr_value(_n,"math_pause",0)<=0){cr_caught(_n);return;}
            break;
        case "Principal":
            _n.speed=min(_n.params.max_speed,_n.speed+_n.params.accel*_dt);_speed=_n.speed;
            cr_principal_notice(_n,_seen,_dt);
            if(_n.angry && (_seen || _g.hard || _n.params.allKnowing)){_n.gx=_g.px;_n.gz=_g.pz;_n.route_timer=0;}
            if(!_n.angry)cr_principal_bully(_n);
            if(_n.angry && _dist<4 && cr_demo_can_touch(_n)){
                cr_principal_detain(_n);
            }
            if(_n.cooldown>0){_speed=0;_n.speed=0;}
            break;
        case "Playtime":
            _n.anim_time+=_dt;
            _speed=_seen && _n.cooldown<=0?_n.params.runSpeed:_n.params.normSpeed;
            if(_seen && _n.cooldown<=0 && !_n.playing){_n.gx=_g.px;_n.gz=_g.pz;_n.route_timer=0;if(!_n.was_seen)cr_npc_sound(_n,_n.params.audLetsPlay);}
            if(_dist<4 && _n.cooldown<=0 && !_g.rope && !_n.contact && cr_demo_can_touch(_n))cr_rope_begin(_n);
            _n.contact=_dist<4;_n.was_seen=_seen;
            if(_n.playing)_speed=0;
            break;
        case "Sweep":case "GottaSweep":
            if(_n.cooldown>0){_speed=0;break;}_speed=40;
            break;
        case "FirstPrize":
            cr_first_prize_step(_n,_dt,_seen);return;
    }
    if(point_distance(_n.px,_n.pz,_n.gx,_n.gz)<3 && !_n.angry && _n.target_npc<0)cr_wander(_n);
    var _ox=_n.px,_oz=_n.pz,_travel=cr_npc_move(_n,_speed,_dt);
    if(_n.name=="Principal" && _n.target_npc>=0){var _b=_g.npcs[_n.target_npc];if(!_b.hidden && cr_principal_bully_contact(_n,_b))cr_principal_evict(_n,_b);}
    if(_n.name=="Baldi")_n.slap_left=max(0,_n.slap_left-_travel);
    if((_n.name=="FirstPrize" || _n.name=="Sweep" || _n.name=="GottaSweep") && _dist<5 && _g.boots<=0)cr_move(_g,(_n.px-_ox)*.9,(_n.pz-_oz)*.9);
}

function cr_corridor_target(_n,_direction,_windows=false) {
    var _dx=round(sin(_direction*pi/2)),_dz=round(cos(_direction*pi/2)),_t=cr_tile(_n.px,_n.pz);
    repeat(global.cr_map.size.x+global.cr_map.size.z){
        if(is_undefined(_t))break;
        var _next=cr_tile((_t.x+_dx)*10+5,(_t.z+_dz)*10+5);if(is_undefined(_next))break;
        var _cx=_t.x*10+5+_dx*5,_cz=_t.z*10+5+_dz*5,_locked=false;
        for(var _j=0;_j<array_length(global.bbcr.doors);_j++){
            var _d=global.bbcr.doors[_j];if(abs(_d.cx-_cx)<.01 && abs(_d.cz-_cz)<.01 && (_d.locked || _d.lock>0))_locked=true;
        }
        for(var _j=0;_j<array_length(global.bbcr.exits);_j++){
            var _e=global.bbcr.exits[_j];if(_e.state>0 && variable_struct_exists(_e,"barrier")){
                var _b=_e.barrier;if(cr_segment_distance(_cx,_cz,_b[0],_b[1],_b[2],_b[3])<.01)_locked=true;
            }
        }if(_locked)break;
        if((_t.walls & (1<<_direction))!=0){
            var _pass=false;
            for(var _j=0;_j<array_length(global.bbcr.doors);_j++){var _d=global.bbcr.doors[_j];if(abs(_d.cx-_cx)<.01 && abs(_d.cz-_cz)<.01 && !_d.locked && _d.lock<=0)_pass=true;}
            if(_windows)for(var _j=0;_j<array_length(global.cr_map.windows);_j++){var _w=global.cr_map.windows[_j];if(abs(_w.cx-_cx)<.01 && abs(_w.cz-_cz)<.01)_pass=true;}
            if(!_pass)break;
        }
        _t=_next;
    }
    return is_undefined(_t)?[_n.px,_n.pz]:[_t.x*10+5,_t.z*10+5];
}
function cr_first_wander(_n) {
    var _choices=[];
    for(var _i=0;_i<4;_i++){
        var _target=cr_corridor_target(_n,_i);if(point_distance(_target[0],_target[1],_n.px,_n.pz)>3)array_push(_choices,_target);
    }
    if(array_length(_choices)>0){var _t=_choices[irandom(array_length(_choices)-1)];_n.gx=_t[0];_n.gz=_t[1];}
    _n.charging=false;
}
function cr_first_voice(_n,_key) {
    if(!audio_is_playing(_n.voice)){
        var _list=_n.params[$ _key];if(array_length(_list)>0)_n.voice=cr_npc_sound(_n,_list[irandom(array_length(_list)-1)]);
    }
}
function cr_first_prize_step(_n,_dt,_seen) {
    var _g=global.bbcr,_p=_n.params,_before=_n.speed;
    if(_seen){
        if(!_n.was_seen)cr_first_voice(_n,"audSee");_n.unseen=1;
        var _dir=(round(radtodeg(arctan2(_g.px-_n.px,_g.pz-_n.pz))/90)+4) mod 4;
        var _target=cr_corridor_target(_n,_dir,_n.speed>=_p.slamSpeed);
        if(_n.speed>_p.wanderSpeed+1)_n.pending_target=_target;
        else {_n.gx=_target[0];_n.gz=_target[1];_n.pending_target=undefined;_n.charging=true;}
    }else if(_n.unseen>0){
        _n.unseen=max(0,_n.unseen-_dt);
        if(_n.unseen<=0){cr_first_voice(_n,"audLose");_n.pending_target=undefined;if(_n.speed<=_p.wanderSpeed+1)cr_first_wander(_n);}
    }
    _n.was_seen=_seen;
    if(!is_undefined(_n.pending_target) && _n.speed<=_p.wanderSpeed+1){_n.gx=_n.pending_target[0];_n.gz=_n.pending_target[1];_n.pending_target=undefined;}
    var _dist=point_distance(_n.px,_n.pz,_n.gx,_n.gz);
    if(_dist<.1){
        _n.speed=0;_n.pushing=false;cr_first_wander(_n);_dist=point_distance(_n.px,_n.pz,_n.gx,_n.gz);
        if(random(100)<=_p.randomAudioChance)cr_first_voice(_n,"audRand");
    }
    var _angle=arctan2(_n.gx-_n.px,_n.gz-_n.pz),_delta=arctan2(sin(_angle-_n.yaw),cos(_angle-_n.yaw));
    if(_n.cooldown>0){_n.yaw+=degtorad(_p.turnSpeed*10)*_dt;_n.speed=0;_n.pushing=false;return;}
    if(abs(radtodeg(_delta))>_p.angleRange){_n.speed=0;_n.pushing=false;}
    else {
        var _chase=_n.unseen>0 && (is_undefined(_n.pending_target) || point_distance(_n.gx,_n.gz,_n.pending_target[0],_n.pending_target[1])<.1);
        var _max=_chase?_p.chaseSpeed:_p.wanderSpeed;_n.speed+=clamp(_max-_n.speed,-_p.accel*_dt,_p.accel*_dt);_n.pushing=_chase;
    }
    if(_n.speed<_p.minPushSpeed || abs(radtodeg(_delta))<=_p.angleRange)_n.yaw+=clamp(_delta,-degtorad(_p.turnSpeed)*_dt,degtorad(_p.turnSpeed)*_dt);
    if(_n.speed>=_p.slamSpeed){
        for(var _i=0;_i<array_length(global.cr_map.windows);_i++){
            var _w=global.cr_map.windows[_i];if(!_w.broken && point_distance(_n.px,_n.pz,_w.cx,_w.cz)<5){_w.broken=true;cr_sound(_w.break_sound,_w.cx,_w.cz);cr_noise(_w.cx,_w.cz,_w.noise);}
        }
    }
    for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(cr_box_overlap(_d.trigger,_n.px,_n.pz,_p.radius))cr_door_open(_d,false);}
    var _ox=_n.px,_oz=_n.pz,_travel=min(_dist,_n.speed*_dt);
    if(_travel>0)cr_npc_push(_n,sin(_angle)*_travel,cos(_angle)*_travel);
    if(_travel>0 && point_distance(_ox,_oz,_n.px,_n.pz)<.001){_n.speed=0;_n.gx=_n.px;_n.gz=_n.pz;}
    if(_n.speed==0 && _before>=_p.slamSpeed){cr_npc_sound(_n,_p.audBang);cr_noise(_n.px,_n.pz,_p.slamNoiseValue);}
    var _contact=abs(_g.px-_n.px)<4.5 && abs(_g.pz-_n.pz)<4.5;
    if(_contact && !_n.contact)cr_first_voice(_n,"audHug");_n.contact=_contact;
    if(_contact && _n.pushing && _n.speed>=_p.minPushSpeed && _g.boots<=0){
        var _tx=_n.px+sin(_n.yaw)*2-_g.px,_tz=_n.pz+cos(_n.yaw)*2-_g.pz,_len=point_distance(0,0,_tx,_tz);
        cr_move(_g,(_tx*2*_len+sin(_n.yaw)*(_n.speed+_p.accel*_dt))*_dt,(_tz*2*_len+cos(_n.yaw)*(_n.speed+_p.accel*_dt))*_dt,global.cr_catalog.movement.radius);
    }
}
