/// Real Runner behavior checks plus native F1/F2/W/E/Q input from the test driver.
function cr_cheat_behavior_tests() {
    var _g=global.bbcr,_c=global.cr_cheat;
    cr_assert(!_c.open && !_c.god && !_c.noclip && !_c.used && _c.speed==1 && _c.time_scale==1,"cheats start disabled at source movement speed");
    var _n=_g.npcs[0];_n.px=_g.px;_n.pz=_g.pz;_c.god=true;
    cr_npc_step(_n,1/60);cr_assert(!_g.dead,"invincibility prevents actual overlapping Baldi capture");
    _c.god=false;_c.used=true;var _score=_g.high_score;_g.notebooks=_score+100;
    cr_npc_step(_n,1/60);cr_assert(_g.dead,"disabling invincibility restores actual Baldi capture");
    cr_assert(_g.high_score==_score,"modified run cannot replace high score");
    _g.dead=false;_g.notebooks=0;_n.px=_n.hx;_n.pz=_n.hz;
    var _d=_g.doors[0],_yaw=degtorad(_d.dir*90),_dx=sin(_yaw),_dz=cos(_yaw);
    _g.px=_d.cx-_dx*4;_g.pz=_d.cz-_dz*4;cr_move(_g,_dx*8,_dz*8,2);
    cr_assert(point_distance(_g.px,_g.pz,_d.cx+_dx*4,_d.cz+_dz*4)>3,"closed door blocks ordinary player movement");
    cr_cheat_noclip(true);_g.px=_d.cx-_dx*4;_g.pz=_d.cz-_dz*4;cr_move(_g,_dx*8,_dz*8,2);
    cr_assert(point_distance(_g.px,_g.pz,_d.cx+_dx*4,_d.cz+_dz*4)<.001,"noclip moves player through closed source door");
    _g.px=_d.cx;_g.pz=_d.cz;cr_cheat_noclip(false);
    cr_assert(!_c.noclip && !cr_blocked(_g.px,_g.pz,2),"turning noclip off inside door finds a collision-free landing");
    cr_cheat_noclip(true);_g.px=-500;_g.pz=-500;cr_cheat_noclip(false);
    cr_assert(!_c.noclip && !cr_blocked(_g.px,_g.pz,2),"noclip outside map safely returns to entrance on disable");
    var _before=[_g.px,_g.pz];cr_assert(!cr_cheat_teleport(-500,-500) && _g.px==_before[0] && _g.pz==_before[1],"invalid teleport leaves player at previous position");
    for(var _i=0;_i<array_length(_g.books);_i++){
        var _b=_g.books[_i],_ok=cr_cheat_teleport(_b.x,_b.z);
        cr_assert(_ok && !cr_blocked(_g.px,_g.pz,2) && point_distance(_g.px,_g.pz,_b.x,_b.z)<=20,"notebook teleport clears source furniture "+string(_i+1));
    }
    cr_cheat_action(cr_cheat_row("mark","action","mark"));var _marked=[_g.px,_g.pz,_g.yaw];
    cr_cheat_teleport(global.cr_map.spawn[0],global.cr_map.spawn[2]);cr_cheat_action(cr_cheat_row("return","teleport","mark"));
    cr_assert(_g.px==_marked[0] && _g.pz==_marked[1] && _g.yaw==_marked[2],"marked teleport restores position and heading");
    _c.slot=2;cr_cheat_give("Zesty");cr_assert(_g.inventory[2]=="Zesty" && _g.slot==2,"give replaces only chosen inventory slot");
    _c.keep_items=true;cr_use_item();cr_assert(_g.stamina==200 && _g.inventory[2]=="Zesty","kept Zesty still applies real item effect");
    _c.keep_items=false;cr_use_item();cr_assert(_g.inventory[2]=="","item consumption resumes when modifier disabled");
    cr_assert(!cr_cheat_give("missing-item") && _g.inventory[2]=="","unknown item cannot corrupt inventory");
    _c.category=1;var _rows=cr_cheat_rows(),_items=0;
    for(var _i=0;_i<array_length(_rows);_i++)if(_rows[_i].kind=="item"){
        _items++;cr_assert(cr_cheat_give(_rows[_i].value) && cr_sprite(global.cr_catalog.items[$ _rows[_i].value].small)>=0,"giveable item exists and its preview loads: "+_rows[_i].value);
    }cr_assert(_items>=10,"items category contains all ten implemented item types");
    _c.freeze_npcs=true;var _state=json_stringify(_n);cr_npc_step(_n,1);
    cr_assert(json_stringify(_n)==_state,"freeze NPCs preserves positions, states and timers");_c.freeze_npcs=false;
    _g.inventory=["Zesty","Quarter",""];_g.slot=0;_c.god=false;_c.speed=1;_c.time_scale=1;
    _c.category=0;cr_cheat_set_open(true);var _time=_g.time,_x=_g.px,_z=_g.pz;
    repeat(3)bbcr_game_step();cr_assert(_g.time==_time && _g.px==_x && _g.pz==_z,"open test menu pauses simulation without changing gameplay pause state");
    cr_cheat_click(580,131);cr_assert(_c.god,"mouse row action toggles invincibility");
    cr_cheat_click(540,267);cr_assert(_c.speed==5,"speed slider sets its maximum");
    cr_cheat_click(420,267);cr_assert(_c.speed==.25,"speed slider sets its minimum");_c.drag=-1;
    cr_cheat_click(60,175);cr_assert(_c.category==1 && _c.scroll==0,"mouse sidebar selects item category");
    cr_cheat_click(595,132);cr_assert(_c.slot==0,"slot selector wraps from slot three to one");
    cr_cheat_click(589,409);cr_assert(_c.scroll>0 && _c.selected==_c.scroll,"pagination keeps keyboard selection visible");
    cr_cheat_set_open(false);_g.stamina=1;_c.stamina=true;bbcr_game_step();
    cr_assert(_g.stamina>=100,"unlimited stamina restores exhausted player in real gameplay step");
    _g.rope=true;_g.detention=30;_g.guilt_time=1;_g.npcs[1].angry=true;
    cr_cheat_action(cr_cheat_row("release","action","release"));
    cr_assert(!_g.rope && _g.detention==0 && _g.guilt_time==0 && !_g.npcs[1].angry,"release clears rope, detention and Principal pursuit");
    for(var _i=0;_i<array_length(_g.doors);_i++){_g.doors[_i].locked=true;_g.doors[_i].lock=5;}
    cr_cheat_action(cr_cheat_row("unlock","action","unlock"));var _locked=0;
    for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].locked || _g.doors[_i].lock>0)_locked++;
    cr_assert(_locked==0,"world action removes both kinds of door lock");
    for(var _i=0;_i<array_length(global.cr_map.facilities);_i++){var _f=global.cr_map.facilities[_i];if(variable_struct_exists(_f,"uses"))_f.uses=0;}
    cr_cheat_action(cr_cheat_row("stock","action","restock"));var _empty=0;
    for(var _i=0;_i<array_length(global.cr_map.facilities);_i++){var _f=global.cr_map.facilities[_i];if(variable_struct_exists(_f,"uses") && _f.uses!=1)_empty++;}
    cr_assert(_empty==0,"restock restores vending inventory and render state");
    cr_cheat_number_set(cr_cheat_row("anger","number","anger",[.1,100,1]),10.1);
    cr_assert(abs(_g.anger-10.1)<=.00001 && _g.extra_anger==0 && abs(_n.slap_timer-cr_curve(_n.params.slapCurve,_g.anger))<=.00001,"anger control refreshes Baldi cadence without a stale movement burst");
    var _font=global.cr_ui_data.fonts.COMIC_24_Pro;
    cr_assert(cr_sprite(_font.file)>=0 && variable_struct_exists(_font.chars,"F") && variable_struct_exists(_font.chars,"1"),"small rounded menu text uses bundled source Comic atlas");
    bbcr_start_game("story");cr_assert(!global.cr_cheat.used && !global.cr_cheat.god && !global.cr_cheat.stamina && global.cr_cheat.speed==1,"new run resets every test modifier");
}
function cr_cheat_test_input(_action) {
    show_debug_message("BBCR_CHEAT_INPUT: "+_action);global.bbcr.cheat_deadline=current_time+4000;
}
function cr_cheat_test_step() {
    var _g=global.bbcr,_c=global.cr_cheat,_stage=_g.cheat_test_stage;
    if(_stage>0 && _stage<11)bbcr_game_step();
    if(_stage>=24 && _stage<=32)cr_cheat_step();
    switch(_stage){
        case 0:
            cr_cheat_behavior_tests();_g.cheat_test_stage=1;cr_cheat_test_input("f1_down");break;
        case 1:
            if(!_c.open)break;cr_assert(!window_mouse_get_locked(),"native F1 opens menu and releases mouse");
            cr_cheat_test_input("f1_up");_g.cheat_test_stage=2;_g.cheat_deadline=current_time+120;break;
        case 2:
            if(current_time<_g.cheat_deadline)break;
            _g.inventory=["Zesty","",""];_g.slot=0;_g.cheat_saved=[_g.px,_g.pz,_g.yaw,_g.time];
            cr_cheat_test_input("game_keys_down");_g.cheat_test_stage=3;break;
        case 3:
            if(!keyboard_check(ord("W")) || !keyboard_check(ord("Q")))break;
            cr_assert(_g.px==_g.cheat_saved[0] && _g.pz==_g.cheat_saved[1] && _g.yaw==_g.cheat_saved[2] && _g.time==_g.cheat_saved[3] && _g.inventory[0]=="Zesty" && _g.scene=="game","native W/E/Q cannot move, interact or consume item behind menu");
            cr_cheat_test_input("game_keys_up");_g.cheat_test_stage=4;_g.cheat_deadline=current_time+120;break;
        case 4:
            if(current_time<_g.cheat_deadline)break;
            cr_cheat_test_input("f1_down");_g.cheat_test_stage=5;break;
        case 5:
            if(_c.open)break;cr_assert(!_g.paused && _g.mouse_skip && _g.move_latch,"native F1 close preserves pause state and latches movement");
            cr_cheat_test_input("f1_up");_g.cheat_test_stage=6;_g.cheat_deadline=current_time+120;break;
        case 6:
            if(current_time<_g.cheat_deadline)break;
            _c.noclip=true;_c.used=true;_g.px=175;_g.pz=25;_g.yaw=0;_g.move_latch=false;
            cr_cheat_test_input("w_down");_g.cheat_test_stage=7;break;
        case 7:
            if(!keyboard_check(ord("W")))break;
            _g.cheat_saved=[_g.pz,_g.time];_g.cheat_test_stage=8;_g.cheat_deadline=current_time+3000;break;
        case 8:
            if(_g.time-_g.cheat_saved[1]<.3)break;
            var _distance=_g.pz-_g.cheat_saved[0],_expected=global.cr_catalog.movement.walkSpeed*(_g.time-_g.cheat_saved[1]);
            cr_assert(abs(_distance-_expected)<.01,"native W at 1x covers source walkSpeed times simulation time");
            _c.speed=2;_g.cheat_saved=[_g.pz,_g.time];_g.cheat_test_stage=9;break;
        case 9:
            if(_g.time-_g.cheat_saved[1]<.3)break;
            var _distance=_g.pz-_g.cheat_saved[0],_expected=global.cr_catalog.movement.walkSpeed*2*(_g.time-_g.cheat_saved[1]);
            cr_assert(abs(_distance-_expected)<.01,"native W at 2x doubles actual displacement");
            cr_cheat_test_input("w_up");_g.cheat_test_stage=10;_g.cheat_deadline=current_time+120;break;
        case 10:
            if(current_time<_g.cheat_deadline)break;
            cr_cheat_set_open(true);cr_cheat_category(0);_g.cheat_capture="player";_g.cheat_test_stage=11;break;
        case 11:
            cr_cheat_category(1);_g.cheat_capture="items";_g.cheat_test_stage++;break;
        case 12:
            cr_cheat_category(2);_g.cheat_capture="teleport";_g.cheat_test_stage++;break;
        case 13:
            cr_cheat_category(3);_g.cheat_capture="world";_g.cheat_test_stage++;break;
        case 14:window_set_size(1280,720);_g.cheat_test_stage++;break;
        case 15:
            var _v=cr_game_viewport(),_p=cr_cheat_pointer(_v[0]+60*_v[2],_v[1]+131*_v[2]);cr_cheat_click(_p[0],_p[1]);
            cr_assert(_c.category==0,"wide-window pointer selects same logical sidebar");_g.cheat_capture="wide";_g.cheat_test_stage++;break;
        case 16:window_set_size(600,800);_g.cheat_test_stage++;break;
        case 17:
            var _v=cr_game_viewport(),_p=cr_cheat_pointer(_v[0]+60*_v[2],_v[1]+219*_v[2]);cr_cheat_click(_p[0],_p[1]);
            cr_assert(_c.category==2,"portrait pointer maps to teleport category");_g.cheat_capture="portrait";_g.cheat_test_stage++;break;
        case 18:window_set_size(777,555);_g.cheat_test_stage++;break;
        case 19:_g.cheat_capture="fractional";_g.cheat_test_stage++;break;
        case 20:
            window_set_size(960,720);cr_cheat_set_open(false);repeat(20){cr_transition_tick(global.cr_math_ui,.017);cr_pause_tick(.017);cr_loading_exit_tick(.017);}
            cr_pause(true);repeat(20)cr_pause_tick(.017);cr_cheat_set_open(true);cr_cheat_set_open(false);
            cr_assert(_g.paused && !window_mouse_get_locked(),"closing cheats over Pause keeps original pause and unlocked pointer");
            cr_pause(false);repeat(20)cr_pause_tick(.017);cr_collect_book(0);repeat(20)cr_transition_tick(global.cr_math_ui,.017);
            cr_cheat_set_open(true);var _q=_g.q,_delay=_g.math_delay;repeat(2)bbcr_game_step();
            cr_cheat_action(cr_cheat_row("entrance","teleport","spawn"));
            cr_assert(_g.scene=="math" && _g.q==_q && _g.math_delay==_delay,"cheat overlay pauses YCTP and rejects cross-scene teleport");
            cr_cheat_set_open(false);cr_assert(_g.scene=="math" && !window_mouse_get_locked(),"closing cheats resumes YCTP with free cursor");
            _g.scene="game";cr_cheat_set_open(true);_c.god=true;_g.cheat_test_stage=21;cr_return_menu();room_goto(rm_menu);break;
        case 21:
            cr_assert(_g.loaded && array_length(_g.npcs)==7 && !_c.open && !_c.god && !_c.noclip && !_c.freeze_npcs && _c.speed==1 && is_undefined(_c.mark),"actual menu roundtrip rebuilds world with clean cheat defaults");
            window_set_size(960,720);_g.cheat_test_stage++;break;
        case 22:
            _g.cheat_capture="closed";_g.cheat_test_stage++;break;
        case 23:
            cr_cheat_test_input("f2_down");_g.cheat_test_stage=24;break;
        case 24:
            if(global.cr_cheat_hint_visible)break;
            cr_assert(!_c.open && !_c.used,"native F2 hides cue without opening menu or marking run modified");
            _g.cheat_capture="hint_hidden_closed";cr_cheat_test_input("f2_up");_g.cheat_test_stage=25;_g.cheat_deadline=current_time+120;break;
        case 25:
            if(current_time<_g.cheat_deadline)break;
            cr_cheat_test_input("f1_down");_g.cheat_test_stage=26;break;
        case 26:
            if(!_c.open)break;
            cr_assert(!global.cr_cheat_hint_visible && !window_mouse_get_locked(),"native F1 still opens menu with hidden cue");
            _g.cheat_capture="hint_hidden_open";cr_cheat_test_input("f1_up");_g.cheat_test_stage=27;_g.cheat_deadline=current_time+120;break;
        case 27:
            if(current_time<_g.cheat_deadline)break;
            cr_cheat_test_input("f2_down");_g.cheat_test_stage=28;break;
        case 28:
            if(!global.cr_cheat_hint_visible)break;
            cr_assert(_c.open && !_c.used,"native F2 restores cue without closing menu or changing modifiers");
            _g.cheat_capture="hint_restored_open";_g.cheat_test_stage=29;_g.cheat_deadline=current_time+200;break;
        case 29:
            if(current_time<_g.cheat_deadline)break;
            cr_assert(global.cr_cheat_hint_visible,"holding F2 does not toggle cue every frame");
            cr_cheat_test_input("f2_up");_g.cheat_test_stage=30;_g.cheat_deadline=current_time+120;break;
        case 30:
            if(current_time<_g.cheat_deadline)break;
            cr_cheat_test_input("f2_down");_g.cheat_test_stage=31;break;
        case 31:
            if(global.cr_cheat_hint_visible)break;
            cr_assert(_c.open,"native F2 hides cue again while keeping menu open");
            cr_cheat_test_input("f2_up");_g.cheat_test_stage=32;_g.cheat_deadline=current_time+120;break;
        case 32:
            if(current_time<_g.cheat_deadline)break;
            bbcr_start_game("story");cr_assert(!global.cr_cheat_hint_visible,"new run preserves hidden cue preference");
            _g.cheat_test_stage=33;cr_return_menu();room_goto(rm_menu);break;
        case 33:
            cr_assert(!global.cr_cheat_hint_visible && !_c.open && !_c.used,"menu roundtrip preserves hidden cue but resets test modifiers");
            _g.cheat_test_stage++;break;
        case 34:
            show_debug_message("BBCR_CHEAT_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
    if(array_contains([1,3,5,7,8,9,24,26,28,31],_stage) && _g.cheat_test_stage==_stage && current_time>_g.cheat_deadline){
        cr_assert(false,"native cheat input timed out at stage "+string(_stage));show_debug_message("BBCR_CHEAT_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();
    }
}
