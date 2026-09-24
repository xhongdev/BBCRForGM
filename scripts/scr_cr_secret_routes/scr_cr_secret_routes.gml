function cr_secret_load(_next) {
    bbcr_start_game("story",_next);
    var _u=global.cr_load_transition;_u.previous=surface_create(480,360);surface_set_target(_u.previous);draw_clear(c_black);surface_reset_target();_u.stage=0;_u.interval=.01666667;_u.timer=_u.interval;
}
function cr_secret_route_init() {
    var _g=global.bbcr;
    _g.secret_route={manager:global.cr_map.manager,time:0,lights:false,spawned:false,active:false,voice:-1,finished:false,book_page:0,book_spec:undefined,audio_cues:[]};
    if(global.cr_map.manager=="ClassicFinaleManager")cr_finale_visual_init();
    _g.items_disabled=true;_g.inventory=["","",""];_g.mirror=false;_g.lightsout=false;_g.hard=false;
    for(var _i=0;_i<array_length(global.cr_map.triggers);_i++){var _t=global.cr_map.triggers[_i];_t.entered=false;_t.on=cr_value(_t,"start_on",false);_t.press_time=0;}
    for(var _i=0;_i<array_length(global.cr_map.lockdowns);_i++){var _l=global.cr_map.lockdowns[_i];_l.height=0;_l.target=0;_l.voice=-1;}
    if(global.cr_map.manager=="ClassicBasementManager")for(var _i=0;_i<array_length(_g.doors);_i++){
        var _d=_g.doors[_i];if(_d.x>=8 && _d.x<15 && _d.z>=14 && _d.z<24)_d.lock=1000000;
    }
    if(global.cr_map.manager=="ClassicBasementManager"){
        _g.exit_fx.active=true;
        for(var _i=0;_i<array_length(global.cr_map.lights);_i++){var _p=global.cr_map.lights[_i].position;if(_p.x>=8 && _p.x<15 && _p.z>=14 && _p.z<24)_g.exit_fx.on[_i]=false;}
        _g.exit_fx.dirty=true;
    }
}
function cr_secret_trigger_function(_t) {
    return cr_value(_t.fields,"functionIndexVal",cr_value(_t.fields,"functionToTrigger",cr_value(_t.fields,"functionIndex",-1)));
}
function cr_secret_route_interact() {
    var _g=global.bbcr,_best=global.cr_catalog.movement.reach,_index=-1;
    for(var _i=0;_i<array_length(global.cr_map.triggers);_i++){
        var _t=global.cr_map.triggers[_i];if(_t.script!="ClickableSpecialFunctionTrigger" && _t.script!="SpecialManagerFunction" && _t.script!="GameLever" && _t.script!="GameButton")continue;
        for(var _j=0;_j<array_length(_t.boxes);_j++){var _d=cr_ray_box(_t.boxes[_j],_g.px,5,_g.pz,sin(_g.yaw),cos(_g.yaw));if(_d<_best){_best=_d;_index=_i;}}
        for(var _j=0;_j<array_length(_t.spheres);_j++){
            var _sp=_t.spheres[_j],_dx=_g.px-_sp.position[0],_dz=_g.pz-_sp.position[2],_b=_dx*sin(_g.yaw)+_dz*cos(_g.yaw),_disc=sqr(_b)-sqr(_dx)-sqr(_dz)+sqr(_sp.radius);
            if(_disc>=0){var _d=-_b-sqrt(_disc);if(_d>=0 && _d<_best){_best=_d;_index=_i;}}
        }
    }
    if(_index<0)return false;var _trigger=global.cr_map.triggers[_index];
    if(_trigger.press_time>0)return true;
    if(_trigger.script=="GameLever")_trigger.on=!_trigger.on;
    if(_trigger.script=="GameButton"){_trigger.on=true;_trigger.press_time=_trigger.reset;}
    if(variable_struct_exists(_trigger,"sound"))cr_sound(_trigger.on?_trigger.sound:_trigger.release);
    if(variable_struct_exists(_trigger,"receivers"))for(var _j=0;_j<array_length(_trigger.receivers);_j++){
        var _r=_trigger.receivers[_j];if(_r.type==1 && _r.receiverIndex<array_length(global.cr_map.lockdowns)){
            var _l=global.cr_map.lockdowns[_r.receiverIndex];_l.target=_l.target>0?0:_l.original_height;_l.voice=cr_sound(_l.loop);if(_l.voice>=0)audio_sound_loop(_l.voice,true);
        }
    }
    if(cr_value(_trigger.fields,"triggerSpecialManagerFunction",true))cr_secret_route_function(cr_secret_trigger_function(_trigger),_trigger);return true;
}
function cr_secret_route_function(_id,_trigger=undefined) {
    var _g=global.bbcr,_s=_g.secret_route,_data=global.cr_map.secret_manager;
    if(_s.manager=="ClassicFinaleManager"){
        if(_id==0)cr_secret_book_open(_data.book);
        if(_id==1 && !_s.active){
            _s.active=true;_s.time=0;
            if(!_g.progress.flags[4]){
                for(var _i=0;_i<array_length(_data.audio_timeline);_i++)array_push(_s.audio_cues,{spec:_data.audio_timeline[_i],started:false,handle:-1,stopped:false});
                cr_finale_audio_step();
            }
        }
        return;
    }
    switch(_id){
        case 0:
            _s.lights=!_s.lights;for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(_d.x>=8 && _d.x<15 && _d.z>=14 && _d.z<24){_d.lock=_s.lights?0:1000000;_d.locked=!_s.lights;}}
            for(var _i=0;_i<array_length(global.cr_map.lights);_i++){var _p=global.cr_map.lights[_i].position;if(_p.x>=8 && _p.x<15 && _p.z>=14 && _p.z<24)_g.exit_fx.on[_i]=_s.lights;}_g.exit_fx.dirty=true;break;
        case 1:
            var _index=is_undefined(_trigger)?0:real(string_copy(cr_value(_trigger,"object","00"),1,2));cr_secret_book_open(_data.books[clamp(_index,0,array_length(_data.books)-1)]);break;
        case 3:
            if(_s.spawned || _s.active)return;_s.spawned=true;
            if(!_g.progress.flags[4]){_s.voice=cr_sound(_data.speech);for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].x>=8 && _g.doors[_i].x<15 && _g.doors[_i].z>=14 && _g.doors[_i].z<24)_g.doors[_i].lock=1000000;}
            else {cr_voice_clear();cr_queue(_data.sounds.audBaldiIntro);cr_queue(_data.sounds.audBaldiLoop);cr_voice_tick();}break;
        case 4:
            if(!_g.progress.flags[4])return;_s.active=true;cr_voice_clear();cr_queue(_data.sounds.audBaldiScream);cr_queue(_data.sounds.audBaldiEnd);cr_voice_tick();break;
    }
}
function cr_secret_book_open(_name) {
    var _g=global.bbcr;cr_ui_dispose(global.cr_math_ui);global.cr_math_ui=cr_ui_context(_name);_g.secret_route.book_page=0;
    var _u=global.cr_math_ui;for(var _i=0;_i<array_length(_u.nodes);_i++)if(variable_struct_exists(_u.nodes[_i].scripts,"ClassicMathBook"))_g.secret_route.book_spec=_u.nodes[_i].scripts.ClassicMathBook;
    var _old=global.cr_ui;global.cr_ui=_u;cr_ui_transition(.01666667);_u.reveal=true;global.cr_ui=_old;
    _g.scene="secretbook";audio_pause_all();_g.math_audio_paused=true;window_mouse_set_locked(false);
}
function cr_secret_book_turn(_forward) {
    var _s=global.bbcr.secret_route,_b=_s.book_spec;_s.book_page=clamp(_s.book_page+(_forward?1:-1),0,array_length(_b.openContents));
    cr_ui_node(_b.bookRenderer).image_override=_s.book_page>0?_b.openBook:_b.closedBook;
    for(var _i=0;_i<array_length(_b.openContents);_i++)cr_ui_active(_b.openContents[_i],_i==_s.book_page-1);
    cr_ui_active(_b.coverContents,_s.book_page==0);cr_sound(_b.audTurn,undefined,undefined,true);
}
function cr_secret_book_close() {
    var _id=global.bbcr.secret_route.book_spec.closeSpecialFunctionId;cr_null_pad_close();cr_secret_route_function(_id);
}
function cr_secret_route_step(_dt) {
    var _g=global.bbcr,_s=_g.secret_route,_data=global.cr_map.secret_manager;_s.time+=_dt;_g.stamina=200;
    for(var _i=0;_i<array_length(global.cr_map.triggers);_i++){var _t=global.cr_map.triggers[_i];if(_t.press_time>0){_t.press_time=max(0,_t.press_time-_dt);if(_t.press_time==0){_t.on=false;cr_sound(_t.release);}}}
    for(var _i=0;_i<array_length(global.cr_map.lockdowns);_i++){
        var _l=global.cr_map.lockdowns[_i];if(_l.height==_l.target)continue;
        _l.height+=clamp(_l.target-_l.height,-_l.speed*_dt,_l.speed*_dt);
        if(_l.height==_l.target){if(audio_is_playing(_l.voice))audio_stop_sound(_l.voice);_l.voice=cr_sound(_l.end);}
    }
    for(var _i=0;_i<array_length(global.cr_map.triggers);_i++){
        var _t=global.cr_map.triggers[_i];if(_t.script!="SpecialManagerFunctionTrigger")continue;
        var _inside=cr_exit_contact(_t.boxes);for(var _j=0;_j<array_length(_t.spheres);_j++){var _b=_t.spheres[_j];if(point_distance(_g.px,_g.pz,_b.position[0],_b.position[2])<_b.radius+2)_inside=true;}
        if(_inside && !_t.entered)cr_secret_route_function(cr_secret_trigger_function(_t),_t);_t.entered=_inside;
    }
    if(_s.manager=="ClassicBasementManager"){
        if(_s.spawned && !_g.progress.flags[4] && !audio_is_playing(_s.voice)){if(_data.quit)game_end();}
        if(_s.active && !audio_is_playing(_g.voice) && array_length(_g.voice_queue)==0)cr_return_menu();
    }else if(_s.active && !_s.finished){
        // Use the primary Timeline clip's sample clock so effects cannot drift
        // away from the speech during slow frames or after pausing the book.
        if(audio_is_playing(_s.voice))_s.time=audio_sound_get_track_position(_s.voice);
        cr_finale_audio_step();cr_finale_visual_step();
        if(_s.time>=_data.duration){_s.finished=true;_g.games_since_error=0;cr_finale_visual_step();cr_progress_complete_null();}
    }
}
function cr_finale_audio_step() {
    var _s=global.bbcr.secret_route;
    for(var _i=0;_i<array_length(_s.audio_cues);_i++){
        var _cue=_s.audio_cues[_i],_spec=_cue.spec,_elapsed=_s.time-_spec.start;
        if(!_cue.started && _elapsed>=0){
            _cue.started=true;
            if(_elapsed<_spec.duration){
                _cue.handle=cr_sound(_spec.key);audio_sound_set_track_position(_cue.handle,_spec.clip_in+_elapsed*_spec.speed);audio_sound_pitch(_cue.handle,_spec.speed);
                if(_spec.start==0)_s.voice=_cue.handle;
            }
        }
        if(_cue.started && !_cue.stopped && _elapsed>=_spec.duration){if(audio_is_playing(_cue.handle))audio_stop_sound(_cue.handle);_cue.stopped=true;}
    }
}
function cr_secret_route_draw() {
    var _g=global.bbcr,_s=_g.secret_route;if(!is_struct(_s))return;var _d=global.cr_map.secret_manager;
    for(var _i=0;_i<array_length(global.cr_map.triggers);_i++){var _t=global.cr_map.triggers[_i];if(variable_struct_exists(_t,"geometry")){var _c=_t.on?_t.on_color:_t.off_color;cr_geometry_draw(_t.geometry,_t.on?_t.on_texture:_t.off_texture,make_color_rgb(_c[0],_c[1],_c[2]));}}
    for(var _i=0;_i<array_length(global.cr_map.lockdowns);_i++){var _l=global.cr_map.lockdowns[_i];cr_demo_geometry_at(_l.geometry,0,_l.height-_l.original_height,0);}
    if(_s.manager=="ClassicBasementManager"){
        cr_demo_geometry_at(_d.water,0,0,-(_s.time*5) mod 50);cr_geometry_draw(_d.machine);
        if(_g.progress.flags[4])cr_geometry_draw(_s.active?_d.exploded:_d.normal);
        else if(_s.spawned)cr_geometry_draw(_d.null);
    }else if(_s.active && !_s.finished){if(_g.progress.flags[4])cr_geometry_draw(_d.thanks);else cr_finale_null_draw();}
}
