/// Only the current NULL session report. No legacy suite is invoked.
function cr_ns_capture() {
    var _g=global.bbcr,_label=cr_value(_g,"ns_capture","");if(_label=="")return;
    screen_save("bbcr_nullsession_"+_label+".png");
    if(_g.scene!="menu")surface_save(global.cr_world_surface,"bbcr_nullsession_"+_label+"_world.png");
    _g.ns_capture="";
}
function cr_ns_navigation() {
    var _g=global.bbcr,_n=_g.npcs[0],_count=0;
    for(var _i=0;_i<array_length(_g.doors);_i++){_g.doors[_i].locked=false;_g.doors[_i].lock=0;}
    cr_null_navigation_rebuild();
    for(var _i=0;_i<array_length(global.cr_map.tiles) && _count<12;_i+=13){
        var _t=global.cr_map.tiles[_i];if(_t.room!=0 || cr_blocked(_t.x*10+5,_t.z*10+5,2,false))continue;
        _n.px=175;_n.pz=55;_n.gx=_t.x*10+5;_n.gz=_t.z*10+5;path_clear_points(_n.path);_n.node=0;
        var _steps=0,_travel=0;while(_steps<2000 && !cr_null_destination_reached(_n)){_travel+=cr_npc_move(_n,30,1/60);_steps++;}
        cr_assert(cr_null_destination_reached(_n),"NULL reaches hall destination around source walls/furniture "+string(_i));
        show_debug_message("BBCR_NULLSESSION_ROUTE: "+json_stringify({tile:_i,steps:_steps,travel:_travel,x:_n.px,z:_n.pz,target:[_n.gx,_n.gz]}));_count++;
    }
    cr_assert(_count==12,"twelve distinct NULL routes exercised");
    _n.px=175;_n.pz=45;path_clear_points(_n.path);var _travel=0;
    for(var _frame=0;_frame<120;_frame++){_n.gx=175;_n.gz=95+_frame*.25;_travel+=cr_npc_move(_n,30,1/60);}
    cr_assert(abs(_n.pz-105)<.01 && abs(_travel-60)<.01,"moving target across tile boundaries never resets NULL behind its current position");
    // Door noise heard out of sight must survive until its reachable grid point,
    // then release priority 127 so a lower-priority sound can become the target.
    _g.px=175;_g.pz=55;_n.px=175;_n.pz=165;_n.was_seen=false;cr_baldi_clear_sounds(_n);
    var _chosen=false;
    for(var _i=0;_i<array_length(_g.doors);_i++){
        var _d=_g.doors[_i];if(_d.swing || cr_clear_line(_n.px,_n.pz,_d.cx,_d.cz,_n.params.sight_mask))continue;
        _d.open=0;cr_door_open(_d,true);_chosen=true;break;
    }
    cr_assert(_chosen && _n.targeting_sound && _n.current_sound==_d.noise,"actual unseen door interaction queues its source priority for NULL");
    var _goal=[_n.gx,_n.gz];_g.px=global.cr_map.spawn[0];_g.pz=15;global.cr_cheat.god=true;
    repeat(900)cr_null_step(1/60);
    cr_assert(point_distance(_n.px,_n.pz,175,165)>10,"ordinary NULL follows sound without visual contact");
    cr_baldi_clear_sounds(_n);_n.gx=_goal[0];_n.gz=_goal[1];_n.current_sound=127;_n.targeting_sound=true;path_clear_points(_n.path);
    var _steps=0;while(_steps<1800 && !cr_null_destination_reached(_n)){cr_npc_move(_n,30,1/60);_steps++;}
    cr_baldi_destination(_n);cr_noise(175,75,31);
    cr_assert(_n.current_sound==31 && _n.gx==175 && _n.gz==75,"completed snapped destination releases stale 127 priority for the next noise");
}
function cr_ns_window() {
    var _g=global.bbcr,_n=_g.npcs[0],_w=global.cr_map.windows[0],_a=_w.direction*pi/2,_dx=sin(_a),_dz=cos(_a);
    _n.px=_w.cx-_dx*4;_n.pz=_w.cz-_dz*4;_g.px=_w.cx+_dx*4;_g.pz=_w.cz+_dz*4;
    cr_assert(_n.params.sight_mask==98305 && cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask),"source NULL mask sees the player through intact layer-21 glass");
    cr_assert(!cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask | (1<<21)),"same ray is blocked when glass layer is included");
    cr_null_window_permission(false);_n.was_seen=false;var _s=_g.null_mode;_s.phase="collect";_s.stun=0;_g.ns_window=_w;
    cr_null_step(0);cr_assert(_n.pass_windows && !_w.broken,"ordinary sight grants source window permission before contact");
    var _count=array_length(_g.sound_instances);repeat(35){var _x=_n.px,_z=_n.pz;cr_npc_move(_n,10,.03);cr_null_break_windows(_n,_x,_z);}
    var _sounds=0;for(var _i=_count;_i<array_length(_g.sound_instances);_i++)if(_g.sound_instances[_i].key==_w.break_sound)_sounds++;
    cr_assert(_w.broken && _sounds==1,"ordinary routed contact breaks glass with one source sound");
}
function cr_ns_speeds() {
    var _g=global.bbcr,_n=_g.npcs[0],_rows=[];
    for(var _hit=1;_hit<=9;_hit++){
        var _anger=7.1+3*(_hit-1),_source=cr_curve(_n.params.speedCurve,_anger)+_n.params.baseSpeed;
        _g.anger=_anger;_g.null_mode.phase="boss";_g.null_mode.boss_wait=false;_g.null_mode.stun=0;
        _n.px=175;_n.pz=55;_n.gx=175;_n.gz=165;path_clear_points(_n.path);
        _n.slap_distance=0;_n.slap_left=0;_n.slap_timer=cr_curve(_n.params.slapCurve,_anger);var _distance=0;
        repeat(180){cr_baldi_tick(_n,1/60);_n.slap_left=max(0,_n.slap_left-min(_n.slap_speed,_n.slap_left*60)/60);}
        repeat(60){cr_baldi_tick(_n,1/60);var _d=cr_npc_move(_n,min(_n.slap_speed,_n.slap_left*60),1/60);_n.slap_left=max(0,_n.slap_left-_d);_distance+=_d;}
        array_push(_rows,{health:10-_hit,anger:_anger,source:_source,player:21+4*_hit,actual:_distance});
        cr_assert(abs(_distance-_source)<1.2,"boss steady speed follows source curve across actual movement at HP "+string(10-_hit));
    }
    show_debug_message("BBCR_NULLSESSION_SPEEDS: "+json_stringify(_rows));
}
function cr_ns_step() {
    var _g=global.bbcr;
    if(!variable_struct_exists(_g,"ns_stage")){_g.ns_stage=0;global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;}
    var _stage=_g.ns_stage++;_g.ns_capture="";
    if(_stage>=8 && _stage<24){
        var _spec=floor((_stage-8)/4),_angle=(_stage-8) mod 4;_g.yaw=_angle*pi/2;
        _g.null_mode.projectiles=[{x:_g.px+sin(_g.yaw)*4,z:_g.pz+cos(_g.yaw)*4,yaw:_g.yaw,state:"held",spec:global.cr_map.null_mode.projectiles[_spec]}];_g.null_mode.held=0;
        _g.ns_fixture="held";_g.ns_capture="held_"+string(_spec)+"_"+string(_angle);return;
    }
    switch(_stage){
        case 0:
            _g.progress=cr_progress_default();_g.progress.flags[0]=true;cr_ui_scene("MainMenu");global.cr_ui.stage=16;cr_ui_active("Title",false);cr_ui_active("StyleSelect",true);_g.ns_capture="selector_off";break;
        case 1:cr_ui_hover(cr_ui_node("StyleSelect/Baldi").id);_g.ns_capture="selector_on";break;
        case 2:
            _g.style="null";_g.progress.flags[1]=true;_g.progress.flags[2]=true;_g.progress.flags[3]=true;bbcr_start_game("story");global.cr_load_transition.stage=16;_g.ns_wait_draw=true;break;
        case 3:
            var _s=_g.null_mode,_exit=_g.exits[_s.spawn_exit];cr_assert(_s.spawn_exit>=0 && _exit.state==0,"NULL spawn gate is open on a real fresh start");
            _s.time=5;_g.yaw=pi;repeat(52){cr_doors_step(1/60);cr_move(_g,0,-.25,2);cr_null_spawn_step();}
            var _hit=cr_interaction_target();cr_assert(_hit.kind=="item" && global.cr_catalog.items[$ _g.items[_hit.index].item].type==13,"source chalk eraser behind spawn is reachable before the gate closes");
            cr_interact();cr_null_spawn_step();cr_assert(_exit.state==0,"taking the rear eraser does not close the gate around the player");
            _g.yaw=0;repeat(105){cr_doors_step(1/60);cr_move(_g,0,.25,2);cr_null_spawn_step();}
            cr_assert(_g.pz>35 && _s.spawn_left && _exit.state==1 && !cr_blocked(_g.px,_g.pz,2),"walk out of the source spawn trigger before gate closure");break;
        case 4:cr_ns_navigation();break;
        case 5:cr_ns_window();break;
        case 6:cr_ns_speeds();break;
        case 7:
            _g.px=175;_g.pz=55;_g.yaw=0;_g.npcs[0].hidden=true;_g.exit_fx.active=false;_g.null_mode.phase="intro";_g.null_mode.glitch=0;break;
        case 24:
            _g.ns_fixture="";_g.null_mode.held=-1;_g.null_mode.projectiles=[];_g.null_mode.phase="intro";_g.null_mode.stun=999999;
            _g.ns_fixture="chalk";_g.yaw=0;_g.chalk_clouds=[];_g.ns_capture="chalk_off";break;
        case 25:
            _g.chalk_clouds=[{px:175,pz:62,time:55,emit:0,particles:[{px:175,py:5,pz:62,age:2.5,size:8}]}];_g.ns_capture="chalk_on";break;
        case 26:
            _g.ns_fixture="";_g.chalk_clouds=[];_g.npcs[0].hidden=false;_g.npcs[0].px=175;_g.npcs[0].pz=105;
            _g.anger=107.1;_g.null_mode.health=10;_g.null_mode.final_exit=0;cr_null_boss_begin();
            cr_assert(audio_is_playing(_g.game_music) && !audio_is_paused(_g.game_music) && abs(audio_sound_get_pitch(_g.game_music)-1)<.0001,"boss music starts live at unchanged musical pitch");
            cr_assert(abs(_g.null_mode.track_tempo-.8333333)<.0001,"BossIntro uses serialized 0.8333333 tempo, not unit-rate playback");
            _g.ns_music_start=current_time;_g.ns_audio_position=audio_sound_get_track_position(_g.game_music);break;
        case 27:
            if(current_time-_g.ns_music_start<1100){_g.ns_stage--;return;}
            cr_audio_update_volume();cr_assert(audio_sound_get_track_position(_g.game_music)-_g.ns_audio_position>.8 && audio_sound_get_gain(_g.game_music)>.5,"actual music advances and keeps audible gain after the per-frame volume update");
            cr_null_hit();_g.ns_hit_start=current_time;_g.ns_last=current_time;_g.ns_voice_wait=true;_g.ns_warp_done=false;break;
        case 28:
            var _dt=(current_time-_g.ns_last)/1000;_g.ns_last=current_time;
            var _x=_g.npcs[0].px,_z=_g.npcs[0].pz;cr_null_step(_dt);
            if(_g.null_mode.boss_wait && point_distance(_x,_z,_g.npcs[0].px,_g.npcs[0].pz)>.001)_g.ns_voice_wait=false;
            if(_g.null_mode.hit_time>11.8 && !_g.ns_warp_done){_g.ns_capture="roar";_g.ns_warp_done=true;cr_assert(_g.null_mode.glitch>5 && audio_is_playing(_g.npcs[0].voice),"large source anger distortion overlaps the actually playing first-hit speech");}
            if(_g.null_mode.boss_wait){if(current_time-_g.ns_hit_start<23000){_g.ns_stage--;return;}cr_assert(false,"first-hit audio/transition ends within source duration");}
            cr_assert(_g.ns_voice_wait && !audio_is_playing(_g.npcs[0].voice) && array_length(_g.npcs[0].voice_queue)==0,"real first-hit speech plays to completion before chase resumes");
            cr_assert(_g.null_mode.intro_done && _g.npcs[0].pass_windows,"music transition completes alongside voice gate");
            show_debug_message("BBCR_NULLSESSION_WAIT: "+string((current_time-_g.ns_hit_start)/1000));break;
        case 29:
            _g.null_mode.glitch=0;_g.ns_capture="roar_clear";
            var _before=_g.null_mode.music_speed;cr_null_hit();cr_audio_update_volume();
            cr_assert(_g.null_mode.track_tempo>_before && abs(audio_sound_get_pitch(_g.game_music)-1)<.0001,"next hit increases tempo without lowering pitch");break;
        case 30:
            _g.null_mode.projectiles=[];_g.null_mode.held=-1;_g.null_mode.glitch=0;_g.null_mode.color_glitch=0;
            _g.npcs[0].px=175;_g.npcs[0].pz=80;_g.px=172.8;_g.pz=80;_g.yaw=0;
            cr_caught(_g.npcs[0]);_g.ending.time=0;_g.ns_capture="caught_start";
            cr_assert(abs(point_distance(_g.ending.x,_g.ending.z,175,80)-2)<.0001 && _g.ending.yaw!=_g.yaw,"capture camera moves to source two-unit NULL target and faces it");break;
        case 31:_g.ending.time=8;_g.ns_capture="caught_late";break;
        case 32:
            show_debug_message("BBCR_NULLSESSION_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
}
function cr_ns_render_fixture() {
    var _g=global.bbcr,_fixture=cr_value(_g,"ns_fixture","");if(_fixture=="")return;
    draw_clear(c_black);draw_clear_depth(1);gpu_set_cullmode(cull_noculling);
    if(_fixture=="held")return;
    // Real source billboard behind smoke; nearer opaque panel must still win Z.
    cr_billboard("Plant",175,5,65,6,8);
    var _vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);cr_quad(_vb,[172,3,59],[174.5,3,59],[174.5,7,59],[172,7,59],c_red);vertex_end(_vb);vertex_submit(_vb,pr_trianglelist,-1);
}
