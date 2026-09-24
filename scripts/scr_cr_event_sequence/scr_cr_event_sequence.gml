/// Serialized material parameters and coroutine stages. Shader noise is rebuilt
/// because the AssetRipper shader programs are placeholders, not source code.
function cr_event_effect() {
    return {seed:random(4096),color:false,alpha:false,chunk:false,scramble:false,percent:0,threshold:1,full:1,tile:[1,1,0,0],shift:0};
}
function cr_event_image_draw(_node,_key,_rect,_color) {
    var _sprite=cr_sprite(_key);if(_sprite<0){cr_ui_fill(_rect,_color);return;}
    var _f=_node.event_effect,_uv=sprite_get_uvs(_sprite,0);
    shader_set(shd_cr_event);
    shader_set_uniform_f(shader_get_uniform(shd_cr_event,"u_rect"),_uv[0],_uv[1],_uv[2],_uv[3]);
    shader_set_uniform_f(shader_get_uniform(shd_cr_event,"u_tile"),_f.tile[0],_f.tile[1],_f.tile[2],_f.tile[3]);
    shader_set_uniform_f(shader_get_uniform(shd_cr_event,"u_flags"),_f.color,_f.alpha,_f.chunk,_f.scramble);
    shader_set_uniform_f(shader_get_uniform(shd_cr_event,"u_values"),_f.seed,_f.percent,_f.threshold,_f.full);
    shader_set_uniform_f(shader_get_uniform(shd_cr_event,"u_shift"),_f.shift);
    cr_ui_image(_key,_rect,_color);shader_reset();
}
function cr_error_new_glitch(_e) {
    var _f=cr_event_effect();
    do {_e.tile=irandom(3)==0;_e.tile_flicker=irandom(7)!=0;_f.color=irandom(1)==0;_f.chunk=irandom(1)==0;_f.scramble=irandom(3)==0;}
    until(_e.tile || _f.color || _f.chunk || _f.scramble);
    _f.color=_f.color || _f.chunk || _f.scramble;_f.percent=random_range(.2,.75);_f.threshold=random(.75);_f.full=random_range(_f.threshold,1);
    _e.tile_values=[random_range(-960,960),random_range(-720,720),random_range(-960,960),random_range(-720,720)];
    if(_e.tile)_f.tile=_e.tile_values;
    cr_ui_node("CoreGameManager/ErrorScreen/Canvas/BG").event_effect=_f;
    _e.next_glitch=_e.time+random_range(.2,10);
    var _text=cr_ui_node(global.cr_session_data.error.errorTmp);
    for(var _i=0;_i<array_length(_text.graphics);_i++){
        var _graphic=_text.graphics[_i];if(_graphic.type!="text")continue;
        _graphic.layout.atlas=global.cr_ui_data.fonts[$ global.cr_session_data.error.errorFontUsed].file;
        for(var _j=0;_j<array_length(_graphic.layout.quads);_j++){
            var _q=_graphic.layout.quads[_j];_q[0]=irandom(255);_q[1]=irandom(255);_q[2]=irandom(49);_q[3]=irandom(49);_q[6]=irandom_range(10,39);_q[7]=irandom_range(10,39);
        }
    }
}
function cr_error_glitch_step(_e,_dt) {
    var _old=global.cr_ui;global.cr_ui=_e.ui;
    if(!cr_value(_e,"glitch_started",false)){
        _e.glitch_started=true;cr_error_new_glitch(_e);
        if(audio_is_playing(_e.voice))audio_stop_sound(_e.voice);
        _e.voice=cr_sound("ErrorGlitch",undefined,undefined,true,undefined,undefined,true,undefined,true);
        audio_sound_pitch(_e.voice,random_range(.01,1.5));cr_audio_loop(_e.voice,true);
    }
    if(_e.time>=_e.next_glitch)cr_error_new_glitch(_e);
    var _f=cr_ui_node("CoreGameManager/ErrorScreen/Canvas/BG").event_effect;
    if(_e.tile && _e.tile_flicker && random(1)<=.05){if(random(1)<=.9)_f.tile=_e.tile_values;else {_e.tile_values[0]=random_range(-960,960);_e.tile_values[1]=random_range(-720,720);}}
    if(!_e.tile)_f.tile=[1,1,0,0];global.cr_ui=_old;
}
function cr_nullend_begin(_e) {
    if(audio_is_playing(_e.voice))audio_stop_sound(_e.voice);
    cr_ui_dispose(_e.ui);cr_audio_clear_all();
    _e.ui=cr_ui_context("NullEnd");_e.phase="nullend";_e.time=0;_e.start=random_range(15,30);_e.stage1=random_range(1,7);_e.stage=0;_e.voice=-1;_e.spoop_time=0;_e.snippets=[undefined,undefined,undefined];_e.notes=[];
    var _old=global.cr_ui;global.cr_ui=_e.ui;var _s=global.cr_session_data.null_end,_f=cr_event_effect();
    _f.color=true;_f.alpha=true;_f.chunk=true;_f.percent=.5;_f.threshold=.4;
    cr_ui_node(_s.pic).event_effect=_f;cr_ui_node(_s.person).event_effect=cr_event_effect();global.cr_ui=_old;
}
function cr_nullend_snippet(_e,_mode,_slot,_key,_pitch,_duration,_offset) {
    var _previous=_e.snippets[_slot];if(is_struct(_previous) && audio_is_playing(_previous.handle))audio_stop_sound(_previous.handle);
    if(_key=="" || !variable_struct_exists(global.cr_catalog.sounds,_key))return;
    var _play=_key,_reverse=_pitch<0,_bank=global.cr_session_data.event_audio.reverse;
    if(_reverse && variable_struct_exists(_bank,_key))_play=_bank[$ _key];else _reverse=false;
    var _handle=cr_sound(_play,undefined,undefined,true,undefined,undefined,true,undefined,true);if(_handle<0)return;
    var _length=audio_sound_length(_handle),_rate=max(.01,abs(_pitch));
    audio_sound_pitch(_handle,_rate);
    var _entry=global.bbcr.sound_instances[array_length(global.bbcr.sound_instances)-1];_entry.mix=random(1);cr_sound_apply(_entry);
    // The decompile discards Random.Range's sample result: startSample stays 0.
    // A negative pitch therefore reaches the start boundary immediately.
    audio_sound_set_track_position(_handle,_reverse?max(0,_length-.00003):0);
    _e.snippets[_slot]={handle:_handle,left:_duration,period:_duration,loop:_mode!=1,sample:0,offset:_mode==3?_offset:0,reverse:_reverse,length:_length};
}
function cr_nullend_audio_step(_e,_dt) {
    for(var _i=0;_i<3;_i++){
        var _v=_e.snippets[_i];if(!is_struct(_v))continue;_v.left-=_dt;
        if(_e.stage>0 || (_v.left<=0 && !_v.loop)){if(audio_is_playing(_v.handle))audio_stop_sound(_v.handle);_e.snippets[_i]=undefined;continue;}
        if(_v.left<=0){_v.left=_v.period;_v.sample=min(_v.sample+_v.offset/44100,max(0,_v.length-.00003));audio_sound_set_track_position(_v.handle,_v.reverse?_v.length-_v.sample-.00003:_v.sample);}
    }
    for(var _i=array_length(_e.notes)-1;_i>=0;_i--){var _n=_e.notes[_i];_n.left-=_dt;if(_n.left<=0){if(audio_is_playing(_n.handle))audio_stop_sound(_n.handle);array_delete(_e.notes,_i,1);}}
    if(_e.stage!=0)return;_e.spoop_time+=_dt;if(_e.spoop_time<.25)return;
    if(random(1)<=.75){_e.spoop_time-=.1;return;}
    var _mode=irandom(3),_slot=irandom(2),_key=array_length(_e.memory)>0?_e.memory[irandom(array_length(_e.memory)-1)]:"";
    if(_mode==0){
        var _note=irandom(127),_velocity=irandom(127),_h=cr_sound(global.cr_session_data.event_audio.notes[_note],undefined,undefined,true,undefined,undefined,true,undefined,true);
        var _entry=global.bbcr.sound_instances[array_length(global.bbcr.sound_instances)-1];_entry.mix=sqr(_velocity/100);cr_sound_apply(_entry);
        array_push(_e.notes,{handle:_h,left:irandom_range(1000,4999)/1000});_e.spoop_time=0;
    }else cr_nullend_snippet(_e,_mode,_slot,_key,random_range(-2,2),random_range(.02,.2),irandom(1023));
}
function cr_nullend_step(_e,_dt) {
    var _old=global.cr_ui;global.cr_ui=_e.ui;var _s=global.cr_session_data.null_end;
    if(_e.time>=_e.start && _e.voice<0)_e.voice=cr_sound(_s.sound,undefined,undefined,true,undefined,undefined,true,undefined,true);
    var _at=audio_is_playing(_e.voice)?audio_sound_get_track_position(_e.voice):0,_pic=cr_ui_node(_s.pic),_fx=_pic.event_effect;
    if(_e.stage==0){cr_ui_active(_s.error,irandom(2)==0);if(audio_is_playing(_e.voice))cr_ui_active(_s.pic,irandom(2)==0);}
    if(_at>=_e.stage1 && _e.stage<1){_e.stage=1;cr_ui_active(_s.pic,true);cr_ui_active(_s.error,false);_pic.graphics[0].color=[255,255,255,255];_fx.alpha=false;}
    else if(_at>=16 && _e.stage<2){_e.stage=2;cr_ui_active(_s.person,true);_pic.image_override=_s.empty;cr_progress_set_flag(5);cr_save();}
    else if(_at>=24 && _e.stage<3){_e.stage=3;cr_ui_active(_s.person,false);cr_ui_active(_s.face,irandom(15)==0);}
    else if(_at>=27 && _e.stage<4){_e.stage=4;_e.disappear_threshold=1;_e.disappear_phase=0;_e.disappear_time=0;_fx.color=true;_fx.alpha=true;_fx.percent=0;_fx.threshold=1;_fx.full=1;}
    var _person=cr_ui_node(_s.person).event_effect;_person.seed=irandom(4095);_person.shift=_at<17?0:sqr((_at-17)/8);
    if(_e.stage>0 && _e.stage<4){_fx.color=random(1)<=.01;if(!_fx.color)_fx.seed=random(4096);}
    if(_e.stage==4 && _e.disappear_phase!=3){
        _e.disappear_time-=_dt;
        if(_e.disappear_phase==0){_e.disappear_threshold*=.8;if(_e.disappear_threshold<.1)_e.disappear_threshold=0;_fx.threshold=_e.disappear_threshold;_e.disappear_phase=1;_e.disappear_time=.25;}
        else if(_e.disappear_phase==1){_fx.percent=clamp(1-_e.disappear_time*4,0,1);if(_e.disappear_time<=0){_fx.full=_e.disappear_threshold;_fx.percent=0;_e.disappear_phase=_e.disappear_threshold<=0?3:2;_e.disappear_time=random(.5);}}
        else if(_e.disappear_time<=0)_e.disappear_phase=0;
    }else if(_e.stage==4){_fx.full=0;_fx.threshold=0;}
    cr_nullend_audio_step(_e,_dt);global.cr_ui=_old;
    if(_e.stage>0 && !audio_is_playing(_e.voice))game_end();
}
