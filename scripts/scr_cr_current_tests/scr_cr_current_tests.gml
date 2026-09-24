/// Isolated checks for the latest seven issues, with no old suites invoked.
function cr_current_wait(_condition,_stage) {
    if(_condition)return false;
    if(current_time>global.bbcr.current_deadline){cr_assert(false,"targeted native F1 input timeout");game_end();}
    global.bbcr.current_stage=_stage;return true;
}
function cr_current_portal() {
    var _g=global.bbcr,_placed=false,_tiles=global.cr_map.tiles;
    for(var _i=0;_i<array_length(_tiles) && !_placed;_i++){
        var _t=_tiles[_i];if(_t.contains_object)continue;
        for(var _d=0;_d<4 && !_placed;_d++)if((_t.walls & (1<<_d))!=0){
            _g.px=_t.x*10+5;_g.pz=_t.z*10+5;_g.yaw=_d*pi/2;
            if(cr_blocked(_g.px,_g.pz,2))continue;
            _g.inventory=["PortalPoster","",""];_g.slot=0;cr_use_item();_placed=_g.inventory[0]=="";
        }
    }
    cr_assert(_placed,"new portal case places the actual item on a source wall");
    if(!_placed)return;
    var _p=_g.portals[0],_dx=sin(_g.yaw),_dz=cos(_g.yaw);_g.current_portal={x:_g.px,z:_g.pz,yaw:_g.yaw,portal:_p};
    cr_move(_g,_dx*10,_dz*10,2);cr_assert((_g.px-_p.cx)*_dx+(_g.pz-_p.cz)*_dz>2,"player crosses Portal Poster center with collision enabled");
    cr_move(_g,-_dx*10,-_dz*10,2);cr_assert((_g.px-_p.cx)*_dx+(_g.pz-_p.cz)*_dz<-2,"portal is traversable in both directions");
    _g.px=_g.current_portal.x;_g.pz=_g.current_portal.z;
    show_debug_message("BBCR_CURRENT_PORTAL: "+json_stringify({x:_g.px,z:_g.pz,yaw:_g.yaw,cx:_p.cx,cz:_p.cz,texture:global.cr_map.rooms[cr_tile(_g.px,_g.pz).room].portal}));
}
function cr_current_puzzle() {
    var _g=global.bbcr,_p=global.cr_map.puzzle;
    _g.party.values=[1,2,3,4];
    for(var _i=0;_i<4;_i++){
        var _b=_p.buttons[_i].box,_aim=false;
        for(var _a=0;_a<360 && !_aim;_a+=15){
            _g.px=_b.center[0]+lengthdir_x(6,_a);_g.pz=_b.center[2]+lengthdir_y(6,_a);_g.yaw=arctan2(_b.center[0]-_g.px,_b.center[2]-_g.pz);
            var _hit=cr_interaction_target();if(!cr_blocked(_g.px,_g.pz,2) && _hit.kind=="party_button" && _hit.index==_i)_aim=true;
        }
        cr_assert(_aim,"Party puzzle button has a reachable source interaction: "+string(_i));
        if(_aim)repeat(_i+1){cr_interact();cr_party_step(.13);}
    }
    cr_assert(_g.party.puzzle_open && json_stringify(_g.party.puzzle)==json_stringify(_g.party.values),"four source colored counts open Party puzzle wall");
    var _b=_p.wall.box;cr_assert(!cr_blocked(_b.center[0],_b.center[2],2),"solved puzzle removes wall collision");
}
function cr_current_actor(_name) {
    var _g=global.bbcr;for(var _i=0;_i<array_length(_g.npcs);_i++)if(_g.npcs[_i].name==_name)return _g.npcs[_i];
    var _pool=global.cr_map.demo.potential_npcs;
    for(var _i=0;_i<array_length(_pool);_i++)if(_pool[_i].npc.name==_name){
        var _s=_pool[_i].npc,_n=json_parse(json_stringify(_g.npcs[1]));
        _n.name=_s.name;_n.params=_s.params;_n.visual=_s.visual;_n.sprite=_s.sprite;_n.path=path_add();_n.voice=-1;_n.voice_queue=[];_n.hidden=false;_n.cooldown=0;_n.optional_pending=false;
        array_push(_g.npcs,_n);array_push(global.cr_map.npcs,_s);return _n;
    }return undefined;
}
function cr_current_demo_behaviors() {
    var _g=global.bbcr,_names=[];for(var _i=0;_i<array_length(_g.npcs);_i++)array_push(_names,_g.npcs[_i].name);
    cr_assert(array_length(_g.npcs)==8 && array_length(array_unique(_names))==8,"Demo selects four weighted optional NPCs without replacement beside its four fixed NPCs");
    cr_assert(array_length(_g.demo.events)==4 && _g.demo.events[0].start>=55 && _g.demo.events[0].start<=100,"four Demo events are scheduled with original initial and random gaps");
    cr_world_step(10);cr_assert(_g.demo.event_clock==0,"Demo event clock waits for first failed activity");
    cr_demo_hold_number((_g.books[0].answer+1) mod 10);cr_demo_submit_machine(0);
    cr_assert(_g.demo.events_started,"real Demo wrong answer starts event clocks");
    var _first=_g.demo.events[0];_g.demo.event_clock=_first.start-.1;cr_world_step(.2);
    cr_assert(_first.state=="active" && _g.demo.event_text==global.cr_text[$ _first.spec.eventDescKey],"normal world update begins timed Demo event with source announcement");
    cr_demo_event_end(_first);
    for(var _i=0;_i<array_length(_g.demo.events);_i++){var _e=_g.demo.events[_i];_e.state="done";}
    var _beans=cr_current_actor("Beans"),_chalk=cr_current_actor("ChalkFace"),_cloud=cr_current_actor("Cumulo");cr_demo_actors_init();
    _g.px=175;_g.pz=75;_g.yaw=pi;_beans.px=175;_beans.pz=55;_beans.gx=175;_beans.gz=55;_beans.optional_pending=false;
    cr_npc_step(_beans,.01);cr_assert(_beans.actor_state=="chew","Beans live NPC dispatch begins chewing on visible target at destination");
    repeat(31)cr_npc_step(_beans,.1);
    cr_assert(array_length(_g.demo.gum)==1 && _beans.actor_state=="spit","Beans spits an actual source gum projectile after three seconds");
    repeat(60)cr_demo_gum_step(.02);
    cr_assert(_g.gum_time>0 && cr_demo_move_scale(_g)==.25,"Beans gum hits player and applies source quarter-speed penalty");
    _g.demo.gum=[];_g.gum_time=0;_beans.gum=undefined;
    cr_assert(array_length(_g.demo.boards)==5,"Chalkles creates source seventy-percent classroom blackboards");
    var _board=_g.demo.boards[0];_g.px=_board.x;_g.pz=_board.z;_chalk.optional_pending=false;
    repeat(201)cr_npc_step(_chalk,.1);
    cr_assert(_chalk.actor_state=="orbit" && !_chalk.hidden && audio_is_playing(_chalk.voice),"Chalkles live NPC dispatch forms then orbits with source laughing audio");
    var _locked=0;for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].lock>0)_locked++;
    cr_assert(_locked>0,"Chalkles locks its classroom doors");
    _cloud.optional_pending=false;cr_npc_step(_cloud,.01);
    cr_assert(is_array(_cloud.hall) && _cloud.actor_state=="travel","Cloudy Copter live dispatch finds a valid source-length hall");
    _cloud.px=_cloud.gx;_cloud.pz=_cloud.gz;cr_npc_step(_cloud,.01);
    cr_assert(_cloud.actor_state=="blow" && audio_is_playing(_cloud.voice),"Cloudy Copter reaches hall and plays source wind loop");
    show_debug_message("BBCR_CURRENT_DEMO: "+json_stringify({selected:_names,events:_g.demo.events,boards:array_length(_g.demo.boards)}));
    _g.current_actors=[_beans,_chalk,_cloud];_g.current_board=_board;
}
function cr_current_step() {
    var _g=global.bbcr,_stage=cr_value(_g,"current_stage",0);_g.current_stage=_stage+1;
    switch(_stage){
        case 0:
            global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;cr_audio_clear_all();cr_ui_scene("MainMenu");global.cr_ui.stage=16;
            cr_assert(!_g.loaded && !variable_struct_exists(_g,"px"),"menu F1 fixture is cold startup without any initialized game world");
            _g.current_deadline=current_time+5000;show_debug_message("BBCR_CURRENT_INPUT: f1_down");break;
        case 1:
            cr_cheat_step();if(cr_current_wait(global.cr_cheat.open,_stage))break;
            _g.capture_scene="current_menu_open";show_debug_message("BBCR_CURRENT_INPUT: f1_up");break;
        case 2:if(cr_current_wait(!keyboard_check(vk_f1),_stage))break;break;
        case 3:show_debug_message("BBCR_CURRENT_INPUT: f1_down");break;
        case 4:
            cr_cheat_step();if(cr_current_wait(!global.cr_cheat.open,_stage))break;
            cr_assert(cr_cheat_in_menu() && !_g.loaded && !window_mouse_get_locked(),"cold-start native F1 close restores menu without accessing gameplay state");
            show_debug_message("BBCR_CURRENT_INPUT: f1_up");_g.capture_scene="current_menu_closed";break;
        case 5:if(cr_current_wait(!keyboard_check(vk_f1),_stage))break;bbcr_menu_step(.017);cr_audio_update_volume();break;
        case 6:_g.style="party";bbcr_start_game("story");cr_current_portal();_g.capture_scene="current_portal";break;
        case 7:
            _g.current_portal_mask=global.cr_map.rooms[cr_tile(_g.px,_g.pz).room].portal;
            _g.capture_scene="current_portal_fixture";_g.current_portal_fixture=true;break;
        case 8:
            _g.current_portal_fixture=false;cr_party_final_exit();cr_party_begin_lift();repeat(301)cr_party_step(.01);
            _g.yaw=pi/2;_g.capture_scene="current_raised_wall";
            cr_assert(array_length(_g.party.data.shells)>0 && _g.party.phase=="candle","raised Party lift retains source cafeteria shell");break;
        case 9:_g.current_shells=_g.party.data.shells;_g.party.data.shells=[];_g.capture_scene="current_raised_no_wall";break;
        case 10:_g.party.data.shells=_g.current_shells;cr_party_candle();cr_current_puzzle();_g.capture_scene="current_puzzle";break;
        case 11:
            _g.px=135;_g.pz=345;_g.yaw=pi/2;_g.capture_scene="current_ending_wall";
            cr_assert(_g.world_y==30 && _g.party.secret_ready,"candle activates ending environment and school secret tutor branch");break;
        case 12:
            _g.party.values=[1,2,3,4];_g.inventory=["Teleporter","",""];_g.slot=0;cr_use_item();
            cr_assert(_g.party.phase=="returned" && _g.world_y==0 && global.cr_map.manager=="ClassicPartyManager","Dangerous Teleporter returns from raised ending to original school");
            _g.teleporter=undefined;var _t=_g.party.data.tutors.secretNull;_g.px=_t.position[0];_g.pz=_t.position[2]-8;_g.progress.flags[4]=false;cr_party_step(.01);
            cr_assert(is_struct(_g.party.tutor) && audio_is_playing(_g.party.tutor.handle) && _g.party.tutor.spec.quit,"school office NULL starts source speech and selects quit-on-end");
            _g.yaw=0;_g.capture_scene="current_secret_null";_g.current_quit_tutor=_g.party.tutor;_g.current_stage=40;break;
        case 40:
            audio_stop_sound(_g.party.tutor.handle);_g.party.tutor=undefined;
            _g.party.angry_secret=true;cr_party_step(.01);cr_assert(_g.party.tutor.spec.speech=="Null_Party_Mad","triggered corruption selects angry school NULL dialogue");
            _g.capture_scene="current_secret_angry";break;
        case 41:
            audio_stop_sound(_g.party.tutor.handle);_g.party.tutor=undefined;_g.progress.flags[4]=true;cr_party_step(.01);
            cr_assert(_g.party.tutor.spec.speech=="BAL_PartySecret" && _g.party.tutor.spec.menu,"post-NULL flag selects Baldi office speech and return-menu behavior");
            _g.capture_scene="current_secret_baldi";break;
        case 42:
            audio_stop_sound(_g.party.tutor.handle);cr_party_step(.01);cr_assert(_g.scene=="menu","Baldi party tutor finishes through actual return-menu callback");_g.current_stage=13;break;
        case 13:
            _g.style="demo";bbcr_start_game("story");global.cr_cheat.god=true;cr_current_demo_behaviors();_g.spoop=false;
            _g.demo.event_text_time=0;_g.demo.fog=0;_g.demo.water=0;_g.demo.roll=0;_g.demo.roll_target=0;_g.demo.flipped=false;
            _g.current_math_texts=[];for(var _i=0;_i<7;_i++)array_push(_g.current_math_texts,_g.books[_i].machine.text);
            for(var _i=0;_i<array_length(_g.books);_i++){var _b=_g.books[_i];_b.state="active";_b.corrupted=false;_b.book_ready=false;for(var _j=0;_j<10;_j++)_b.numbers[_j].active=false;}
            break;
        case 14:case 16:case 18:case 20:case 22:case 24:case 26:
            var _i=(_stage-14)/2,_b=_g.books[_i],_m=_b.machine;_g.current_text=_m.text;
            _g.px=_m.x-sin(_m.direction*pi/2)*9;_g.pz=_m.z-cos(_m.direction*pi/2)*9;_g.yaw=_m.direction*pi/2;
            _g.capture_scene="current_math_"+string(_i);show_debug_message("BBCR_CURRENT_MATH: "+json_stringify({index:_i,x:_g.px,z:_g.pz,yaw:_g.yaw,values:[_b.a,_b.op,_b.b,"?"]}));break;
        case 15:case 17:case 19:case 21:case 23:case 25:case 27:
            var _i=(_stage-15)/2;_g.books[_i].machine.text=[];_g.capture_scene="current_math_base_"+string(_i);break;
        case 28:
            _g.books[6].machine.text=_g.current_text;_g.px=175;_g.pz=55;_g.yaw=0;_g.capture_scene="current_event_base";break;
        case 29:
            for(var _i=0;_i<4;_i++)if(_g.demo.events[_i].spec.name=="FogEvent"){_g.current_event=_g.demo.events[_i];cr_demo_event_begin(_g.current_event);}
            repeat(41)cr_demo_events_step(.1);cr_assert(_g.demo.fog==1 && _g.demo.max_sight==40,"timed fog reaches source strength and limits NPC sight to forty units");_g.capture_scene="current_fog";break;
        case 30:
            cr_demo_event_end(_g.current_event);repeat(41)cr_demo_events_step(.1);
            for(var _i=0;_i<4;_i++)if(_g.demo.events[_i].spec.name=="FloodEvent"){_g.current_event=_g.demo.events[_i];cr_demo_event_begin(_g.current_event);}
            repeat(31)cr_demo_events_step(.1);
            cr_assert(_g.demo.water==3 && array_length(_g.current_event.objects)>=15 && cr_demo_move_scale(_g)==.75,"flood rises and spawns source-range whirlpools with movement penalty");_g.capture_scene="current_flood";break;
        case 31:
            cr_demo_event_end(_g.current_event);repeat(31)cr_demo_events_step(.1);
            for(var _i=0;_i<4;_i++)if(_g.demo.events[_i].spec.name=="GravityEvent"){_g.current_event=_g.demo.events[_i];cr_demo_event_begin(_g.current_event);}
            // Keep this timer assertion independent of randomly landing on a flipper.
            _g.px=-100;_g.pz=-100;for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].hidden=true;
            repeat(101)cr_demo_events_step(.1);
            cr_assert(_g.demo.flipped && _g.demo.roll==180 && array_length(_g.current_event.objects)>=15,"gravity event rolls camera and spawns source flippers after ten seconds");
            _g.px=175;_g.pz=55;_g.capture_scene="current_gravity";break;
        case 32:
            cr_demo_event_end(_g.current_event);repeat(11)cr_demo_events_step(.1);
            for(var _i=0;_i<4;_i++)if(_g.demo.events[_i].spec.name=="RulerEvent"){_g.current_event=_g.demo.events[_i];cr_demo_event_begin(_g.current_event);}
            var _n=_g.npcs[0];_n.slap_timer=0;cr_baldi_tick(_n,.01);
            cr_assert(_g.demo.ruler && !_g.demo.ruler_break,"broken-ruler event uses one-shot source break sound in real Baldi timer");cr_demo_event_end(_g.current_event);
            _g.spoop=true;for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].hidden=true;
            var _n=_g.current_actors[0];_n.hidden=false;_n.optional_pending=false;_n.px=175;_n.pz=65;_n.actor_state="chew";_n.anim_time=1;
            _g.capture_scene="current_beans";break;
        case 33:
            _g.current_actors[0].hidden=true;var _n=_g.current_actors[1];_n.hidden=false;_n.actor_state="orbit";_n.sprite=_n.params.flying_sprite;_n.px=175;_n.pz=65;_n.height=5;_g.capture_scene="current_chalk";break;
        case 34:
            _g.current_actors[1].hidden=true;var _n=_g.current_actors[2];_n.hidden=false;_n.px=175;_n.pz=65;_g.capture_scene="current_cloud";break;
        case 35:
            _g.spoop=false;_g.demo.event_text_time=0;_g.demo.roll=0;_g.demo.roll_target=0;
            var _b=_g.books[0],_m=_b.machine;_m.text=_g.current_math_texts[0];
            var _yaw=_m.direction*pi/2;_g.px=_m.x-sin(_yaw)*7.5+cos(_yaw)*1.6;_g.pz=_m.z-cos(_yaw)*7.5-sin(_yaw)*1.6;_g.yaw=arctan2(_m.x-_g.px,_m.z-_g.pz);
            _g.capture_scene="current_math_angle";show_debug_message("BBCR_CURRENT_MATH: "+json_stringify({index:0,tag:"angle",x:_g.px,z:_g.pz,yaw:_g.yaw,values:[_b.a,_b.op,_b.b,"?"]}));break;
        case 36:_g.books[0].machine.text=[];_g.capture_scene="current_math_base_angle";break;
        case 37:
            cr_assert(_g.current_quit_tutor.spec.quit,"pending school NULL completion retains original quit callback");
            show_debug_message("BBCR_CURRENT_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");
            _g.party={tutor:_g.current_quit_tutor};cr_party_tutor_complete();break;
    }
}
