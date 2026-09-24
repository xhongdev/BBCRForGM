/// Narrow menu-only checks: no gameplay or previous regression suites.
function cr_unlock_check_saved() {
    var _g=global.bbcr,_expected=json_stringify(_g.progress);
    ini_open("bbcr_menu_unlock_test.ini");
    var _loaded=cr_progress_read();
    cr_assert(json_stringify(_loaded)==_expected,"shortcut persists every progression flag using startup INI reader");
    cr_assert(ini_read_real("scores","classic",0)==137 && ini_read_string("options","sentinel","")=="keep-me","progress-only save preserves existing score and settings sections");
    ini_close();
    cr_assert(_g.high_score==137 && !_g.mirror && !_g.lightsout && !_g.hard,"shortcut does not submit a score or enable gameplay modifiers");
}
function cr_unlock_click(_row) {cr_cheat_click(260,130+34*_row);}
function cr_unlock_check_selector(_glitch) {
    var _n=cr_ui_node(_glitch?"StyleSelect/BaldiGlitch":"StyleSelect/Baldi");
    var _other=cr_ui_node(_glitch?"StyleSelect/Baldi":"StyleSelect/BaldiGlitch");
    cr_assert(_n.active && !_other.active && _n.graphics[0].raycast,"only the requested NULL/Glitch selector is active and clickable");
    cr_ui_actions(_n.button.press);
    cr_assert(global.bbcr.style=="null" && cr_style_level()==(_glitch?"ClassicGlitch":"ClassicNull"),"serialized style button selects the requested level through the game's level resolver");
    cr_assert(cr_ui_visible(cr_ui_node("ModeSelect")),"style shortcut can reach its actual mode-selection page");
}
function cr_unlock_checks() {
    var _g=global.bbcr,_c=global.cr_cheat;
    cr_assert(CR_CHEATS_CAN_UNLOCK_MODES==1,"this testing build enables cheat progression");
    cr_assert(!_g.loaded && !variable_global_exists("cr_map"),"unlock actions run from a cold main menu without a gameplay world");
    cr_assert(array_length(cr_cheat_rows())==6,"main-menu Unlocks category exposes six shortcuts");
    // Each independent shortcut must work immediately after a full progress reset.
    for(var _i=0;_i<3;_i++){
        _g.progress=cr_progress_default();cr_progress_menu_sync();cr_unlock_click(_i);
        var _p=_g.progress;
        cr_assert(_p.classic_won==(_i==0) && _p.party_won==(_i==1) && _p.demo_won==(_i==2) && !_p.flags[0],"individual fun-setting shortcut only unlocks its own mode: "+string(_i));
        var _f=cr_ui_node("ModeSelect/FunSettings/FunSetting"+string(_i+1)).scripts.FunSetting;
        cr_assert(!cr_ui_node(_f.lockedText).active && cr_ui_node(_f.unlockedText).active && !cr_ui_node(_f.checkMark).active,"new fun-setting unlock updates the source locked/unlocked presentation immediately");
        cr_unlock_check_saved();
    }
    _g.progress=cr_progress_default();_g.progress.flags[5]=true;
    cr_unlock_click(3);
    cr_assert(_g.progress.flags[0] && _g.progress.flags[1] && _g.progress.flags[2] && _g.progress.flags[3] && !_g.progress.flags[4] && _g.progress.flags[5],"NULL shortcut supplies all notebook prerequisites and preserves unrelated flags");
    cr_unlock_check_selector(false);cr_unlock_check_saved();
    // Switch while ModeSelect is already open, exercising live listing refresh.
    cr_unlock_click(4);cr_unlock_check_selector(true);cr_unlock_check_saved();
    cr_unlock_click(3);cr_unlock_check_selector(false);cr_unlock_check_saved();
    _g.progress=cr_progress_default();cr_unlock_click(4);
    cr_assert(_g.progress.flags[0] && _g.progress.flags[1] && _g.progress.flags[2] && _g.progress.flags[3] && _g.progress.flags[4],"Glitch shortcut works from a reset save without completing other runs");
    cr_unlock_check_selector(true);cr_unlock_check_saved();
    cr_unlock_click(5);
    cr_assert(_g.progress.classic_won && _g.progress.party_won && _g.progress.demo_won && !_g.progress.flags[4],"unlock-all exposes all fun settings and restores playable NULL from Glitch");
    cr_unlock_check_saved();
    // Startup reader + reconstructed menu, independent of the current UI nodes.
    _g.progress=cr_progress_default();ini_open("bbcr_menu_unlock_test.ini");_g.progress=cr_progress_read();ini_close();
    cr_ui_scene("MainMenu");global.cr_ui.stage=16;cr_progress_menu_sync();
    cr_unlock_check_selector(false);
    var _saved=json_stringify(_g.progress);_g.scene="game";
    cr_assert(!cr_cheat_menu_unlock("menu_unlock_glitch") && json_stringify(_g.progress)==_saved,"menu-only shortcut rejects calls outside the main menu");_g.scene="menu";
    cr_cheat_category(1);cr_assert(cr_cheat_rows()[0].key=="menu_reset","User data remains a separate category");
    cr_cheat_category(2);cr_assert(cr_cheat_rows()[0].key=="menu_preview_party","Preview remains a separate category");
    cr_cheat_category(3);cr_assert(_c.category==0,"three-category navigation wraps to Unlocks");
    cr_assert(_g.unlock_notice=="","quick unlocks complete without queuing an interrupting notification");
    show_debug_message("BBCR_UNLOCK_PROGRESS: "+json_stringify(_g.progress));
    _g.unlock_capture=true;
}
function cr_unlock_test_step() {
    var _g=global.bbcr;
    if(!variable_struct_exists(_g,"unlock_stage")){
        global.cr_checks=0;global.cr_failures=0;
        _g.progress=cr_progress_default();_g.high_score=137;_g.mirror=false;_g.lightsout=false;_g.hard=false;_g.unlock_notice="";
        ini_open("bbcr_menu_unlock_test.ini");ini_write_real("scores","classic",137);ini_write_string("options","sentinel","keep-me");ini_close();
        cr_ui_scene("MainMenu");global.cr_ui.stage=16;_g.unlock_capture=false;
        _g.unlock_stage=1;_g.unlock_deadline=current_time+5000;show_debug_message("BBCR_UNLOCK_INPUT: f1_down");return;
    }
    switch(_g.unlock_stage){
        case 1:
            cr_cheat_step();
            if(global.cr_cheat.open){cr_assert(global.cr_cheat.menu_context,"native F1 opens the main-menu overlay");_g.unlock_stage=2;show_debug_message("BBCR_UNLOCK_INPUT: f1_up");}
            break;
        case 2:
            cr_cheat_step();if(keyboard_check(vk_f1))break;
            cr_unlock_checks();_g.unlock_stage=3;break;
        case 3:
            if(_g.unlock_capture)break;
            _g.unlock_deadline=current_time+5000;_g.unlock_stage=4;show_debug_message("BBCR_UNLOCK_INPUT: f1_down");break;
        case 4:
            cr_cheat_step();if(global.cr_cheat.open)break;
            cr_assert(!window_mouse_get_locked(),"closing the new unlock menu leaves menu mouse unlocked");
            _g.unlock_stage=5;show_debug_message("BBCR_UNLOCK_INPUT: f1_up");break;
        case 5:
            cr_cheat_step();if(keyboard_check(vk_f1))break;
            bbcr_menu_step(.016);cr_audio_update_volume();
            cr_assert(_g.scene=="menu" && _g.high_score==137 && !global.cr_cheat.open,"normal menu update resumes after shortcuts and F1 close");
            show_debug_message("BBCR_UNLOCK_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();return;
    }
    if(current_time>_g.unlock_deadline){cr_assert(false,"unlock-menu native input/capture timeout");game_end();}
}
