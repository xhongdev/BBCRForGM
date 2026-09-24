/// Only this round's menu/Beans/captions/NULL safeguards and visual feedback.
function cr_session_capture() {
    var _g=global.bbcr,_label=cr_value(_g,"session_capture","");if(_label=="")return;
    screen_save("bbcr_session_"+_label+".png");
    if(_g.scene=="menu")surface_save(global.cr_ui.surface,"bbcr_session_native_"+_label+".png");
    _g.session_capture="";
}
function cr_session_pause_check(_glitch) {
    var _g=global.bbcr;_g.progress.flags[4]=_glitch;_g.notebooks=0;
    global.cr_load_transition.stage=16;global.cr_math_ui.stage=16;global.cr_pause_ui.stage=16;_g.paused=false;
    cr_pause(true);global.cr_pause_ui.stage=16;var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;
    cr_ui_press(cr_ui_node("ClassicPauseMenu/Main/Quit"));global.cr_pause_ui.stage=16;
    var _n=_g.npcs[0];_n.px=_g.px+40;_n.pz=_g.pz;
    var _button=cr_ui_node("ClassicPauseMenu/Confirm/YesButton");cr_ui_hover(_button.id);
    cr_assert(_g.paused && point_distance(_g.px,_g.pz,_n.px,_n.pz)>30,"NULL/Glitch Yes hover animates without teleport "+string(_glitch));
    cr_ui_press(_button);
    cr_assert(!_g.paused && _g.scene=="game" && abs(_n.px-_g.px-sin(_g.yaw))<.001 && abs(_n.pz-_g.pz-cos(_g.yaw))<.001,"NULL/Glitch actual Yes press resumes and teleports at zero notebooks "+string(_glitch));
    global.cr_ui=_old;global.cr_pause_ui.stage=16;
}
function cr_session_beans_check() {
    var _g=global.bbcr,_n=undefined;
    for(var _i=0;_i<array_length(_g.npcs);_i++)if(_g.npcs[_i].name=="Beans")_n=_g.npcs[_i];
    if(is_undefined(_n)){
        var _spec=undefined;for(var _i=0;_i<array_length(global.cr_map.demo.potential_npcs);_i++)if(global.cr_map.demo.potential_npcs[_i].npc.name=="Beans")_spec=global.cr_map.demo.potential_npcs[_i].npc;
        _n=json_parse(json_stringify(_g.npcs[0]));_n.path=path_add();_n.name="Beans";_n.params=_spec.params;_n.visual=_spec.visual;_n.sprite=_spec.sprite;
        array_push(_g.npcs,_n);array_push(global.cr_map.npcs,_spec);
    }
    cr_demo_actors_init();_n.optional_pending=false;_n.hidden=false;_n.cooldown=0;_n.actor_state="wander";_n.targeting=false;_n.gum=undefined;
    var _found=false;
    for(var _i=0;_i<array_length(global.cr_map.tiles) && !_found;_i++){
        var _a=global.cr_map.tiles[_i];if(_a.room!=0)continue;
        for(var _d=0;_d<4;_d++){
            var _bi=_a.nav[_d];if(_bi<0)continue;var _b=global.cr_map.tiles[_bi];var _ci=_b.nav[_d];if(_ci<0 || _b.room!=0)continue;var _c=global.cr_map.tiles[_ci];if(_c.room!=0)continue;
            var _ax=_a.x*10+5,_az=_a.z*10+5,_bx=_b.x*10+5,_bz=_b.z*10+5,_cx=_c.x*10+5,_cz=_c.z*10+5;
            if(cr_blocked(_ax,_az,2) || cr_blocked(_bx,_bz,2) || cr_blocked(_cx,_cz,2) || !cr_clear_line(_ax,_az,_cx,_cz,_n.params.sight_mask))continue;
            _n.px=_ax;_n.pz=_az;_n.gx=_bx+cos(_d*pi/2)*4.8;_n.gz=_bz-sin(_d*pi/2)*4.8;_g.px=_cx;_g.pz=_cz;_g.yaw=_d*pi/2+pi;_found=true;break;
        }
    }
    cr_assert(_found,"Beans fixture uses a real unobstructed hallway and source sight mask");
    _n.route_timer=0;_n.timer=0;_n.sprint_wait=1000;path_clear_points(_n.path);_g.spoop=true;
    var _time=0;while(!is_struct(_n.gum) && _time<20){cr_npc_step(_n,1/60);_time+=1/60;}
    cr_assert(is_struct(_n.gum) && _n.actor_state=="spit","Beans reaches a snapped path endpoint, chews and launches without forcing chew state");
    cr_assert(_time>=3 && _time<20,"Beans source three-second chew follows destination completion");
    var _distance=is_struct(_n.gum)?point_distance(_n.gum.px,_n.gum.pz,_g.px,_g.pz):0;cr_demo_gum_step(.1);
    cr_assert(array_length(_g.demo.gum)>0 && point_distance(_g.demo.gum[0].px,_g.demo.gum[0].pz,_g.px,_g.pz)<_distance,"actual beans_gumwad travels toward player");
    repeat(120)cr_demo_gum_step(1/60);
    cr_assert(_g.gum_time>0 && cr_demo_move_scale(_g)==.25,"launched gum reaches player and applies source slowdown");
    show_debug_message("BBCR_SESSION_BEANS: "+json_stringify({time:_time,x:_n.px,z:_n.pz,gum:_g.gum_time,state:_n.actor_state,targeting:_n.targeting,cooldown:_n.cooldown,gx:_n.gx,gz:_n.gz,node:_n.node,path:path_get_number(_n.path),visible:cr_clear_line(_n.px,_n.pz,_g.px,_g.pz,_n.params.sight_mask),sight:_n.params.sight_distance,pending:_n.optional_pending}));
}
function cr_session_step() {
    var _g=global.bbcr;if(!variable_struct_exists(_g,"session_stage")){_g.session_stage=0;global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;}
    var _stage=_g.session_stage;_g.session_stage++;cr_audio_update_volume();cr_caption_tick(delta_time/1000000);
    switch(_stage){
        case 0:
            cr_audio_clear_all();cr_ui_scene("MainMenu");global.cr_ui.stage=16;cr_ui_active("Title",false);cr_ui_active("HowToPlay",true);_g.session_capture="how";break;
        case 1:
            cr_ui_active("HowToPlay",false);cr_ui_active("Options",true);var _o=cr_ui_node("Options").scripts.OptionsMenu;
            for(var _i=0;_i<array_length(_o.categories);_i++)cr_ui_active(_o.categories[_i],_i==2);
            var _n=cr_ui_node("Options/Audio/TooltipHotspots/SubtitleTT");global.cr_ui.cx=200;global.cr_ui.cy=148;cr_ui_hover(_n.id);
            cr_assert(cr_value(global.cr_ui,"tooltip_key","")=="Tip_Subtitles","serialized options hover opens source caption tooltip");_g.session_capture="tooltip";break;
        case 2:
            cr_ui_hover("");cr_assert(!cr_ui_node(cr_ui_node("Options").scripts.TooltipController.tooltipTmp).active,"leaving settings hides tooltip");
            _g.subtitles=false;cr_ui_toggle_set(cr_ui_node(cr_ui_node("Options").scripts.OptionsMenu.subtitlesToggle),false);var _clicked=false;
            for(var _i=0;_i<array_length(global.cr_ui.nodes) && !_clicked;_i++){var _n=global.cr_ui.nodes[_i];if(is_undefined(_n.button))continue;for(var _j=0;_j<array_length(_n.button.press);_j++)if(_n.button.press[_j].method=="SubtitlesChanged"){cr_ui_press(_n);_clicked=true;break;}}
            cr_assert(_clicked && _g.subtitles,"actual source Captions button callbacks enable caption display");
            cr_save("bbcr_session_settings_test.ini");ini_open("bbcr_session_settings_test.ini");var _persisted=ini_read_real("options","subtitles",0);ini_close();
            cr_assert(_persisted==1,"Captions preference persists through normal save serializer in isolated file");file_delete("bbcr_session_settings_test.ini");
            cr_ui_active("Options",false);cr_ui_active("Title",true);_g.session_voice=cr_sound("BAL_MenuIntro",undefined,undefined,true);cr_caption_tick(.01);
            cr_assert(array_length(global.cr_captions)==1,"menu speech creates a caption from source SoundObject");_g.session_capture="caption_menu";break;
        case 3:
            _g.subtitles=false;_g.session_capture="caption_off";break;
        case 4:
            cr_audio_clear_all();cr_ui_active("Title",false);cr_ui_active("Credits",true);_g.boss_seen=false;cr_menu_special_step(.01);_g.session_capture="credits_hidden";
            cr_assert(audio_is_playing(global.cr_ui.music),"source Credits music starts on activation");break;
        case 5:
            var _n=cr_ui_node("Credits"),_period=_n.scripts.Credits.timeBetweenFrames;cr_menu_special_step(_period);
            cr_assert(_n.credits_index==1 && global.cr_ui.transition_type=="swipe","credits advances on serialized seven-second interval");
            cr_ui_active("Credits",false);cr_ui_active("Title",true);global.cr_ui.stage=16;
            for(var _c=0;_c<4;_c++){
                cr_assert(!cr_error_eligible(_c<3?4:8,_c,0),"caught rare-event minimum sessions "+string(_c));
                cr_assert(cr_error_eligible(_c<3?5:9,_c,0) && !cr_error_eligible(100,_c,1),"caught rare-event source lottery branch "+string(_c));
            }
            _g.style="demo";bbcr_start_game("story");global.cr_load_transition.stage=16;break;
        case 6:cr_session_beans_check();_g.session_capture="beans";break;
        case 7:
            _g.style="null";_g.progress.flags[4]=false;bbcr_start_game("story","ClassicNull");global.cr_load_transition.stage=16;global.cr_cheat.god=true;
            _g.px=175;_g.pz=55;_g.yaw=0;cr_session_pause_check(false);cr_session_pause_check(true);_g.progress.flags[4]=false;
            var _n=_g.npcs[0];_n.px=175;_n.pz=155;_n.hidden=true;_g.session_voice=cr_npc_sound(_n,_n.params.audBossStart);_g.subtitles=true;
            var _e=_g.sound_instances[array_length(_g.sound_instances)-1],_levels=[];
            for(var _i=0;_i<3;_i++){_g.pz=_n.pz-[25,150,700][_i];cr_audio_update_volume();array_push(_levels,audio_sound_get_gain(_e.handle));}
            cr_assert(_levels[0]>_levels[1]*2 && _levels[1]>_levels[2]*3,"playing final-battle voice follows source spatial attenuation");
            show_debug_message("BBCR_SESSION_VOICE: "+json_stringify(_levels));_g.pz=55;_g.session_capture="caption_world";break;
        case 8:
            audio_sound_set_track_position(_g.session_voice,8);cr_caption_tick(.01);var _capt=global.cr_captions[array_length(global.cr_captions)-1];
            cr_assert(_capt.key!=_capt.meta.keys[0].key,"source additional caption keys advance with real voice playback position");
            var _pos=cr_caption_position(_capt.entry);_g.mirror=true;var _mirror=cr_caption_position(_capt.entry);_g.mirror=false;
            cr_assert(abs(_pos[0]+_mirror[0]-480)<.01 && _pos[2]<1,"positional captions scale with distance and mirror their bearing");
            cr_audio_clear_all();_g.session_capture="caption_cleared";break;
        case 9:
            var _s=_g.null_mode;_s.phase="boss";_s.spawn_timer=10000;_s.blockers=[];var _safe=0,_rejected=0;
            repeat(8){cr_null_spawn_blocker();var _b=_s.blockers[array_length(_s.blockers)-1];for(var _j=0;_j<array_length(_b.dirs);_j++){if(cr_null_blocker_safe(_b,_b.dirs[_j]))_safe++;else _rejected++;}}
            cr_assert(_safe>0 && _rejected>0,"live school traversal admits alternate routes and rejects dead-end blocker edges");
            var _b=_s.blockers[0];_s.blockers=[_b];var _direction=-1;
            for(var _j=0;_j<array_length(_b.dirs);_j++)if(cr_null_blocker_safe(_b,_b.dirs[_j])){_direction=_b.dirs[_j];break;}
            if(_direction>=0){for(var _j=0;_j<array_length(_b.dirs);_j++)if(_b.dirs[_j]!=_direction){var _other=json_parse(json_stringify(_b));_other.active=true;_other.dir=_b.dirs[_j];array_push(_s.blockers,_other);}
                cr_assert(!cr_null_blocker_safe(_b,_direction),"existing temporary barriers prevent blocking the last traversable corridor");}
            else cr_assert(_rejected>0,"junction without an alternate route remains unblocked");
            show_debug_message("BBCR_SESSION_BLOCKERS: "+json_stringify({safe:_safe,rejected:_rejected}));_s.blockers=[];_s.glitch=0;_s.beat=0;_s.hit_time=0;_s.boss_wait=true;_s.warp_seed=123;_g.exit_fx.active=false;_g.session_capture="roar_clear";break;
        case 10:
            _g.null_mode.hit_time=10.5;cr_null_anger_visual();_g.session_capture="roar_low";
            cr_assert(_g.null_mode.warp_phase=="anger" && _g.null_mode.glitch==1,"first-hit source roar begins after 9.5 seconds");break;
        case 11:
            _g.null_mode.hit_time=12.4;cr_null_anger_visual();_g.session_capture="roar_high";
            cr_assert(cr_null_visual_warp(_g.null_mode.glitch,"anger")>2,"roar has a separate visible growing displacement range");break;
        case 12:
            _g.null_mode.hit_time=13;_g.null_mode.beat=0;cr_null_anger_visual();_g.session_capture="roar_reset";cr_assert(_g.null_mode.glitch==0,"roar restores normal room vertices after ramp");break;
        case 13:
            _g.null_mode.beat=1;cr_null_anger_visual();_g.session_capture="beat";cr_assert(cr_null_visual_warp(_g.null_mode.glitch)==.6,"boss beat retains visibly distinct quarter-second displacement");break;
        case 14:
            _g.null_mode.glitch=0;var _s=_g.null_mode;_s.blockers=[];cr_null_spawn_blocker();var _b=_s.blockers[0];_b.active=true;_b.dir=_b.dirs[0];_b.anim_time=0;
            _g.px=_b.x-sin(_b.dir*pi/2)*10;_g.pz=_b.z-cos(_b.dir*pi/2)*10;_g.yaw=_b.dir*pi/2;_g.session_capture="block_start";break;
        case 15:_g.null_mode.blockers[0].anim_time=.125;_g.session_capture="block_middle";break;
        case 16:_g.null_mode.blockers[0].anim_time=.25;_g.session_capture="block_end";break;
        case 17:
            bbcr_start_game("story","ClassicFinale_0");global.cr_load_transition.stage=16;_g.progress.flags[4]=false;_g.px=55;_g.pz=50;_g.yaw=0;cr_secret_route_function(1);_g.session_capture="finale_start";break;
        case 18:case 19:case 20:case 21:case 22:case 23:
            var _at=[12.2,13.7,14.1,62.7,69.8,75][_stage-18];
            audio_sound_set_track_position(_g.secret_route.voice,_at);cr_secret_route_step(.01);_g.session_capture="finale_"+string(_stage-18);
            if(_stage==19)cr_assert(_g.secret_route.visual.warp>8,"actual finale speech clock drives fourth-power room distortion");
            if(_stage==20)cr_assert(_g.secret_route.visual.warp==0,"finale room distortion ends at fourteen seconds");
            if(_stage==21)cr_assert(_g.secret_route.visual.times==4,"serialized finale signals trigger progressive NULL corruption");
            if(_stage==23)cr_assert(_g.secret_route.visual.shake==30 && _g.secret_route.visual.times==18,"late finale corruption targets NULL after all eighteen signals");break;
        case 24:
            _g.dead=true;_g.won=false;_g.progress.flags[4]=false;_g.progress.flags[5]=false;_g.ending={kind:"caught",time:3,phase:1};_g.games_since_error=5;
            var _seed=0;while(true){random_set_seed(_seed);if(cr_error_eligible(5,0))break;_seed++;}
            for(var _i=0;_i<3;_i++){
                if(is_struct(_g.error_event))cr_ui_dispose(_g.error_event.ui);_g.error_event=undefined;_g.style=["classic","party","demo"][_i];_g.mode="story";_g.games_since_error=5;_g.error_count=0;
                random_set_seed(_seed);cr_ending_step(0);
                cr_assert(is_struct(_g.error_event) && _g.games_since_error==0 && _g.error_event.ends==5,"real captured ending dispatch selects rare event for "+_g.style);
            }_g.session_capture="error";break;
        case 25:
            _g.progress.flags[4]=true;cr_ui_dispose(_g.error_event.ui);cr_error_begin();var _e=_g.error_event;cr_error_step(_e.ends+.01);
            cr_assert(_e.phase=="nullend" && _e.start>=15 && _e.start<=30,"post-NULL error selects serialized ending sequence after delay");cr_error_step(_e.start+.01);_g.session_capture="nullend_start";break;
        case 26:
            audio_sound_set_track_position(_g.error_event.voice,16.5);cr_error_step(.01);
            cr_assert(_g.progress.flags[5] && _g.error_event.stage==2,"post-NULL source voice timestamp reveals person and records flag five");_g.session_capture="nullend_person";break;
        case 27:
            _g.style="null";_g.progress.flags[4]=true;bbcr_start_game("story","ClassicGlitch");global.cr_load_transition.stage=16;cr_session_pause_check(true);
            var _n=_g.npcs[0];_g.px=_n.px;_g.pz=_n.pz+25;var _h=cr_npc_sound(_n,_n.params.audBossStart);cr_audio_update_volume();var _near=audio_sound_get_gain(_h);
            _g.pz=_n.pz+200;cr_audio_update_volume();var _far=audio_sound_get_gain(_h);
            cr_assert(_near>_far*2 && _far>0,"actual ClassicGlitch voice instance attenuates independently of interface sounds");break;
        default:show_debug_message("BBCR_SESSION_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
}
