cr_caption_present();
if(global.bbcr.crypto_testing)exit;
if(global.bbcr.captionevent_testing){cr_ce_capture();exit;}
if(cr_cheat_in_menu())cr_cheat_draw();
if(global.bbcr.policy_testing){cr_policy_capture();exit;}
if(global.bbcr.session_testing){cr_session_capture();exit;}
if(global.bbcr.unlock_testing){
    if(cr_value(global.bbcr,"unlock_capture",false)){screen_save("bbcr_unlock_menu.png");global.bbcr.unlock_capture=false;}
    exit;
}
if(global.bbcr.nullsession_testing){cr_ns_capture();exit;}
if(global.bbcr.latest_testing){cr_latest_capture();exit;}
if(global.bbcr.revision_testing){cr_revision_capture();exit;}
if((global.bbcr.current_testing || global.bbcr.style_feedback_testing) && cr_value(global.bbcr,"capture_scene","")!=""){
    screen_save("bbcr_"+global.bbcr.capture_scene+".png");global.bbcr.capture_scene="";
}
