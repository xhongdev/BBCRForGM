if(global.bbcr.captionevent_testing){cr_caption_present();cr_ce_capture();exit;}
cr_game_gui_draw();
cr_caption_present();
if(global.bbcr.session_testing){cr_session_capture();exit;}
if(global.bbcr.nulleffects_testing){cr_ne_capture();exit;}
if(global.bbcr.finalfeedback_testing){cr_ff_capture();exit;}
if(global.bbcr.dead && is_struct(global.bbcr.null_mode))cr_null_capture_draw();
if(global.bbcr.nullsession_testing){cr_ns_capture();exit;}
if(global.bbcr.latest_testing){cr_latest_capture();exit;}
if(global.bbcr.revision_testing){cr_revision_capture();exit;}
if(global.bbcr.cheat_testing && string_pos("hint_",cr_value(global.bbcr,"cheat_capture",""))==1)
    screen_save("bbcr_cheat_"+global.bbcr.cheat_capture+"_base.png");
cr_cheat_draw();
if(global.bbcr.current_testing || global.bbcr.ending_testing || global.bbcr.encounter_testing || global.bbcr.sense_testing || global.bbcr.style_testing || global.bbcr.style_feedback_testing){
    var _capture=cr_value(global.bbcr,"capture_scene","");
    if(_capture=="encounter_red_full" && surface_exists(global.cr_light_surface))surface_save(global.cr_light_surface,"bbcr_encounter_lightmap.png");
    if(_capture!=""){screen_save("bbcr_"+_capture+".png");global.bbcr.capture_scene="";}
}else if(global.bbcr.cheat_testing){
    var _capture=cr_value(global.bbcr,"cheat_capture","");
    if(_capture!=""){screen_save("bbcr_cheat_"+_capture+".png");global.bbcr.cheat_capture="";}
}else if(global.bbcr.testing && !global.bbcr.window_testing){
    var _cycle=cr_value(global.bbcr,"roundtrip",0);
    screen_save("bbcr_"+(_cycle>0?"roundtrip_"+string(_cycle)+"_":"game_")+string(test_frame)+".png");
    var _capture=cr_value(global.bbcr,"capture_scene","");if(_capture!="")screen_save("bbcr_"+_capture+".png");
}
