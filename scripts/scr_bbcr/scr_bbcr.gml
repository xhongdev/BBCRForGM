/// BBCR runtime uses Unity world units (one tile = 10 units).
#macro CR_CHEATS_CAN_OPEN_MENU true
#macro CR_CHEATS_CAN_RECORD_PROGRESS true
// Compatibility name for older focused tests; this is not a separate policy.
#macro CR_CHEATS_CAN_UNLOCK_MODES CR_CHEATS_CAN_RECORD_PROGRESS
function cr_json(_file) {
    var _b=buffer_load(_file);
    if (_b<0) show_error("Missing BBCR data: "+_file,true);
    var _s=buffer_read(_b,buffer_text); buffer_delete(_b); return json_parse(_s);
}
function cr_value(_s,_k,_default) { return variable_struct_exists(_s,_k)?_s[$ _k]:_default; }
function cr_sprite(_key) {
    if (_key=="") return -1;
    if (variable_struct_exists(global.cr_sprites,_key)) return global.cr_sprites[$ _key];
    var _file=_key;
    if (variable_struct_exists(global.cr_catalog.sprites,_key)) _file=global.cr_catalog.sprites[$ _key].file;
    else if(variable_struct_exists(global.cr_catalog.textures,_key)) _file=global.cr_catalog.textures[$ _key];
    if (!file_exists(_file)) return -1;
    var _s=sprite_add(_file,1,false,false,0,0); global.cr_sprites[$ _key]=_s; return _s;
}
function cr_sound_attenuation(_entry) {
    if(_entry.interface || is_undefined(_entry.px))return 1;
    var _x=_entry.px,_z=_entry.pz;
    if(is_struct(_entry.owner)){_x=_entry.owner.px;_z=_entry.owner.pz;}
    var _distance=point_distance(_x,_z,global.bbcr.px,global.bbcr.pz),_profile=_entry.audio;
    if(is_struct(_profile) && _profile.positional){
        var _min=max(.0001,_profile.min_distance),_max=max(_min,_profile.max_distance);
        if(_distance<=_min)return 1;
        if(_profile.rolloff_mode==2 && array_length(_profile.rolloff_curve)>0)return clamp(cr_curve(_profile.rolloff_curve,_distance/_max),0,1);
        if(_distance>=_max)return 0;
        if(_profile.rolloff_mode==1)return 1-(_distance-_min)/(_max-_min);
        return clamp(_min/_distance,0,1);
    }
    return clamp(1-_distance/150,.03,1);
}
function cr_sound_apply(_entry) {
    audio_sound_gain(_entry.handle,_entry.gain*cr_value(_entry,"mix",1)*cr_sound_attenuation(_entry)*sqr(global.bbcr.volumes[_entry.category]),0);
}
function cr_sound(_key,_px=undefined,_pz=undefined,_interface=false,_owner=undefined,_audio=undefined,_ignore_pause=false,_caption_source=undefined,_raw=false) {
    if (!variable_struct_exists(global.cr_catalog.sounds,_key)) return -1;
    var _d=global.cr_catalog.sounds[$ _key];
    if (_d.file=="") return -1;
    if (!variable_struct_exists(global.cr_sounds,_key)) global.cr_sounds[$ _key]=audio_create_stream(_d.file);
    var _s=global.cr_sounds[$ _key]; if (_s<0) return -1;
    var _h=audio_play_sound(_s,1,false),_gain=_d.volume;
    if(cr_value(global.bbcr,"ending_testing",false))show_debug_message("BBCR_ENDING_AUDIO: "+string(_h)+" "+_key);
    var _category=cr_value(_d,"category",1);
    if(is_undefined(_caption_source))_caption_source=is_struct(_owner)?_owner:(is_undefined(_px)?"sound:"+_key:"position:"+string(_px)+":"+string(_pz));
    var _entry={handle:_h,key:_key,category:_category,gain:_gain,interface:_interface,ignore_pause:_interface || _ignore_pause,px:_px,pz:_pz,owner:_owner,audio:_audio,caption_source:_caption_source};
    array_push(global.bbcr.sound_instances,_entry);cr_sound_apply(_entry);
    if(!_raw){cr_sound_memory_add(_key);cr_caption_start(_entry);}
    if(cr_value(global.bbcr,"math_audio_paused",false) && !_entry.ignore_pause)audio_pause_sound(_h);
    return _h;
}
function cr_npc_sound(_n,_key) {return cr_sound(_key,_n.px,_n.pz,false,_n,cr_value(_n.params,"audio",undefined),string_pos("NULL",_n.name)>0);}
function cr_audio_update_volume() {
    var _g=global.bbcr;
    for(var _i=array_length(_g.sound_instances)-1;_i>=0;_i--){
        var _s=_g.sound_instances[_i];
        if(audio_is_playing(_s.handle))cr_sound_apply(_s);
        else if(!cr_value(_g,"paused",false) && !cr_value(_g,"math_audio_paused",false) && !cr_cheat_flag("open") && !cr_value(_g,"dead",false) && !cr_value(_g,"won",false))array_delete(_g.sound_instances,_i,1);
    }
}
function cr_queue(_key) { array_push(global.bbcr.voice_queue,_key); }
function cr_voice_tick() {
    var _g=global.bbcr;
    if (!audio_is_playing(_g.voice) && array_length(_g.voice_queue)>0){
        var _entry=array_shift(_g.voice_queue);_g.voice_key=is_struct(_entry)?_entry.key:_entry;
        _g.voice=cr_sound(_g.voice_key,is_struct(_entry)?_entry.x:undefined,is_struct(_entry)?_entry.z:undefined,_g.scene=="math");
    }
}
function cr_voice_clear() {
    var _g=global.bbcr;cr_caption_remove(_g.voice); if (audio_is_playing(_g.voice)) audio_stop_sound(_g.voice); _g.voice=-1; _g.voice_key="";_g.voice_queue=[];
}
function cr_audio_clear_all() {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(_g.sound_instances);_i++){
        var _h=_g.sound_instances[_i].handle;if(audio_is_playing(_h))audio_stop_sound(_h);
    }
    _g.sound_instances=[];_g.voice=-1;_g.voice_key="";_g.voice_queue=[];
    if(variable_global_exists("cr_captions"))global.cr_captions=[];
}
function cr_progress_default() {
    return {classic_won:false,party_won:false,demo_won:false,flags:array_create(6,false)};
}
/// Only the native extension writes user-save bytes. INI parsing stays in RAM.
function cr_crypto_path(_name) {return environment_get_variable("LOCALAPPDATA")+"\\BBCRForGM\\"+_name;}
function cr_crypto_report(_message) {
    var _c=global.bbcr.crypto;_c.error=_message;
    show_debug_message("BBCR_SAVE_ERROR: "+_message);
    if(!global.bbcr.testing && !_c.notified){
        _c.notified=true;
        show_message("The user save could not be read or written. The existing file has been preserved.\n"+_message);
    }
}
function cr_crypto_text_valid(_text) {
    if(_text=="")return true;
    ini_open_from_string(_text);
    var _ok=ini_section_exists("scores") || ini_section_exists("progress") || ini_section_exists("options") || ini_section_exists("events");
    ini_close();return _ok;
}
function cr_crypto_legacy_text(_path) {
    var _b=buffer_load(_path);if(_b<0)return undefined;
    var _text=buffer_read(_b,buffer_text);buffer_delete(_b);return _text;
}
function cr_crypto_prepare(_sealed="bbcr.sav",_legacy="bbcr.ini") {
    var _c={enabled: true,sealed: _sealed,legacy: _legacy,text: "",corrupt: false,ready: false,converted: false,write_failed: false,error:"",notified: false};
    global.bbcr.crypto=_c;
    var _root=cr_crypto_path("");
    if(!directory_exists(_root))directory_create(_root);
    if(!directory_exists(_root)){_c.write_failed=true;cr_crypto_report("Unable to create the user-save directory.");return false;}
    var _text=bbcr_save_crypto_read(cr_crypto_path(_sealed)),_status=bbcr_save_crypto_status();
    if(_status<0){_c.corrupt=true;cr_crypto_report(bbcr_save_crypto_error());return false;}
    if(_status==0 && file_exists(cr_crypto_path(_legacy))){
        _text=cr_crypto_legacy_text(cr_crypto_path(_legacy));
        if(is_undefined(_text) || !cr_crypto_text_valid(_text)){_c.corrupt=true;cr_crypto_report("Invalid legacy INI; automatic conversion was cancelled.");return false;}
        if(bbcr_save_crypto_write(cr_crypto_path(_sealed),_text)!=1){_c.write_failed=true;cr_crypto_report(bbcr_save_crypto_error());return false;}
        // Verify through the public read API before removing legacy plaintext.
        var _verified=bbcr_save_crypto_read(cr_crypto_path(_sealed));
        if(bbcr_save_crypto_status()!=1 || _verified!=_text){_c.corrupt=true;cr_crypto_report("Converted save could not be verified; legacy INI preserved.");return false;}
        file_delete(cr_crypto_path(_legacy));_c.converted=true;
    }
    if(!cr_crypto_text_valid(_text)){_c.corrupt=true;cr_crypto_report("Authenticated save has invalid INI content.");return false;}
    _c.text=_text;_c.ready=true;return true;
}
function cr_store_encrypted(_file) {return _file=="bbcr.ini" && variable_struct_exists(global.bbcr,"crypto") && global.bbcr.crypto.enabled;}
function cr_store_open(_file) {
    if(cr_store_encrypted(_file)){
        var _c=global.bbcr.crypto;if(!_c.ready || _c.corrupt)return false;
        ini_open_from_string(_c.text);
    }else ini_open(_file);
    return true;
}
function cr_store_close(_file) {
    var _text=ini_close();if(!cr_store_encrypted(_file))return true;
    var _c=global.bbcr.crypto;
    if(bbcr_save_crypto_write(cr_crypto_path(_c.sealed),_text)!=1){_c.write_failed=true;cr_crypto_report(bbcr_save_crypto_error());return false;}
    _c.text=_text;_c.write_failed=false;_c.notified=false;_c.error="";return true;
}
// These helpers operate on the currently open INI, shared by startup and saves.
function cr_progress_read() {
    var _p=cr_progress_default();
    _p.classic_won=ini_read_real("progress","classic_won",0)>0;
    _p.party_won=ini_read_real("progress","party_won",0)>0;
    _p.demo_won=ini_read_real("progress","demo_won",0)>0;
    for(var _i=0;_i<6;_i++)_p.flags[_i]=ini_read_real("progress","flag_"+string(_i),0)>0;
    return _p;
}
function cr_progress_write() {
    if(!cr_progress_cheats_allowed())return;
    var _p=global.bbcr.progress;
    ini_write_real("progress","classic_won",_p.classic_won);
    ini_write_real("progress","party_won",_p.party_won);
    ini_write_real("progress","demo_won",_p.demo_won);
    for(var _i=0;_i<6;_i++)ini_write_real("progress","flag_"+string(_i),_p.flags[_i]);
}
function cr_progress_save() {
    if(!cr_progress_cheats_allowed())return;
    var _g=global.bbcr,_file="bbcr.ini";
    if(_g.testing){
        if(cr_value(_g,"policy_testing",false))_file="bbcr_policy_test.ini";
        else if(cr_value(_g,"unlock_testing",false))_file="bbcr_menu_unlock_test.ini";
        else if(!cr_value(_g,"crypto_testing",false))return;
    }
    if(!cr_store_open(_file))return false;
    cr_progress_write();return cr_store_close(_file);
}
function cr_style_level() {
    switch(global.bbcr.style){
        case "party":return "PartyMain";
        case "demo":return "ClassicDemo";
        case "null":return global.bbcr.progress.flags[4]?"ClassicGlitch":"ClassicNull";
    }return "ClassicMain";
}
function cr_progress_cheats_allowed() {
    return !cr_cheat_flag("used") || CR_CHEATS_CAN_RECORD_PROGRESS;
}
function cr_progress_set_flag(_index) {
    if(!cr_progress_cheats_allowed())return false;
    global.bbcr.progress.flags[_index]=true;return true;
}
function cr_score_submit(_score) {
    if(!cr_progress_cheats_allowed())return false;
    global.bbcr.high_score=max(global.bbcr.high_score,_score);return true;
}
function cr_progress_notice(_key) {
    if(!cr_progress_cheats_allowed())return;
    var _g=global.bbcr,_label=_key;
    if(variable_struct_exists(global.cr_text,_key))_label=global.cr_text[$ _key];
    _g.unlock_notice=global.cr_text.Men_UnlockNotif+_label;
}
function cr_progress_complete_style(_style) {
    var _g=global.bbcr;if(!cr_progress_cheats_allowed())return false;
    switch(_style){
        case "classic":if(!_g.progress.classic_won)cr_progress_notice("Men_MirrorMode");_g.progress.classic_won=true;break;
        case "party":if(!_g.progress.party_won)cr_progress_notice("But_LightsOut");_g.progress.party_won=true;break;
        case "demo":if(!_g.progress.demo_won)cr_progress_notice("But_HardMode");_g.progress.demo_won=true;break;
        default:return false;
    }
    cr_progress_check_all_fun();cr_save();return true;
}
function cr_progress_check_all_fun() {
    var _g=global.bbcr;if(!_g.mirror || !_g.lightsout || !_g.hard || !cr_progress_cheats_allowed())return false;
    if(!_g.progress.flags[0])cr_progress_notice("NULL");_g.progress.flags[0]=true;cr_save();return true;
}
function cr_progress_complete_null() {
    var _g=global.bbcr;if(!_g.progress.flags[0] || !cr_progress_cheats_allowed())return false;
    if(!_g.progress.flags[4])cr_progress_notice("Men_GlitchStyleUnlock");_g.progress.flags[4]=true;cr_save();return true;
}
function cr_progress_fun_state(_path,_unlocked,_selected) {
    var _n=cr_ui_node(_path);if(is_undefined(_n) || !variable_struct_exists(_n.scripts,"FunSetting"))return;
    var _f=_n.scripts.FunSetting;cr_ui_active(_f.lockedText,!_unlocked);cr_ui_active(_f.unlockedText,_unlocked);cr_ui_active(_f.checkMark,_unlocked && _selected);
}
function cr_progress_menu_sync() {
    if(!variable_global_exists("cr_ui") || global.cr_ui.scene!="MainMenu")return;
    var _g=global.bbcr,_p=_g.progress;
    cr_progress_fun_state("ModeSelect/FunSettings/FunSetting1",_p.classic_won,_g.mirror);
    cr_progress_fun_state("ModeSelect/FunSettings/FunSetting2",_p.party_won,_g.lightsout);
    cr_progress_fun_state("ModeSelect/FunSettings/FunSetting3",_p.demo_won,_g.hard);
    cr_progress_fun_state("ModeSelect/FunSettings/FunSetting4",true,global.cr_ui.free);
    var _null=cr_ui_node("StyleSelect/Baldi"),_glitch=cr_ui_node("StyleSelect/BaldiGlitch"),_glitch_unlocked=_p.flags[4] && _p.flags[0];
    if(!is_undefined(_null)){
        _null.active=!_glitch_unlocked;
        for(var _i=0;_i<array_length(_null.graphics);_i++)_null.graphics[_i].raycast=_p.flags[0];
    }
    if(!is_undefined(_glitch)){
        _glitch.active=_glitch_unlocked;
        for(var _i=0;_i<array_length(_glitch.graphics);_i++)_glitch.graphics[_i].raycast=_glitch_unlocked;
    }
}
function bbcr_init_menu() {
    global.cr_catalog=cr_json("bbcr/catalog.json"); global.cr_sprites={}; global.cr_sounds={};
    global.cr_text={}; var _loc=cr_json("bbcr/localization/Subtitles_En.json");
    for(var _i=0;_i<array_length(_loc.items);_i++) global.cr_text[$ _loc.items[_i].key]=_loc.items[_i].value;
    global.bbcr={scene:"menu",page:"warning",selection:0,mode:"story",voice:-1,voice_key:"",voice_queue:[],loaded:false,paused:false,dead:false,won:false,
        mouse_skip:true,high_score:0,sensitivity:.29,volume:1,style:"classic",mirror:false,lightsout:false,hard:false,testing:false,skip_launcher:false,
        volumes:[1,1,.8],sensitivities:[.29,1,400,400],subtitles:false,vsync:true,pixel_filter:true,reduce_flashing:false,rumble:true,sound_instances:[],unlock_notice:""};
    global.bbcr.progress=cr_progress_default();
    global.bbcr.menu_testing=false;global.bbcr.window_testing=false;global.bbcr.window_test_frame=0;global.bbcr.cheat_testing=false;global.bbcr.encounter_testing=false;global.bbcr.ending_testing=false;global.bbcr.sense_testing=false;global.bbcr.followup_testing=false;global.bbcr.style_testing=false;
    global.bbcr.style_feedback_testing=false;global.bbcr.current_testing=false;global.bbcr.revision_testing=false;global.bbcr.latest_testing=false;global.bbcr.nullsession_testing=false;global.bbcr.unlock_testing=false;global.bbcr.finalfeedback_testing=false;
    global.bbcr.nulleffects_testing=false;
    global.bbcr.session_testing=false;
    global.bbcr.policy_testing=false;
    global.bbcr.captionevent_testing=false;
    global.bbcr.crypto_testing=false;global.bbcr.crypto_test_stage=0;
    //for(var _a=1;_a<=parameter_count();_a++) {
    //    if(parameter_string(_a)=="--bbcr-test")global.bbcr.testing=true;
    //    if(parameter_string(_a)=="--bbcr-menu-test"){global.bbcr.testing=true;global.bbcr.menu_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-window-test"){global.bbcr.testing=true;global.bbcr.window_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-cheat-test"){global.bbcr.testing=true;global.bbcr.cheat_testing=true;global.bbcr.cheat_test_stage=0;}
    //    if(parameter_string(_a)=="--bbcr-encounter-test"){global.bbcr.testing=true;global.bbcr.encounter_testing=true;global.bbcr.encounter_stage=0;}
    //    if(parameter_string(_a)=="--bbcr-ending-test"){global.bbcr.testing=true;global.bbcr.ending_testing=true;global.bbcr.ending_test_stage=0;}
    //    if(parameter_string(_a)=="--bbcr-sense-test"){global.bbcr.testing=true;global.bbcr.sense_testing=true;global.bbcr.sense_test_stage=0;}
    //    if(parameter_string(_a)=="--bbcr-followup-test"){global.bbcr.testing=true;global.bbcr.followup_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-style-test"){global.bbcr.testing=true;global.bbcr.style_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-style_feedback-test"){global.bbcr.testing=true;global.bbcr.style_feedback_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-current-test"){global.bbcr.testing=true;global.bbcr.current_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-revision-test"){global.bbcr.testing=true;global.bbcr.revision_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-latest-test"){global.bbcr.testing=true;global.bbcr.latest_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-nullsession-test"){global.bbcr.testing=true;global.bbcr.nullsession_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-unlock-test"){global.bbcr.testing=true;global.bbcr.unlock_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-finalfeedback-test"){global.bbcr.testing=true;global.bbcr.finalfeedback_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-nulleffects-test"){global.bbcr.testing=true;global.bbcr.nulleffects_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-session-test"){global.bbcr.testing=true;global.bbcr.session_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-policy-test"){global.bbcr.testing=true;global.bbcr.policy_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-captionevent-test"){global.bbcr.testing=true;global.bbcr.captionevent_testing=true;}
    //    if(parameter_string(_a)=="--bbcr-crypto-test"){global.bbcr.testing=true;global.bbcr.crypto_testing=true;global.bbcr.crypto_test_stage=0;}
    //}
    // Tests never migrate or rewrite the real user save.
    var _save_text="";
    if(global.bbcr.crypto_testing){cr_crypto_prepare("bbcr_crypto_test.sav","bbcr_crypto_test.ini");_save_text=global.bbcr.crypto.text;}
    else if(!global.bbcr.testing){cr_crypto_prepare();_save_text=global.bbcr.crypto.text;}
    ini_open_from_string(_save_text);global.bbcr.high_score=ini_read_real("scores","classic",0);
    global.bbcr.skip_launcher=ini_read_real("options","skip_launcher",0);
    for(var _i=0;_i<3;_i++)global.bbcr.volumes[_i]=ini_read_real("options","volume_"+string(_i),global.bbcr.volumes[_i]);
    for(var _i=0;_i<4;_i++)global.bbcr.sensitivities[_i]=ini_read_real("options","sensitivity_"+string(_i),global.bbcr.sensitivities[_i]);
    global.bbcr.sensitivity=global.bbcr.sensitivities[0];
    global.bbcr.progress=cr_progress_read();
    global.bbcr.subtitles=ini_read_real("options","subtitles",0)>0;
    global.bbcr.games_since_error=ini_read_real("events","games_since_error",0);
    global.bbcr.error_count=ini_read_real("events","error_count",0);
    global.bbcr.boss_seen=ini_read_real("events","boss_seen",0)>0;
    global.bbcr.vsync=ini_read_real("options","vsync",1)>0;
    global.bbcr.pixel_filter=ini_read_real("options","pixel_filter",1)>0;
    global.bbcr.reduce_flashing=ini_read_real("options","reduce_flashing",0)>0;
    global.bbcr.rumble=ini_read_real("options","rumble",1)>0;
    ini_close();
    audio_master_gain(global.bbcr.volume); display_set_gui_size(640,480);window_set_size(960,720);
    var _font="bbcr/fonts/fallback.ttf";
    global.cr_font=file_exists(_font)?font_add(_font,18,false,false,32,255):-1;
    global.cr_font_small=file_exists(_font)?font_add(_font,12,false,false,32,255):-1;
    cr_render_init();cr_cheat_init();
    cr_ui_init();if(global.bbcr.skip_launcher && !global.bbcr.testing)cr_ui_scene("Logo");
}
function cr_save(_file="bbcr.ini") {
    if(global.bbcr.testing && ((!global.bbcr.session_testing && !global.bbcr.policy_testing && !global.bbcr.crypto_testing) || (_file=="bbcr.ini" && !global.bbcr.crypto_testing))) return;
    if(!cr_store_open(_file))return false;
    if(cr_progress_cheats_allowed()){
        ini_write_real("scores","classic",global.bbcr.high_score);
        ini_write_real("events","games_since_error",global.bbcr.games_since_error);
        ini_write_real("events","error_count",global.bbcr.error_count);
        ini_write_real("events","boss_seen",global.bbcr.boss_seen);
    }
    ini_write_real("options","skip_launcher",global.bbcr.skip_launcher);
    ini_write_real("options","subtitles",global.bbcr.subtitles);
    for(var _i=0;_i<3;_i++)ini_write_real("options","volume_"+string(_i),global.bbcr.volumes[_i]);
    for(var _i=0;_i<4;_i++)ini_write_real("options","sensitivity_"+string(_i),global.bbcr.sensitivities[_i]);
    ini_write_real("options","sensitivity",global.bbcr.sensitivity);ini_write_real("options","volume",global.bbcr.volume);
    ini_write_real("options","vsync",global.bbcr.vsync);ini_write_real("options","pixel_filter",global.bbcr.pixel_filter);
    ini_write_real("options","reduce_flashing",global.bbcr.reduce_flashing);ini_write_real("options","rumble",global.bbcr.rumble);
    cr_progress_write();
    return cr_store_close(_file);
}
function cr_tile(_x,_z) {
    var _m=global.cr_map; var _tx=floor(_x/10),_tz=floor(_z/10);
    if(_tx<0 || _tz<0 || _tx>=_m.size.x || _tz>=_m.size.z) return undefined;
    return global.cr_tiles[_tx+_tz*_m.size.x];
}
function cr_segment_distance(_x,_z,_ax,_az,_bx,_bz) {
    var _dx=_bx-_ax,_dz=_bz-_az,_l=_dx*_dx+_dz*_dz;
    var _t=_l<=.0001?0:clamp(((_x-_ax)*_dx+(_z-_az)*_dz)/_l,0,1);
    return point_distance(_x,_z,_ax+_t*_dx,_az+_t*_dz);
}
function cr_blocked(_x,_z,_radius,_doors=true,_furniture=true,_actor=undefined) {
    if(is_undefined(cr_tile(_x,_z))) return true;
    var _tx=floor(_x/10),_tz=floor(_z/10);
    var _cell=_tx+_tz*global.cr_map.size.x;
    var _wall_list=(variable_global_exists("cr_wall_grid") && _cell<array_length(global.cr_wall_grid))?global.cr_wall_grid[_cell]:[];
    for(var _wi=0;_wi<array_length(_wall_list);_wi++) {
        var _w=global.cr_walls[_wall_list[_wi]];if(array_length(_w)>4 && _w[4]>=0 && (global.cr_map.windows[_w[4]].broken || (is_struct(_actor) && cr_value(_actor,"pass_windows",false))))continue;
        if(cr_segment_distance(_x,_z,_w[0],_w[1],_w[2],_w[3])<_radius)return true;
    }
    for(var _i=0;_i<array_length(global.bbcr.exits);_i++){
        var _e=global.bbcr.exits[_i];if((_e.state>0 || (_doors && _e.prepared)) && variable_struct_exists(_e,"barrier")){
            var _w=_e.barrier;if(cr_segment_distance(_x,_z,_w[0],_w[1],_w[2],_w[3])<_radius)return true;
        }
    }
    if(_doors) for(var _i=0;_i<array_length(global.bbcr.doors);_i++) {
        var _d=global.bbcr.doors[_i];if(_d.open>0 || (_d.swing && !_d.locked && _d.lock<=0))continue;
        var _principal_pass=is_struct(_actor) && variable_struct_exists(_actor,"name") && _actor.name=="Principal" && _d.lock>0 && global.bbcr.detention_room>=0 && (_d.a_room==global.bbcr.detention_room || _d.b_room==global.bbcr.detention_room);
        if(_principal_pass)continue;
        if(cr_segment_distance(_x,_z,_d.cx-_d.tx*_d.half,_d.cz-_d.tz*_d.half,_d.cx+_d.tx*_d.half,_d.cz+_d.tz*_d.half)<_radius) return true;
    }
    var _furniture_list=(variable_global_exists("cr_furniture_grid") && _cell<array_length(global.cr_furniture_grid))?global.cr_furniture_grid[_cell]:[];
    if(_furniture) for(var _fi=0;_fi<array_length(_furniture_list);_fi++) {
        var _b=global.cr_map.colliders[_furniture_list[_fi]];if(cr_box_overlap(_b,_x,_z,_radius))return true;
    }
    if(global.bbcr.style=="party" && is_struct(global.bbcr.party) && global.bbcr.party.phase=="school"){
        var _boxes=global.bbcr.party.data.elevator.colliders;
        for(var _i=0;_i<array_length(_boxes);_i++)if(cr_box_overlap(_boxes[_i],_x,_z,_radius))return true;
    }
    if(global.bbcr.style=="party" && variable_struct_exists(global.cr_map,"puzzle") && !global.bbcr.party.puzzle_open && cr_box_overlap(global.cr_map.puzzle.wall.box,_x,_z,_radius))return true;
    if(variable_struct_exists(global.bbcr,"null_mode") && cr_null_blocks(_x,_z,_radius))return true;
    if(is_struct(global.bbcr.secret_route))for(var _i=0;_i<array_length(global.cr_map.lockdowns);_i++){var _l=global.cr_map.lockdowns[_i];if(_l.height<=_l.collision_height && cr_box_overlap(_l.box,_x,_z,_radius))return true;}
    return false;
}
function cr_box_overlap(_b,_x,_z,_r) {
    var _dx=_x-_b.center[0],_dz=_z-_b.center[2];
    var _lx=_dx*_b.axes[0][0]+_dz*_b.axes[0][2],_lz=_dx*_b.axes[2][0]+_dz*_b.axes[2][2];
    var _ex=max(0,abs(_lx)-_b.half[0]),_ez=max(0,abs(_lz)-_b.half[2]);
    var _eye=global.cr_map.spawn[1],_half=max(0,global.cr_catalog.movement.height/2-_r);
    var _ey=max(0,_b.bounds[1]-(_eye+_half),(_eye-_half)-_b.bounds[4]);
    return _ex*_ex+_ez*_ez+_ey*_ey<_r*_r;
}
function cr_move(_actor,_dx,_dz,_r=1.5) {
    if(_actor==global.bbcr && cr_cheat_flag("noclip")){_actor.px+=_dx;_actor.pz+=_dz;return;}
    var _steps=max(1,ceil(point_distance(0,0,_dx,_dz)/.6));_dx/=_steps;_dz/=_steps;
    repeat(_steps) {
        if(!cr_blocked(_actor.px+_dx,_actor.pz,_r,true,true,_actor) && (_actor!=global.bbcr || !cr_bully_blocks(_actor.px+_dx,_actor.pz,_r)))_actor.px+=_dx;
        if(!cr_blocked(_actor.px,_actor.pz+_dz,_r,true,true,_actor) && (_actor!=global.bbcr || !cr_bully_blocks(_actor.px,_actor.pz+_dz,_r)))_actor.pz+=_dz;
    }
}
function cr_bully_blocks(_x,_z,_r) {
    var _g=global.bbcr;if(!_g.spoop || _g.mode=="free")return false;
    for(var _i=0;_i<array_length(_g.npcs);_i++){
        var _n=_g.npcs[_i];if(_n.name!="Bully" || _n.hidden)continue;
        var _dx=max(0,abs(_x-_n.px)-_n.params.solid_half[0]),_dz=max(0,abs(_z-_n.pz)-_n.params.solid_half[2]);
        if(_dx*_dx+_dz*_dz<_r*_r)return true;
    }return false;
}
function cr_clear_line(_ax,_az,_bx,_bz,_mask=2195457) {
    var _len=point_distance(_ax,_az,_bx,_bz);if(_len<=.0001)return true;
    var _dx=(_bx-_ax)/_len,_dz=(_bz-_az)/_len;
    if(is_struct(global.bbcr.teleporter))return false;
    if((_mask & (1<<15))!=0)for(var _i=0;_i<array_length(global.bbcr.chalk_clouds);_i++)if(cr_ray_box(global.bbcr.chalk_clouds[_i].box,_ax,5,_az,_dx,_dz)<_len)return false;
    for(var _i=0;_i<array_length(global.cr_walls);_i++){
        var _w=global.cr_walls[_i];
        if(array_length(_w)>4 && _w[4]>=0){
            // Window glass is layer 21, while its solid frame is layer 0.
            // NULL's source Looker mask (98305) excludes the glass entirely;
            // the imported frame colliders below still block the ray.
            var _window=global.cr_map.windows[_w[4]];
            if(_window.broken || (_mask & (1<<21))==0)continue;
        }
        var _t=cr_ray_segment(_ax,_az,_dx,_dz,_w);if(_t>.0001 && _t<_len)return false;
    }
    for(var _i=0;_i<array_length(global.bbcr.doors);_i++){
        var _d=global.bbcr.doors[_i];if(_d.open>0 || (_d.swing && !_d.locked && _d.lock<=0))continue;
        var _t=cr_ray_segment(_ax,_az,_dx,_dz,[_d.cx-_d.tx*5,_d.cz-_d.tz*5,_d.cx+_d.tx*5,_d.cz+_d.tz*5]);if(_t<_len)return false;
    }
    for(var _i=0;_i<array_length(global.bbcr.exits);_i++){
        var _e=global.bbcr.exits[_i];if(_e.state>0 && variable_struct_exists(_e,"barrier") && cr_ray_segment(_ax,_az,_dx,_dz,_e.barrier)<_len)return false;
    }
    // Looker ignores triggers, and tests physical source colliders at eye height.
    for(var _i=0;_i<array_length(global.cr_map.colliders);_i++){
        var _b=global.cr_map.colliders[_i];if((_mask & (1<<_b.layer))!=0 && cr_ray_box(_b,_ax,5,_az,_dx,_dz)<_len)return false;
    }
    return true;
}
function cr_door_open(_d,_noise=true) {
    if(_d.lock>0 || _d.locked) {if(_noise && !_d.swing)cr_sound("Doors_StandardLocked");return false;}
    if(_d.open<=0) {if(_d.silent<=0)cr_sound(_d.swing?"Doors_Swinging":"Doors_StandardOpen",_d.cx,_d.cz);if(_noise && _d.silent<=0)cr_noise(_d.cx,_d.cz,_d.noise);if(_noise && _d.silent>0)_d.silent--;}
    _d.open=_d.default_time;return true;
}
function cr_noise(_x,_z,_priority) {
    var _g=global.bbcr;if(!_g.spoop || _g.deaf>0 || array_length(_g.npcs)==0)return;
    cr_baldi_hear(_g.npcs[0],_x,_z,_priority,true);
}
function bbcr_start_game(_mode,_level="") {
    var _g=global.bbcr; cr_world_cleanup();cr_audio_clear_all();
    if(is_struct(cr_value(_g,"error_event",undefined)))cr_ui_dispose(_g.error_event.ui);_g.error_event=undefined;
    // A secret/finale level is part of the same run. It must keep its cheat mark.
    cr_cheat_init(_level!="");
    if(global.cr_cheat_events.enabled)cr_cheat_mark_used();
    if(_level==""){_g.games_since_error++;cr_save();}
    cr_loading_exit_begin();
    cr_ui_active("LoadingScreen",false);global.cr_ui.wait="";global.cr_ui.stage=16;_g.loading_drawn=false;
    if(surface_exists(global.cr_ui.previous))surface_free(global.cr_ui.previous);global.cr_ui.previous=-1;
    var _map_file=cr_style_level();
    if(_level!="")_map_file=_level;
    global.cr_map=cr_json("bbcr/"+_map_file+".json"); var _m=global.cr_map;
    _g.scene="game";_g.mode=_mode;_g.px=_m.spawn[0];_g.pz=_m.spawn[2];_g.yaw=degtorad(_m.yaw);
    _g.sound_memory=json_parse(json_stringify(global.cr_session_data.initial_memory));_g.sound_memory_pos=0;
    _g.stamina=100;_g.notebooks=0;_g.needed=array_length(_m.books);_g.spoop=false;_g.anger=.1;_g.extra_anger=0;_g.secret=true;
    _g.time=0;_g.world_y=0;_g.paused=false;_g.dead=false;_g.won=false;_g.death_time=0;_g.mouse_skip=true;_g.move_latch=true;_g.game_music=-1;_g.math_music=-1;
    _g.ending=undefined;_g.math_audio_paused=false;_g.math_waiting=false;_g.world_voice=undefined;_g.secret_level=_m.manager=="ClassicSecretManager";_g.secret_tutors=[];_g.party=undefined;_g.demo=undefined;_g.null_mode=undefined;_g.secret_route=undefined;_g.balloons=[];
    _g.inventory=["","",""];_g.slot=0;_g.items_disabled=_g.secret_level;_g.boots=0;_g.boot_effects=[];_g.deaf=0;_g.indicator=0;_g.indicator_state="Baldicator_Look";_g.detention=0;_g.detention_escape=0;_g.detention_room=-1;_g.detention_inside=false;_g.detention_level=0;_g.guilt="";_g.guilt_time=0;
    _g.happy_time=0;_g.happy_spoke=false;_g.happy_voice=-1;
    _g.jumps=0;_g.rope=false;_g.rope_time=0;_g.jump_height=0;_g.jump_velocity=0;
    _g.rope_npc=undefined;_g.rope_anim=-1;_g.rope_max=5;
    _g.projectiles=[];_g.alarms=[];_g.exits_closed=0;_g.anger_rate=.01;_g.anger_tick=1;
    cr_extra_items_init();
    _g.books=_m.books;var _sprites=global.cr_catalog.pickups.Notebook.sprites;
    for(var _i=0;_i<array_length(_g.books);_i++){_g.books[_i].done=false;_g.books[_i].reset=0;_g.books[_i].sprite=_sprites[irandom(array_length(_sprites)-1)];}
    _g.items=_m.items;for(var _i=0;_i<array_length(_g.items);_i++)_g.items[_i].done=false;
    _g.doors=_m.doors;for(var _i=0;_i<array_length(_g.doors);_i++) {
        var _d=_g.doors[_i];_d.open=0;_d.lock=0;_d.silent=0;_d.player_inside=false;_d.need_voice=-1;_d.tx=cos(degtorad(_d.dir*90));_d.tz=-sin(degtorad(_d.dir*90));_d.half=5;
        if(_mode=="free")_d.locked=false;
    }
    _g.exits=_m.exits;for(var _i=0;_i<array_length(_g.exits);_i++){_g.exits[_i].used=false;_g.exits[_i].state=0;_g.exits[_i].prepared=false;}
    for(var _i=0;_i<array_length(_m.windows);_i++)_m.windows[_i].broken=false;
    _g.npcs=[];
    if(_m.scene=="ClassicDemo")cr_demo_select_npcs();
    for(var _i=0;_i<array_length(_m.npcs);_i++) {
        var _src=_m.npcs[_i];array_push(_g.npcs,{name:_src.name,px:_src.x,pz:_src.z,hx:_src.x,hz:_src.z,sprite:_src.sprite,params:_src.params,visual:_src.visual,
            gx:_src.x,gz:_src.z,priority:0,current_sound:0,targeting_sound:false,sound_locations:array_create(128,undefined),path:path_add(),route_timer:0,node:0,cooldown:0,timer:0,sight:0,viewtime:0,run_time:random_range(cr_value(_src.params,"minSightTime",1),cr_value(_src.params,"maxSightTime",6)),angry:false,running:false,hidden:false,
            slap_timer:0,slap_distance:0,slap_left:0,slap_speed:0,slap_frame:0,slap_count:0,yaw:0,speed:_src.params.initial_speed,unseen:0,was_seen:false,pushing:false,contact:false,voice:-1,
            pending_target:undefined,charging:false,playing:false,sad:false,anim_time:0,target_npc:-1,voice_queue:[],
            spawn_pending:_src.name=="Bully",stay:0,spoken:false,bully_guilt:0,intended:[_src.x,_src.z],
            crafters_state:_src.name=="ArtsAndCrafters"?"hidden":"",spawn_target:-1,spawn_phase:0,trigger_tile:-1,attack_time:0,attack_angle:0,attack_spin:0,echo_distance:0,echoes:[]});
        if(_src.name=="Bully")_g.npcs[_i].hidden=true;
    }
    if(array_length(_g.npcs)>0){_g.anger=max(.1,_g.npcs[0].params.baseAnger);_g.npcs[0].slap_timer=cr_curve(_g.npcs[0].params.slapCurve,_g.anger);}
    if(_g.secret_level){
        var _branch=_m.secret_objects[$ (cr_value(_g,"null_defeated",false)?"standard":"null")];
        for(var _i=0;_i<array_length(_branch.decorations);_i++)array_push(_m.decorations,_branch.decorations[_i]);
        _g.secret_tutors=_branch.tutors;for(var _i=0;_i<array_length(_g.secret_tutors);_i++){_g.secret_tutors[_i].started=false;_g.secret_tutors[_i].handle=-1;}
    }
    global.cr_tiles=array_create(_m.size.x*_m.size.z,undefined);for(var _i=0;_i<array_length(_m.tiles);_i++){var _t=_m.tiles[_i];_t.index=_i;global.cr_tiles[_t.x+_t.z*_m.size.x]=_t;}
    cr_build_world();cr_build_navigation();_g.loaded=true;
    cr_game_ui_init();
    cr_exit_init();
    var _halls=[];for(var _i=0;_i<array_length(_m.tiles);_i++){var _t=_m.tiles[_i];if(_t.room==0 && _t.z>=15 && !cr_blocked(_t.x*10+5,_t.z*10+5,2))array_push(_halls,_t);}
    if(!_g.secret_level && array_length(_halls)>0){var _t=_halls[irandom(array_length(_halls)-1)];array_push(_g.items,{x:_t.x*10+5,z:_t.z*10+5,item:"Quarter",done:false});}
    if(_g.style=="party" && is_struct(_m.party))cr_party_init();
    if(_m.scene=="ClassicDemo"){cr_demo_init();cr_demo_events_init();cr_demo_actors_init();}
    if(variable_struct_exists(_m,"null_mode"))cr_null_init();
    if(variable_struct_exists(_m,"secret_manager"))cr_secret_route_init();
    window_mouse_set_locked(!_g.testing);window_set_cursor(cr_none);
    if(!_g.secret_level && !is_struct(_g.null_mode) && !is_struct(_g.secret_route)){_g.game_music=cr_sound("school");if(_g.game_music>=0)audio_sound_loop(_g.game_music,true);}
}
function cr_spoop() {
    var _g=global.bbcr;if(_g.spoop)return;_g.spoop=true;
    if(_g.style=="demo")cr_demo_actors_init();
    if(audio_is_playing(_g.game_music))audio_stop_sound(_g.game_music);if(audio_is_playing(_g.math_music))audio_stop_sound(_g.math_music);_g.game_music=-1;_g.math_music=-1;
    cr_voice_clear();cr_noise(_g.px,_g.pz,0);
    if(audio_is_playing(_g.happy_voice))audio_stop_sound(_g.happy_voice);
    if(is_struct(_g.world_voice)){if(audio_is_playing(_g.world_voice.voice))audio_stop_sound(_g.world_voice.voice);_g.world_voice=undefined;}
    if(_g.mode!="free")for(var _i=0;_i<array_length(_g.exits);_i++)_g.exits[_i].state=1;
    for(var _i=0;_i<array_length(_g.npcs);_i++) {
        var _n=_g.npcs[_i];if(_n.name=="GottaSweep")_n.cooldown=random_range(60,180);
        if(_n.name=="ArtsAndCrafters"){_n.hidden=true;_n.crafters_state="hidden";_n.spawn_target=-1;_n.spawn_phase=0;_n.trigger_tile=-1;}
    }
}
function cr_math_problem() {
    var _g=global.bbcr;_g.a=irandom(8);_g.b=irandom(8);_g.op=choose("+","-");_g.answer=_g.op=="+"?_g.a+_g.b:_g.a-_g.b;
    _g.corrupt=(_g.q==2 && _g.notebooks>=2 && (_g.mode!="endless" || _g.notebooks==2) && (!_g.hard || _g.notebooks==2));_g.input="";
    var _src=global.cr_ui_data.yctp;
    _g.problem_text=global.cr_text[$ "YCTP_Solve"+string(_g.q+1)]+string(_g.a)+_g.op+string(_g.b)+"=?";
    if(_g.corrupt){
        var _ops=["+","-","X","/"],_op1=irandom(3),_op2=irandom(3);
        _g.problem_text="Solve Math Q3\n\n"+string(irandom_range(1000000000,2147483646))+_ops[_op1]+string(irandom_range(1000000000,2147483646))+_ops[_op2]+string(current_time)+string(_g.notebooks)+string(_g.needed)+string(irandom(2147483646))+"=?";
    }
    if(!_g.spoop){
        cr_queue(_src.audProbs[_g.q]);
        if(_g.corrupt){cr_queue(_src.audGlitch);cr_queue(_src.audOps[_op1]);cr_queue(_src.audGlitch);cr_queue(_src.audOps[_op2]);cr_queue(_src.audGlitch);}
        else {cr_queue(_src.audNums[_g.a]);cr_queue(_src.audOps[_g.op=="+"?0:1]);cr_queue(_src.audNums[_g.b]);}cr_queue(_src.audEquals);
    }
}
function cr_collect_book(_index) {
    if(is_struct(global.bbcr.null_mode)){cr_null_collect(_index);return;}
    var _g=global.bbcr;if(_g.style=="demo"){cr_demo_collect_book(_index);return;}
    _g.books[_index].done=true;_g.books[_index].reset=60;_g.notebooks++;_g.stamina=100;
    if(_g.notebooks>=2)for(var _i=0;_i<array_length(_g.doors);_i++)_g.doors[_i].locked=false;
    if(_g.mode=="free")return;
    if(_g.notebooks==_g.needed && _g.mode=="story")for(var _i=0;_i<array_length(_g.exits);_i++){_g.exits[_i].state=0;_g.exits[_i].prepared=true;}
    if(_g.mode=="endless")_g.anger=max(.1,_g.anger-max(_g.anger_rate*15,1));
    _g.world_voice={voice:_g.voice,key:_g.voice_key,queue:_g.voice_queue};_g.voice=-1;_g.voice_key="";_g.voice_queue=[];
    _g.scene="math";_g.q=0;_g.correct=0;_g.wrong=0;_g.marks=[0,0,0];_g.math_done=false;_g.math_delay=0;_g.math_wait=1;_g.math_face=!_g.spoop;
    _g.math_waiting=true;_g.problem_text="";_g.input="";_g.math_audio_paused=!_g.hard;
    if(_g.math_audio_paused)audio_pause_all();
    cr_ui_dispose(global.cr_math_ui);global.cr_math_ui=cr_ui_context("YCTP");
    var _old=global.cr_ui;global.cr_ui=global.cr_math_ui;cr_ui_transition(.01666667);global.cr_ui.reveal=true;global.cr_ui=_old;
    if(audio_is_playing(_g.game_music))audio_stop_sound(_g.game_music);_g.game_music=-1;
    _g.math_music_stage=1;_g.math_music_position=0;
    if(!_g.spoop){_g.math_music=cr_sound("learnNew_1",undefined,undefined,true);if(_g.math_music>=0)audio_sound_loop(_g.math_music,true);}
    cr_voice_clear();window_mouse_set_locked(false);window_set_cursor(cr_none);
}
function cr_math_start_ready() {
    var _g=global.bbcr;if(!_g.math_waiting || global.cr_math_ui.stage<16)return;
    _g.math_waiting=false;
    if(!_g.spoop && _g.notebooks<=1){var _intro=global.cr_ui_data.yctp.audIntro;for(var _i=0;_i<array_length(_intro);_i++)cr_queue(_intro[_i]);}
    cr_math_problem();
}
function bbcr_submit_math() {
    var _g=global.bbcr;if(_g.math_done || _g.math_waiting)return;
    var _right=(_g.input!="" && _g.input!="-" && real(_g.input)==_g.answer && !_g.corrupt);
    cr_voice_clear();_g.marks[_g.q]=_right?1:-1;
    if(_right){_g.correct++;_g.secret=false;if(!_g.spoop)cr_queue("BAL_Praise"+string(irandom_range(1,6)));}
    else {
        if(!_g.spoop){_g.math_delay=5;cr_spoop();}
        _g.wrong++;if(_g.q<2 && _g.mode!="endless" && !_g.hard)_g.extra_anger++;else{_g.anger++;if(_g.correct==0)cr_noise(_g.px,_g.pz,global.cr_ui_data.yctp.noiseVal);}
    }
    _g.q++;if(_g.q<3)cr_math_problem();else{
        _g.math_done=true;_g.math_wait=1;var _src=global.cr_ui_data.yctp,_key="YCTP_CompleteFail";
        if(_g.wrong==0 && !_g.spoop)_key=_src.victoryKeys[irandom(array_length(_src.victoryKeys)-1)];
        else if(_g.wrong==0 && _g.mode=="endless")_key=_src.recoverKeys[irandom(array_length(_src.recoverKeys)-1)];
        else if(_g.correct>0)_key=_src.failKeys[irandom(array_length(_src.failKeys)-1)];
        _g.problem_text=global.cr_text[$ _key];
    }_g.input="";
}
function cr_math_step(_dt) {
    var _g=global.bbcr;cr_math_start_ready();if(!_g.math_waiting)cr_voice_tick();_g.math_delay=max(0,_g.math_delay-_dt);
    cr_game_ui_input(global.cr_math_ui,_dt);
    if(audio_is_playing(_g.math_music)){
        var _pos=audio_sound_get_track_position(_g.math_music);
        if(_pos<_g.math_music_position && min(3,_g.q+1)>_g.math_music_stage){
            _g.math_music_stage=min(3,_g.q+1);audio_stop_sound(_g.math_music);_g.math_music=cr_sound("learnNew_"+string(_g.math_music_stage),undefined,undefined,true);audio_sound_loop(_g.math_music,true);_pos=0;
        }_g.math_music_position=_pos;
    }
    if(_g.math_done) {
        if(_g.math_delay<=0 && !audio_is_playing(_g.voice) && array_length(_g.voice_queue)==0)_g.math_wait-=_dt;
        if(_g.math_wait<=0) {
            cr_math_close();
        }
        return;
    }
    if(global.cr_math_ui.stage<16)return;
    for(var _i=0;_i<10;_i++)if(keyboard_check_pressed(ord("0")+_i) || keyboard_check_pressed(vk_numpad0+_i))cr_math_input(string(_i));
    if(keyboard_check_pressed(ord("-")) || keyboard_check_pressed(vk_subtract))cr_math_input("-");
    if(keyboard_check_pressed(vk_backspace))_g.input=string_delete(_g.input,string_length(_g.input),1);
    if(keyboard_check_pressed(vk_enter))bbcr_submit_math();
}
function cr_math_close() {
    var _g=global.bbcr,_old=global.cr_ui;global.cr_ui=global.cr_math_ui;cr_ui_transition(.01666667);global.cr_ui=_old;
    cr_voice_clear();
    if(is_struct(_g.world_voice)){_g.voice=_g.world_voice.voice;_g.voice_key=_g.world_voice.key;_g.voice_queue=_g.world_voice.queue;}_g.world_voice=undefined;
    _g.scene="game";_g.mouse_skip=true;_g.move_latch=true;keyboard_string="";window_mouse_set_locked(!_g.testing);window_set_cursor(cr_none);
    if(audio_is_playing(_g.math_music))audio_stop_sound(_g.math_music);_g.math_music=-1;
    if(_g.math_audio_paused){_g.math_audio_paused=false;audio_resume_all();}
    if(!_g.spoop){_g.game_music=cr_sound("school");audio_sound_loop(_g.game_music,true);}
    if(_g.notebooks==1 && _g.wrong==0 && is_struct(global.cr_map.happy)){
        var _p=global.cr_map.spawn,_off=global.cr_map.happy.quarter_offset,_yaw=degtorad(global.cr_map.yaw),_item="Quarter",_entry;
        if(_g.style=="party")_item=cr_weighted_item(_g.party.data.prizes);
        _entry={x:_p[0]+sin(_yaw)*15+_off[0],z:_p[2]+cos(_yaw)*15+_off[2],item:_item,done:false};if(_g.style=="party")_entry.sprite_override=_g.party.data.present_sprite;array_push(_g.items,_entry);
        for(var _i=1;_i<=6;_i++)array_push(_g.voice_queue,{key:"BAL_GetPrize"+string(_i),x:_p[0]+sin(_yaw)*15,z:_p[2]+cos(_yaw)*15});
        cr_voice_tick();
    }
    if(_g.notebooks==_g.needed && _g.mode=="story"){
        cr_sound(_g.style=="party"?_g.party.data.aud_all:"BAL_AllNotebooksNull");cr_exit_music("exit_music",1);
    }
}
function cr_math_input(_text) {
    var _g=global.bbcr;if(_g.math_done || _g.math_waiting)return;
    if(_text=="OK"){bbcr_submit_math();return;}if(_text=="C"){_g.input="";return;}
    if(_text=="-"){_g.input=string_pos("-",_g.input)==1?string_delete(_g.input,1,1):"-"+_g.input;return;}
    if(string_length(string_replace_all(_g.input,"-",""))<9)_g.input+=_text;
}
function cr_use_item() {
    var _g=global.bbcr,_item=_g.inventory[_g.slot];if(_item=="" || cr_value(_g,"items_disabled",false))return;
    var _type=global.cr_catalog.items[$ _item].type,_used=false;
    switch(_type){
        case 1:var _yaw=cr_view_yaw();array_push(_g.projectiles,{px:_g.px,pz:_g.pz,dx:sin(_yaw),dz:cos(_yaw),life:30});cr_sound("BsodaSpray");_used=true;cr_rule_break("Drinking",.8);break;
        case 2:_g.stamina=global.cr_catalog.movement.staminaMax*2;_used=true;break;
        case 8:
            var _target=cr_interaction_target();if(_target.kind=="door"){
                _g.doors[_target.index].silent=global.cr_catalog.effects.quiet_opens;cr_sound(global.cr_catalog.effects.nosquee_sound);_used=true;
            }break;
        case 3:case 5:
            for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(point_distance(_g.px,_g.pz,_d.cx,_d.cz)>10)continue;
                if(_type==3 && _d.swing){_d.lock=30;_d.open=0;_used=true;}
                if(_type==5 && _d.lock>0){_d.lock=0;_d.locked=false;cr_door_open(_d);_used=true;}
                if(_used)break;
            }break;
        case 4:cr_alarm_use();_used=true;break;
        case 9:if(_g.rope){cr_rope_end(false);_used=true;}for(var _i=0;_i<array_length(_g.npcs);_i++){var _n=_g.npcs[_i];if(_n.name=="FirstPrize" && point_distance(_g.px,_g.pz,_n.px,_n.pz)<10){_n.cooldown=30;_used=true;}}break;
        case 18:_g.boots=global.cr_catalog.effects.boots_time;array_push(_g.boot_effects,{time:0,duration:_g.boots});_used=true;break;
        case 12:cr_teleporter_begin();_used=true;break;
        case 13:cr_chalk_use();_used=true;break;
        case 14:_used=cr_portal_use();break;
        case 6:case 17:
            for(var _i=0;_i<array_length(global.cr_map.facilities);_i++){var _f=global.cr_map.facilities[_i];if(point_distance(_g.px,_g.pz,_f.x,_f.z)>15)continue;
                if(_type==6 && (string_pos("VendingMachine",_f.name)>0 || _f.name=="SodaMachine" || _f.name=="ZestyMachine")){
                    var _hit=cr_interaction_target();if(_hit.kind!="facility" || _hit.index!=_i || _f.uses<=0)continue;
                    var _keep=cr_cheat_flag("keep_items"),_slot=-1;
                    if(!_keep)_g.inventory[_g.slot]="";
                    for(var _j=0;_j<3;_j++)if(_g.inventory[_j]==""){_slot=_j;break;}
                    if(_keep && _slot<0)return;
                    _f.uses--;
                    _g.inventory[_slot]=array_length(_f.potential)>0?cr_weighted_item(_f.potential):_f.item;
                    return;
                }
                if((_type==6 && _f.name=="PayPhone") || (_type==17 && _f.name=="TapePlayer")){_g.deaf=30;cr_sound("AntiHearing");_used=true;}
            }break;
    }
    if(_used && !cr_cheat_flag("keep_items"))_g.inventory[_g.slot]="";
}
function cr_view_yaw() {
    if(cr_value(global.bbcr,"dead",false) && is_struct(global.bbcr.ending))return global.bbcr.ending.yaw;
    if(cr_cheat_flag("open"))return global.cr_cheat.camera_yaw;
    return global.bbcr.yaw+(keyboard_check(vk_space) && !global.bbcr.rope?pi:0);
}
function cr_ray_box(_b,_x,_y,_z,_dx,_dz) {
    var _delta=[_x-_b.center[0],_y-_b.center[1],_z-_b.center[2]],_near=0,_far=1000000000;
    for(var _i=0;_i<3;_i++){
        var _a=_b.axes[_i],_p=_delta[0]*_a[0]+_delta[1]*_a[1]+_delta[2]*_a[2],_v=_dx*_a[0]+_dz*_a[2],_h=_b.half[_i];
        if(abs(_v)<.00001){if(abs(_p)>_h)return 1000000000;continue;}
        var _t1=(-_h-_p)/_v,_t2=(_h-_p)/_v;
        _near=max(_near,min(_t1,_t2));_far=min(_far,max(_t1,_t2));if(_near>_far)return 1000000000;
    }return _near;
}
function cr_ray_segment(_x,_z,_dx,_dz,_w) {
    var _ex=_w[2]-_w[0],_ez=_w[3]-_w[1],_den=_dx*_ez-_dz*_ex;if(abs(_den)<.00001)return 1000000000;
    var _qx=_w[0]-_x,_qz=_w[1]-_z,_t=(_qx*_ez-_qz*_ex)/_den,_s=(_qx*_dz-_qz*_dx)/_den;
    return (_t>=0 && _s>=0 && _s<=1)?_t:1000000000;
}
function cr_interaction_target() {
    var _g=global.bbcr,_reach=global.cr_catalog.movement.reach,_best=_reach+.0001,_kind="",_index=-1;
    var _yaw=cr_view_yaw(),_dx=sin(_yaw),_dz=cos(_yaw),_eye=global.cr_map.spawn[1]+_g.jump_height;
    for(var _i=0;_i<array_length(global.cr_walls);_i++){
        var _w=global.cr_walls[_i];if(array_length(_w)>4 && _w[4]>=0 && global.cr_map.windows[_w[4]].broken)continue;
        if(_eye>=0 && _eye<=10)_best=min(_best,cr_ray_segment(_g.px,_g.pz,_dx,_dz,_w));
    }
    for(var _i=0;_i<array_length(_g.exits);_i++){var _e=_g.exits[_i];if(_e.state>0 && variable_struct_exists(_e,"barrier"))_best=min(_best,cr_ray_segment(_g.px,_g.pz,_dx,_dz,_e.barrier));}
    var _colliders=global.cr_map.colliders,_mask=global.cr_catalog.movement.click_mask;
    for(var _i=0;_i<array_length(_colliders);_i++){
        var _b=_colliders[_i];if((_mask & (1<<_b.layer))!=0){
            var _t=cr_ray_box(_b,_g.px,_eye,_g.pz,_dx,_dz);
            if(_t<_best){_best=_t;_kind=variable_struct_exists(_b,"facility")?"facility":(variable_struct_exists(_b,"activity") && _g.style=="demo"?"demo_machine":"");_index=variable_struct_exists(_b,"facility")?_b.facility:cr_value(_b,"activity",-1);}
        }
    }
    // Unlocked swing doors use an automatic trigger; they are not IClickable.
    for(var _i=0;_i<array_length(_g.doors);_i++){
        var _d=_g.doors[_i];
        if(_d.swing){var _t=cr_ray_box(_d.trigger,_g.px,_eye,_g.pz,_dx,_dz);if(_t<_best){_best=_t;_kind="";_index=-1;}continue;}
        if(_d.open>0)continue;
        var _t=cr_ray_box(_d.trigger,_g.px,_eye,_g.pz,_dx,_dz);
        if(_t<_best){_best=_t;_kind="door";_index=_i;}
        var _wall_t=cr_ray_segment(_g.px,_g.pz,_dx,_dz,[_d.cx-_d.tx*5,_d.cz-_d.tz*5,_d.cx+_d.tx*5,_d.cz+_d.tz*5]);
        if(_eye>=0 && _eye<=10 && _wall_t<_best){_best=_wall_t;_kind="";_index=-1;}
    }
    for(var _k=0;_k<2;_k++){
        var _list=_k==0?_g.books:_g.items,_radius=_k==0?global.cr_catalog.pickups.Notebook.radius:global.cr_catalog.pickups.Pickup.radius;
        for(var _i=0;_i<array_length(_list);_i++){
            var _o=_list[_i];if(_o.done || (_k==0 && _g.style=="demo" && !_o.book_ready))continue;
            var _target_x=(_k==0 && _g.style=="demo")?_o.book_x:_o.x,_target_z=(_k==0 && _g.style=="demo")?_o.book_z:_o.z;
            var _ox=_g.px-_target_x,_oz=_g.pz-_target_z,_oy=_eye-5,_b=_ox*_dx+_oz*_dz,_c=_ox*_ox+_oz*_oz+_oy*_oy-_radius*_radius,_disc=_b*_b-_c;
            if(_disc<0 || _c<0)continue;var _t=-_b-sqrt(_disc);
            if(_t>=0 && _t<_best){_best=_t;_kind=_k==0?"book":"item";_index=_i;}
        }
    }
    if(_g.style=="demo")for(var _bi=0;_bi<array_length(_g.books);_bi++){
        var _book=_g.books[_bi];if(_book.state!="active")continue;
        for(var _ni=0;_ni<array_length(_book.numbers);_ni++){
            var _n=_book.numbers[_ni];if(!_n.active || _n.held)continue;var _ox=_g.px-_n.px,_oz=_g.pz-_n.pz,_oy=_eye-5,_b=_ox*_dx+_oz*_dz,_c=_ox*_ox+_oz*_oz+_oy*_oy-_n.spec.radius*_n.spec.radius,_disc=_b*_b-_c;
            if(_disc<0 || _c<0)continue;var _t=-_b-sqrt(_disc);if(_t>=0 && _t<_best){_best=_t;_kind="demo_number";_index=_bi*10+_ni;}
        }
    }
    if(_g.style=="party" && is_struct(_g.party) && _g.party.phase=="candle"){
        var _t=cr_ray_box(_g.party.data.candle.box,_g.px,_eye,_g.pz,_dx,_dz);if(_t<_best){_best=_t;_kind="party_candle";_index=0;}
    }
    if(_g.style=="party" && variable_struct_exists(global.cr_map,"puzzle")){
        var _p=global.cr_map.puzzle;
        if(!_g.party.puzzle_open){var _t=cr_ray_box(_p.wall.box,_g.px,_eye,_g.pz,_dx,_dz);if(_t<_best){_best=_t;_kind="";_index=-1;}}
        for(var _i=0;_i<4;_i++){var _t=cr_ray_box(_p.buttons[_i].box,_g.px,_eye,_g.pz,_dx,_dz);if(_t<_best){_best=_t;_kind="party_button";_index=_i;}}
    }
    for(var _i=0;_i<array_length(_g.alarms);_i++){
        var _a=_g.alarms[_i],_s=global.cr_catalog.effects.alarm,_ox=_g.px-_a.x,_oz=_g.pz-_a.z;
        var _b=_ox*_dx+_oz*_dz,_c=sqr(_ox)+sqr(_oz)+sqr(_eye-5-_s.center.y)-sqr(_s.radius),_disc=sqr(_b)-_c;
        if(!_a.finished && _disc>=0){var _t=-_b-sqrt(_disc);if(_t>=0 && _t<_best){_best=_t;_kind="alarm";_index=_i;}}
    }
    return {kind:_kind,index:_index,distance:_best};
}
function cr_interact() {
    if(is_struct(global.bbcr.null_mode) && cr_null_throw())return;
    if(is_struct(global.bbcr.secret_route) && cr_secret_route_interact())return;
    var _g=global.bbcr,_target=cr_interaction_target(),_kind=_target.kind,_index=_target.index;
    if(_kind=="door")cr_door_open(_g.doors[_index]);
    if(_kind=="book")cr_collect_book(_index);
    if(_kind=="demo_number")cr_demo_hold_number(_index);
    if(_kind=="demo_machine")cr_demo_submit_machine(_index);
    if(_kind=="party_candle")cr_party_candle();
    if(_kind=="party_button")cr_party_puzzle_press(_index);
    if(_kind=="alarm")cr_alarm_wind(_index);
    if(_kind=="item"){
        var _slot=_g.slot;for(var _i=0;_i<3;_i++)if(_g.inventory[_i]==""){_slot=_i;break;}
        var _old=_g.inventory[_slot];_g.inventory[_slot]=_g.items[_index].item;_g.items[_index].done=true;
        if(_old!="")array_push(_g.items,{x:_g.items[_index].x,z:_g.items[_index].z,item:_old,done:false});
    }
}
function bbcr_game_step() {
    cr_caption_tick(delta_time/1000000);
    var _g=global.bbcr,_dt=min(delta_time/1000000,.05);
    cr_audio_update_volume();
    if(cr_cheat_step())return;
    _dt*=cr_cheat_multiplier("time_scale");
    if(cr_cheat_flag("stamina"))_g.stamina=max(_g.stamina,global.cr_catalog.movement.staminaMax);
    cr_pause_tick(delta_time/1000000);
    cr_transition_tick(global.cr_math_ui,delta_time/1000000);
    cr_loading_exit_tick(delta_time/1000000);
    if(_g.dead || _g.won){cr_ending_step(delta_time/1000000);return;}
    if(_g.scene=="nullpad" || _g.scene=="secretbook"){if(_g.scene=="nullpad")cr_npc_voice_tick(_g.npcs[0]);cr_game_ui_input(global.cr_math_ui,_dt);return;}
    if(_g.scene=="math"){cr_math_step(_dt);if(!_g.hard)return;}
    if(keyboard_check_pressed(vk_escape) && _g.scene!="math")cr_pause(!_g.paused);
    if(_g.paused){cr_game_ui_input(global.cr_pause_ui,_dt);return;}
    _g.time+=_dt;cr_voice_tick();
    var _canmove=_g.scene=="game";
    if(_canmove){
        var _reverse=cr_input_reverse();
        if(window_has_focus() && !_g.testing){if(!window_mouse_get_locked()){window_mouse_set_locked(true);_g.mouse_skip=true;}var _md=window_mouse_get_delta_x();if(!_g.mouse_skip)_g.yaw+=degtorad(_md*_g.sensitivity)*_reverse;_g.mouse_skip=false;}
        _g.yaw+=(keyboard_check(vk_right)-keyboard_check(vk_left))*_dt*1.8*_reverse;
        var _f=keyboard_check(ord("W"))-keyboard_check(ord("S")),_s=keyboard_check(ord("D"))-keyboard_check(ord("A"));
        _s*=_reverse;
        if(_g.move_latch){if(_f==0 && _s==0)_g.move_latch=false;_f=0;_s=0;}
        cr_rope_step(_dt,keyboard_check_pressed(vk_space));
        var _len=point_distance(0,0,_f,_s),_run=keyboard_check(vk_shift),_speed=(_run && _g.stamina>0)?global.cr_catalog.movement.runSpeed:global.cr_catalog.movement.walkSpeed;
        if(is_struct(_g.null_mode))_speed=_run && _g.stamina>0?_g.null_mode.run_speed:_g.null_mode.walk_speed;
        _speed*=cr_cheat_multiplier("speed")*cr_rope_move_scale()*cr_party_move_scale()*cr_extra_move_scale()*cr_demo_move_scale(_g);
        var _oldx=_g.px,_oldz=_g.pz;
        if(_len>0)cr_move(_g,(_f*sin(_g.yaw)+_s*cos(_g.yaw))/_len*_speed*_dt,(_f*cos(_g.yaw)-_s*sin(_g.yaw))/_len*_speed*_dt,global.cr_catalog.movement.radius);
        var _moved=point_distance(_oldx,_oldz,_g.px,_g.pz)>.001;
        if(_moved && _run){if(!cr_cheat_flag("stamina"))_g.stamina=max(0,_g.stamina-global.cr_catalog.movement.staminaDrop*_dt);if(_g.stamina>0)cr_rule_break("Running",.1);}
        else if(!_moved && _g.stamina<100)_g.stamina=min(100,_g.stamina+global.cr_catalog.movement.staminaRise*_dt);
        if(mouse_check_button_pressed(mb_left) || keyboard_check_pressed(ord("E")))cr_interact();
        for(var _i=0;_i<3;_i++)if(keyboard_check_pressed(ord("1")+_i))_g.slot=_i;
        _g.slot=(_g.slot+3+mouse_wheel_down()-mouse_wheel_up()) mod 3;
        if(mouse_check_button_pressed(mb_right) || keyboard_check_pressed(ord("Q")))cr_use_item();
    }
    cr_world_step(_dt);
}
function cr_pause(_on) {
    var _g=global.bbcr;if(global.cr_load_transition.stage<16 || global.cr_pause_ui.stage<16 || global.cr_math_ui.stage<16 || _g.paused==_on)return;
    _g.paused=_on;window_mouse_set_locked(!_on && !_g.testing);window_set_cursor(_on?cr_default:cr_none);_g.mouse_skip=true;
    if(_on){audio_pause_all();cr_ui_dispose(global.cr_pause_ui);global.cr_pause_ui=cr_ui_context("Pause");var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;cr_ui_active("CoreGameManager/PauseMenuScreens",true);global.cr_ui=_old;}
    else {audio_resume_all();cr_audio_update_volume();}
    var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;cr_ui_transition(.01666667);global.cr_pause_ui.reveal=_on;global.cr_ui=_old;
}
function cr_return_menu() {
    if(cr_cheat_flag("open"))cr_cheat_set_open(false);
    cr_cheat_init();
    cr_world_cleanup();cr_audio_clear_all();global.bbcr.math_audio_paused=false;global.bbcr.scene="menu";global.bbcr.page="title";global.bbcr.selection=0;global.bbcr.paused=false;
    cr_ui_scene("MainMenu");cr_save();
}
