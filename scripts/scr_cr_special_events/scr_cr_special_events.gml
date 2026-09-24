/// Source conditions: CoreGameManager.ErrorNow, ClassicLoadScreen and Credits.
function cr_error_eligible(_games,_count,_roll=-1) {
    var _custom=CR_CHEATS_CAN_OPEN_MENU && global.cr_cheat_events.enabled;
    if(_custom)cr_cheat_mark_used();
    if(_games<=(_count<3?4:8) && !(_custom && global.cr_cheat_events.skip_gate))return false;
    if(_custom)return cr_event_percent_roll(global.cr_cheat_events.error_percent,_roll);
    var _denominator=16*power(2,min(_count,3));return (_roll<0?irandom(_denominator-1):_roll)==0;
}
function cr_event_percent_roll(_percent,_roll=-1) {
    // Integer basis points give exact 0%, 100% and two-decimal percentages.
    return (_roll<0?irandom(9999):_roll)<round(clamp(_percent,0,100)*100);
}
function cr_loading_face_eligible(_roll=-1) {
    if(CR_CHEATS_CAN_OPEN_MENU && global.cr_cheat_events.enabled){
        cr_cheat_mark_used();return cr_event_percent_roll(global.cr_cheat_events.loading_percent,_roll);
    }
    return (_roll<0?irandom(255):_roll)==0;
}
function cr_error_begin() {
    var _g=global.bbcr,_memory=array_create(array_length(_g.sound_memory));array_copy(_memory,0,_g.sound_memory,0,array_length(_memory));cr_audio_clear_all();audio_resume_all();_g.games_since_error=0;_g.error_count++;cr_save();
    var _after=_g.progress.flags[4] && !_g.progress.flags[5];
    _g.error_event={phase:"error",time:0,after_null:_after,glitch_at:_after?random_range(3,8):100000,ends:_after?random_range(10,20):5,
        voice:cr_sound(global.cr_session_data.error.initial_sound,undefined,undefined,true,undefined,undefined,true,undefined,true),ui:cr_ui_context("Error"),next_glitch:0,memory:_memory};
    cr_audio_loop(_g.error_event.voice,global.cr_session_data.error.initial_loop);
    audio_sound_pitch(_g.error_event.voice,global.cr_session_data.error.initial_pitch);
}
function cr_error_step(_dt) {
    var _g=global.bbcr,_e=_g.error_event;_e.time+=_dt;
    if(_e.phase=="error"){
        if(_e.time>=_e.glitch_at)cr_error_glitch_step(_e,_dt);
        if(_e.time<_e.ends)return;
        if(!_e.after_null){game_end();return;}
        cr_nullend_begin(_e);
    }else cr_nullend_step(_e,_dt);
}
function cr_menu_on_enable(_node) {
    if(variable_struct_exists(_node.scripts,"ClassicLoadScreen")){
        var _d=_node.scripts.ClassicLoadScreen,_pic=cr_ui_node(_d.theChosenOne);
        _pic.image_override=cr_loading_face_eligible()?_d.badli:"";
    }
    if(variable_struct_exists(_node.scripts,"Credits")){
        _node.credits_time=0;_node.credits_index=0;
        var _s=_node.scripts.Credits;
        for(var _i=0;_i<array_length(_s.screens);_i++)cr_ui_active(_s.screens[_i],_i==0);
        audio_stop_all();global.cr_ui.music=cr_sound("ClassicCredits");
    }
}
function cr_menu_special_step(_dt) {
    var _u=global.cr_ui,_node=cr_ui_node("Credits");if(is_undefined(_node) || !cr_ui_visible(_node))return;
    var _s=_node.scripts.Credits;_node.credits_time=cr_value(_node,"credits_time",0)+_dt;
    if(_node.credits_time>=_s.timeBetweenFrames){
        _node.credits_time=0;_node.credits_index=cr_value(_node,"credits_index",0)+1;cr_ui_transition(.25);_u.transition_type="swipe";_u.swipe_time=0;
        for(var _i=0;_i<array_length(_s.screens);_i++)cr_ui_active(_s.screens[_i],_i==_node.credits_index);
        if(_node.credits_index>=array_length(_s.screens)){cr_ui_active(_node.id,false);cr_ui_active(_s.previous,true);audio_stop_all();}
    }
    var _n=cr_ui_node(_s.glitchTmp);if(global.bbcr.boss_seen){_n.text_key="";return;}
    // Credits.ScrambleFont changes a private font instance. Do not mutate the
    // shared atlas metrics used by the rest of the UI.
    for(var _i=0;_i<array_length(_n.graphics);_i++){var _g=_n.graphics[_i];if(_g.type!="text")continue;
        var _base=global.cr_ui_data.fonts[$ _s.errorFontUsed];_g.layout.atlas=_base.file;
        for(var _j=0;_j<array_length(_g.layout.quads);_j++){var _q=_g.layout.quads[_j];_q[0]=irandom(255);_q[1]=irandom(255);_q[2]=irandom(49);_q[3]=irandom(49);_q[6]=irandom_range(10,39);_q[7]=irandom_range(10,39);}
    }
}
