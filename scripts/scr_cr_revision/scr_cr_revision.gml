function cr_lantern_color(_x,_z) {
    var _g=global.bbcr,_s=global.cr_map.lantern,_rgb=[0,0,0],_a=1-clamp(point_distance(_x,_z,_g.px,_g.pz)/(10*_s.strength),0,1);
    _rgb=[_s.color.r*_a,_s.color.g*_a,_s.color.b*_a];
    if(_g.spoop)for(var _i=0;_i<array_length(_g.npcs);_i++){
        var _n=_g.npcs[_i];if(_n.hidden || cr_value(_n,"optional_pending",false))continue;
        _a=1-clamp(point_distance(_x,_z,_n.px,_n.pz)/40,0,1);
        for(var _c=0;_c<3;_c++)_rgb[_c]+=_a*(1-_rgb[_c]);
    }
    return make_color_rgb(round(_rgb[0]*255),round(_rgb[1]*255),round(_rgb[2]*255));
}
function cr_alarm_use() {
    var _g=global.bbcr,_s=global.cr_catalog.effects.alarm;
    var _a={x:_g.px,z:_g.pz,t:_s.times[_s.initial],finished:false,voice:cr_sound(_s.tick,_g.px,_g.pz,false,undefined,_s.audio)};
    if(_a.voice>=0)audio_sound_loop(_a.voice,true);array_push(_g.alarms,_a);
}
function cr_alarm_frame(_a) {
    if(_a.finished)return 3;var _times=global.cr_catalog.effects.alarm.times;
    for(var _i=0;_i<3;_i++)if(_a.t<=_times[_i])return _i;return 3;
}
function cr_alarm_wind(_index) {
    var _a=global.bbcr.alarms[_index],_s=global.cr_catalog.effects.alarm;if(_a.finished)return;
    _a.t=_s.times[(cr_alarm_frame(_a)+1) mod 4];cr_sound(_s.wind,_a.x,_a.z,false,undefined,_s.audio);
}
function cr_alarm_step(_dt) {
    var _g=global.bbcr,_s=global.cr_catalog.effects.alarm;
    for(var _i=array_length(_g.alarms)-1;_i>=0;_i--){var _a=_g.alarms[_i];
        if(_a.finished){if(!audio_is_playing(_a.voice))array_delete(_g.alarms,_i,1);continue;}
        _a.t-=_dt;if(_a.t>0)continue;_a.finished=true;
        if(audio_is_playing(_a.voice))audio_stop_sound(_a.voice);
        cr_noise(_a.x,_a.z,_s.noise);_a.voice=cr_sound(_s.ring,_a.x,_a.z,false,undefined,_s.audio);
    }
}
function cr_alarm_draw() {
    var _s=global.cr_catalog.effects.alarm;
    for(var _i=0;_i<array_length(global.bbcr.alarms);_i++){var _a=global.bbcr.alarms[_i];cr_actor_draw(_s.visual,_s.sprites[cr_alarm_frame(_a)],_a.x,_a.z,0);}
}
function cr_tile_shape(_bin) {
    var _count=0;for(var _i=0;_i<4;_i++)if((_bin & (1<<_i))!=0)_count++;
    if(_count==0)return 0;if(_count==4)return 1;if(_count==1)return 2;if(_count==3)return 5;return (_bin==5 || _bin==10)?3:4;
}
function cr_input_reverse() {
    return (global.bbcr.mirror?-1:1)*(is_struct(global.bbcr.demo) && global.bbcr.demo.flipped?-1:1);
}
function cr_baldi_please(_n,_time) {
    _n.math_pause=cr_value(_n,"math_pause",0)+_time;
    var _sounds=_n.params.correct_sounds;if(array_length(_sounds)==0)return;
    var _total=0;for(var _i=0;_i<array_length(_sounds);_i++)_total+=_sounds[_i].weight;
    var _pick=random(_total);for(var _i=0;_i<array_length(_sounds);_i++){_pick-=_sounds[_i].weight;if(_pick<0){cr_npc_sound(_n,_sounds[_i].sound);break;}}
}
