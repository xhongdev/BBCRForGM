/// Isolated tests for finale presentation, locked-door sound and boss music.
function cr_ff_capture() {
    var _g=global.bbcr,_label=cr_value(_g,"ff_capture","");if(_label=="")return;
    screen_save("bbcr_finalfeedback_"+_label+".png");
    if(_g.scene=="secretbook")surface_save(global.cr_math_ui.surface,"bbcr_finalfeedback_"+_label+"_ui.png");
    _g.ff_capture="";
}
function cr_ff_step() {
    var _g=global.bbcr;
    if(!variable_struct_exists(_g,"ff_stage")){_g.ff_stage=0;global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;}
    var _stage=_g.ff_stage;
    if(_stage==0){
        _g.style="null";_g.progress.flags[4]=false;bbcr_start_game("story","ClassicNull");global.cr_load_transition.stage=16;
        global.cr_cheat.god=true;_g.npcs[0].hidden=true;
        var _door=undefined;for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].swing && _g.doors[_i].locked){_door=_g.doors[_i];break;}
        _g.px=_door.cx;_g.pz=_door.cz;_g.notebooks=0;var _count=array_length(_g.sound_instances);
        repeat(300)cr_doors_step(1/60);
        var _open=0,_locked=0,_need=0;for(var _i=_count;_i<array_length(_g.sound_instances);_i++){var _key=_g.sound_instances[_i].key;if(_key=="Doors_Swinging")_open++;if(_key=="Doors_StandardLocked")_locked++;if(_key==_door.need_sound)_need++;}
        cr_assert(_open==0 && _locked==0 && _door.open==0,"locked yellow trigger plays no repeated opening/locked sound over 300 frames");
        cr_assert(_need==1,"same contact retains one two-notebook reminder");
        _door.locked=false;_g.notebooks=2;_count=array_length(_g.sound_instances);repeat(300)cr_doors_step(1/60);_open=0;
        for(var _i=_count;_i<array_length(_g.sound_instances);_i++)if(_g.sound_instances[_i].key=="Doors_Swinging")_open++;
        cr_assert(_open==1 && _door.open>0,"unlocked trigger opens once and renews its timer while occupied");
        _g.null_mode.phase="intro";_g.null_mode.stun=999999;cr_null_music_play("BossIntro",2,false);
        cr_assert(audio_is_playing(_g.game_music) && audio_is_playing(_g.null_mode.drum_track),"intro plays separate melodic and drum buses");
        _g.ff_start=current_time;_g.ff_position=cr_null_music_position();
        _g.ff_wait_draw=true;
    }else if(_stage==1){
        if(current_time-_g.ff_start<1200){cr_null_music_step(delta_time/1000000);return;}
        var _s=_g.null_mode,_elapsed=(current_time-_g.ff_start)/1000,_advance=cr_null_music_position()-_g.ff_position;
        cr_assert(abs(_advance-_elapsed*global.cr_map.null_mode.music_speed)<.15,"intro sample clock advances at serialized tempo");
        var _rows=[];_s.phase="boss";_s.intro_done=true;_s.boss_wait=false;_s.hit_time=30;
        for(var _hp=9;_hp>=1;_hp--){
            _s.health=_hp;_s.music_speed=global.cr_map.null_mode.music_speed+(9-_hp)*global.cr_map.null_mode.music_increment;
            cr_null_music_play("BossLoop",5,true);
            array_push(_rows,{hp:_hp,speed:_s.track_tempo,position:cr_null_music_position()});
            cr_assert(abs(cr_null_music_position()-5)<.05 && audio_sound_get_pitch(_g.game_music)==1 && audio_sound_get_pitch(_s.drum_track)==1,"HP "+string(_hp)+" tempo switch retains source position and pitch");
        }
        show_debug_message("BBCR_FINALFEEDBACK_TEMPOS: "+json_stringify(_rows));
        _g.px=175;_g.pz=55;_g.npcs[0].px=175;
        var _mix=[];for(var _i=0;_i<3;_i++){_g.npcs[0].pz=55+75+75*_i;cr_null_music_mix(0);cr_audio_update_volume();array_push(_mix,_s.drum_gain);}
        cr_assert(_mix[0]==1 && abs(_mix[1]-.5)<.001 && _mix[2]==0,"drum channel follows source 75 to 225-unit distance fade");
        var _mel=undefined;for(var _i=0;_i<array_length(_g.sound_instances);_i++)if(_g.sound_instances[_i].handle==_g.game_music)_mel=_g.sound_instances[_i];
        cr_assert(_mel.mix==0 && audio_is_playing(_g.game_music),"one HP stops new melodic audio while retaining a live synchronized clock");
        cr_assert(array_length(_s.hold_tracks)>0,"one HP retains the sounding source notes instead of abruptly silencing them");
        var _holding=true;for(var _i=0;_i<array_length(_s.hold_tracks);_i++)if(!audio_is_playing(_s.hold_tracks[_i]) || audio_sound_get_pitch(_s.hold_tracks[_i])!=1)_holding=false;
        cr_assert(_holding,"held source SoundFont notes play as sustained voices at unchanged pitch");
        show_debug_message("BBCR_FINALFEEDBACK_HOLD: "+string(array_length(_s.hold_tracks)));
        _g.npcs[0].pz=55;cr_null_music_mix(0);cr_assert(_s.drum_gain==1 && audio_is_playing(_s.drum_track),"one HP keeps the source drum channel audible");
        var _beat=global.cr_ui_data.boss_music.beats[4];
        cr_null_beat_sample(_beat+.1*_s.track_tempo);cr_assert(abs(_s.beat-.6)<.001,"late frame ages pulse from audio time instead of restarting it");
        cr_null_beat_sample(_beat+.27*_s.track_tempo);cr_assert(_s.beat==0,"pulse expires after source quarter-second decay");
        cr_assert(cr_null_visual_warp(3)<=.07501 && cr_null_visual_warp(9)<=.18001,"normal and anger warp have bounded world displacement");
        _s.projectiles=[];_g.px=175;_g.pz=55;_g.yaw=0;_s.glitch=0;_g.exit_fx.active=false;_g.ff_stage=2;return;
    }else if(_stage>=2 && _stage<=17){
        var _i=floor((_stage-2)/4),_mode=floor(((_stage-2) mod 4)/2),_high=(_stage mod 2)==0,_s=_g.null_mode;
        _g.time=_high?pi/10:3*pi/10;_g.px=175;_g.pz=55;_g.yaw=0;_s.projectiles=[];
        cr_null_spawn_projectile(175,65);var _p=_s.projectiles[0];_p.spec=global.cr_map.null_mode.projectiles[_i];_p.state=_mode==0?"idle":"held";_p.z=_mode==0?65:59;_s.held=_mode==0?-1:0;
        cr_assert(_p.spec.bob,"source projectile visual uses PickupBob "+string(_i)+":"+string(_mode));
        _g.ff_capture="projectile_"+string(_i)+"_"+string(_mode)+"_"+string(_high?"high":"low");
    }else switch(_stage){
        case 18:
            bbcr_start_game("story","ClassicFinale_0");global.cr_load_transition.stage=16;_g.progress.flags[4]=false;
            _g.px=41.5;_g.pz=70;_g.yaw=0;_g.time=pi/10;_g.ff_capture="book_high";
            cr_assert(array_length(global.cr_map.rotators)==1 && global.cr_map.rotators[0].speed==30,"finale fan imports source Spinner target and speed");break;
        case 19:_g.time=3*pi/10;_g.ff_capture="book_low";break;
        case 20:_g.px=55;_g.pz=55;_g.time=0;_g.ff_capture="fan_a";break;
        case 21:_g.time=1;_g.ff_capture="fan_b";break;
        case 22:
            _g.px=41.5;_g.pz=70;cr_interact();cr_assert(_g.scene=="secretbook","real book collider opens finale reading UI");global.cr_math_ui.stage=16;_g.ff_capture="cover";break;
        case 23:case 24:case 25:
            var _old=global.cr_ui;global.cr_ui=global.cr_math_ui;cr_secret_book_turn(true);global.cr_ui=_old;
            _g.ff_capture="page_"+string(_stage-22);break;
        case 26:
            cr_secret_book_close();global.cr_math_ui.stage=16;
            cr_assert(_g.scene=="game" && _g.secret_route.active && audio_is_playing(_g.secret_route.voice),"closing book starts real Timeline speech at time zero");
            var _cue=_g.secret_route.audio_cues[0];cr_assert(_cue.spec.key=="FinaleTimeline_Null_Final" && _cue.spec.volume==1 && !_g.math_audio_paused,"Timeline audible clip is independent of muted subtitle SoundObject");
            _g.ff_start=current_time;_g.ff_voice=_cue.handle;_g.ff_capture="speaker";break;
        case 27:
            cr_secret_route_step(min(delta_time/1000000,.1));
            if(current_time-_g.ff_start<1500)return;
            cr_assert(audio_is_playing(_g.ff_voice) && audio_sound_get_track_position(_g.ff_voice)>1,"finale voice actually advances after leaving reading mode");
            _g.secret_route.time=11.5;cr_finale_audio_step();cr_assert(_g.secret_route.audio_cues[1].started && audio_is_playing(_g.secret_route.audio_cues[1].handle),"secondary Timeline clip starts at source cue");
            break;
        case 28:
            bbcr_start_game("story","ClassicNull");global.cr_load_transition.stage=16;global.cr_math_ui.stage=16;
            _g.px=175;_g.pz=55;_g.yaw=0;_g.time=0;_g.exit_fx.active=false;_g.npcs[0].hidden=true;
            _g.null_mode.glitch=0;_g.null_mode.warp_seed=17;_g.ff_capture="warp_clear";break;
        case 29:_g.null_mode.glitch=3;_g.ff_capture="warp_beat";break;
        case 30:_g.null_mode.glitch=9;_g.ff_capture="warp_anger";break;
        case 31:
            var _s=_g.null_mode;_s.phase="boss";_s.health=8;_s.intro_done=true;_s.boss_wait=false;_s.hit_time=30;
            _s.music_speed=global.cr_map.null_mode.music_speed+global.cr_map.null_mode.music_increment;
            cr_null_music_play("BossLoop",global.cr_ui_data.boss_music.beats[4]-.1,true);
            _g.ff_start=current_time;_g.ff_max_skew=0;_g.ff_beat_samples=0;_g.ff_errors=0;break;
        case 32:
            var _s=_g.null_mode;cr_null_music_step(delta_time/1000000);
            var _pos=cr_null_music_position(),_last=-100,_beats=global.cr_ui_data.boss_music.beats;
            for(var _i=0;_i<array_length(_beats);_i++){if(_beats[_i]>_s.beat_position)break;_last=_beats[_i];}
            var _expected=max(0,1-(_s.beat_position-_last)/_s.track_tempo*4);
            if(abs(_s.beat-_expected)>.001)_g.ff_errors++;
            _g.ff_max_skew=max(_g.ff_max_skew,abs(audio_sound_get_track_position(_g.game_music)-audio_sound_get_track_position(_s.drum_track)));
            _g.ff_beat_samples++;
            if(current_time-_g.ff_start<1600)return;
            cr_assert(_g.ff_errors==0 && _g.ff_beat_samples>15,"actual playing audio clocks drive beat envelope on every sampled frame");
            cr_assert(_g.ff_max_skew<.06,"live melodic/drum stems remain synchronized within one audio buffer");
            show_debug_message("BBCR_FINALFEEDBACK_SYNC: "+json_stringify({frames:_g.ff_beat_samples,skew:_g.ff_max_skew}));
            show_debug_message("BBCR_FINALFEEDBACK_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();return;
    }
    _g.ff_stage++;
}
