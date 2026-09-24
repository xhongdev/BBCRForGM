function cr_test_math_ready() {repeat(16)cr_transition_tick(global.cr_math_ui,.017);cr_math_start_ready();}
function cr_ending_behavior_tests() {
    var _g=global.bbcr;global.cr_cheat_hint_visible=false;
    var _world=cr_sound("BsodaSpray");audio_sound_loop(_world,true);
    cr_collect_book(0);
    cr_assert(_g.math_waiting && _g.problem_text=="" && array_length(_g.voice_queue)==0,"YCTP opens with blank question and no early speech");
    cr_assert(audio_is_paused(_world) && audio_is_playing(_g.math_music) && !audio_is_paused(_g.math_music),"first notebook pauses outside sounds but not YCTP music");
    _g.input="0";bbcr_submit_math();cr_assert(_g.q==0,"transition blocks answer submission");
    repeat(15){cr_transition_tick(global.cr_math_ui,.017);cr_math_step(.017);}
    cr_assert(_g.problem_text=="" && _g.voice<0,"all entering dither stages precede question and voice");
    cr_transition_tick(global.cr_math_ui,.017);cr_math_step(.017);
    cr_assert(!_g.math_waiting && string_pos(global.cr_text.YCTP_Solve1,_g.problem_text)==1 && _g.voice_key==global.cr_ui_data.yctp.audIntro[0],"last dither stage releases source intro and first problem");
    repeat(3){_g.input=string(_g.answer);bbcr_submit_math();}
    cr_assert(!_g.secret && _g.correct==3,"any correct answer disables all-wrong ending");
    cr_voice_clear();cr_math_close();
    cr_assert(audio_is_playing(_world) && !audio_is_paused(_world),"YCTP close resumes original outside sound instance");
    cr_assert(global.cr_math_ui.stage==0 && _g.voice_key=="BAL_GetPrize1" && audio_is_playing(_g.voice),"source quarter voice starts at exit transition, without invented delay");
    var _prize=_g.voice;cr_collect_book(1);cr_assert(audio_is_paused(_world),"second notebook also pauses external sounds");
    cr_assert(_g.world_voice.voice==_prize && audio_is_paused(_prize),"second notebook retains paused Happy Baldi voice in its own audio queue");
    cr_cheat_set_open(true);cr_cheat_set_open(false);cr_assert(audio_is_paused(_world) && !audio_is_paused(_g.math_music),"closing test menu cannot unpause outside YCTP audio");
    cr_test_math_ready();_g.input="999";bbcr_submit_math();
    cr_assert(_g.spoop && audio_is_paused(_world),"first wrong answer preserves listener pause instead of discarding outside audio");
    cr_math_close();_g.hard=true;cr_collect_book(2);
    cr_assert(!_g.math_audio_paused && !audio_is_paused(_world),"hard mode leaves outside audio running");
    _g.hard=false;bbcr_start_game("story");global.cr_cheat.freeze_npcs=true;
    _g.notebooks=6;cr_collect_book(6);cr_math_close();
    cr_assert(_g.exits[0].prepared && _g.exits[0].state==0,"AllNotebooks prepares invisible source gates before triggers");
    var _contacts=0;
    for(var _i=0;_i<array_length(_g.exits);_i++)for(var _side=-1;_side<=1;_side++){
        for(var _j=0;_j<array_length(_g.exits);_j++){_g.exits[_j].used=false;_g.exits[_j].state=0;_g.exits[_j].prepared=true;}
        _g.exits_closed=0;var _e=_g.exits[_i],_nx=round(sin(_e.dir*pi/2)),_nz=round(cos(_e.dir*pi/2));
        _g.px=_e.x+_nx*12+_nz*_side*10;_g.pz=_e.z+_nz*12-_nx*_side*10;
        var _offset=10;
        while(cr_blocked(_g.px,_g.pz,2) && _offset>0){_offset--;_g.px=_e.x+_nx*12+_nz*_side*_offset;_g.pz=_e.z+_nz*12-_nx*_side*_offset;}
        var _initial=[_g.px,_g.pz,cr_blocked(_g.px,_g.pz,2)];
        var _reached=false;
        repeat(60){cr_move(_g,-_nx*.4,-_nz*.4,2);cr_exits_trigger();if(_e.used){_reached=true;break;}}
        cr_assert(_reached && !cr_blocked(_g.px,_g.pz,2),"continuous approach closes exit without embedding player "+string(_i)+":"+string(_side));
        if(!_reached || cr_blocked(_g.px,_g.pz,2))show_debug_message("BBCR_ENDING_EXIT: "+json_stringify({exit:_i,side:_side,start:_initial,finish:[_g.px,_g.pz],reached:_reached}));
        var _x=_g.px,_z=_g.pz;cr_move(_g,_nx*3,_nz*3,2);
        cr_assert(point_distance(_x,_z,_g.px,_g.pz)>2.9,"player can walk away from sealed exit "+string(_i)+":"+string(_side));_contacts++;
    }
    var _e=_g.exits[0];_g.px=(_e.barrier[0]+_e.barrier[2])/2;_g.pz=(_e.barrier[1]+_e.barrier[3])/2;cr_exit_unembed(_e);
    cr_assert(!cr_blocked(_g.px,_g.pz,2),"gate overlap resolves source player capsule toward school");
    bbcr_start_game("story");_g.spoop=true;global.cr_cheat.god=true;
    var _p=cr_encounter_npc("Principal"),_b=cr_encounter_npc("Bully"),_tested=0,_failures=[];
    for(var _i=0;_i<array_length(global.cr_map.bully_candidates) && _tested<12;_i++){
        var _t=global.cr_map.tiles[global.cr_map.bully_candidates[_i]],_bx=_t.x*10+5,_bz=_t.z*10+5,_start=[];
        for(var _d=0;_d<4;_d++){
            var _x=_bx+round(sin(_d*pi/2))*40,_z=_bz+round(cos(_d*pi/2))*40;
            if(!cr_blocked(_x,_z,.5) && cr_clear_line(_x,_z,_bx,_bz,_p.params.sight_mask)){_start=[_x,_z];break;}
        }if(array_length(_start)==0 || cr_bully_trap(global.cr_map.bully_candidates[_i]))continue;
        _b.hidden=false;_b.spawn_pending=false;_b.cooldown=0;_b.px=_bx;_b.pz=_bz;_b.intended=[_bx,_bz];_b.stay=120;_b.bully_guilt=10;_b.spoken=false;
        _g.px=_bx;_g.pz=_bz;_g.guilt_time=0;_g.inventory=["","",""];
        _p.px=_start[0];_p.pz=_start[1];_p.angry=false;_p.target_npc=-1;_p.cooldown=0;_p.timer=0;_p.speed=0;_p.route_timer=0;path_clear_points(_p.path);
        repeat(900){cr_bully_step(_b,1/60);cr_npc_step(_p,1/60);if(_b.hidden)break;}
        if(!_b.hidden)array_push(_failures,{bully:[_bx,_bz],principal:[_p.px,_p.pz],goal:[_p.gx,_p.gz],target:_p.target_npc});
        _tested++;
    }
    show_debug_message("BBCR_ENDING_CHASE: "+json_stringify({tested:_tested,failures:_failures}));
    cr_assert(_tested>=8 && array_length(_failures)==0,"Principal pursues from forty units and evicts Bully at actual contact");
    _b.hidden=false;_b.px=_bx;_b.pz=_bz;_b.intended=[_bx,_bz];_b.stay=120;_b.bully_guilt=10;
    _p.px=_start[0];_p.pz=_start[1];_p.cooldown=0;_p.target_npc=-1;_p.route_timer=0;path_clear_points(_p.path);
    _g.px=_bx+1000;_g.pz=_bz;cr_principal_bully(_p);
    cr_assert(_p.target_npc>=0,"Principal acquires guilty NPC before sight/violation expires");
    _b.bully_guilt=0;
    repeat(900){cr_npc_step(_p,1/60);cr_bully_step(_b,1/60);if(_b.hidden)break;}
    cr_assert(_b.hidden,"retained NPC target is evicted on contact even after its guilt expires");
    bbcr_start_game("story");
    for(var _i=0;_i<7;_i++){cr_collect_book(_i);cr_test_math_ready();repeat(3){_g.input="999";bbcr_submit_math();}cr_math_close();}
    cr_assert(_g.secret && _g.notebooks==7 && _g.wrong==3,"all twenty-one wrong answers retain Classic secret eligibility");
    _g.exits_closed=3;for(var _i=0;_i<3;_i++)_g.exits[_i].used=true;
    var _last=_g.exits[3];_last.prepared=false;_g.px=_last.inside[0].center[0];_g.pz=_last.inside[0].center[2];
    cr_exits_trigger();cr_assert(_g.won && _g.ending.kind=="secret" && _g.ending.next=="ClassicTrue" && _g.ending.voice<0,"actual fourth exit selects source ClassicTrue without ordinary win speech");
    cr_ending_step(.017);
    cr_assert(global.cr_map.manager=="ClassicSecretManager" && array_length(global.cr_map.tiles)==28 && array_length(_g.npcs)==0,"secret transition loads original 28-tile office with no school NPCs");
    cr_assert(_g.px==25 && _g.pz==20 && _g.yaw==pi && global.cr_load_transition.stage==0,"secret starts at source position and orientation beneath dither");
    cr_assert(array_length(_g.secret_tutors)==1 && _g.secret_tutors[0].speech=="null_classic" && _g.secret_tutors[0].quit,"source NULL tutor has correct original speech and quit-on-completion");
    cr_secret_step();cr_assert(_g.stamina==200 && !_g.secret_tutors[0].started,"secret manager grants full overfilled stamina and waits for tutor trigger");
}
function cr_ending_test_step() {
    var _g=global.bbcr;
    switch(_g.ending_test_stage){
        case 0:cr_ending_behavior_tests();_g.capture_scene="ending_secret_start";break;
        case 1:repeat(16)cr_loading_exit_tick(.017);_g.capture_scene="ending_secret_entry";break;
        case 2:_g.px=30;_g.pz=112;_g.yaw=0;_g.doors[0].open=100;_g.capture_scene="ending_secret_office";break;
        case 3:
            _g.px=30;_g.pz=125;cr_secret_step();cr_assert(_g.secret_tutors[0].started && audio_is_playing(_g.secret_tutors[0].handle),"walking into source tutor sphere starts original secret speech");
            bbcr_start_game("story");global.cr_cheat_hint_visible=false;_g.px=175;_g.pz=55;_g.yaw=0;_g.secret=false;_g.capture_scene="ending_win_base";break;
        case 4:cr_win_begin();cr_assert(_g.ending.sound=="null_great" && audio_is_playing(_g.ending.voice),"ordinary win uses serialized null_great sound");_g.capture_scene="ending_win_start";break;
        case 5:repeat(8)cr_ending_step(.017);_g.capture_scene="ending_win_half";break;
        case 6:repeat(8)cr_ending_step(.017);_g.capture_scene="ending_win_full";break;
        case 7:
            cr_ending_step(7);cr_assert(_g.ending.phase==0,"win cannot disappear before eight unscaled seconds");
            audio_stop_sound(_g.ending.voice);cr_ending_step(1);cr_assert(_g.ending.phase==1,"win waits for both minimum duration and audio completion");_g.capture_scene="ending_win_black";break;
        case 8:
            cr_ending_step(4.9);cr_assert(_g.scene=="game","win black screen holds for five more seconds");cr_ending_step(.11);cr_assert(_g.scene=="menu","normal win returns to menu automatically");
            bbcr_start_game("story");_g.px=175;_g.pz=55;_g.yaw=0;_g.spoop=true;var _b=_g.npcs[0];_b.px=175;_b.pz=57;_b.slap_frame=0;
            cr_npc_step(_b,.001);cr_assert(_g.dead && _g.ending.kind=="caught","actual Baldi contact starts capture sequence");
            cr_assert(abs(_g.ending.x-175)<=.0001 && abs(_g.ending.z-55)<=.0001 && _g.ending.far==500,"capture camera uses source two-unit offset and initial far plane");_g.capture_scene="ending_caught_start";break;
        case 9:cr_ending_step(.5);cr_assert(_g.ending.far==250,"capture far plane shrinks with unscaled time");_g.capture_scene="ending_caught_half";break;
        case 10:cr_ending_step(.499);_g.capture_scene="ending_caught_last";break;
        case 11:cr_ending_step(.002);cr_assert(_g.ending.phase==1 && !audio_is_playing(_g.ending.voice),"capture stops rendering and sound after one second");_g.capture_scene="ending_caught_black";break;
        case 12:
            cr_ending_step(1.9);cr_assert(_g.scene=="game","capture retains two-second black hold");cr_ending_step(.11);cr_assert(_g.scene=="menu","capture returns to main menu without keyboard input");
            bbcr_start_game("story");_g.px=135;_g.pz=340;_g.yaw=pi/2;_g.happy_time=0;_g.capture_scene="ending_cafe_base";break;
        case 13:_g.exits_closed=1;cr_exit_closed();repeat(200)cr_exit_step(.2);_g.capture_scene="ending_cafe_red";break;
        case 14:
            bbcr_start_game("story");_g.px=175;_g.pz=55;_g.yaw=0;cr_rope_begin(cr_encounter_npc("Playtime"));_g.rope_anim=.15;_g.capture_scene="ending_rope_a";break;
        case 15:_g.rope_anim=.55;_g.capture_scene="ending_rope_b";break;
        case 16:
            cr_rope_end(true);cr_collect_book(0);_g.capture_scene="ending_math_start";break;
        case 17:repeat(8)cr_transition_tick(global.cr_math_ui,.017);cr_math_step(.001);_g.capture_scene="ending_math_half";break;
        case 18:repeat(8)cr_transition_tick(global.cr_math_ui,.017);cr_math_step(.001);_g.capture_scene="ending_math_full";break;
        case 19:show_debug_message("BBCR_ENDING_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();return;
    }_g.ending_test_stage++;
}
