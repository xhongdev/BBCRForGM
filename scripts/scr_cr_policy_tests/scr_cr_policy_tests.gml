/// Only the probability controls and compile-time recording/open policy.
function cr_policy_baseline() {
    cr_cheat_init();global.cr_cheat_events.enabled=false;global.cr_cheat_events.skip_gate=false;
    var _g=global.bbcr;_g.progress=cr_progress_default();_g.progress.flags[0]=true;
    _g.high_score=137;_g.games_since_error=5;_g.error_count=0;_g.boss_seen=false;_g.unlock_notice="";
    _g.mirror=false;_g.lightsout=false;_g.hard=false;
}
function cr_policy_probability_checks() {
    var _e=global.cr_cheat_events,_g=global.bbcr;
    _e.enabled=false;
    for(var _count=0;_count<4;_count++){
        var _den=16*power(2,_count),_wins=0;
        for(var _i=0;_i<_den;_i++)if(cr_error_eligible(9,_count,_i))_wins++;
        cr_assert(_wins==1 && !cr_error_eligible(_count<3?4:8,_count,0),"disabled override keeps source denominator and gate "+string(_count));
    }
    var _wins=0;for(var _i=0;_i<256;_i++)if(cr_loading_face_eligible(_i))_wins++;
    cr_assert(_wins==1,"loading face retains source 1/256 by default");
    if(!CR_CHEATS_CAN_OPEN_MENU){
        cr_cheat_set_open(true);cr_assert(!global.cr_cheat.open,"direct open rejected by compile-time macro");
        var _before=json_stringify(_e);cr_cheat_action(cr_cheat_event_rows()[0]);
        cr_assert(json_stringify(_e)==_before && !cr_cheat_menu_unlock("menu_unlock_all"),"disabled build rejects event actions and shortcut dispatch");return;
    }
    cr_cheat_category(3);var _rows=cr_cheat_rows();
    cr_assert(array_length(_rows)==5 && _rows[1].key=="error_percent","menu Events category exposes explicit probabilities");
    cr_cheat_click(590,130); // Enable via actual row hit test.
    cr_assert(_e.enabled && global.cr_cheat.used,"enabling override marks the session modified");
    cr_cheat_click(460,156); // Numeric value above its slider.
    cr_assert(is_struct(global.cr_cheat.edit),"percentage value opens typed editor");
    keyboard_string="37.25";cr_assert(cr_cheat_edit_commit() && abs(_e.error_percent-37.25)<=.000001,"typed fractional percentage commits");
    cr_cheat_edit_number(_rows[1]);keyboard_string="abc";cr_assert(!cr_cheat_edit_commit() && _e.error_percent==37.25,"invalid text leaves probability unchanged");
    keyboard_string=".";cr_assert(!cr_cheat_edit_commit(),"empty decimal rejected without real() exception");
    keyboard_string="200";cr_assert(cr_cheat_edit_commit() && _e.error_percent==100,"typed probability clamps to 100 percent");
    cr_cheat_number_set(_rows[1],37.25);cr_cheat_number_set(_rows[2],12.5);
    var _captures=0,_faces=0;
    for(var _i=0;_i<10000;_i++){if(cr_error_eligible(9,0,_i))_captures++;if(cr_loading_face_eligible(_i))_faces++;}
    cr_assert(_captures==3725 && _faces==1250,"independent rolls implement exact custom percentages");
    cr_assert(!cr_error_eligible(4,0,0),"100-percent override still respects original count gate unless bypass selected");
    cr_cheat_action(_rows[3]);cr_assert(cr_error_eligible(0,0,0),"explicit skip-gate control permits first-game event testing");
    cr_cheat_number_set(_rows[1],0);cr_cheat_number_set(_rows[2],0);
    cr_assert(!cr_error_eligible(100,0,0) && !cr_loading_face_eligible(0),"zero percent disables both random events");
    cr_cheat_number_set(_rows[1],100);cr_cheat_number_set(_rows[2],100);
    cr_assert(cr_error_eligible(0,0,9999) && cr_loading_face_eligible(9999),"100 percent includes last random bin");
    var _load=cr_ui_node("LoadingScreen"),_pic=cr_ui_node(_load.scripts.ClassicLoadScreen.theChosenOne);
    cr_menu_on_enable(_load);cr_assert(_pic.image_override==_load.scripts.ClassicLoadScreen.badli,"custom loading chance drives actual presentation callback");
    cr_cheat_number_set(_rows[2],0);cr_menu_on_enable(_load);cr_assert(_pic.image_override=="","zero chance clears a previous rare image");
    cr_cheat_action(_rows[4]);cr_assert(!_e.enabled && !_e.skip_gate && global.cr_cheat.used,"restoring source defaults cannot remove run marking");
    cr_cheat_number_set(_rows[1],37.25);cr_cheat_number_set(_rows[2],12.5);cr_cheat_action(_rows[0]);
    _g.policy_capture="events";
}
function cr_policy_record_checks() {
    var _g=global.bbcr,_record=CR_CHEATS_CAN_RECORD_PROGRESS;
    if(global.cr_cheat.open)cr_cheat_set_open(false);
    cr_policy_baseline();_g.style="party";
    // A real world + hidden-level transition, without running prior gameplay suites.
    bbcr_start_game("story","PartyMain");global.cr_load_transition.stage=16;
    cr_save("bbcr_policy_test.ini");
    cr_cheat_set_open(true);
    if(CR_CHEATS_CAN_OPEN_MENU)cr_assert(global.cr_cheat.used,"opening gameplay menu alone marks the run");
    else cr_cheat_mark_used(); // Exercise writer defense against an already marked run.
    cr_cheat_set_open(false);
    _g.notebooks=237;cr_caught(_g.npcs[0]);
    cr_assert(_g.high_score==(_record?237:137),"actual capture score submission obeys recording macro");
    _g.mirror=true;_g.lightsout=true;_g.hard=true;
    for(var _i=0;_i<3;_i++)cr_assert(cr_progress_complete_style(["classic","party","demo"][_i])==_record,"source completion hook obeys unified policy "+string(_i));
    cr_assert(cr_progress_check_all_fun()==_record && cr_progress_complete_null()==_record,"all-fun and NULL completions obey unified policy");
    for(var _i=1;_i<6;_i++)cr_assert(cr_progress_set_flag(_i)==_record,"secret/event flag write obeys policy "+string(_i));
    cr_assert((_g.unlock_notice!="")==_record,"forbidden progress never creates unlock notification");
    if(CR_CHEATS_CAN_OPEN_MENU){
        global.cr_cheat_events.enabled=true;global.cr_cheat_events.skip_gate=false;global.cr_cheat_events.error_percent=100;
        _g.ending={kind:"caught",time:3,phase:1};_g.mode="story";_g.games_since_error=5;_g.progress.flags[4]=false;
        // Restore flag 4 after event routing: no completion bypass is involved.
        cr_ending_step(.01);
        cr_assert(is_struct(_g.error_event) && _g.error_count==1,"eligible cheat capture enters real special event despite record policy");
        _g.progress.flags[4]=_record;
        cr_ui_dispose(_g.error_event.ui);_g.error_event=undefined;cr_audio_clear_all();
    }else {_g.games_since_error=0;_g.error_count=1;}
    global.cr_cheat_events.enabled=false;_g.dead=false;_g.boss_seen=true;
    if(CR_CHEATS_CAN_OPEN_MENU)cr_cheat_action(cr_cheat_row("Reset modifiers","action","reset"));
    cr_assert(global.cr_cheat.used,"closing menu and resetting modifiers preserve cheat marking");
    bbcr_start_game("story","ClassicTrue");global.cr_load_transition.stage=16;
    cr_assert(global.cr_cheat.used && cr_progress_cheats_allowed()==_record,"hidden scene reload retains run recording policy");
    // All INI writers are checked, including an options save during the run.
    _g.subtitles=!_g.subtitles;cr_save("bbcr_policy_test.ini");cr_progress_save();
    ini_open("bbcr_policy_test.ini");var _p=cr_progress_read();
    cr_assert(ini_read_real("scores","classic",0)==(_record?237:137),"saved high score obeys recording policy");
    cr_assert(_p.classic_won==_record && _p.party_won==_record && _p.demo_won==_record && _p.flags[0] && _p.flags[4]==_record && _p.flags[5]==_record,"saved unlock flags obey policy while existing unlock stays intact");
    cr_assert(ini_read_real("events","error_count",-1)==(_record?1:0),"special-event counters stay transient in non-recording run");
    cr_assert((ini_read_real("options","subtitles",0)>0)==_g.subtitles,"user options still save independently of run results");ini_close();
    cr_return_menu();cr_save("bbcr_policy_test.ini");
    cr_assert(_g.high_score==(_record?237:137) && _g.progress.flags[4]==_record && _g.error_count==(_record?1:0),"returning to menu restores suppressed records before later saves");
    cr_cheat_set_open(true);
    cr_assert(cr_cheat_menu_unlock("menu_unlock_glitch")==(_record && CR_CHEATS_CAN_OPEN_MENU),"explicit menu shortcuts cannot bypass recording or opening macros");
    cr_cheat_set_open(false);
    // Baseline is now clean; a future unmodified session can record normally.
    cr_cheat_init();cr_assert(cr_progress_cheats_allowed(),"cheat restriction does not contaminate a future clean run");
    var _file=file_text_open_write("bbcr_policy_result.json");
    file_text_write_string(_file,json_stringify({open:CR_CHEATS_CAN_OPEN_MENU,record:_record,checks:global.cr_checks,failures:global.cr_failures}));file_text_close(_file);
}
function cr_policy_step() {
    var _g=global.bbcr;
    if(!variable_struct_exists(_g,"policy_stage")){
        global.cr_checks=0;global.cr_failures=0;cr_policy_baseline();cr_ui_scene("MainMenu");global.cr_ui.stage=16;
        _g.policy_stage=-1;_g.policy_capture="";_g.policy_deadline=current_time+10000;return;
    }
    switch(_g.policy_stage){
        // screen_save observes the presented frame; allow the initial scene draw.
        case -1:_g.policy_capture="base";_g.policy_stage=0;break;
        case 0:if(_g.policy_capture!="")break;show_debug_message("BBCR_POLICY_INPUT: f1_down");_g.policy_stage=1;break;
        case 1:
            cr_cheat_step();if(!keyboard_check(vk_f1))break;
            cr_assert(global.cr_cheat.open==CR_CHEATS_CAN_OPEN_MENU,"native F1 obeys opening macro");
            show_debug_message("BBCR_POLICY_INPUT: f1_up");_g.policy_stage=2;break;
        case 2:
            cr_cheat_step();if(keyboard_check(vk_f1))break;
            if(!CR_CHEATS_CAN_OPEN_MENU)_g.policy_capture="disabled";
            cr_policy_probability_checks();_g.policy_stage=3;break;
        case 3:
            if(_g.policy_capture!="")break;
            cr_policy_record_checks();
            show_debug_message("BBCR_POLICY_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();return;
    }
    if(current_time>_g.policy_deadline){cr_assert(false,"policy native-input/capture timeout");game_end();}
}
function cr_policy_capture() {
    var _g=global.bbcr,_name=cr_value(_g,"policy_capture","");
    if(_name!=""){
        if(!cr_value(_g,"policy_capture_ready",false)){_g.policy_capture_ready=true;return;}
        screen_save("bbcr_policy_"+_name+".png");_g.policy_capture="";_g.policy_capture_ready=false;
    }
}
