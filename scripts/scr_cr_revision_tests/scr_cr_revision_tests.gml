function cr_revision_capture() {
    var _g=global.bbcr,_name=cr_value(_g,"revision_capture","");if(_name=="")return;
    screen_save("bbcr_revision_"+_name+".png");_g.revision_capture="";
}
function cr_revision_event(_name) {
    var _events=global.bbcr.demo.events;for(var _i=0;_i<array_length(_events);_i++)if(_events[_i].spec.name==_name)return _events[_i];return undefined;
}
function cr_revision_sound_count(_key) {
    var _list=global.bbcr.sound_instances,_count=0;for(var _i=0;_i<array_length(_list);_i++)if(_list[_i].key==_key)_count++;return _count;
}
function cr_revision_item(_type) {
    var _keys=variable_struct_get_names(global.cr_catalog.items);for(var _i=0;_i<array_length(_keys);_i++)if(global.cr_catalog.items[$ _keys[_i]].type==_type)return _keys[_i];return "";
}
function cr_revision_test_step() {
    var _g=global.bbcr;if(!variable_struct_exists(_g,"revision_stage")){_g.revision_stage=0;global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;}
    var _stage=_g.revision_stage++;_g.revision_capture="";
    switch(_stage){
        case 0:
            _g.progress=cr_progress_default();_g.progress.flags[0]=true;cr_ui_scene("MainMenu");global.cr_ui.stage=16;
            cr_ui_active("Title",false);cr_ui_active("StyleSelect",true);_g.revision_capture="null_idle";break;
        case 1:
            cr_ui_hover(cr_ui_node("StyleSelect/Baldi").id);cr_assert(cr_ui_node("StyleSelect/Baldi").glitch,"NULL hover activates source GlitchBaldiButton renderer");_g.revision_capture="null_hover";break;
        case 2:
            cr_ui_press(cr_ui_node("StyleSelect/Baldi"));global.cr_ui.stage=16;
            var _n=cr_ui_node(cr_ui_node("ModeSelect").scripts.EndlessMapOverview.levelName);cr_assert(_n.graphics[0].layout.text!="undefined","NULL empty level key follows source fallback, never undefined");
            cr_assert(_g.style=="null" && cr_ui_node("ModeSelect").active,"NULL selector executes source mode callback");_g.revision_capture="null_menu";break;
        case 3:
            _g.style="demo";_g.mirror=false;_g.lightsout=false;_g.hard=false;bbcr_start_game("story");_g.happy_spoke=true;
            cr_assert(array_length(_g.demo.boards)==0,"Chalkles does not build boards before NPC initialization after spoop");
            cr_assert(global.cr_map.demo.events.bell=="SchoolBell","event warning resolves Sfx_EventStartBell asset");
            _g.revision_hide_hud=true;_g.px=175;_g.pz=45;_g.yaw=0;_g.time=0;_g.revision_capture="normal";_g.revision_wait_draw=true;break;
        case 4:
            _g.mirror=true;cr_assert(cr_input_reverse()==-1,"Mirror reverses lateral input and look controls");_g.revision_capture="mirror";break;
        case 5:
            _g.mirror=false;_g.lightsout=true;cr_assert(cr_lantern_color(_g.px,_g.pz)!=c_black && cr_lantern_color(_g.px+100,_g.pz)==c_black,"Lights Out source lantern reaches six tiles then black");_g.revision_capture="lights";break;
        case 6:
            _g.lightsout=false;_g.inventory=[cr_revision_item(4),"",""];_g.slot=0;cr_use_item();var _a=_g.alarms[0];_a.z=_g.pz+8;
            cr_assert(_a.t==30 && cr_alarm_frame(_a)==1,"Alarm starts on source 30-second sprite");_g.revision_capture="alarm";break;
        case 7:
            cr_alarm_wind(0);cr_assert(_g.alarms[0].t==45 && cr_alarm_frame(_g.alarms[0])==2,"Alarm click changes countdown and visible source frame");_g.revision_capture="alarm_wound";break;
        case 8:
            cr_spoop();_g.demo.events_started=true;
            var _e=cr_revision_event("RulerEvent");for(var _i=0;_i<array_length(_g.demo.events);_i++)if(_g.demo.events[_i]!=_e)_g.demo.events[_i].state="done";
            _e.start=100;_g.demo.event_clock=96.99;var _sounds=cr_revision_sound_count("SchoolBell");cr_demo_events_step(.02);
            cr_assert(_e.announced && cr_revision_sound_count("SchoolBell")==_sounds+1,"event bell plays three seconds before event start");cr_demo_events_step(.01);cr_assert(cr_revision_sound_count("SchoolBell")==_sounds+1,"event warning is not repeated each frame");
            for(var _i=0;_i<array_length(_g.demo.events);_i++)_g.demo.events[_i].state="done";
            cr_demo_event_begin(_e);var _n=_g.npcs[0];_n.px=_g.px;_n.pz=_g.pz;cr_npc_step(_n,.01);
            cr_assert(!_g.dead && _g.demo.ruler,"Broken Ruler excludes actual Baldi player capture branch");cr_demo_event_end(_e);cr_assert(!_g.demo.ruler,"Broken Ruler restores capture after event end");_n.px=65;_n.pz=55;
            var _keys=[];for(var _i=0;_i<array_length(_n.params.correct_sounds);_i++)array_push(_keys,_n.params.correct_sounds[_i].sound);
            _g.demo.problems=2;cr_demo_complete(0,true);var _last=_g.sound_instances[array_length(_g.sound_instances)-1];
            cr_assert(array_contains(_keys,_last.key) && _n.math_pause>0,"correct MathMachine answer plays source weighted Baldi praise and pauses movement");
            for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].hidden=true;
            _g.alarms=[];_g.revision_fixture="fog";_g.demo.fog=0;_g.revision_capture="fog_off";break;
        case 9:_g.demo.fog=1;_g.revision_capture="fog_on";break;
        case 10:
            _g.revision_fixture="";_g.demo.fog=0;var _e=cr_revision_event("FloodEvent");cr_demo_event_begin(_e);_g.demo.water=3;
            _g.px=175;_g.pz=65;_g.yaw=0;_g.revision_capture="flood";break;
        case 11:
            cr_demo_event_end(cr_revision_event("FloodEvent"));_g.demo.water=0;_g.revision_capture="dry";break;
        case 12:
            var _e=cr_revision_event("GravityEvent");cr_demo_event_begin(_e);_g.demo.roll=0;_g.demo.flipped=false;
            _e.objects=[{px:_g.px,pz:_g.pz+9,variant:0,rotation:matrix_build_identity()}];_e.spawn_timer=9999;
            _g.revision_capture="gravity_a";break;
        case 13:
            var _e=cr_revision_event("GravityEvent");_e.objects[0].rotation=matrix_build(0,0,0,25,25,25,1,1,1);_g.revision_capture="gravity_b";
            cr_assert(global.cr_map.demo.events.events[0].name!="" && array_length(_e.spec.flippers)>1,"Gravity imports the source geometric variants");break;
        case 14:
            cr_demo_event_end(cr_revision_event("GravityEvent"));_g.demo.roll=0;_g.demo.flipped=false;_g.demo.roll_target=0;
            var _cloud=undefined;for(var _i=0;_i<array_length(global.cr_map.demo.potential_npcs);_i++)if(global.cr_map.demo.potential_npcs[_i].npc.name=="Cumulo")_cloud=global.cr_map.demo.potential_npcs[_i].npc;
            _g.revision_cloud={params:_cloud.params,hall:[175,55,175,115]};_g.revision_fixture="wind";_g.revision_capture="wind";
            cr_assert(array_length(_cloud.params.wind.surfaces)==4,"Cloudy Copter imports all four source wind graphics");break;
        case 15:
            _g.revision_fixture="";_g.revision_hide_hud=false;global.cr_load_transition.stage=16;global.cr_math_ui.stage=16;cr_pause(true);global.cr_pause_ui.stage=16;
            var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;cr_ui_press(cr_ui_node("ClassicPauseMenu/Main/Quit"));global.cr_ui.stage=16;
            cr_assert(cr_ui_node("ClassicPauseMenu/Confirm").active,"Pause Quit opens source confirmation instead of quitting");cr_ui_hover(cr_ui_node("ClassicPauseMenu/Confirm/YesButton").id);cr_ui_animation_tick(global.cr_ui,.13);global.cr_ui=_old;
            _g.revision_capture="quit_yes_a";break;
        case 16:cr_ui_animation_tick(global.cr_pause_ui,.2);_g.revision_capture="quit_yes_b";break;
        case 17:
            var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;cr_ui_hover(cr_ui_node("ClassicPauseMenu/Confirm/NoButton").id);cr_ui_animation_tick(global.cr_ui,.2);
            cr_assert(cr_ui_node(cr_ui_node("ClassicPauseMenu/Confirm/NoButton").button.animation.target).animation=="ChalkBaldiShake","No choice uses source shake animation");global.cr_ui=_old;_g.revision_capture="quit_no";break;
        case 18:
            _g.paused=false;audio_resume_all();global.cr_pause_ui.stage=16;_g.notebooks=6;_g.books[1].done=false;_g.books[1].book_ready=true;_g.demo.last=1;
            var _key=global.cr_map.manager_sounds.audAllNotebooks,_count=cr_revision_sound_count(_key);cr_demo_collect_book(1);
            cr_assert(_g.notebooks==7 && cr_revision_sound_count(_key)==_count+1,"seventh Demo notebook plays source all-notebooks speech");
            var _bonus=0;for(var _i=0;_i<7;_i++)if(_g.books[_i].bonus)_bonus++;cr_assert(_bonus==6,"source lastActivity is excluded from six bonus machines");
            var _before=array_length(_g.items);for(var _i=0;_i<7;_i++)if(_g.books[_i].bonus){cr_demo_complete(_i,true);if(_g.demo.bonus_wins<6)cr_assert(array_length(_g.items)==_before,"Portal Poster is not granted before sixth bonus completion");}
            cr_assert(array_length(_g.items)==_before+1 && _g.items[_before].item==_g.books[0].machine.bonus_item,"six completed bonus machines grant source Portal Poster");break;
        case 19:
            var _entered=false,_room=cr_tile(185,235).room;
            for(var _ti=0;_ti<array_length(global.cr_map.tiles) && !_entered;_ti++){
                var _inside=global.cr_map.tiles[_ti];if(_inside.room!=_room)continue;
                for(var _d=0;_d<4 && !_entered;_d++){
                    var _dx=round(sin(_d*pi/2)),_dz=round(cos(_d*pi/2)),_x=_inside.x*10+5-_dx*10,_z=_inside.z*10+5-_dz*10,_tile=cr_tile(_x,_z);
                    if(is_undefined(_tile) || _tile.room==_room || (_tile.walls & (1<<_d))==0 || cr_blocked(_x,_z,2))continue;
                    _g.px=_x;_g.pz=_z;_g.yaw=_d*pi/2;_g.inventory=["PortalPoster","",""];_g.slot=0;cr_use_item();
                    if(_g.inventory[0]!="")continue;cr_move(_g,_dx*10,_dz*10,2);cr_move(_g,185-_g.px,235-_g.pz,2);_entered=point_distance(_g.px,_g.pz,185,235)<3;
                }
            }
            cr_assert(_entered,"reward Portal Poster opens the actual Demo hatch wall and player crosses with collision enabled");
            cr_demo_hatch_step();cr_assert(global.cr_map.scene=="ClassicBasement_0" && is_struct(_g.secret_route),"Demo hatch transitions to the source basement manager, not a school offset");
            global.cr_load_transition.stage=16;_g.revision_capture="basement";break;
        case 20:
            cr_assert(array_length(global.cr_map.lockdowns)==1,"Demo basement imports source lockdown gate and controls");
            _g.px=55;_g.pz=215;_g.yaw=pi/2;
            cr_assert(cr_secret_route_interact() && global.cr_map.lockdowns[0].target>0,"basement source button targets its serialized lockdown receiver");
            cr_secret_route_step(30);cr_assert(global.cr_map.lockdowns[0].height>global.cr_map.lockdowns[0].collision_height,"lockdown rises beyond source collision height");
            _g.px=45;_g.pz=215;_g.yaw=pi*1.5;
            cr_assert(cr_secret_route_interact() && _g.secret_route.lights,"basement source lever toggles lights and office door locks");
            _g.px=203;_g.pz=300;_g.yaw=0;cr_assert(cr_secret_route_interact() && _g.scene=="secretbook","basement math book opens through its source sphere and click callback");_g.revision_capture="basement_book";break;
        case 21:
            cr_secret_book_close();_g.px=155;_g.pz=170;cr_secret_route_step(.01);
            cr_assert(_g.secret_route.spawned && audio_is_playing(_g.secret_route.voice),"basement source trigger spawns NULL and plays Null_Demo");
            _g.revision_capture="basement_tutor";break;
        case 22:
            _g.style="null";_g.progress.flags[1]=false;_g.progress.flags[2]=false;_g.progress.flags[3]=false;_g.progress.flags[4]=false;
            bbcr_start_game("story");cr_assert(is_struct(_g.null_mode) && _g.spoop && _g.game_music<0,"NULL uses its own manager from level start with no school music");cr_null_collect(0);
            cr_assert(_g.notebooks==0 && !_g.books[0].done && _g.scene=="nullpad","NULL gates notebook collection on the three source secret flags");global.cr_math_ui.stage=16;_g.revision_capture="nullpad_locked";break;
        case 23:
            cr_null_pad_close();_g.px=175;_g.pz=25;_g.yaw=0;var _n=_g.npcs[0];_n.px=175;_n.pz=55;_n.slap_timer=999;
            _g.inventory=[cr_revision_item(1),"",""];_g.slot=0;cr_use_item();repeat(120)cr_world_step(.01);
            cr_assert(array_length(_g.projectiles)>0 && _g.projectiles[0].pz>55 && _n.pz>55,"NULL preboss still advances item projectiles and receives BSODA pushes");_g.projectiles=[];
            _g.progress.flags[1]=true;_g.progress.flags[2]=true;_g.progress.flags[3]=true;
            for(var _i=0;_i<7;_i++){cr_null_collect(_i);cr_null_pad_close();}
            cr_assert(_g.notebooks==7 && !_g.doors[0].locked,"NULL collection is enabled after prerequisites");
            for(var _i=0;_i<3;_i++){var _e=_g.exits[_i];_g.px=_e.triggers[0].center[0];_g.pz=_e.triggers[0].center[2];cr_null_elevators();}
            cr_assert(_g.exits_closed==3 && _g.null_mode.phase=="preboss","NULL third exit begins dedicated preboss, not Classic victory");
            var _e=_g.exits[_g.null_mode.final_exit],_target=cr_tile(_e.x+sin(_e.dir*pi/2)*10,_e.z+cos(_e.dir*pi/2)*10),_n=_g.npcs[0];
            _n.px=_target.x*10+5;_n.pz=_target.z*10+5;_n.gx=_n.px;_n.gz=_n.pz;
            var _neighbor=_target;for(var _d=0;_d<4;_d++)if(_target.nav[_d]>=0)_neighbor=global.cr_map.tiles[_target.nav[_d]];
            _g.px=_neighbor.x*10+5;_g.pz=_neighbor.z*10+5;cr_null_step(.001);
            cr_assert(_g.null_mode.phase=="intro" && _g.exits_closed==4,"approaching final NULL elevator triggers rush arrival and closes fourth exit");
            cr_assert(array_length(_g.null_mode.projectiles)==9 && _g.items_disabled,"NULL boss initializes the nine source projectile spawns and disables inventory");
            global.cr_math_ui.stage=16;_g.revision_capture="null_boss";break;
        case 24:
            var _s=_g.null_mode,_p=_s.projectiles[0];_g.px=_p.x;_g.pz=_p.z;cr_null_step(.001);
            cr_assert(_s.held==0,"NULL boss projectile is picked up on player contact");cr_assert(cr_null_throw() && _s.held<0,"Interact throws held source projectile");
            var _n=_g.npcs[0];_n.px=_p.x+sin(_p.yaw)*2;_n.pz=_p.z+cos(_p.yaw)*2;cr_null_step(.03);
            cr_assert(_s.health==9 && _s.phase=="boss" && _s.walk_speed==25,"projectile hit starts boss chase and source player speed progression");
            cr_null_spawn_blocker();cr_assert(array_length(_s.blockers)>0,"NULL boss selects a source corridor junction for blocker spawn");
            if(array_length(_s.blockers)>0){var _b=_s.blockers[0];_g.px=_b.x;_g.pz=_b.z;cr_null_blockers_step(.01);cr_assert(_b.active,"NULL blocker activates on player entering its junction");_g.px=_b.x+30;cr_null_blockers_step(1.1);cr_assert(array_length(_s.blockers)==0,"NULL blocker despawns one second after leaving trigger");}
            repeat(9)cr_null_hit();cr_assert(global.cr_map.scene=="ClassicFinale_0" && is_struct(_g.secret_route),"tenth hit loads source NULL finale scene");global.cr_load_transition.stage=16;_g.revision_capture="finale";break;
        case 25:
            _g.px=41.5;_g.pz=70.5;_g.yaw=0;cr_assert(cr_secret_route_interact() && _g.scene=="secretbook","finale opens source final book through its click trigger");cr_secret_book_close();
            cr_assert(_g.secret_route.active && audio_is_playing(_g.secret_route.voice),"closing final book starts original finale speech");
            cr_secret_route_step(global.cr_map.secret_manager.duration+.1);cr_assert(_g.progress.flags[4],"finishing source timeline persists NULL completion flag");
            _g.progress.flags[4]=false;bbcr_start_game("story");cr_caught(_g.npcs[0]);cr_ending_step(9.9);
            cr_assert(_g.dead && _g.ending.kind=="nullcaught" && _g.scene!="menu","NULL capture uses source ten-second sequence rather than Classic menu return");_g.revision_capture="null_caught";break;
        case 26:
            show_debug_message("BBCR_REVISION_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");cr_ending_step(.2);break;
    }
}
