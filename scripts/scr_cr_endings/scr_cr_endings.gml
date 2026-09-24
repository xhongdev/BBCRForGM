function cr_math_restore_audio_pause() {
    var _g=global.bbcr;if(!cr_value(_g,"math_audio_paused",false))return;
    for(var _i=0;_i<array_length(_g.sound_instances);_i++){
        var _s=_g.sound_instances[_i];if(!cr_value(_s,"ignore_pause",_s.interface) && audio_is_playing(_s.handle))audio_pause_sound(_s.handle);
    }
}
function cr_saved_voice_tick(_v) {
    if(audio_is_playing(_v.voice) || array_length(_v.queue)==0)return;
    var _entry=array_shift(_v.queue);_v.key=is_struct(_entry)?_entry.key:_entry;
    _v.voice=cr_sound(_v.key,is_struct(_entry)?_entry.x:undefined,is_struct(_entry)?_entry.z:undefined);
}
function cr_caught(_n) {
    var _g=global.bbcr;if(_g.dead || _g.won)return;
    if(is_struct(_g.null_mode))cr_null_speech("audHaha",.04);
    cr_rope_end(false);_g.dead=true;_g.scene="game";_g.paused=false;_g.math_audio_paused=false;
    cr_voice_clear();if(_g.game_music>=0)audio_stop_sound(_g.game_music);if(_g.math_music>=0)audio_stop_sound(_g.math_music);
    var _dx=_g.px-_n.px,_dz=_g.pz-_n.pz,_len=point_distance(0,0,_dx,_dz);
    if(_len<=.0001){_dx=-sin(_g.yaw);_dz=-cos(_g.yaw);_len=1;}
    var _sounds=_n.params.lose_sounds,_total=0;for(var _i=0;_i<array_length(_sounds);_i++)_total+=_sounds[_i].weight;
    var _pick=random(_total),_key=_sounds[0].sound;
    for(var _i=0;_i<array_length(_sounds);_i++){_pick-=_sounds[_i].weight;if(_pick<0){_key=_sounds[_i].sound;break;}}
    var _voice=cr_sound(_key,undefined,undefined,true),_last=array_length(_g.sound_instances)-1;
    if(_voice>=0 && !is_struct(_g.null_mode)){_g.sound_instances[_last].gain*=.6;cr_audio_update_volume();}
    _g.ending={kind:"caught",time:0,phase:0,x:_n.px+_dx/_len*2,z:_n.pz+_dz/_len*2,yaw:arctan2(-_dx,-_dz),far:500,voice:_voice,sound:_key};
    if(is_struct(_g.null_mode)){
        _g.ending.kind="nullcaught";_g.ending.far=1000;_g.ending.glitch_seed=irandom(4095);_g.ending.glitch_timer=.5;
        _g.null_mode.glitch=0;_g.null_mode.color_glitch=0;
        for(var _i=0;_i<array_length(_g.exit_fx.on);_i++)_g.exit_fx.on[_i]=true;_g.exit_fx.dirty=true;
    }
    global.cr_math_ui.stage=16;global.cr_pause_ui.stage=16;global.cr_load_transition.stage=16;
    window_mouse_set_locked(false);window_set_cursor(cr_none);
    cr_score_submit(_g.notebooks);cr_save();
}
function cr_win_begin() {
    var _g=global.bbcr;if(_g.won || _g.dead)return;
    cr_progress_complete_style(_g.style);
    cr_rope_end(false);_g.won=true;_g.math_audio_paused=false;audio_pause_all();cr_voice_clear();cr_caption_world_end();
    if(_g.exit_fx.chaos>=0)audio_stop_sound(_g.exit_fx.chaos);
    var _secret=_g.style=="classic" && _g.secret && !cr_value(_g,"debug_mode",false);
    if(_secret)cr_progress_set_flag(1);
    _g.ending={kind:_secret?"secret":"win",time:0,phase:0,voice:-1,sound:"",next:global.cr_map.next_level};
    var _old=global.cr_ui;global.cr_ui=global.cr_win_ui;
    cr_ui_active(global.cr_ui_data.win.bg,!_secret);cr_ui_transition(.01666667);global.cr_ui.reveal=true;global.cr_ui=_old;
    if(_secret)global.cr_win_ui.stage=16;
    if(!_secret && !cr_value(_g,"null_defeated",false)){_g.ending.sound=global.cr_ui_data.win.sound;_g.ending.voice=cr_sound(_g.ending.sound,undefined,undefined,true);}
    window_mouse_set_locked(false);window_set_cursor(cr_none);cr_save();
}
function cr_ending_step(_dt) {
    var _g=global.bbcr,_e=_g.ending;if(!is_struct(_e))return;
    if(is_struct(cr_value(_g,"error_event",undefined))){cr_error_step(_dt);return;}
    _e.time+=_dt;
    if(_e.kind=="nullcaught"){
        _e.glitch_timer-=_dt;
        if(_e.glitch_timer<=0 && !_g.reduce_flashing){_e.glitch_seed=irandom(4095);_e.glitch_timer=.55-_e.time*.05;}
        if(_e.time>=10)game_end();
    }else if(_e.kind=="caught"){
        _e.far=max(.31,500*(1-_e.time));
        if(_e.time>=1 && _e.phase==0){_e.phase=1;audio_stop_sound(_e.voice);audio_pause_all();}
        if(_e.time>=3){
            var _reveal=_g.mode=="endless" && _g.notebooks>=_g.high_score && cr_progress_cheats_allowed();
            if(!_reveal && cr_error_eligible(_g.games_since_error,_g.error_count))cr_error_begin();else cr_return_menu();
        }
    }else if(_e.kind=="win"){
        cr_transition_tick(global.cr_win_ui,_dt);
        if(_e.phase==0 && _e.time>=8 && !audio_is_playing(_e.voice)){
            var _old=global.cr_ui;global.cr_ui=global.cr_win_ui;cr_ui_active(global.cr_ui_data.win.bg,false);global.cr_ui=_old;
            _e.phase=1;_e.time=0;
        }else if(_e.phase==1 && _e.time>=5)cr_return_menu();
    }else if(_e.kind=="secret"){
        // ClassicWin's black cover survives the reload, then BeginPlay removes it.
        var _next=_e.next;
        bbcr_start_game("story",_next);
        var _u=global.cr_load_transition;_u.previous=surface_create(480,360);
        surface_set_target(_u.previous);draw_clear(c_black);surface_reset_target();
        _u.stage=0;_u.interval=.01666667;_u.timer=_u.interval;
    }
}
function cr_ending_draw() {
    var _g=global.bbcr;if(!_g.dead && !_g.won)return false;
    if(is_struct(cr_value(_g,"error_event",undefined))){cr_game_ui_draw(_g.error_event.ui,false);return true;}
    if(_g.dead){
        if(_g.ending.phase>=1){draw_set_color(c_black);draw_rectangle(0,0,480,360,false);draw_set_color(c_white);}
    }else cr_game_ui_draw(global.cr_win_ui,false);
    return true;
}
function cr_secret_step() {
    var _g=global.bbcr;_g.stamina=global.cr_catalog.movement.staminaMax*2;
    for(var _i=0;_i<array_length(_g.secret_tutors);_i++){
        var _t=_g.secret_tutors[_i];
        if(!_t.started && sqrt(sqr(_g.px-_t.position[0])+sqr(global.cr_map.spawn[1]-_t.position[1])+sqr(_g.pz-_t.position[2]))<_t.radius+global.cr_catalog.movement.radius){
            _t.handle=cr_sound(_t.speech,_t.position[0],_t.position[2]);_t.started=true;
        }else if(_t.started && !audio_is_playing(_t.handle)){
            if(_t.quit){game_end();return;}if(_t.menu){cr_return_menu();return;}
        }
    }
}
