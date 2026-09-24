function cr_null_init() {
    var _g=global.bbcr;
    cr_null_effect_data();
    _g.null_mode={phase:"collect",health:10,projectiles:[],held:-1,blockers:[],spawn_timer:0,stun:0,run_speed:16,walk_speed:10,music_speed:global.cr_map.null_mode.music_speed,final_exit:-1,voice:-1,time:0,speech_timer:10,spoken:{},intro_done:false,boss_wait:false,transition_started:false,hit_time:0,glitch:0};
    _g.npcs[0].pass_windows=false;
    _g.npcs[0].params.audio=global.cr_session_data.profiles[$ (_g.progress.flags[4]?"Glitch":"NULL")];
    _g.null_mode.beat=0;_g.null_mode.beat_position=-1;_g.null_mode.warp_seed=0;
    _g.spoop=true;_g.mirror=false;_g.lightsout=false;_g.hard=false;
    _g.exit_fx.active=true;_g.null_mode.flicker_timer=0;_g.null_mode.had_target=0;_g.null_mode.exciting=0;
    _g.null_attempts=cr_value(_g,"null_attempts",0)+1;_g.null_mode.door_comment=0;
    _g.null_mode.spawn_exit=-1;_g.null_mode.spawn_left=false;
    for(var _i=0;_i<array_length(_g.exits);_i++){
        var _e=_g.exits[_i];_e.state=1;
        if(cr_exit_contact(_e.triggers)){_g.null_mode.spawn_exit=_i;_e.state=0;}
    }
    cr_null_navigation_rebuild();
}
function cr_null_collect(_index) {
    var _g=global.bbcr,_n=_g.npcs[0],_ready=_g.progress.flags[1] && _g.progress.flags[2] && _g.progress.flags[3];
    if(_ready){_g.books[_index].done=true;_g.notebooks++;_g.anger++;}
    if(_g.notebooks>=2)for(var _i=0;_i<array_length(_g.doors);_i++)_g.doors[_i].locked=false;
    if(_g.notebooks>=7)for(var _i=0;_i<array_length(_g.exits);_i++){_g.exits[_i].state=0;_g.exits[_i].prepared=true;}
    cr_null_navigation_rebuild();cr_noise(_g.px,_g.pz,126);cr_ui_dispose(global.cr_math_ui);global.cr_math_ui=cr_ui_context("NullPad");
    var _old=global.cr_ui;global.cr_ui=global.cr_math_ui;global.cr_ui.static_max=.1;global.cr_ui.shift_intensity=.002;
    for(var _i=1;_i<=3;_i++)if(!_g.progress.flags[_i]){global.cr_ui.static_max+=.2;global.cr_ui.shift_intensity+=.005;}
    var _src=undefined;for(var _i=0;_i<array_length(global.cr_ui.nodes);_i++)if(variable_struct_exists(global.cr_ui.nodes[_i].scripts,"NullPad"))_src=global.cr_ui.nodes[_i].scripts.NullPad;
    for(var _i=0;_i<3;_i++){var _node=cr_ui_node(_src.indicator[_i]);_node.active=true;_node.image_override=_g.progress.flags[_i+1]?"YCTP_IndicatorsSheet_0":_src.wrongSprite;}
    var _key=_g.progress.flags[4]?"YCTP_Glitch_"+(_ready?"Ready":"NotReady")+string(irandom_range(1,3)):"Enc_NullPad_"+(_ready?"Ready":"NotReady")+string(irandom_range(1,_ready?9:3));
    cr_ui_set_text(cr_ui_node(_src.problemTxt),_g.progress.flags[4]?global.cr_text[$ _key]:global.cr_ui_data.null_text[$ _key]);
    cr_ui_active(_src.nullImage,true);if(_g.progress.flags[4])cr_ui_node(_src.nullImage).image_override=_src.glitchSprite;
    cr_ui_transition(.01666667);global.cr_ui.reveal=true;global.cr_ui=_old;
    _g.scene="nullpad";audio_pause_all();_g.math_audio_paused=true;window_mouse_set_locked(false);
    if(audio_is_playing(_n.voice))audio_resume_sound(_n.voice);
}
function cr_null_pad_close() {
    var _g=global.bbcr,_old=global.cr_ui;global.cr_ui=global.cr_math_ui;cr_ui_transition(.01666667);global.cr_ui=_old;
    _g.scene="game";_g.math_audio_paused=false;audio_resume_all();_g.mouse_skip=true;
}
function cr_null_elevators() {
    var _g=global.bbcr,_s=_g.null_mode;if(_s.phase!="collect" || _g.notebooks<7)return;
    for(var _i=0;_i<array_length(_g.exits);_i++){
        var _e=_g.exits[_i];if(_e.used || !cr_exit_contact(_e.triggers))continue;
        cr_exit_unembed(_e);_e.used=true;_e.state=2;_e.prepared=false;_g.exits_closed++;cr_sound(_e.sound,_e.x,_e.z);
        var _open=[];for(var _j=0;_j<array_length(_g.exits);_j++)if(!_g.exits[_j].used)array_push(_open,_j);
        if(array_length(_open)>0){var _target=_g.exits[_open[irandom(array_length(_open)-1)]];cr_noise(_target.x+sin(_target.dir*pi/2)*10,_target.z+cos(_target.dir*pi/2)*10,31);}
        if(_g.exits_closed==3){_s.phase="preboss";_s.final_exit=_open[0];_g.npcs[0].hidden=true;_g.npcs[0].gx=195;_g.npcs[0].gz=215;_g.npcs[0].route_timer=0;_g.anger+=100;cr_null_window_permission(false);}
    }
}
function cr_null_spawn_projectile(_x,_z) {
    var _s=global.bbcr.null_mode,_src=global.cr_map.null_mode.projectiles;
    array_push(_s.projectiles,{x:_x,z:_z,spawn_x:_x,spawn_z:_z,yaw:0,state:"idle",life:10,spec:_src[irandom(array_length(_src)-1)]});
}
function cr_null_boss_begin() {
    var _g=global.bbcr,_s=_g.null_mode,_n=_g.npcs[0],_e=_g.exits[_s.final_exit];
    _e.used=true;_e.state=2;_e.prepared=false;_g.exits_closed=4;cr_exit_unembed(_e);
    _s.phase="intro";_s.stun=999999;_g.items_disabled=true;_n.hidden=false;_s.time=0;
    _g.boss_seen=true;cr_save();
    _n.voice_queue=[_n.params.audBossIntro,_n.params.audBossLoop];cr_npc_voice_tick(_n);
    var _positions=global.cr_map.null_mode.initial;for(var _i=0;_i<array_length(_positions);_i++)cr_null_spawn_projectile(_positions[_i][0]*10+5,_positions[_i][1]*10+5);
    cr_null_window_permission(false);cr_null_music_play("BossIntro",0,false);cr_null_navigation_rebuild();
}
function cr_null_throw() {
    var _g=global.bbcr,_s=_g.null_mode;if(_s.held<0)return false;
    var _p=_s.projectiles[_s.held];_p.state="thrown";_p.x=_g.px;_p.z=_g.pz;_p.yaw=cr_view_yaw();_s.held=-1;return true;
}
function cr_null_hit() {
    var _g=global.bbcr,_s=_g.null_mode,_n=_g.npcs[0];_s.health--;_s.stun=_n.params.stunTime;_g.anger+=3;
    if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);_n.voice=-1;_n.voice_queue=[_n.params.audHit];
    if(_s.health==9){_s.phase="boss";_s.boss_wait=true;_s.transition_started=false;_s.intro_done=false;_s.hit_time=0;_s.run_speed+=5;_g.anger=max(.1,_g.anger-103);array_push(_n.voice_queue,_n.params.audBossStart);_s.projectiles=[];_s.held=-1;}
    else _s.music_speed=global.cr_map.null_mode.music_speed+(9-_s.health)*global.cr_map.null_mode.music_increment;
    cr_npc_voice_tick(_n);_s.run_speed+=4;_s.walk_speed=_s.run_speed;
    if(_s.health<9 && _s.health>0)cr_null_music_play("BossLoop",cr_null_music_position(),true);
    var _tiles=[];for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){var _t=global.cr_map.tiles[_i];if(_t.room==0 && !_t.contains_object && !cr_blocked(_t.x*10+5,_t.z*10+5,1))array_push(_tiles,_t);}
    repeat(max(0,floor((_s.health-1)/3))){if(array_length(_tiles)==0)break;var _j=irandom(array_length(_tiles)-1),_t=_tiles[_j];array_delete(_tiles,_j,1);cr_null_spawn_projectile(_t.x*10+5,_t.z*10+5);}
    if(_s.health<=0){cr_secret_load(global.cr_map.next_level);return;}
}
function cr_null_step(_dt) {
    var _g=global.bbcr,_s=_g.null_mode,_n=_g.npcs[0];_s.time+=_dt;_s.stun=max(0,_s.stun-_dt);cr_npc_voice_tick(_n);
    cr_null_spawn_step();cr_null_atmosphere(_dt);cr_null_blockers_step(_dt);
    cr_null_music_step(_dt);
    if(_s.phase=="boss"){_g.stamina=200;cr_baldi_hear(_n,_g.px,_g.pz,127,false);}
    var _oldx=_n.px,_oldz=_n.pz;
    if(_s.phase=="preboss"){
        cr_npc_move(_n,cr_curve(_n.params.speedCurve,_g.anger)+_n.params.baseSpeed,_dt);
        var _e=_g.exits[_s.final_exit],_t=cr_tile(_e.x+sin(_e.dir*pi/2)*10,_e.z+cos(_e.dir*pi/2)*10);
        var _p=cr_tile(_g.px,_g.pz),_path=is_undefined(_p)||is_undefined(_t)?[]:cr_map_tile_path(_p.index,_t.index);
        if(array_length(_path)>0 && array_length(_path)<10){_s.phase="rush";_n.hidden=false;_n.gx=_t.x*10+5;_n.gz=_t.z*10+5;_n.route_timer=0;}
    }
    if(_s.phase=="rush"){
        cr_npc_move(_n,200,_dt);if(point_distance(_n.px,_n.pz,_n.gx,_n.gz)<3)cr_null_boss_begin();
    }else if(_s.stun<=0 && _s.phase!="preboss" && !_s.boss_wait){
        if(_s.phase!="boss"){
            var _seen=cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask);
            if(_seen){if(!_n.was_seen)cr_null_window_permission(true);cr_baldi_clear_sounds(_n);cr_baldi_hear(_n,_g.px,_g.pz,127,false);}
            else if(cr_null_destination_reached(_n)){cr_null_window_permission(false);cr_baldi_destination(_n);}
            _n.was_seen=_seen;
        }
        cr_baldi_tick(_n,_dt);var _pushed=false;
        for(var _i=0;_i<array_length(_g.projectiles);_i++){var _spray=_g.projectiles[_i];if(point_distance(_spray.px,_spray.pz,_n.px,_n.pz)<5){cr_npc_push(_n,_spray.dx*30*_dt,_spray.dz*30*_dt);path_clear_points(_n.path);_pushed=true;}}
        var _speed=_pushed?0:min(_n.slap_speed,_n.slap_left/max(.000001,_dt));
        _n.slap_left=max(0,_n.slap_left-cr_npc_move(_n,_speed,_dt));
        if(!_n.hidden && point_distance(_g.px,_g.pz,_n.px,_n.pz)<3 && !cr_cheat_flag("god")){cr_caught(_n);return;}
    }
    cr_null_break_windows(_n,_oldx,_oldz);
    for(var _i=0;_i<array_length(_s.projectiles);_i++){
        var _p=_s.projectiles[_i];if(_p.state=="idle" && _s.held<0 && point_distance(_p.x,_p.z,_g.px,_g.pz)<3){_s.held=_i;_p.state="held";_p.yaw=cr_view_yaw();}
        if(_p.state=="held"){_p.yaw=cr_view_yaw();_p.x=_g.px+sin(_p.yaw)*4;_p.z=_g.pz+cos(_p.yaw)*4;}
        if(_p.state=="thrown"){
            var _ox=_p.x,_oz=_p.z;_p.x+=sin(_p.yaw)*_p.spec.speed*_dt;_p.z+=cos(_p.yaw)*_p.spec.speed*_dt;_p.life-=_dt;
            if(cr_segment_distance(_n.px,_n.pz,_ox,_oz,_p.x,_p.z)<3){_p.state="used";cr_null_hit();if(!is_struct(_g.null_mode))return;break;}
            if(_p.life<=0){_p.state="idle";_p.x=_p.spawn_x;_p.z=_p.spawn_z;_p.life=10;}
        }
    }
    cr_null_elevators();
}
function cr_null_window_permission(_value) {
    var _n=global.bbcr.npcs[0];if(_n.pass_windows==_value)return;
    _n.pass_windows=_value;cr_null_navigation_rebuild();
    path_clear_points(_n.path);_n.route_timer=0;
}
function cr_null_break_windows(_n,_oldx,_oldz) {
    if(!_n.pass_windows || _n.hidden)return;
    for(var _i=0;_i<array_length(global.cr_walls);_i++){
        var _line=global.cr_walls[_i];if(array_length(_line)<5 || _line[4]<0)continue;
        var _w=global.cr_map.windows[_line[4]];if(_w.broken)continue;
        var _distance=point_distance(_oldx,_oldz,_n.px,_n.pz),_hit=cr_ray_segment(_oldx,_oldz,(_n.px-_oldx)/max(.0001,_distance),(_n.pz-_oldz)/max(.0001,_distance),_line);
        if(cr_segment_distance(_n.px,_n.pz,_line[0],_line[1],_line[2],_line[3])>_n.params.collision_radius && (_distance<.0001 || _hit>_distance))continue;
        _w.broken=true;cr_sound(_w.break_sound,_w.cx,_w.cz);cr_null_speech("audHide",.04);
    }
}
function cr_null_draw() {
    var _s=global.bbcr.null_mode;if(!is_struct(_s))return;
    for(var _i=0;_i<array_length(_s.projectiles);_i++){var _p=_s.projectiles[_i];if(_p.state!="used" && _p.state!="held")cr_null_projectile_draw(_p);}
    for(var _i=0;_i<array_length(_s.blockers);_i++){var _b=_s.blockers[_i];if(_b.active)cr_null_blocker_draw(_b);}
}
function cr_null_music_step(_dt) {
    var _g=global.bbcr,_s=_g.null_mode;if(_s.phase!="intro" && _s.phase!="boss")return;
    cr_null_music_mix(_dt);
    var _src=global.cr_ui_data.boss_music,_pos=audio_is_playing(_g.game_music)?cr_null_music_position():_src.end;
    if(_s.phase=="intro" && _pos>=_src.loop)cr_null_music_seek(0);
    if(_s.boss_wait){
        _s.hit_time+=_dt;
        if(!_s.transition_started){
            if(!variable_struct_exists(_s,"next_marker")){_s.next_marker=_src.loop;for(var _i=0;_i<array_length(_src.markers);_i++)if(_src.markers[_i]>_pos){_s.next_marker=_src.markers[_i];break;}}
            if(_pos>=_s.next_marker){cr_null_music_seek(_src.transition);_s.transition_started=true;}
        }else if(!_s.intro_done && (!audio_is_playing(_g.game_music) || _pos>=_src.end-.015)){
            cr_null_music_play("BossLoop",0,true);_s.intro_done=true;
        }
        // Both audio timelines must finish. A completed MIDI transition alone
        // used to cancel Pause while Null_PreBoss_Start was still speaking.
        if(_s.intro_done && !audio_is_playing(_g.npcs[0].voice) && array_length(_g.npcs[0].voice_queue)==0 && _s.hit_time>=(global.bbcr.progress.flags[4]?15.5:12.5)){
            _s.stun=0;_s.boss_wait=false;cr_null_window_permission(true);
        }
    }else if(_s.phase=="boss")_s.hit_time+=_dt;
    _s.beat=max(0,_s.beat-_dt*4);
    if(_s.intro_done && !_s.boss_wait){
        _pos=cr_null_music_position();
        cr_null_beat_sample(_pos);
    }
    cr_null_anger_visual();
}
function cr_null_spawn_blocker() {
    var _g=global.bbcr,_s=_g.null_mode,_pool=[];
    for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){
        var _t=global.cr_map.tiles[_i];if(_t.room!=0 || _t.open)continue;
        var _dirs=[],_okay=true;for(var _d=0;_d<4;_d++)if(_t.nav[_d]>=0){var _next=global.cr_map.tiles[_t.nav[_d]];if(_next.room!=0 || global.cr_map.rooms[_next.room].offlimits)_okay=false;array_push(_dirs,_d);}
        if(!_okay || array_length(_dirs)<3)continue;
        for(var _j=0;_j<array_length(_s.blockers);_j++)if(_s.blockers[_j].tile==_i)_okay=false;
        if(_okay)array_push(_pool,{tile:_i,dirs:_dirs});
    }
    if(array_length(_pool)==0)return;
    var _choice=_pool[irandom(array_length(_pool)-1)],_t=global.cr_map.tiles[_choice.tile],_pres=global.cr_map.null_mode.blockers;
    var _variant=irandom(array_length(_pres)-1);
    array_push(_s.blockers,{tile:_choice.tile,x:_t.x*10+5,z:_t.z*10+5,dirs:_choice.dirs,dir:0,life:1,entered:false,active:false,spec:_pres[_variant],effect:global.cr_null_effects.blockers[_variant],anim_time:0});
}
function cr_null_blockers_step(_dt) {
    var _g=global.bbcr,_s=_g.null_mode,_changed=false;_s.spawn_timer-=_dt;
    if(_s.spawn_timer<=0){_s.spawn_timer=global.cr_map.null_mode.spawn_rate-floor((10-_s.health)/2);if(_s.phase=="boss" && irandom(max(0,floor(_s.health/3)-1))==0)cr_null_spawn_blocker();}
    for(var _i=array_length(_s.blockers)-1;_i>=0;_i--){
        var _b=_s.blockers[_i],_dx=_g.px-_b.x,_dz=_g.pz-_b.z,_inside=false,_entry=-1;
        if(_b.active)_b.anim_time=min(_b.effect.length,_b.anim_time+_dt);
        for(var _j=0;_j<array_length(_b.effect.triggers);_j++){
            var _trigger=_b.effect.triggers[_j];if(cr_box_overlap(_trigger.box,_dx,_dz,global.cr_catalog.movement.radius)){_inside=true;if(_entry<0)_entry=_trigger.dir;}
        }
        if(_inside){_b.entered=true;_b.life=1;if(!_b.active && !cr_value(_b,"evaluated",false)){var _pool=[];_b.evaluated=true;
            for(var _j=0;_j<array_length(_b.dirs);_j++)if(_b.dirs[_j]!=_entry && cr_null_blocker_safe(_b,_b.dirs[_j]))array_push(_pool,_b.dirs[_j]);
            if(array_length(_pool)>0){_b.dir=_pool[irandom(array_length(_pool)-1)];_b.active=true;_b.anim_time=0;_changed=true;}
        }}else if(_b.entered){_b.life-=_dt;if(_b.life<=0){array_delete(_s.blockers,_i,1);_changed=true;}}
    }
    if(_changed)cr_null_navigation_rebuild();
}
function cr_null_blocks(_x,_z,_radius) {
    var _s=global.bbcr.null_mode;if(!is_struct(_s))return false;
    for(var _i=0;_i<array_length(_s.blockers);_i++){
        var _b=_s.blockers[_i];if(!_b.active)continue;var _a=_b.dir*pi/2,_dx=_x-_b.x,_dz=_z-_b.z;
        for(var _j=0;_j<array_length(_b.effect.colliders);_j++)if(cr_box_overlap(_b.effect.colliders[_j],_dx*cos(_a)-_dz*sin(_a),_dx*sin(_a)+_dz*cos(_a),_radius))return true;
    }return false;
}
function cr_null_speech(_field,_chance) {
    var _s=global.bbcr.null_mode,_n=global.bbcr.npcs[0];if(_s.health!=10 || global.bbcr.anger>=20 || _s.phase!="collect" || cr_value(_s.spoken,_field,false))return;
    if(random(1)>_chance)return;array_push(_n.voice_queue,_n.params[$ _field]);_s.spoken[$ _field]=true;cr_npc_voice_tick(_n);
}
function cr_null_atmosphere(_dt) {
    var _g=global.bbcr,_s=_g.null_mode,_n=_g.npcs[0],_fx=_g.exit_fx;
    _s.flicker_timer-=_dt;_s.exciting+=_dt;_s.had_target=_n.targeting_sound?0:_s.had_target+_dt;
    var _seen=cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask);if(_seen && point_distance(_n.px,_n.pz,_g.px,_g.pz)<=50)_s.exciting=0;
    if(!_n.hidden && _s.flicker_timer<=0){
        _s.flicker_timer=_n.params.flickerSpeed;
        for(var _i=0;_i<array_length(global.cr_map.lights);_i++){
            var _l=global.cr_map.lights[_i];if(_l.strength<=1)continue;var _dist=point_distance(_l.position.x*10+5,_l.position.z*10+5,_n.px,_n.pz);
            if(_g.reduce_flashing)_fx.on[_i]=_dist>50;
            else if(_dist<=30)_fx.on[_i]=false;else if(_dist>100)_fx.on[_i]=true;else if(random(1)<=.1)_fx.on[_i]=random(1)<=(_dist-30)/70;
        }_fx.dirty=true;
    }
    _s.door_comment=max(0,_s.door_comment-_dt);
    for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(point_distance(_n.px,_n.pz,_d.cx,_d.cz)<6 && !_d.locked && _d.lock<=0){cr_door_open(_d,false);_d.open=.5;if(_s.door_comment<=0){cr_null_speech("audHide",.01);_s.door_comment=1;}}}
    _s.speech_timer-=_dt;if(_s.speech_timer<=0){_s.speech_timer=10;var _phrases=[];
        if(_s.time>=300 && _s.exciting>=60 && !cr_value(_s.spoken,"audBored",false))array_push(_phrases,"audBored");
        if(_s.time>=240 && !_seen && !cr_value(_s.spoken,"audScary",false))array_push(_phrases,"audScary");
        if(_s.time>=60 && _s.had_target>=30 && !cr_value(_s.spoken,"audWhere",false))array_push(_phrases,"audWhere");
        if(_s.time>=60 && _g.null_attempts>=5 && !cr_value(_s.spoken,"audStop",false))array_push(_phrases,"audStop");
        if(array_length(_phrases)>0)cr_null_speech(_phrases[irandom(array_length(_phrases)-1)],.1);
        if(_g.stamina<=0 && _g.anger>=4 && point_distance(_g.px,_g.pz,_n.px,_n.pz)<=25 && _g.inventory[0]=="" && _g.inventory[1]=="" && _g.inventory[2]=="")cr_null_speech("audNothing",.2);
    }
    if(_s.phase=="intro" && audio_is_playing(_n.voice) && array_length(_n.voice_queue)==0)for(var _i=0;_i<array_length(_g.sound_instances);_i++)if(_g.sound_instances[_i].handle==_n.voice && _g.sound_instances[_i].key==_n.params.audBossLoop)cr_audio_loop(_n.voice,true);
}
