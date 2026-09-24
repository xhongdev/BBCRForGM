if (!variable_global_exists("bbcr") || global.bbcr.scene != "game") bbcr_start_game(variable_global_exists("bbcr") ? global.bbcr.mode : "story");
test_frame=0;
if(global.bbcr.captionevent_testing)exit;
if(global.bbcr.session_testing)exit;
if(global.bbcr.nulleffects_testing)exit;
if(global.bbcr.finalfeedback_testing)exit;
if(global.bbcr.nullsession_testing)exit;
if(global.bbcr.testing && !global.bbcr.latest_testing && !global.bbcr.revision_testing && !global.bbcr.current_testing && !global.bbcr.style_feedback_testing && !global.bbcr.window_testing && !global.bbcr.cheat_testing && !global.bbcr.encounter_testing && !global.bbcr.ending_testing && !global.bbcr.sense_testing && !global.bbcr.followup_testing && !global.bbcr.style_testing && cr_value(global.bbcr,"roundtrip",0)==0) cr_run_tests();
