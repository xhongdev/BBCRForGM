/// Only the newly reported roar/beat, animated blockers and finale visuals.
function cr_ne_capture() {
    var _g=global.bbcr,_label=cr_value(_g,"ne_capture","");if(_label=="")return;
    surface_save(global.cr_world_surface,"bbcr_nulleffects_"+_label+".png");_g.ne_capture="";
}
function cr_ne_render_fixture() {
    var _g=global.bbcr;
    if(cr_value(_g,"ne_split_fixture",false)){
        draw_clear(make_color_rgb(7,11,13));draw_clear_depth(1);matrix_set(matrix_world,matrix_build_identity());matrix_set(matrix_view,cr_camera_view(55,50,0));cr_finale_null_draw();return;
    }
    if(!cr_value(_g,"ne_blocker_fixture",false))return;
    draw_clear(make_color_rgb(7,11,13));draw_clear_depth(1);gpu_set_cullmode(cull_noculling);
    matrix_set(matrix_world,matrix_build_identity());matrix_set(matrix_view,cr_camera_view(0,-10,0));
    cr_null_blocker_draw(_g.ne_blocker);
}
function cr_ne_blocker_checks() {
    var _g=global.bbcr,_s=_g.null_mode;_s.phase="boss";_s.spawn_timer=10000;_s.blockers=[];
    cr_null_spawn_blocker();cr_assert(array_length(_s.blockers)==1,"actual junction selection creates a source blocker");
    var _b=_s.blockers[0];_g.px=_b.x;_g.pz=_b.z+30;cr_null_blockers_step(1/60);
    cr_assert(_b.active && _b.anim_time==0 && _b.dir!=0,"source long approach trigger starts animation thirty units before junction and excludes entry");
    cr_null_blockers_step(.125);cr_assert(abs(_b.anim_time-.125)<.001,"blocker animation advances through source quarter-second clip");
    _g.px=-100;_g.pz=-100;cr_null_blockers_step(.9);cr_assert(array_length(_s.blockers)==1,"leaving all source triggers keeps blocker for one second");
    cr_null_blockers_step(.11);cr_assert(array_length(_s.blockers)==0,"source lifetime releases geometry and navigation after departure");
    for(var _variant=0;_variant<array_length(global.cr_null_effects.blockers);_variant++){
        var _fx=global.cr_null_effects.blockers[_variant];
        cr_assert(array_length(_fx.frames)==31 && _fx.length==.25 && array_length(_fx.colliders)==1,"source animation frames and blocking MeshCollider imported "+string(_variant));
        for(var _dir=0;_dir<4;_dir++){
            _b={x:175,z:75,active:true,dir:_dir,effect:_fx};_s.blockers=[_b];var _a=_dir*pi/2;
            cr_assert(cr_null_blocks(175+sin(_a)*5,75+cos(_a)*5,2) && !cr_null_blocks(175-sin(_a)*5,75-cos(_a)*5,2),"blocking quad faces same corridor as animation "+string(_variant)+":"+string(_dir));
        }
    }
    // Real player movement at an unobstructed imported junction must stop at
    // the blocker plane rather than merely returning true from a fixture ray.
    _s.blockers=[];cr_null_spawn_blocker();_b=_s.blockers[0];_b.active=true;_b.dir=_b.dirs[0];_b.anim_time=.25;
    _g.px=_b.x;_g.pz=_b.z;var _a=_b.dir*pi/2;repeat(100)cr_move(_g,sin(_a)*.1,cos(_a)*.1,2);
    var _travel=(_g.px-_b.x)*sin(_a)+(_g.pz-_b.z)*cos(_a);
    cr_assert(_travel>1 && _travel<3.1,"player capsule physically stops before completed blocker");
    show_debug_message("BBCR_NULLEFFECTS_BLOCK: "+string(_travel));_s.blockers=[];
}
function cr_ne_step() {
    var _g=global.bbcr;if(!variable_struct_exists(_g,"ne_stage")){_g.ne_stage=0;global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;}
    var _stage=_g.ne_stage,_dt=delta_time/1000000;cr_audio_update_volume();
    if(_stage==0){
        _g.style="null";_g.progress.flags[4]=false;_g.reduce_flashing=false;bbcr_start_game("story","ClassicNull");global.cr_load_transition.stage=16;
        _g.px=175;_g.pz=55;_g.yaw=0;_g.time=0;_g.exit_fx.active=false;_g.npcs[0].hidden=true;global.cr_cheat.god=true;
        _g.null_mode.phase="intro";cr_null_music_play("BossIntro",0,false);cr_null_hit();_g.ne_sample=0;_g.ne_capture="roar_before";_g.ne_wait_draw=true;
    }else if(_stage==1){
        var _s=_g.null_mode;cr_npc_voice_tick(_g.npcs[0]);cr_null_music_step(_dt);
        var _times=[9.6,10.5,11.5,12.4,12.6];if(_g.ne_sample<5 && _s.hit_time>=_times[_g.ne_sample]){
            var _i=_g.ne_sample;_g.ne_capture="roar_"+string(_i);
            cr_assert((_i==4 && _s.glitch==0) || (_i<4 && _s.warp_phase=="anger" && _s.glitch>0),"live first-hit voice phase enters and leaves ramp "+string(_i));
            cr_assert(audio_is_playing(_g.npcs[0].voice),"roar envelope is visible while first-hit voice is actually playing "+string(_i));
            show_debug_message("BBCR_NULLEFFECTS_ROAR: "+json_stringify({time:_s.hit_time,intensity:_s.glitch,world:cr_null_visual_warp(_s.glitch,_s.warp_phase)}));_g.ne_sample++;
        }
        if(_s.hit_time<13)return;
        cr_audio_clear_all();_s.phase="boss";_s.hit_time=30;_s.boss_wait=false;_s.intro_done=true;_s.track_tempo=1;_s.beat=0;cr_null_anger_visual();_g.ne_capture="beat_clear";
    }else if(_stage>=2 && _stage<=4){
        var _s=_g.null_mode,_marker=global.cr_ui_data.boss_music.beats[4],_age=[0,.1,.26][_stage-2];
        cr_null_beat_sample(_marker+_age);cr_null_anger_visual();_s.warp_seed=123;
        _g.ne_capture="beat_"+string(_stage-2);
        cr_assert(abs(cr_null_visual_warp(_s.glitch)-max(0,1-_age*4)*.6)<.001,"beat visibility retains source quarter-second decay "+string(_stage));
    }else if(_stage==5){
        _g.reduce_flashing=true;cr_assert(cr_null_visual_warp(9,"anger")<=.12 && cr_null_visual_warp(3,"beat")<.1,"reduced flashing retains a separate low-motion option");_g.reduce_flashing=false;
        cr_ne_blocker_checks();_g.exit_fx.active=false;_g.null_mode.glitch=0;_g.null_mode.color_glitch=0;_g.ne_blocker_fixture=true;
        _g.ne_blocker={x:0,z:0,dir:0,effect:global.cr_null_effects.blockers[0],anim_time:0};
    }else if(_stage>=6 && _stage<24){
        var _i=floor((_stage-6)/3),_frame=(_stage-6) mod 3;
        _g.ne_blocker={x:0,z:0,dir:0,effect:global.cr_null_effects.blockers[_i],anim_time:_frame*.125};
        _g.ne_capture="block_"+string(_i)+"_"+string(_frame);
    }else if(_stage==24){
        _g.ne_blocker_fixture=false;bbcr_start_game("story","ClassicFinale_0");global.cr_load_transition.stage=16;_g.progress.flags[4]=false;
        _g.px=55;_g.pz=50;_g.yaw=0;_g.time=0;cr_secret_route_function(1);_g.ne_sample=0;_g.ne_capture="finale_initial";
        cr_assert(audio_is_playing(_g.secret_route.voice),"real finale Timeline starts its source speech clock");
    }else if(_stage==25){
        cr_secret_route_step(_dt);var _s=_g.secret_route,_v=_s.visual;
        var _times=[11.9,12.3,13,13.8,14.1,60.9,62.7,68.6,69.8,72,75,77.83];
        if(_g.ne_sample<12 && (_s.time>=_times[_g.ne_sample] || _s.finished)){
            var _i=_g.ne_sample;_g.ne_capture="finale_"+string(_i);
            show_debug_message("BBCR_NULLEFFECTS_FINALE: "+json_stringify({sample:_i,time:_s.time,warp:_v.warp,signals:_v.times,shake:_v.shake,alpha:_v.alpha,finished:_s.finished,audio:audio_is_playing(_s.voice)}));
            if(_i==0 || _i==4)cr_assert(_v.warp==0,"finale room outside 12-14 seconds restores unwarped vertices "+string(_i));
            if(_i>=1 && _i<=3)cr_assert(abs(_v.warp-power(_s.time-12,4))<.001,"finale speech clock drives exact fourth-power ramp "+string(_i));
            if(_i==6)cr_assert(_v.times==4 && _v.shake==1,"four serialized Timeline signals progressively disturb NULL");
            if(_i>=8 && _i<=10)cr_assert(_v.shake==30 && _v.times==18 && _v.warp==0,"late NULL disintegration is isolated from room geometry "+string(_i));
            if(_i==11)cr_assert(_s.finished && _g.progress.flags[4],"Timeline completion removes NULL and records route completion");
            _g.ne_sample++;
        }
        if(_g.ne_sample<12)return;
    }else if(_stage==26){
        _g.secret_route.active=false;_g.ne_capture="finale_empty";
    }else if(_stage>=27 && _stage<=29){
        // Hold the translated center fixed only in this rendering fixture to
        // distinguish real chunk/alpha breakup from moving a whole sprite away.
        _g.ne_split_fixture=true;var _v=_g.secret_route.visual;_v.time=72;_v.warp=0;_v.offset=[0,0,0];_v.seed=123;
        _v.chunk=_stage>27;_v.threshold=.2;_v.full_threshold=.6;_v.alpha=_stage>27;_v.color_on=true;_v.color=[0,.3,.8][_stage-27];_v.tiling=[1,1];_v.uv_offset=[0,0];
        _g.ne_capture="split_"+string(_stage-27);
    }else{
        show_debug_message("BBCR_NULLEFFECTS_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();return;
    }
    _g.ne_stage++;
}
