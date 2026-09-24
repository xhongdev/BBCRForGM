cr_game_display_resize();
if(global.bbcr.captionevent_testing){if(cr_value(global.bbcr,"ce_wait_draw",false)){global.bbcr.ce_wait_draw=false;exit;}cr_ce_step();exit;}
if(global.bbcr.session_testing){cr_session_step();exit;}
if(global.bbcr.nulleffects_testing){if(cr_value(global.bbcr,"ne_wait_draw",false)){global.bbcr.ne_wait_draw=false;exit;}cr_ne_step();exit;}
if(global.bbcr.finalfeedback_testing){if(cr_value(global.bbcr,"ff_wait_draw",false)){global.bbcr.ff_wait_draw=false;exit;}cr_ff_step();exit;}
if(global.bbcr.nullsession_testing){if(cr_value(global.bbcr,"ns_wait_draw",false)){global.bbcr.ns_wait_draw=false;exit;}cr_ns_step();exit;}
if(global.bbcr.latest_testing){if(cr_value(global.bbcr,"latest_wait_draw",false)){global.bbcr.latest_wait_draw=false;exit;}cr_latest_step();if(global.bbcr.scene=="menu")room_goto(rm_menu);exit;}
if(global.bbcr.revision_testing){if(cr_value(global.bbcr,"revision_wait_draw",false)){global.bbcr.revision_wait_draw=false;exit;}cr_revision_test_step();if(global.bbcr.scene=="menu")room_goto(rm_menu);exit;}
if(global.bbcr.current_testing){cr_current_step();if(global.bbcr.scene=="menu")room_goto(rm_menu);exit;}
if(global.bbcr.style_feedback_testing){cr_style_feedback_step();exit;}
if(global.bbcr.style_testing){cr_style_test_step();exit;}
if(global.bbcr.followup_testing){cr_followup_test_step();exit;}
if(global.bbcr.sense_testing){cr_sense_test_step();exit;}
if(global.bbcr.ending_testing){cr_ending_test_step();exit;}
if(global.bbcr.encounter_testing){cr_encounter_test_step();exit;}
if(global.bbcr.cheat_testing){cr_cheat_test_step();exit;}
if(global.bbcr.window_testing){cr_window_test_step();exit;}
if(global.bbcr.testing){
    test_frame++;
    if((test_frame==47 && !keyboard_check(vk_space)) || (test_frame==48 && keyboard_check(vk_space))){
        if(current_time<global.bbcr.input_deadline){test_frame--;exit;}
        cr_assert(false,"native Space input reached Runner before deadline");
    }
    if(cr_value(global.bbcr,"roundtrip",0)>0){
        if(test_frame==2){
            cr_assert(global.bbcr.loaded && array_length(global.bbcr.npcs)==7,"actual room reentry rebuilds NPC paths "+string(global.bbcr.roundtrip));
            cr_assert(global.cr_ui.wait=="" && !cr_ui_node("LoadingScreen").active,"actual reentry removes loading screen "+string(global.bbcr.roundtrip));
        }
        if(test_frame==3){repeat(16)cr_transition_tick(global.cr_load_transition,.017);cr_pause(true);repeat(32)cr_pause_tick(1/60);}
        if(test_frame==5){
            if(global.bbcr.roundtrip>=3){show_debug_message("BBCR_TEST_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();exit;}
            global.bbcr.roundtrip++;var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;
            cr_ui_press(cr_ui_node("ClassicPauseMenu/Main/Quit"));
            cr_assert(cr_ui_node("ClassicPauseMenu/Confirm").active,"source pause Quit opens confirmation");
            cr_ui_press(cr_ui_node("ClassicPauseMenu/Confirm/YesButton"));room_goto(rm_menu);
        }exit;
    }
    if(test_frame==3){global.bbcr.scene="math";global.bbcr.q=0;cr_math_problem();}
    if(test_frame==5){global.bbcr.scene="game";global.bbcr.px=175;global.bbcr.pz=35;global.bbcr.spoop=false;}
    if(test_frame==6)window_set_size(1280,720);
    if(test_frame==9){window_set_size(600,800);global.bbcr.scene="math";}
    if(test_frame==11){
        var _v=cr_game_viewport(),_button=cr_math_buttons()[0].rect;
        cr_assert(cr_game_hit_at(_button,_v[0]+(_button[0]+10)*_v[2],_v[1]+(_button[1]+10)*_v[2]),"YCTP mouse hit transforms with portrait viewport");
        cr_assert(!cr_game_hit_at(_button,20,20),"letterbox region cannot press YCTP buttons");
    }
    if(test_frame==12){window_set_size(960,720);global.bbcr.scene="game";}
    if(test_frame==14){cr_pause(true);cr_assert(global.cr_pause_ui.reveal && global.cr_pause_ui.stage==0,"pause starts source dither reveal");}
    if(test_frame==15){repeat(8)cr_pause_tick(.017);global.bbcr.capture_scene="pause_half";}
    if(test_frame==16){repeat(8)cr_pause_tick(.017);global.bbcr.capture_scene="pause_full";cr_assert(global.cr_pause_ui.stage==16,"pause transition completes while game time is stopped");}
    if(test_frame==17){
        var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;
        for(var _i=0;_i<array_length(global.cr_ui.nodes);_i++){
            var _n=global.cr_ui.nodes[_i];if(is_undefined(_n.button))continue;
            for(var _j=0;_j<array_length(_n.button.press);_j++)if(_n.button.press[_j].method=="Pause")cr_ui_press(_n);
        }
        global.cr_ui=_old;cr_assert(!global.bbcr.paused && global.cr_pause_ui.stage==0,"source Resume button starts fade-out and restores gameplay");
        repeat(8)cr_pause_tick(.017);global.bbcr.capture_scene="resume_half";
    }
    if(test_frame==18){repeat(8)cr_pause_tick(.017);global.bbcr.capture_scene="resume_full";}
    if(test_frame==19){global.bbcr.yaw=0;global.bbcr.projection_fixture=true;global.bbcr.capture_scene="projection";}
    if(test_frame==20){global.bbcr.projection_fixture=false;global.bbcr.capture_scene="";}
    if(test_frame==21){
        var _g=global.bbcr,_d=_g.doors[0];_g.yaw=degtorad(_d.dir*90);_g.px=_d.cx-sin(_g.yaw)*4;_g.pz=_d.cz-cos(_g.yaw)*4;_g.capture_scene="reticle_hand";
    }
    if(test_frame==22){global.bbcr.yaw+=pi/2;global.bbcr.capture_scene="reticle_idle";}
    if(test_frame==23 || test_frame==24){
        var _g=global.bbcr,_b=_g.books[0];_g.px=_b.x;_g.pz=_b.z-8;_g.yaw=0;_g.time=(test_frame==23?pi/2:pi*1.5)/5;
        _g.capture_scene=test_frame==23?"notebook_high":"notebook_low";
    }
    if(test_frame==25 || test_frame==26){
        var _g=global.bbcr;_g.books[0].done=true;_g.items=[{x:_g.px,z:_g.pz+8,item:"Zesty",done:false}];_g.time=(test_frame==25?pi/2:pi*1.5)/5;
        _g.capture_scene=test_frame==25?"pickup_high":"pickup_low";
    }
    if(test_frame==27){global.bbcr.scene="math";global.bbcr.math_face=false;global.bbcr.capture_scene="math_blank";}
    if(test_frame>=28 && test_frame<=45)cr_feedback_capture_step(test_frame);
    if(test_frame>=46 && test_frame<=55)cr_npc_feedback_capture(test_frame);
    if(test_frame>55){global.bbcr.capture_scene="";global.bbcr.roundtrip=1;cr_return_menu();room_goto(rm_menu);}
    exit;
}
bbcr_game_step();
if (global.bbcr.scene == "menu") room_goto(rm_menu);
if (keyboard_check_pressed(vk_f11)) window_set_fullscreen(!window_get_fullscreen());
