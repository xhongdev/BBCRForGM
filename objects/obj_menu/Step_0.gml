cr_ui_display_resize();
if(global.bbcr.crypto_testing){cr_crypto_test_step();exit;}
if(global.bbcr.captionevent_testing){cr_ce_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.policy_testing){cr_policy_step();exit;}
if(global.bbcr.session_testing){cr_session_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.nulleffects_testing){cr_ne_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.finalfeedback_testing){cr_ff_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.unlock_testing){cr_unlock_test_step();exit;}
if(global.bbcr.nullsession_testing){cr_ns_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.latest_testing){cr_latest_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.revision_testing){cr_revision_test_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.current_testing){cr_current_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if(global.bbcr.style_feedback_testing){
    if(!variable_struct_exists(global.bbcr,"sf_stage")){global.cr_checks=0;global.cr_failures=0;global.bbcr.style="party";bbcr_start_game("story");room_goto(rm_game);}
    else cr_style_feedback_step();exit;
}
if(global.bbcr.style_testing){global.cr_checks=0;global.cr_failures=0;global.bbcr.style="party";bbcr_start_game("story");room_goto(rm_game);exit;}
if(global.bbcr.followup_testing){global.cr_checks=0;global.cr_failures=0;bbcr_start_game("story");room_goto(rm_game);exit;}
if(global.bbcr.sense_testing){global.cr_checks=0;global.cr_failures=0;bbcr_start_game("story");room_goto(rm_game);exit;}
if(global.bbcr.ending_testing){global.cr_checks=0;global.cr_failures=0;bbcr_start_game("story");room_goto(rm_game);exit;}
if(global.bbcr.encounter_testing){
    if(global.bbcr.encounter_stage==0){global.cr_checks=0;global.cr_failures=0;}
    bbcr_start_game("story");room_goto(rm_game);exit;
}
if(global.bbcr.cheat_testing){
    if(global.bbcr.cheat_test_stage==0){global.cr_checks=0;global.cr_failures=0;}
    else cr_assert(!global.cr_cheat.open && !global.cr_cheat.used,"return to menu discards test modifiers and releases overlay");
    bbcr_start_game("story");room_goto(rm_game);exit;
}
if(global.bbcr.window_testing){cr_window_test_step();if(global.bbcr.scene=="game")room_goto(rm_game);exit;}
if (global.bbcr.testing) {
    if(cr_value(global.bbcr,"roundtrip",0)>0){cr_roundtrip_menu_test();exit;}
    global.bbcr_frame++;
    cr_menu_test_step(global.bbcr_frame);
    exit;
}
if (global.bbcr.scene == "menu" || global.bbcr.scene == "loading") {
    if(global.cr_ui.scene=="MainMenu" && cr_cheat_step())exit;
    bbcr_menu_step();
    if (global.bbcr.scene == "game") room_goto(rm_game);
}
if (keyboard_check_pressed(vk_f11)) window_set_fullscreen(!window_get_fullscreen());
