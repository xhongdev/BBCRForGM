function cr_latest_capture() {
    var _g=global.bbcr;if(cr_value(_g,"latest_capture","")=="")return;
    screen_save("bbcr_latest_"+_g.latest_capture+".png");_g.latest_capture="";
}
function cr_latest_camera(_box) {
    var _g=global.bbcr,_axis=_box.axes[2];_g.px=_box.center[0]-_axis[0]*5;_g.pz=_box.center[2]-_axis[2]*5;_g.yaw=arctan2(_axis[0],_axis[2]);
}
function cr_latest_sound_count(_key) {
    var _count=0;for(var _i=0;_i<array_length(global.bbcr.sound_instances);_i++)if(global.bbcr.sound_instances[_i].key==_key)_count++;return _count;
}
function cr_latest_step() {
    var _g=global.bbcr;if(!variable_struct_exists(_g,"latest_stage")){_g.latest_stage=0;global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;}
    var _stage=_g.latest_stage++;_g.latest_capture="";
    if(_stage>=4 && _stage<12){
        var _index=floor((_stage-4)/2),_b=global.cr_map.puzzle.buttons[_index];cr_latest_camera(_b.box);
        if((_stage mod 2)==0){
            cr_assert(!cr_blocked(_g.px,_g.pz,2),"Party puzzle control has a reachable source-facing approach "+string(_index));
            var _hit=cr_interaction_target();cr_assert(_hit.kind=="party_button" && _hit.index==_index,"Party puzzle ray hits visible control "+string(_index));
            _g.latest_capture="party_"+string(_index)+"_off";
        }else{
            cr_interact();cr_assert(_g.party.puzzle[_index]==1 && _g.party.puzzle_timers[_index]>0,"Party puzzle press updates digit, source material and reset timer "+string(_index));
            _g.latest_capture="party_"+string(_index)+"_on";
        }return;
    }
    if(_stage>=13 && _stage<27){
        var _index=16+floor((_stage-13)/2),_t=global.cr_map.triggers[_index];cr_latest_camera(_t.boxes[0]);
        if((_stage mod 2)==1){_g.latest_capture="control_"+string(_index)+"_off";}
        else{
            cr_assert(!cr_blocked(_g.px,_g.pz,2),"Basement control is approachable "+string(_index));
            var _before=_t.on;cr_interact();cr_assert(_t.on!=_before,"Basement actual click toggles source initial switch state "+string(_index));
            _g.latest_capture="control_"+string(_index)+"_on";
        }return;
    }
    switch(_stage){
        case 0:
            _g.progress=cr_progress_default();_g.progress.flags[0]=true;cr_ui_scene("MainMenu");global.cr_ui.stage=16;cr_ui_active("Title",false);cr_ui_active("StyleSelect",true);_g.latest_capture="select_idle";break;
        case 1:cr_ui_hover(cr_ui_node("StyleSelect/Baldi").id);_g.latest_capture="select_glitch";break;
        case 2:
            cr_ui_press(cr_ui_node("StyleSelect/Baldi"));global.cr_ui.stage=16;var _n=cr_ui_node(cr_ui_node("ModeSelect").scripts.EndlessMapOverview.levelName);
            cr_assert(_n.graphics[0].layout.text=="NULL","NULL blackboard label identifies selection and is not blank or undefined");_g.latest_capture="select_null";break;
        case 3:
            _g.style="party";bbcr_start_game("story");cr_party_enter_ending();global.cr_load_transition.stage=16;
            _g.party.values=[1,1,1,1];_g.balloons=[];_g.latest_wait_draw=true;break;
        case 12:
            cr_assert(_g.party.puzzle_open,"four source puzzle controls remove their blocking wall");
            _g.style="demo";bbcr_start_game("story","ClassicBasement_0");global.cr_load_transition.stage=16;_g.exit_fx.active=false;break;
        case 27:
            cr_secret_route_step(.13);cr_assert(!global.cr_map.triggers[16].on && global.cr_map.triggers[17].on,"button releases after source delay while lever retains state");
            _g.style="null";_g.progress.flags[1]=true;_g.progress.flags[2]=true;_g.progress.flags[3]=true;_g.progress.flags[4]=false;
            bbcr_start_game("story");global.cr_load_transition.stage=16;cr_null_collect(0);global.cr_math_ui.stage=16;global.cr_math_ui.effect_time=1000;
            cr_assert(abs(global.cr_math_ui.static_max-.1)<=.00001,"ready NullPad uses source static amount");_g.latest_capture="pad_face";break;
        case 28:
            var _old=global.cr_ui;global.cr_ui=global.cr_math_ui;cr_ui_active("NullPad/YCTP_Canvas/YCTP_Baldi",false);global.cr_ui=_old;_g.latest_capture="pad_no_face";break;
        case 29:
            var _old=global.cr_ui;global.cr_ui=global.cr_math_ui;cr_ui_active("NullPad/YCTP_Canvas/YCTP_Baldi",true);global.cr_ui.effect_time=1200;global.cr_ui=_old;_g.latest_capture="pad_next";break;
        case 30:
            cr_null_pad_close();global.cr_math_ui.stage=16;var _n=_g.npcs[0];_n.px=_g.px+50;_n.pz=_g.pz+50;
            cr_pause(true);global.cr_pause_ui.stage=16;var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;cr_ui_press(cr_ui_node("ClassicPauseMenu/Main/Quit"));global.cr_ui.stage=16;
            cr_assert(_g.paused && point_distance(_g.px,_g.pz,_n.px,_n.pz)>10,"NULL Quit opens confirmation without premature teleport");global.cr_ui=_old;_g.latest_capture="null_confirm";break;
        case 31:
            var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;cr_ui_hover(cr_ui_node("ClassicPauseMenu/Confirm/YesButton").id);global.cr_ui=_old;
            cr_assert(!_g.paused && abs(point_distance(_g.px,_g.pz,_g.npcs[0].px,_g.npcs[0].pz)-1)<=.00001,"source Yes highlight callback positions NULL and resumes");global.cr_pause_ui.stage=16;break;
        case 32:
            var _n=_g.npcs[0],_w=global.cr_map.windows[0];_n.px=_w.cx;_n.pz=_w.cz-5;_g.px=175;_g.pz=55;
            var _ox=_n.px,_oz=_n.pz;cr_move(_n,0,10,_n.params.collision_radius);cr_null_break_windows(_n,_ox,_oz);
            cr_assert(!_w.broken && _n.pz<_w.cz,"NULL cannot break or cross a window without source passability");
            _n.px=_w.cx;_n.pz=_w.cz-5;cr_null_window_permission(true);var _count=cr_latest_sound_count(_w.break_sound);
            cr_null_break_windows(_n,_n.px,_n.pz);cr_assert(!_w.broken,"nearby window is not broken before contact");
            _n.gx=_w.cx;_n.gz=_w.cz+5;path_clear_points(_n.path);_n.route_timer=0;
            repeat(15){_ox=_n.px;_oz=_n.pz;cr_npc_move(_n,10,.1);cr_null_break_windows(_n,_ox,_oz);}
            cr_assert(_w.broken && _n.pz>_w.cz && cr_latest_sound_count(_w.break_sound)==_count+1,"passable contact crosses window and plays original GlassBreak exactly once");break;
        case 33:
            var _s=_g.null_mode;_s.final_exit=3;cr_null_boss_begin();var _src=global.cr_ui_data.boss_music;
            audio_sound_set_track_position(_g.game_music,_src.loop+.02);cr_null_music_step(0);
            cr_assert(audio_sound_get_track_position(_g.game_music)<1 && _s.stun>100,"pre-hit BossIntro obeys source Loop marker and keeps NULL paused");
            _g.px=175;_g.pz=65;_g.yaw=0;_s.projectiles=[];cr_null_spawn_projectile(_g.px,_g.pz);_s.projectiles[0].spec=global.cr_map.null_mode.projectiles[0];cr_null_step(0);
            _g.latest_capture="held_a";break;
        case 34:
            _g.yaw=pi/2;cr_null_step(0);var _p=_g.null_mode.projectiles[0];
            cr_assert(abs(_p.x-_g.px-4)<=.00001 && abs(_p.z-_g.pz)<=.00001 && _p.yaw==_g.yaw,"held projectile follows camera at four units with fixed prefab offset");
            _g.latest_capture="held_b";break;
        case 35:
            cr_assert(cr_null_throw() && _g.null_mode.projectiles[0].state=="thrown","throw removes held offset and uses camera direction");
            _g.null_mode.projectiles=[];var _n=_g.npcs[0];_n.px=175;_n.pz=105;_g.px=175;_g.pz=55;
            audio_sound_set_track_position(_g.game_music,0);cr_null_hit();cr_null_music_step(0);
            cr_assert(_g.null_mode.boss_wait && !_g.null_mode.transition_started,"first hit waits for next source MIDI marker");
            var _ox=_n.px,_oz=_n.pz;cr_null_step(1.1);cr_assert(_n.px==_ox && _n.pz==_oz,"NULL does not resume on stun expiry while boss transition is pending");
            audio_sound_set_track_position(_g.game_music,_g.null_mode.next_marker+.01);cr_null_music_step(0);
            cr_assert(_g.null_mode.transition_started && abs(audio_sound_get_track_position(_g.game_music)-global.cr_ui_data.boss_music.transition)<.1,"source marker seeks BossIntro tick 4992 transition");
            _g.null_mode.hit_time=11;cr_null_music_step(0);_g.latest_capture="anger_warp";break;
        case 36:
            if(audio_is_playing(_g.game_music))audio_stop_sound(_g.game_music);cr_null_music_step(0);
            cr_assert(!_g.null_mode.boss_wait && _g.exit_fx.music_key=="BossLoop" && _g.npcs[0].pass_windows,"only completed MIDI transition enables boss chase and window routing");
            _g.null_mode.hit_time=20;audio_sound_set_track_position(_g.game_music,global.cr_ui_data.boss_music.beats[0]+.01);cr_null_music_step(0);
            cr_assert(_g.null_mode.glitch==3,"BossLoop source text marker drives vertex pulse intensity three");cr_null_music_step(.1);
            cr_assert(_g.null_mode.glitch>0 && _g.null_mode.glitch<3,"boss vertex pulse fades at source four-per-second rate");
            _g.null_mode.glitch=0;_g.latest_capture="anger_clear";break;
        case 37:
            _g.null_mode.phase="collect";_g.npcs[0].hidden=true;_g.exit_fx.active=false;_g.px=175;_g.pz=55;_g.yaw=0;
            cr_chalk_use();_g.chalk_clouds[0].pz=65;repeat(50)cr_extra_items_step(.05);
            cr_assert(array_length(_g.chalk_clouds[0].particles)==25,"chalk emitter creates ten particles per second");_g.latest_capture="chalk_a";break;
        case 38:
            repeat(50)cr_extra_items_step(.05);cr_assert(array_length(_g.chalk_clouds[0].particles)<=50 && array_length(_g.chalk_clouds[0].particles)>=49,"chalk particles expire at five seconds while emission continues");_g.latest_capture="chalk_b";break;
        case 39:
            _g.chalk_clouds[0].time=4.9;cr_extra_items_step(5);cr_assert(array_length(_g.chalk_clouds)==0,"chalk emitter and remaining particles end at source item lifetime");
            show_debug_message("BBCR_LATEST_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
}
