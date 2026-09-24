/// Focused captions and special-event lifecycle checks for the current report.
function cr_ce_capture() {
    var _g=global.bbcr,_label=cr_value(_g,"ce_capture","");
    if(_label=="")return;
    if(_g.scene=="game" && is_struct(cr_value(_g,"error_event",undefined))){
        cr_game_ui_draw(_g.error_event.ui,false);
        if(surface_exists(_g.error_event.ui.surface))surface_save(_g.error_event.ui.surface,"bbcr_captionevent_native_"+_label+".png");
    }else if(_g.scene=="menu" && surface_exists(global.cr_ui.surface))surface_save(global.cr_ui.surface,"bbcr_captionevent_native_"+_label+".png");
    screen_save("bbcr_captionevent_"+_label+".png");_g.ce_capture="";
}
function cr_ce_step() {
    var _g=global.bbcr;if(!variable_struct_exists(_g,"ce_stage")){global.cr_checks=0;global.cr_failures=0;_g.ce_stage=0;_g.ce_wait_draw=false;_g.ce_capture="";global.cr_cheat_hint_visible=false;}
    var _s=_g.ce_stage++;cr_audio_update_volume();cr_caption_tick(1/60);
    switch(_s){
        case 0:
            _g.subtitles=true;_g.px=0;_g.pz=0;_g.yaw=0;_g.null_mode={phase:"none"};cr_ui_scene("ClassicLauncher");global.cr_ui.stage=16;cr_audio_clear_all();
            var _play=cr_ui_node("Canvas/Launcher/PlayButton");cr_ui_press(_play);var _h=global.cr_ui.sound;
            cr_assert(_h>=0 && array_length(global.cr_captions)==1,"source Play slap creates a caption");
            cr_assert(global.cr_captions[0].text=="*SLAP*","source slap localization is attached");_g.ce_capture="slap";break;
        case 1:
            _g.scene="game";cr_audio_clear_all();var _ph=cr_sound("BAL_Slap",0,0,false,undefined,global.cr_session_data.profiles.NULL,false,"captionevent:world");var _c=global.cr_captions[0],_p=cr_caption_position(_c.entry);_g.pz+=100;var _q=cr_caption_position(_c.entry);
            cr_assert(_p[2]>_q[2] && _p[0]!=_q[0],"positional caption follows distance and bearing");_g.scene="menu";_g.ce_capture="caption_far";break;
        case 2:
            cr_audio_clear_all();bbcr_start_game("story");if(!variable_global_exists("cr_hud"))global.cr_hud=cr_ui_context("Hud");global.cr_load_transition.stage=16;_g.progress.flags[4]=true;_g.progress.flags[5]=false;_g.games_since_error=5;_g.error_count=0;_g.dead=true;_g.won=false;cr_error_begin();
            var _initial=global.bbcr.sound_instances[array_length(global.bbcr.sound_instances)-1];
            cr_assert(_g.error_event.voice>=0 && _initial.key==global.cr_session_data.error.initial_sound,"first special event uses source ErrorScreen audio");
            cr_assert(array_length(global.cr_captions)==0,"direct ErrorScreen source does not invent a subtitle");_g.ce_capture="error_initial";break;
        case 3:
            var _e=_g.error_event;cr_error_step(_e.glitch_at+.02);var _gl=global.bbcr.sound_instances[array_length(global.bbcr.sound_instances)-1];cr_assert(_e.glitch_started && _e.voice>=0 && _gl.key=="ErrorGlitch","error glitch replaces the initial source audio at the source phase");_g.ce_capture="error_glitch";break;
        case 4:
            var _e=_g.error_event;_e.time=_e.ends+.01;cr_error_step(0);cr_assert(_e.phase=="nullend","post-NULL event enters NullEnd after the error stage");break;
        case 5:
            var _e=_g.error_event;_e.start=0;cr_error_step(.01);cr_assert(_e.voice>=0,"NullEnd starts its source voice");_g.ce_capture="nullend_start";break;
        case 6:
            var _e=_g.error_event;_e.stage=1;audio_sound_set_track_position(_e.voice,16.5);cr_error_step(.01);var _old=global.cr_ui;global.cr_ui=_e.ui;var _person=cr_ui_visible(cr_ui_node(global.cr_session_data.null_end.person));global.cr_ui=_old;show_debug_message("BBCR_CAPTIONEVENT_NULLEND: stage="+string(_e.stage)+" person="+string(_person)+" audio="+string(audio_is_playing(_e.voice))+" at="+string(audio_sound_get_track_position(_e.voice)));cr_assert(_e.stage==2,"NullEnd reaches source person timestamp");cr_assert(_person,"NullEnd person node becomes visible at source timestamp");_g.ce_capture="nullend_person";break;
        case 7:
            var _e=_g.error_event;audio_sound_set_track_position(_e.voice,27.1);_e.stage=3;cr_error_step(.01);cr_assert(_e.stage==4,"NullEnd enters source disappearance stage");repeat(120)cr_error_step(.05);cr_assert(_e.disappear_phase>=2,"NullEnd advances its staged disappearance animation");_g.ce_capture="nullend_disappear";break;
        case 8:
            cr_caption_world_end();cr_assert(array_length(global.cr_captions)==0,"ending cleanup removes old NPC captions");show_debug_message("BBCR_CAPTIONEVENT_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
    _g.ce_wait_draw=true;
}
