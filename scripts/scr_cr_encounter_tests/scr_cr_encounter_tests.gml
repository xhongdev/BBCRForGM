function cr_encounter_npc(_name) {
    for(var _i=0;_i<array_length(global.bbcr.npcs);_i++)if(global.bbcr.npcs[_i].name==_name)return global.bbcr.npcs[_i];
    return undefined;
}
function cr_encounter_behavior_tests() {
    var _g=global.bbcr,_pt=cr_encounter_npc("Playtime"),_p=cr_encounter_npc("Principal"),_b=cr_encounter_npc("Bully"),_src=global.cr_ui_data.jumprope;
    cr_assert(_src.ropeDelay==.7 && _src.ropeTime==.6 && _src.initVelocity==16 && _src.accel==-42 && _src.jumpBuffer==1.2,"rope serialized timing and physics imported");
    cr_assert(array_length(global.cr_ui_data.animations.Jumprope.frames)==15,"rope uses all fifteen source animation frames");
    var _old=global.cr_ui;global.cr_ui=global.cr_rope_ui;
    var _instructions=cr_ui_node(_src.instructionsTmp),_count=cr_ui_node(_src.countTmp);
    cr_assert(_instructions.graphics[0].font=="COMIC_24_Pro" && _instructions.graphics[0].size==24 && _instructions.rect[0]==10 && _instructions.rect[1]==148,"rope instructions retain source TMP font and RectTransform");
    cr_assert(_count.rect[1]==228 && _count.graphics[0].size==24,"rope counter retains source font and position");global.cr_ui=_old;
    cr_rope_begin(_pt);cr_assert(cr_rope_move_scale()==0 && _g.jump_height==0,"grounded rope blocks walking");
    cr_rope_step(.1,true);cr_assert(abs(_g.jump_height-1.39)<.0001 && abs(_g.jump_velocity-11.8)<.0001 && cr_rope_move_scale()==.25,"jump uses source half-acceleration integration and quarter movement");
    cr_rope_step(.6,false);cr_assert(_g.rope_phase==1 && _g.rope_anim==0,"rope animation starts only after source delay");
    _g.jumps=4;_g.rope_phase=1;_g.rope_timer=.01;_g.jump_height=2;_g.jump_velocity=0;
    cr_rope_step(.02,false);cr_assert(_g.jumps==5 && _g.rope && _g.jump_height>0,"fifth count waits for landing before ending");
    repeat(60)cr_rope_step(1/60,false);
    cr_assert(!_g.rope && _g.jump_height==0 && _g.jump_velocity==0 && cr_rope_move_scale()==1 && _pt.cooldown==15,"completion restores camera, movement and source Playtime cooldown");
    cr_rope_begin(_pt);_g.jump_height=2;_g.jump_velocity=8;_g.inventory[0]="Scissors";
    var _keys=variable_struct_get_names(global.cr_catalog.items);for(var _i=0;_i<array_length(_keys);_i++)if(global.cr_catalog.items[$ _keys[_i]].type==9){_g.inventory[0]=_keys[_i];break;}
    _g.slot=0;cr_use_item();cr_assert(!_g.rope && _g.jump_height==0 && _g.jump_velocity==0 && _pt.sad,"scissors cleanly cancel airborne rope and play sad state");
    cr_rope_begin(_pt);_g.px+=11;cr_rope_step(.01,false);cr_assert(!_g.rope && _g.jump_height==0,"external displacement beyond ten units cancels rope");
    _g.hard=true;cr_rope_begin(_pt);cr_rope_step(.1,true);
    cr_assert(_g.rope_max==10 && abs(_g.jump_height-1.264)<.0001,"hard mode uses ten jumps and 1.6 acceleration modifier");cr_rope_end(false);_g.hard=false;
    _g.guilt_time=0;cr_rule_break("Drinking",.8);cr_rule_break("Running",.1);
    cr_assert(_g.guilt=="Drinking" && _g.guilt_time==.8,"short running violation cannot overwrite longer drinking guilt");
    _p.angry=false;_p.sight=0;cr_principal_notice(_p,true,.4);_g.guilt_time=0;cr_principal_notice(_p,true,.5);
    cr_assert(abs(_p.sight-.4)<=.00001 && !_p.angry,"Principal retains observed violation time during a visible pause in rule-breaking");
    cr_rule_break("Running",.1);cr_principal_notice(_p,true,.34);cr_assert(!_p.angry,"Principal does not scold before source 0.75 seconds");
    _p.route_timer=.8;cr_principal_notice(_p,true,.02);cr_assert(_p.angry && _p.route_timer==0 && audio_is_playing(_p.voice),"Principal scolds at threshold with immediate chase replan and voice");
    cr_principal_notice(_p,false,.01);cr_assert(_p.sight==0,"actual sight loss resets Principal observation timer");
    cr_assert(_p.params.sight_mask==2326529 && _p.params.max_speed==22,"Principal keeps own source ray mask and movement speed");
    cr_assert(_b.hidden && _b.spawn_pending,"Bully starts hidden and awaits source NPC-spawn eligibility");
    _g.px=_b.hx;_g.pz=_b.hz;cr_bully_step(_b,200);cr_assert(_b.spawn_pending && _b.hidden,"Bully delay does not start while player occupies NPC spawn buffer");
    _g.px=175;_g.pz=25;cr_bully_step(_b,.01);
    cr_assert(!_b.spawn_pending && _b.hidden && _b.cooldown>=60 && _b.cooldown<=120,"eligible Bully starts hidden source 60-120 second timer");
    var _delay=_b.cooldown;cr_bully_step(_b,_delay-.01);cr_assert(_b.hidden,"Bully cannot appear before cooldown expires");
    cr_bully_step(_b,.02);cr_assert(!_b.hidden && _b.stay==120,"Bully appears after timer and receives source stay duration");
    var _points=[];
    repeat(20){
        cr_bully_hide(_b);var _ok=cr_bully_spawn(_b),_t=global.cr_map.tiles[_b.spawn_tile];
        cr_assert(_ok && !_t.open && !_t.contains_object && global.cr_map.rooms[_t.room].type==1 && point_distance(_b.px,_b.pz,_g.px,_g.pz)>30 && !cr_bully_trap(_b.spawn_tile),"Bully spawn satisfies source corridor, occupancy, buffer and TrapCheck");
        array_push(_points,_b.spawn_tile);
    }
    show_debug_message("BBCR_ENCOUNTER_SPAWNS: "+json_stringify({tiles:_points,player:[_g.px,_g.pz]}));
    _b.stay=.01;cr_bully_step(_b,.02);cr_assert(_b.hidden && _b.cooldown>=60 && _b.cooldown<=120,"Bully timeout hides and restarts full cooldown");
    cr_bully_spawn(_b);_b.px+=1;cr_bully_step(_b,.01);cr_assert(_b.hidden,"Bully displacement ends current stay");
    cr_bully_spawn(_b);_g.px=_b.px;_g.pz=_b.pz;_g.inventory=["Zesty","Quarter",""];
    cr_bully_step(_b,.01);cr_assert(_b.hidden && ((_g.inventory[0]=="")!=(_g.inventory[1]=="")),"Bully steals one eligible slot and hides on contact");
    _g.px=175;_g.pz=25;cr_bully_spawn(_b);_g.px=_b.px;_g.pz=_b.pz;_g.inventory=["","",""];
    var _sounds=array_length(_g.sound_instances);cr_bully_step(_b,.01);var _first=array_length(_g.sound_instances);cr_bully_step(_b,.01);
    cr_assert(!_b.hidden && _b.contact && _first>_sounds && array_length(_g.sound_instances)==_first,"empty inventory leaves Bully active and does not repeat OnTriggerEnter audio");
    _g.spoop=true;
    cr_assert(cr_bully_blocks(_b.px,_b.pz,2) && !cr_bully_blocks(_b.px+10,_b.pz,2),"Bully uses source eight-unit solid box and player radius");
    _g.spoop=false;
    _p.px=_b.px;_p.pz=_b.pz;_p.angry=false;_b.bully_guilt=10;cr_principal_bully(_p);cr_bully_step(_b,.01);
    cr_assert(_b.hidden && _b.cooldown>=60,"Principal displacement removes guilty Bully and restarts spawn cooldown");
    cr_bully_hide(_b);_g.px=175;_g.pz=55;
    _g.exits_closed=1;cr_exit_closed();var _fx=_g.exit_fx,_pending=array_length(_fx.pending);
    cr_assert(_fx.active && _pending>0 && _fx.music_key=="exit_slow" && audio_is_playing(_g.game_music),"first exit enables local red lights and slow source MIDI");
    cr_exit_step(.19);cr_assert(array_length(_fx.pending)==_pending,"strong lights wait for source 0.2-second interval");
    cr_exit_step(.02);cr_assert(array_length(_fx.pending)==_pending-1,"one random strong light turns red per interval");
    _g.exits_closed=2;cr_exit_closed();cr_assert(_fx.chaos_key=="Chaos_EarlyLoopStart" && audio_is_playing(_fx.chaos) && array_length(_fx.queue)==1 && string_pos("exit_slow_",_fx.music_key)==1,"second exit queues original chaos intro/loop and transposes MIDI");
    audio_stop_sound(_fx.chaos);cr_exit_audio_tick();cr_assert(_fx.chaos_key=="Chaos_EarlyLoop" && array_length(_fx.queue)==0,"chaos intro progresses to original looping segment");
    _g.reduce_flashing=true;_g.exits_closed=3;cr_exit_closed();cr_assert(!_fx.flicker && !audio_is_playing(_g.game_music) && array_length(_fx.queue)==2,"third exit queues buildup/final loop, silences MIDI and respects reduced flashing");
    audio_stop_sound(_fx.chaos);cr_exit_audio_tick();cr_assert(_fx.chaos_key=="Chaos_Buildup","third exit plays original buildup next");
    audio_stop_sound(_fx.chaos);cr_exit_audio_tick();cr_assert(_fx.chaos_key=="Chaos_FinalLoop","third exit reaches original final loop");
    _g.reduce_flashing=false;bbcr_start_game("story");
    cr_assert(!_g.exit_fx.active && _g.exit_fx.chaos==-1 && _g.jump_height==0 && !_g.rope,"restart clears exit audio, red lights and rope state");
}
function cr_encounter_input(_action) {show_debug_message("BBCR_ENCOUNTER_INPUT: "+_action);global.bbcr.encounter_deadline=current_time+4000;}
function cr_encounter_test_step() {
    var _g=global.bbcr,_stage=_g.encounter_stage;
    if(_stage>=1 && _stage<=5)bbcr_game_step();
    switch(_stage){
        case 0:
            cr_encounter_behavior_tests();global.cr_cheat.freeze_npcs=true;global.cr_cheat.god=true;global.cr_cheat_hint_visible=false;
            _g.px=175;_g.pz=55;_g.yaw=0;_g.move_latch=false;cr_rope_begin(cr_encounter_npc("Playtime"));
            _g.encounter_saved=[_g.px,_g.pz];cr_encounter_input("w_down");_g.encounter_stage=1;break;
        case 1:
            if(!keyboard_check(ord("W")))break;
            cr_assert(_g.px==_g.encounter_saved[0] && _g.pz==_g.encounter_saved[1],"real W input cannot move grounded rope player");
            cr_encounter_input("space_down");_g.encounter_stage=2;break;
        case 2:
            if(_g.jump_height<=0)break;
            cr_assert(_g.pz>_g.encounter_saved[1],"real Space plus W moves airborne player");
            _g.encounter_saved=[_g.pz,_g.time];cr_encounter_input("space_up");_g.encounter_stage=3;break;
        case 3:
            if(_g.time-_g.encounter_saved[1]<.15)break;
            cr_assert(abs(_g.pz-_g.encounter_saved[0]-2.5*(_g.time-_g.encounter_saved[1]))<.01,"actual airborne WASD displacement is source walk speed times 0.25");
            _g.encounter_stage=4;break;
        case 4:
            if(_g.jump_height>0)break;
            cr_assert(_g.jump_velocity==0 && cr_rope_move_scale()==0,"landing removes residual vertical velocity and re-locks grounded walking");
            cr_encounter_input("w_up");_g.encounter_stage=5;_g.encounter_deadline=current_time+120;break;
        case 5:
            if(current_time<_g.encounter_deadline)break;
            cr_rope_end(false);_g.px=175;_g.pz=55;_g.yaw=0;_g.time=0;_g.capture_scene="encounter_rope_base";_g.encounter_stage++;break;
        case 6:
            cr_rope_begin(cr_encounter_npc("Playtime"));_g.rope_anim=.15;_g.capture_scene="encounter_rope_a";_g.encounter_stage++;break;
        case 7:_g.rope_anim=.55;_g.jumps=3;_g.capture_scene="encounter_rope_b";_g.encounter_stage++;break;
        case 8:cr_rope_end(true);_g.capture_scene="encounter_rope_done";_g.encounter_stage++;break;
        case 9:
            _g.notebooks=_g.needed;_g.px=_g.exits[0].x;_g.pz=_g.exits[0].z;cr_world_step(.01);
            cr_assert(_g.exits[0].used && _g.exits_closed==1 && _g.exit_fx.active,"actual first-exit trigger activates ending effects");
            _g.px=175;_g.pz=55;_g.capture_scene="encounter_red_start";_g.encounter_stage++;break;
        case 10:repeat(20)cr_exit_step(.2);_g.capture_scene="encounter_red_half";_g.encounter_stage++;break;
        case 11:repeat(200)cr_exit_step(.2);_g.capture_scene="encounter_red_full";_g.encounter_stage++;break;
        case 12:
            show_debug_message("BBCR_ENCOUNTER_LIGHTS: "+json_stringify(global.bbcr.exit_fx.colors));
            _g.capture_scene="";_g.encounter_stage++;cr_return_menu();room_goto(rm_menu);break;
        case 13:
            cr_assert(!_g.exit_fx.active && _g.exit_fx.chaos==-1 && !_g.rope,"actual menu roundtrip leaves no red tint, chaos or jumping");
            show_debug_message("BBCR_ENCOUNTER_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
    if(array_contains([1,2,3,4],_stage) && _g.encounter_stage==_stage && current_time>_g.encounter_deadline){cr_assert(false,"encounter native input timed out");game_end();}
}
