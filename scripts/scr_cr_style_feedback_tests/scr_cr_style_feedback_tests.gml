/// Only the current Party/Demo/notification/menu-tools report is exercised here.
function cr_sf_audio_count(_key) {
    var _n=0,_list=global.bbcr.sound_instances;for(var _i=0;_i<array_length(_list);_i++)if(_list[_i].key==_key)_n++;return _n;
}
function cr_sf_items() {
    var _g=global.bbcr,_keys=["Teleporter","ChalkEraser","PortalPoster"];
    for(var _i=0;_i<3;_i++){cr_assert(cr_cheat_give(_keys[_i]) && _g.inventory[0]==_keys[_i],"Party item is available through real give menu: "+_keys[_i]);}
    _g.inventory=["ChalkEraser","",""];_g.slot=0;cr_use_item();
    cr_assert(_g.inventory[0]=="" && array_length(_g.chalk_clouds)==1 && _g.chalk_clouds[0].time==60,"chalk eraser consumes and creates source sixty-second cloud");
    var _cloud=_g.chalk_clouds[0];cr_assert(!cr_clear_line(_cloud.px-8,_cloud.pz,_cloud.px+8,_cloud.pz),"chalk collider blocks NPC sight through its tile");
    cr_extra_items_step(60);cr_assert(array_length(_g.chalk_clouds)==0,"chalk cloud expires at source lifetime");
    _g.inventory=["Teleporter","",""];cr_use_item();var _tp=_g.teleporter,_count=_tp.remaining;
    cr_assert(_count>=12 && _count<=15 && cr_extra_move_scale()==0,"Dangerous Teleporter locks movement for source 12-15 hops");
    repeat(2000)cr_extra_items_step(.01);
    cr_assert(!is_struct(_g.teleporter) && _tp.count==_count && cr_extra_move_scale()==1 && !cr_blocked(_g.px,_g.pz,2),"Dangerous Teleporter completes all hops at unobstructed tiles and releases movement");
    var _placed=false,_tiles=global.cr_map.tiles;
    for(var _i=0;_i<array_length(_tiles) && !_placed;_i++){
        var _t=_tiles[_i];if(_t.contains_object)continue;
        for(var _dir=0;_dir<4 && !_placed;_dir++)if((_t.walls & (1<<_dir))!=0){
            _g.px=_t.x*10+5;_g.pz=_t.z*10+5;_g.yaw=_dir*pi/2;
            if(cr_blocked(_g.px,_g.pz,2))continue;
            _g.inventory=["PortalPoster","",""];cr_use_item();_placed=_g.inventory[0]=="";
        }
    }
    cr_assert(_placed && array_length(_g.portals)==1,"Portal Poster opens a real eligible wall and consumes only on success");
    if(_placed){var _p=_g.portals[0];cr_assert(!cr_blocked(_p.cx,_p.cz,2),"Portal Poster source opening is traversable at its center");}
    _g.portals=[];cr_rebuild_geometry();_g.inventory=["","",""];
}
function cr_sf_demo() {
    var _g=global.bbcr,_m=_g.books[0].machine;
    var _valid=true,_verts=0;for(var _i=0;_i<7;_i++)for(var _j=0;_j<array_length(_g.books[_i].machine.batches);_j++){
        var _batch=_g.books[_i].machine.batches[_j];if(!is_array(_batch.vertices) || cr_sprite(_batch.texture)<0)_valid=false;else _verts+=array_length(_batch.vertices)/5;
    }
    cr_assert(_valid && _verts>100,"all seven Demo machines contain actual textured mesh triangles");
    var _b=_g.npcs[0],_anger=_g.anger;_g.books[0].book_ready=true;cr_demo_collect_book(0);
    cr_assert(abs(_g.anger-_anger)<=.00001,"Demo notebook collected before Baldi is spawned does not anger a dormant prefab");
    cr_demo_hold_number(10+((_g.books[1].answer+1) mod 10));cr_demo_submit_machine(1);
    cr_assert(_g.spoop && _b.current_sound==0 && abs(_g.anger-.1)<=.00001,"first wrong Demo activity spawns Baldi at base anger with source initial noise zero");
    cr_demo_hold_number(20+((_g.books[2].answer+1) mod 10));cr_demo_submit_machine(2);
    cr_assert(_b.current_sound==126 && _b.gx==_g.books[2].machine.x && _b.gz==_g.books[2].machine.z,"subsequent wrong Demo answer attracts existing Baldi with source noise 126");
    cr_demo_collect_book(1);
    cr_assert(abs(_g.anger-2.1)<=.00001,"spawned Demo Baldi gains one per wrong answer and one per notebook, without double counting");
    show_debug_message("BBCR_STYLE_FEEDBACK_BALDI: "+json_stringify({anger:_g.anger,speed:cr_curve(_b.params.speedCurve,_g.anger)+_b.params.baseSpeed,delay:cr_curve(_b.params.slapCurve,_g.anger)}));
    // Isolate the first completed machine's pop sequence from the second one.
    for(var _j=0;_j<10;_j++)_g.books[2].numbers[_j].active=false;
    var _pop=_g.books[1].numbers[0].spec.pop_sound,_before=cr_sf_audio_count(_pop);cr_demo_pop_step(.01);
    cr_assert(_g.books[1].pop_count==1 && cr_sf_audio_count(_pop)==_before+1,"Demo completion pops one visible number immediately with source audio");
    cr_demo_pop_step(.05);cr_assert(_g.books[1].pop_count==1,"number popper waits its source 0.1-0.3 second delay");
    repeat(300)cr_demo_pop_step(.01);cr_assert(_g.books[1].pop_count==9 && cr_sf_audio_count(_pop)==_before+9,"remaining nine numbers disappear sequentially with nine original pop sounds");
    _g.books[3].corrupted=false;cr_demo_hold_number(30+_g.books[3].answer);cr_demo_submit_machine(3);
    var _pause=_b.math_pause,_timer=_b.slap_timer,_distance=_b.slap_distance;cr_baldi_tick(_b,.1);
    cr_assert(_pause==_g.books[3].machine.baldi_pause && _b.slap_timer==_timer && _b.slap_distance==_distance,"correct Demo answer applies source Baldi pause without accumulating a movement burst");
    _g.exits_closed=1;cr_exit_closed();var _pending=array_length(_g.exit_fx.pending);cr_exit_step(.21);
    cr_assert(_g.exit_fx.active && array_length(_g.exit_fx.pending)==_pending-1 && _g.exit_fx.music_key=="exit_slow","Demo inherited first exit changes one additional light every 0.2 seconds and slows music");
    _g.exits_closed=2;cr_exit_closed();cr_assert(_g.exit_fx.chaos_key==global.cr_ui_data.chaos.ChaosAmbience1[0] && audio_is_playing(_g.exit_fx.chaos),"Demo inherited second exit starts original chaos music");
    cr_exit_stop_file();_g.exit_fx.active=false;_g.spoop=false;
}
function cr_style_feedback_step() {
    var _g=global.bbcr,_stage=cr_value(_g,"sf_stage",0);_g.sf_stage=_stage+1;
    switch(_stage){
        case 0:
            global.cr_cheat_hint_visible=false;cr_sf_items();
            var _b=_g.balloons[0];_b.spec=_g.party.data.school_balloons[0];_g.px=175;_g.pz=55;_g.yaw=0;_b.px=175;_b.pz=63;
            cr_assert(_b.py==0 && _b.spec.pivot.y==0 && _b.spec.height<10,"Party balloon root stays at floor and its source pivot keeps it below ceiling");
            _g.sf_balloon=_b;_g.balloons=[_b];_g.capture_scene="style_feedback_balloon";break;
        case 1:
            _g.balloons=[];_g.capture_scene="style_feedback_balloon_base";break;
        case 2:
            _g.exits_closed=3;cr_exit_closed();var _old=_g.exit_fx.chaos;cr_party_final_exit();cr_exit_step(.1);
            cr_assert(!audio_is_playing(_old) && array_length(_g.exit_fx.queue)==0 && _g.exit_fx.chaos<0 && audio_is_playing(_g.game_music),"Party final exit stops both chaos stream and queued clips while Dance plays");
            _g.px=135;_g.pz=345;_g.yaw=0;_g.capture_scene="style_feedback_elevator";break;
        case 3:
            var _trigger=_g.party.data.elevator_trigger;_g.px=_trigger.center[0];_g.pz=_trigger.center[2];cr_party_step(.01);repeat(300)cr_party_step(.01);
            var _c=_g.party.data.candle.box;_g.yaw=arctan2(_c.center[0]-_g.px,_c.center[2]-_g.pz);
            cr_assert(cr_interaction_target().kind=="party_candle","raised candle ray ignores school walls below its height");
            _g.capture_scene="style_feedback_raised";break;
        case 4:
            cr_interact();cr_assert(_g.party.phase=="ending" && _g.world_y==30 && _g.jump_height==0 && global.cr_map.source=="ClassicPartyEnding","actual candle click swaps render/collision environment at source elevation thirty");
            cr_assert(array_length(_g.books)==0 && array_length(_g.items)==0 && array_length(_g.npcs)==0,"upper ending drops stale school activities, pickups and NPCs");
            cr_assert(audio_is_playing(_g.exit_fx.chaos) && _g.exit_fx.chaos_key==_g.party.data.glitch_sounds[0],"Party upper ending plays source glitch ambience after candle blow");
            _g.capture_scene="style_feedback_ending";
            show_debug_message("BBCR_STYLE_FEEDBACK_ENDING: "+json_stringify({x:_g.px,z:_g.pz,yaw:_g.yaw,world_y:_g.world_y,tiles:array_length(global.cr_map.tiles),batches:array_length(global.cr_batches)}));break;
        case 5:
            _g.style="demo";bbcr_start_game("story");cr_sf_demo();
            var _b=_g.books[0],_m=_b.machine;_g.sf_text=_m.text;_m.text=[];_b.state="active";_b.book_ready=false;
            for(var _i=0;_i<array_length(_b.numbers);_i++)_b.numbers[_i].active=false;
            _g.px=_m.x-sin(_m.direction*pi/2)*9;_g.pz=_m.z-cos(_m.direction*pi/2)*9;_g.yaw=_m.direction*pi/2;
            _g.capture_scene="style_feedback_machine";
            show_debug_message("BBCR_STYLE_FEEDBACK_MACHINE: "+json_stringify({x:_g.px,z:_g.pz,yaw:_g.yaw,index:0}));break;
        case 6:
            _g.sf_mesh=_g.books[0].machine.batches;_g.books[0].machine.batches=[];_g.capture_scene="style_feedback_machine_base";break;
        case 7:
            _g.books[0].machine.batches=_g.sf_mesh;_g.books[0].machine.text=_g.sf_text;
            _g.unlock_notice=global.cr_text.Men_UnlockNotif+global.cr_text.But_LightsOut;cr_return_menu();room_goto(rm_menu);break;
        case 8:
            global.cr_ui.stage=16;global.cr_ui.pointer_inside=false;_g.capture_scene="style_feedback_unlock";
            cr_assert(global.cr_ui.unlock_time==7 && global.cr_ui.music<0,"unlock notification enters actual menu room before title music");break;
        case 9:
            cr_ui_active("Title",false);_g.capture_scene="style_feedback_unlock_only";break;
        case 10:
            cr_ui_active("Title",true);repeat(420)bbcr_menu_step(1/60);global.cr_ui.stage=8;_g.capture_scene="style_feedback_unlock_half";break;
        case 11:
            global.cr_ui.stage=16;_g.capture_scene="style_feedback_title";
            cr_assert(!cr_ui_node("LoadingScreen").active && audio_is_playing(global.cr_ui.music),"unlock removal reveals title and starts its audio");break;
        case 12:
            show_debug_message("BBCR_STYLE_FEEDBACK_INPUT: f1_down");_g.sf_deadline=current_time+3000;break;
        case 13:
            cr_cheat_step();if(!global.cr_cheat.open){_g.sf_stage=_stage;if(current_time>_g.sf_deadline){cr_assert(false,"native F1 menu input timeout");game_end();}break;}
            cr_assert(cr_cheat_in_menu() && !window_mouse_get_locked(),"native F1 opens restricted main-menu tools and releases cursor");
            _g.capture_scene="style_feedback_menu_tools";show_debug_message("BBCR_STYLE_FEEDBACK_INPUT: f1_up");break;
        case 14:
            var _score=_g.high_score,_progress=json_stringify(_g.progress);cr_cheat_action(cr_cheat_row("chase","action","chase"));
            cr_assert(_g.scene=="menu" && _g.high_score==_score && json_stringify(_g.progress)==_progress && !cr_cheat_give("Teleporter"),"menu action dispatch rejects gameplay cheats and item giving");
            cr_cheat_action(cr_cheat_row("reset","action","menu_reset"));cr_assert(global.cr_cheat.reset_confirm && json_stringify(_g.progress)==_progress,"first reset click requests in-app confirmation without deleting data");
            cr_cheat_action(cr_cheat_row("cancel","action","menu_cancel"));cr_assert(!global.cr_cheat.reset_confirm,"reset cancellation preserves user data");
            ini_open("bbcr_style_reset_test.ini");ini_write_real("scores","classic",999);ini_write_real("progress","party_won",1);ini_close();
            _g.high_score=999;_g.progress.party_won=true;_g.sensitivity=2;cr_user_data_reset("bbcr_style_reset_test.ini");
            cr_assert(!file_exists("bbcr_style_reset_test.ini") && _g.high_score==0 && !_g.progress.party_won && _g.sensitivity==.29,"reset deletes isolated test save and clears in-memory scores, unlocks and settings");
            cr_cheat_category(1);cr_cheat_action(cr_cheat_rows()[0]);
            cr_assert(!_g.progress.party_won && _g.high_score==0 && global.cr_ui.unlock_time==7,"main menu notification preview changes no unlock or score data");
            show_debug_message("BBCR_STYLE_FEEDBACK_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
}
