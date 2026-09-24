/// Current feedback: source caption metadata, tooltip callbacks and NULL input.
function cr_session_data_init() {
    global.cr_session_data=cr_json("bbcr/session_feedback.json");var _d=global.cr_session_data;
    var _groups=["scenes","images","fonts","sounds"];
    for(var _g=0;_g<4;_g++){var _group=_groups[_g],_keys=variable_struct_get_names(_d[$ _group]);for(var _i=0;_i<array_length(_keys);_i++)global.cr_ui_data[$ _group][$ _keys[_i]]=_d[$ _group][$ _keys[_i]];}
    var _keys=variable_struct_get_names(_d.images);for(var _i=0;_i<array_length(_keys);_i++)global.cr_catalog.sprites[$ _keys[_i]]=_d.images[$ _keys[_i]];
    _keys=variable_struct_get_names(_d.sounds);for(var _i=0;_i<array_length(_keys);_i++)global.cr_catalog.sounds[$ _keys[_i]]=_d.sounds[$ _keys[_i]];
    global.cr_captions=[];global.cr_caption_ui=cr_ui_context("Subtitle");global.bbcr.error_event=undefined;global.bbcr.sound_memory=[];global.bbcr.sound_memory_pos=0;
    for(var _i=0;_i<array_length(_d.initial_memory);_i++)cr_sound_memory_add(_d.initial_memory[_i]);
}
function cr_null_pause_confirm() {
    var _g=global.bbcr;if(!is_struct(cr_value(_g,"null_mode",undefined)) || array_length(_g.npcs)==0)return false;
    var _n=_g.npcs[0];_n.px=_g.px+sin(_g.yaw);_n.pz=_g.pz+cos(_g.yaw);_n.hidden=false;
    path_clear_points(_n.path);_n.route_timer=0;
    // Press may have started the confirmation's UI transition this frame.
    // Complete it before using the normal resume lifecycle.
    global.cr_pause_ui.stage=16;global.cr_math_ui.stage=16;global.cr_load_transition.stage=16;
    cr_pause(false);return true;
}
function cr_tooltip_open(_owner,_key) {
    if(is_undefined(_owner) || !variable_struct_exists(_owner.scripts,"TooltipController"))return;
    var _u=global.cr_ui;_u.tooltip_owner=_owner.id;_u.tooltip_key=_key;_u.tooltip_count=cr_value(_u,"tooltip_count",0)+1;
    cr_tooltip_update();
}
function cr_tooltip_close(_owner) {
    var _u=global.cr_ui;_u.tooltip_count=max(0,cr_value(_u,"tooltip_count",0)-1);
    if(_u.tooltip_count==0){_u.tooltip_key="";cr_tooltip_update();}
}
function cr_tooltip_update() {
    var _u=global.cr_ui,_owner=cr_ui_node(cr_value(_u,"tooltip_owner","Options"));
    if(is_undefined(_owner) || !variable_struct_exists(_owner.scripts,"TooltipController"))return;
    var _s=_owner.scripts.TooltipController,_txt=cr_ui_node(_s.tooltipTmp),_bg=cr_ui_node(_s.tooltipBgRect),_key=cr_value(_u,"tooltip_key","");
    _txt.active=_key!="";_bg.active=_txt.active;if(!_txt.active)return;
    var _graphic=_txt.graphics[0],_d=_graphic.settings,_font=global.cr_ui_data.fonts[$ _graphic.font],_text=cr_value(global.cr_text,_key,_key);
    var _width=min(_s.xMax-_s.xMin-_s.xBuffer,cr_ui_line_width(_font,_d,_text));
    _txt.rect=[0,0,max(1,_width),500];_graphic.layout.text="";cr_ui_set_text(_txt,_text);
    var _bs=_d.m_fontSize/_font.face.m_PointSize*_font.face.m_Scale;
    var _height=(_font.face.m_AscentLine-_font.face.m_DescentLine)*_bs+(_graphic.layout.line_count-1)*_font.face.m_LineHeight*_bs;
    var _w=_width+_s.xBuffer,_h=_height+_s.yBuffer,_cx=clamp(_u.cx,_s.xMin+_w/2,_s.xMax-_w/2),_cy=_u.cy-_height/2-_s.yBuffer-8;
    _txt.rect=[_cx-_width/2,_cy-_height/2,_width,_height];_bg.rect=[_cx-_w/2,_cy-_h/2,_w,_h];
    _graphic.layout.text="";cr_ui_set_text(_txt,_text);
}
function cr_caption_start(_entry) {
    if(!variable_global_exists("cr_session_data") || !variable_struct_exists(global.cr_session_data.captions,_entry.key))return;
    if(is_struct(_entry.audio) && cr_value(_entry.audio,"disable_subtitles",false))return;
    var _meta=global.cr_session_data.captions[$ _entry.key];if(_meta.duration<=0)return;
    // AudioManager owns one caption: a newer line from that speaker replaces it.
    for(var _i=array_length(global.cr_captions)-1;_i>=0;_i--)if((is_struct(_entry.owner) && global.cr_captions[_i].entry.owner==_entry.owner) || global.cr_captions[_i].entry.caption_source==_entry.caption_source)array_delete(global.cr_captions,_i,1);
    array_push(global.cr_captions,{entry:_entry,meta:_meta,key:_meta.keys[0].key,text:_meta.keys[0].text,age:0});
}
function cr_caption_remove(_handle) {
    if(!variable_global_exists("cr_captions"))return;
    for(var _i=array_length(global.cr_captions)-1;_i>=0;_i--)if(global.cr_captions[_i].entry.handle==_handle)array_delete(global.cr_captions,_i,1);
}
function cr_caption_world_end() {
    // DestroyAll at a level/ending boundary. Do this before the next scene's
    // dialogue starts, so its captions do not inherit school speaker lifetimes.
    if(variable_global_exists("cr_captions"))global.cr_captions=[];
}
function cr_audio_loop(_handle,_loop) {
    audio_sound_loop(_handle,_loop);
    for(var _i=0;_i<array_length(global.bbcr.sound_instances);_i++)if(global.bbcr.sound_instances[_i].handle==_handle)global.bbcr.sound_instances[_i].loop=_loop;
}
function cr_caption_tick(_dt) {
    if(!variable_global_exists("cr_captions"))return;var _g=global.bbcr;
    for(var _i=array_length(global.cr_captions)-1;_i>=0;_i--){
        var _c=global.cr_captions[_i],_e=_c.entry,_paused=(cr_value(_g,"paused",false) || cr_value(_g,"math_audio_paused",false) || cr_value(_g,"won",false) || cr_value(_g,"dead",false) || cr_cheat_flag("open")) && !_e.ignore_pause;
        if(cr_value(_e,"loop",false) && !audio_is_playing(_e.handle) && !_paused){array_delete(global.cr_captions,_i,1);continue;}
        if(_paused)continue;
        // SubtitleController.Die owns its timer, independently of clip length
        // and pitch. Short one-shots such as the ruler retain their full caption.
        if(cr_value(_e,"loop",false))continue;
        _c.age+=_dt;
        if(_c.age>_c.meta.duration){array_delete(global.cr_captions,_i,1);continue;}
        for(var _j=array_length(_c.meta.keys)-1;_j>=0;_j--)if(_c.age>=_c.meta.keys[_j].time){_c.key=_c.meta.keys[_j].key;_c.text=_c.meta.keys[_j].text;break;}
    }
}
function cr_caption_position(_e) {
    var _g=global.bbcr;if(is_undefined(_e.px) || _e.interface || !variable_struct_exists(_g,"px") || _g.scene=="menu" || (is_struct(_e.audio) && !_e.audio.positional))return [240,280,1];
    var _x=is_struct(_e.owner)?_e.owner.px:_e.px,_z=is_struct(_e.owner)?_e.owner.pz:_e.pz;
    var _cx=_g.px,_cz=_g.pz,_yaw=cr_view_yaw(),_cy=5+cr_value(_g,"world_y",0)+cr_value(_g,"jump_height",0);
    if(variable_global_exists("cr_map"))_cy+=global.cr_map.spawn[1]-5;
    if(cr_value(_g,"dead",false) && is_struct(_g.ending)){_cx=_g.ending.x;_cz=_g.ending.z;_yaw=_g.ending.yaw;_cy=6;}
    var _sy=is_struct(_e.owner)?cr_value(_e.owner,"py",5+cr_value(_g,"world_y",0)):cr_value(_e,"py",5+cr_value(_g,"world_y",0));
    var _angle=arctan2(_cz-_z,_cx-_x)+_yaw+pi,_distance=is_struct(_e.audio)?_e.audio.max_distance:150;
    return [240+cos(_angle)*144*(_g.mirror?-1:1),180-sin(_angle)*144,max(0,1-sqrt(sqr(_cx-_x)+sqr(_cz-_z)+sqr(_cy-_sy))/max(.0001,_distance))];
}
function cr_caption_draw() {
    var _g=global.bbcr;if(!_g.subtitles || !variable_global_exists("cr_captions"))return;
    var _old=global.cr_ui;global.cr_ui=global.cr_caption_ui;
    var _root=global.cr_ui.nodes[0],_spec=_root.scripts.SubtitleController,_text=cr_ui_node(_spec.text),_bg=cr_ui_node(_spec.bg);
    for(var _i=0;_i<array_length(global.cr_captions);_i++){
        var _c=global.cr_captions[_i],_e=_c.entry;
        if((cr_value(_g,"paused",false) || cr_value(_g,"math_audio_paused",false) || cr_value(_g,"won",false) || cr_value(_g,"dead",false)) && !_e.ignore_pause)continue;
        var _p=cr_caption_position(_e);if(_p[2]<=0)continue;
        _text.scale=[1,1];_text.rect=[0,0,200,75];_text.graphics[0].settings.m_fontColor=is_struct(_e.audio)&&cr_value(_e.audio,"override_subtitle_color",false)?_e.audio.subtitle_color:_c.meta.color;
        var _font=global.cr_ui_data.fonts[$ _text.graphics[0].font],_size=global.cr_session_data.subtitle.max_size;
        repeat(25){_text.graphics[0].settings.m_fontSize=_size;_text.graphics[0].layout.text="";cr_ui_set_text(_text,_c.text);var _fs=_size/_font.face.m_PointSize*_font.face.m_Scale;
            if((_font.face.m_AscentLine-_font.face.m_DescentLine+(_text.graphics[0].layout.line_count-1)*_font.face.m_LineHeight)*_fs<=75 || _size<=global.cr_session_data.subtitle.min_size)break;_size-=.5;}
        var _r=[_p[0]-100*_p[2],_p[1]-37.5*_p[2],200*_p[2],75*_p[2]];
        cr_ui_fill(_r,_bg.graphics[0].color);
        var _layout=_text.graphics[0].layout,_spr=cr_sprite(_layout.atlas);
        var _filter=gpu_get_texfilter();gpu_set_texfilter(true);gpu_set_tex_mip_filter(mip_off);shader_set(shd_cr_caption);
        for(var _j=0;_j<array_length(_layout.quads);_j++)cr_ui_quad(_spr,_layout.quads[_j],_r[0],_r[1],_p[2],_p[2]);
        shader_reset();gpu_set_texfilter(_filter);
    }global.cr_ui=_old;
}
function cr_caption_present() {
    // SubtitleManager has its own 480x360 canvas, also in the 288x380 launcher.
    // Draw once at the final window resolution so SDF antialiasing sees real pixels.
    var _w=window_get_width(),_h=window_get_height(),_s=min(_w/480,_h/360),_old=matrix_get(matrix_world),_z=gpu_get_ztestenable(),_zw=gpu_get_zwriteenable();
    gpu_set_ztestenable(false);gpu_set_zwriteenable(false);
    matrix_set(matrix_world,matrix_build((_w-480*_s)/2,(_h-360*_s)/2,0,0,0,0,_s,_s,1));
    cr_caption_draw();matrix_set(matrix_world,_old);gpu_set_ztestenable(_z);gpu_set_zwriteenable(_zw);
}
function cr_sound_memory_add(_key) {
    var _g=global.bbcr;if(!variable_struct_exists(global.cr_session_data.sound_objects,_key) || !global.cr_session_data.sound_objects[$ _key].memory)return;
    if(array_contains(_g.sound_memory,_key))return;
    if(array_length(_g.sound_memory)<32)array_push(_g.sound_memory,_key);
    else {_g.sound_memory[_g.sound_memory_pos]=_key;_g.sound_memory_pos=(_g.sound_memory_pos+1) mod 32;}
}
function cr_null_edge_open(_a,_b) {
    var _ta=global.cr_map.tiles[_a],_tb=global.cr_map.tiles[_b];
    for(var _i=1;_i<10;_i++)if(cr_blocked(lerp(_ta.x*10+5,_tb.x*10+5,_i/10),lerp(_ta.z*10+5,_tb.z*10+5,_i/10),global.cr_catalog.movement.radius))return false;
    return true;
}
function cr_null_blocker_safe(_block,_dir) {
    // Removing an edge must not split the currently traversable graph. This
    // includes locked doors and other active blockers, not only static tile bins.
    var _tiles=global.cr_map.tiles,_start=_block.tile,_end=_tiles[_start].nav[_dir];if(_end<0 || !cr_null_edge_open(_start,_end))return false;
    var _queue=[_start],_seen=array_create(array_length(_tiles),false),_head=0;_seen[_start]=true;
    while(_head<array_length(_queue)){
        var _at=_queue[_head++],_t=_tiles[_at];
        for(var _d=0;_d<4;_d++){var _next=_t.nav[_d];if(_next<0 || _seen[_next] || (_at==_start && _next==_end) || (_at==_end && _next==_start))continue;
            if(!cr_null_edge_open(_at,_next))continue;if(_next==_end)return true;_seen[_next]=true;array_push(_queue,_next);
        }
    }return false;
}
