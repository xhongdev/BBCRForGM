/// Shared source UI instances: menu, HUD, YCTP and pause never share mutable nodes.
function cr_ui_context(_scene) {
    var _u={surface:-1,previous:-1,stage:16,interval:0,timer:0,nodes:[],lookup:{},paths:{},
        scene:"",hover:"",held:"",time:0,wait:"",wait_time:0,sound:-1,music:-1,intro_time:-1,
        cx:240,cy:180,mouse_x:window_mouse_get_x(),mouse_y:window_mouse_get_y(),option_category:0,sensitivity_category:0,
        free:false,pointer_inside:true,intro_sound:-1,reveal:false,unlock_time:0};
    cr_ui_load_nodes(_u,_scene);return _u;
}
function cr_ui_load_nodes(_u,_scene) {
    var _s=global.cr_ui_data.scenes[$ _scene];_u.scene=_scene;_u.nodes=json_parse(json_stringify(_s.nodes));_u.lookup={};_u.paths={};_u.size=_s.size;
    for(var _i=0;_i<array_length(_u.nodes);_i++){
        var _n=_u.nodes[_i];_u.lookup[$ _n.id]=_n;_u.paths[$ _n.path]=_n.id;
        if(_scene=="Pause")_u.paths[$ string_replace(_n.path,"CoreGameManager/PauseMenuScreens/","")]=_n.id;
        _n.high=false;_n.text_key="";_n.image_override="";_n.base_rect=array_create(4);array_copy(_n.base_rect,0,_n.rect,0,4);
        _n.bar_value=0;_n.toggle_value=false;_n.load_val=0;_n.load_speed=0;_n.load_time=0;_n.glitch=false;
    }
}
function cr_ui_bar_value(_n) {
    var _d=_n.scripts.AdjustmentBars,_factor=power(10,_d.decimals);
    return round(cr_curve(_d.valueCurve.m_Curve,_n.bar_value/array_length(_d.bars))*_factor)/_factor;
}
function cr_ui_bar_draw_state(_n) {
    var _d=_n.scripts.AdjustmentBars;
    for(var _i=0;_i<array_length(_d.bars);_i++)cr_ui_node(_d.bars[_i]).image_override=_i<_n.bar_value?_d.highlighted:_d.unhighlighted;
}
function cr_ui_bar_set(_n,_value) {
    var _length=array_length(_n.scripts.AdjustmentBars.bars);_n.bar_value=0;
    while(_n.bar_value<_length && cr_ui_bar_value(_n)<_value)_n.bar_value++;
    cr_ui_bar_draw_state(_n);
}
function cr_ui_bar_adjust(_n,_dir) {
    if(is_undefined(_n) || !variable_struct_exists(_n.scripts,"AdjustmentBars"))return;
    _n.bar_value=clamp(_n.bar_value+_dir,0,array_length(_n.scripts.AdjustmentBars.bars));
    cr_ui_bar_draw_state(_n);cr_ui_actions(_n.scripts.AdjustmentBars.changed);
}
function cr_ui_toggle_set(_n,_value) {
    if(is_undefined(_n))return;_n.toggle_value=_value;cr_ui_active(_n.scripts.MenuToggle.checkmark,_value);
}
function cr_ui_loading_tick(_dt) {
    cr_ui_animation_tick(global.cr_ui,_dt);
    var _u=global.cr_ui;if(_u.stage<16)return;
    for(var _i=0;_i<array_length(_u.nodes);_i++){
        var _n=_u.nodes[_i];if(!variable_struct_exists(_n.scripts,"ClassicLoadScreen") || !cr_ui_visible(_n))continue;
        _n.load_val=(_n.load_val+48*_dt*_n.load_speed) mod 192;_n.load_time+=_dt*_n.load_speed;_n.load_speed=min(1,_n.load_speed+_dt);
        var _anchor=cr_ui_node(_n.scripts.ClassicLoadScreen.faceAnchor),_prefix=_anchor.path+"/";
        var _dx=round(_n.load_val),_dy=-round(sin(_n.load_time)*128);
        for(var _j=0;_j<array_length(_u.nodes);_j++){
            var _child=_u.nodes[_j];if(_child.id==_anchor.id || string_pos(_prefix,_child.path)==1){_child.rect[0]=_child.base_rect[0]+_dx;_child.rect[1]=_child.base_rect[1]+_dy;}
        }
    }
}
function cr_ui_glyph(_f,_ch) {return variable_struct_exists(_f.chars,_ch)?_f.chars[$ _ch]:_f.chars[$ "?"];}
function cr_ui_advance(_f,_d,_ch) {
    var _g=cr_ui_glyph(_f,_ch),_s=_d.m_fontSize/_f.face.m_PointSize*_f.face.m_Scale*_g.scale;
    return _g.advance*_s+cr_value(_d,"m_characterSpacing",0)*_d.m_fontSize*.01+(_ch==" "?cr_value(_d,"m_wordSpacing",0)*_d.m_fontSize*.01:0);
}
function cr_ui_line_width(_f,_d,_text) {
    var _w=0;for(var _i=1;_i<=string_length(_text);_i++)_w+=cr_ui_advance(_f,_d,string_char_at(_text,_i));return _w;
}
function cr_ui_set_text(_n,_text) {
    if(is_undefined(_n))return;_text=string_replace_all(string(_text),"\\n","\n");
    for(var _gi=0;_gi<array_length(_n.graphics);_gi++){
        var _g=_n.graphics[_gi];if(_g.type!="text" || _g.layout.text==_text)continue;
        var _f=global.cr_ui_data.fonts[$ _g.font],_d=_g.settings,_m=_d.m_margin;
        var _w=_n.rect[2]/_n.scale[0]-_m.x-_m.z,_h=_n.rect[3]/_n.scale[1]-_m.y-_m.w;
        var _lines=[],_line="",_pen=0;
        for(var _i=1;_i<=string_length(_text);_i++){
            var _ch=string_char_at(_text,_i),_a=cr_ui_advance(_f,_d,_ch);
            if(_ch=="\n"){array_push(_lines,_line);_line="";_pen=0;continue;}
            if(_d.m_enableWordWrapping && _pen+_a>_w && string_length(_line)>0){
                if(_ch==" "){array_push(_lines,_line);_line="";_pen=0;continue;}
                var _split=string_last_pos(" ",_line);
                if(_split>0){array_push(_lines,string_copy(_line,1,_split-1));_line=string_delete(_line,1,_split);}
                else {array_push(_lines,_line);_line="";}
                _pen=cr_ui_line_width(_f,_d,_line);
            }
            _line+=_ch;_pen+=_a;
        }array_push(_lines,_line);
        var _bs=_d.m_fontSize/_f.face.m_PointSize*_f.face.m_Scale,_asc=_f.face.m_AscentLine*_bs,_desc=_f.face.m_DescentLine*_bs;
        var _lh=_f.face.m_LineHeight*_bs+_d.m_lineSpacing*_d.m_fontSize*.01;
        if(_d.m_overflowMode==6 && _g.linked_text!=""){
            var _maxlines=max(1,floor((_h-(_asc-_desc))/_lh)+1),_remaining="";
            for(var _j=_maxlines;_j<array_length(_lines);_j++)_remaining+=(_j>_maxlines?"\n":"")+_lines[_j];
            if(array_length(_lines)>_maxlines)array_resize(_lines,_maxlines);
            cr_ui_set_text(cr_ui_node(_g.linked_text),_remaining);
        }
        var _content=_asc-_desc+(array_length(_lines)-1)*_lh,_top=_m.y;
        if(_d.m_VerticalAlignment==512)_top+=(_h-_content)/2;if(_d.m_VerticalAlignment==1024)_top+=_h-_content;
        var _quads=[],_base=_top+_asc,_rgba=_d.m_fontColor;
        for(var _j=0;_j<array_length(_lines);_j++){
            var _line=string_trim_end(_lines[_j]),_length=cr_ui_line_width(_f,_d,_line),_x=_m.x;
            if(_d.m_HorizontalAlignment==2)_x+=(_w-_length)/2;if(_d.m_HorizontalAlignment==4)_x+=_w-_length;
            for(var _i=1;_i<=string_length(_line);_i++){
                var _ch=string_char_at(_line,_i),_gl=cr_ui_glyph(_f,_ch),_s=_bs*_gl.scale,_r=_gl.rect;
                var _pad=cr_value(_f,"sdf",false)?cr_value(_f,"padding",0):0;
                if(_r[2]>0 && _r[3]>0)array_push(_quads,[_r[0]-_pad,_r[1]-_pad,_r[2]+2*_pad,_r[3]+2*_pad,_x+(_gl.bearing[0]-_pad)*_s,_base-(_gl.bearing[1]+_pad)*_s,(_gl.size[0]+2*_pad)*_s,(_gl.size[1]+2*_pad)*_s,round(_rgba.r*255),round(_rgba.g*255),round(_rgba.b*255),round(_rgba.a*255)]);
                _x+=cr_ui_advance(_f,_d,_ch);
            }_base+=_lh;
        }
        _g.layout={text:_text,atlas:_f.file,quads:_quads,underlines:[],line_count:array_length(_lines)};
    }
}
function cr_game_ui_init() {
    if(variable_global_exists("cr_hud"))cr_ui_dispose(global.cr_hud);
    if(variable_global_exists("cr_math_ui"))cr_ui_dispose(global.cr_math_ui);
    if(variable_global_exists("cr_pause_ui"))cr_ui_dispose(global.cr_pause_ui);
    if(variable_global_exists("cr_boots_ui"))cr_ui_dispose(global.cr_boots_ui);
    if(variable_global_exists("cr_rope_ui"))cr_ui_dispose(global.cr_rope_ui);
    if(variable_global_exists("cr_win_ui"))cr_ui_dispose(global.cr_win_ui);
    if(variable_global_exists("cr_detention_ui"))cr_ui_dispose(global.cr_detention_ui);
    global.cr_hud=cr_ui_context("Hud");global.cr_math_ui=cr_ui_context("YCTP");global.cr_pause_ui=cr_ui_context("Pause");
    global.cr_boots_ui=cr_ui_context("Boots");
    global.cr_rope_ui=cr_ui_context("Jumprope");
    global.cr_win_ui=cr_ui_context("Win");
    global.cr_detention_ui=cr_ui_context("Detention");
    var _old=global.cr_ui;global.cr_ui=global.cr_pause_ui;
    cr_ui_active("CoreGameManager/PauseMenuScreens",true);cr_ui_active("Options",false);global.cr_ui=_old;
}
function cr_loading_exit_begin() {
    var _u=global.cr_ui,_out=global.cr_load_transition;
    if(_u.wait!="game" || !surface_exists(_u.surface))return;
    _out.previous=surface_create(480,360);surface_copy(_out.previous,0,0,_u.surface);
    _out.stage=0;_out.timer=.01666667;_out.interval=.01666667;
}
function cr_loading_exit_tick(_dt) {
    var _out=global.cr_load_transition;cr_transition_tick(_out,_dt);
    if(_out.stage>=16 && surface_exists(_out.previous)){surface_free(_out.previous);_out.previous=-1;}
}
function cr_ui_dispose(_u) {
    if(surface_exists(_u.surface))surface_free(_u.surface);_u.surface=-1;
    if(surface_exists(_u.previous))surface_free(_u.previous);_u.previous=-1;
}
function cr_game_ui_input(_u,_dt) {
    if(_u.stage<16)return;
    var _old=global.cr_ui;global.cr_ui=_u;
    var _v=cr_game_viewport(),_scale=_v[2]*640/480;
    _u.cx=(window_mouse_get_x()-_v[0])/_scale;_u.cy=(window_mouse_get_y()-_v[1])/_scale;
    _u.pointer_inside=_u.cx>=0 && _u.cy>=0 && _u.cx<480 && _u.cy<360;
    window_set_cursor(_u.pointer_inside?cr_none:cr_default);
    cr_ui_hover(_u.pointer_inside?cr_ui_hit(_u.cx,_u.cy):"");
    if(mouse_check_button_pressed(mb_left))cr_ui_press(cr_ui_node(_u.hover));
    if(!mouse_check_button(mb_left))_u.held="";
    // Quit replaces the menu context; preserve that newly created menu state.
    if(global.bbcr.scene!="menu")global.cr_ui=_old;
}
function cr_game_ui_draw(_u,_cursor=false) {
    var _old=global.cr_ui;global.cr_ui=_u;
    if(!surface_exists(_u.surface))_u.surface=surface_create(480,360);
    var _world=matrix_get(matrix_world),_view=matrix_get(matrix_view),_proj=matrix_get(matrix_projection);
    surface_set_target(_u.surface);draw_clear_alpha(c_black,0);
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha,bm_inv_src_alpha,bm_one,bm_inv_src_alpha);
    matrix_set(matrix_world,matrix_build_identity());matrix_set(matrix_view,matrix_build(-240,-180,16000,0,0,0,1,1,1));matrix_set(matrix_projection,matrix_build_projection_ortho(480,-360,1,32000));
    cr_ui_draw_nodes();surface_reset_target();gpu_set_blendmode(bm_normal);
    matrix_set(matrix_world,_world);matrix_set(matrix_view,_view);matrix_set(matrix_projection,_proj);
    if(_u.reveal && _u.stage<16)cr_game_transition_draw(_u,_u.surface,true);
    else {
        draw_surface(_u.surface,0,0);
        if(_u.stage<16 && surface_exists(_u.previous))cr_game_transition_draw(_u,_u.previous,false);
    }
    if(_cursor && _u.stage>=16 && _u.pointer_inside)cr_ui_image(global.cr_ui_data.cursor,[round(_u.cx)-24,round(_u.cy)-18,64,64],[255,255,255,255]);
    global.cr_ui=_old;
}
function cr_game_transition_draw(_u,_surface,_reveal) {
    shader_set(shd_cr_dither);shader_set_uniform_f(shader_get_uniform(shd_cr_dither,"u_stage"),_u.stage);
    shader_set_uniform_f(shader_get_uniform(shd_cr_dither,"u_size"),480,360);shader_set_uniform_f(shader_get_uniform(shd_cr_dither,"u_reveal"),_reveal?1:0);
    draw_surface(_surface,0,0);shader_reset();
}
function cr_pause_tick(_dt) {
    cr_transition_tick(global.cr_pause_ui,_dt);
    cr_ui_animation_tick(global.cr_pause_ui,_dt);
}
function cr_ui_button_animation(_n,_high) {
    if(!variable_struct_exists(_n.button,"animation"))return;
    var _a=_n.button.animation,_t=cr_ui_node(_a.target);if(is_undefined(_t))return;
    _t.animation=_high?_a.high:(_a.off==""?_a.high:_a.off);_t.animation_time=0;_t.animation_play=_high || _a.off!="";
    cr_ui_animation_tick(global.cr_ui,0);
}
function cr_ui_animation_tick(_u,_dt) {
    for(var _i=0;_i<array_length(_u.nodes);_i++){
        var _n=_u.nodes[_i];if(!variable_struct_exists(_n,"animation") || _n.animation=="")continue;
        var _a=global.cr_ui_data.animations[$ _n.animation];if(_n.animation_play)_n.animation_time+=_dt;
        var _t=_a.loop?_n.animation_time mod max(.001,_a.length):min(_n.animation_time,_a.length);
        for(var _j=0;_j<array_length(_a.frames);_j++)if(_a.frames[_j][0]<=_t)_n.image_override=_a.frames[_j][1];
    }
}
function cr_transition_tick(_u,_dt) {
    if(_u.stage<16){_u.timer-=_dt;if(_u.timer<=0){_u.stage++;_u.timer=_u.interval;}}
}
function cr_boots_draw() {
    var _g=global.bbcr,_old=global.cr_ui;global.cr_ui=global.cr_boots_ui;
    var _node=cr_ui_node("Boots/Canvas/Sprite");
    for(var _i=0;_i<array_length(_g.boot_effects);_i++){
        var _e=_g.boot_effects[_i],_up=_e.time>=_e.duration,_anim=global.cr_ui_data.animations[$ (_up?"Up":"Down")];
        var _time=_up?_e.time-_e.duration:_e.time;
        for(var _j=0;_j<array_length(_anim.floats);_j++){
            var _f=_anim.floats[_j];if(_f.attribute=="m_AnchoredPosition.y")_node.rect[1]=_node.base_rect[1]+244-cr_curve(_f.curve.m_Curve,_time);
        }
        cr_ui_draw_nodes();
    }global.cr_ui=_old;
}
function cr_camera_view(_x,_z,_yaw,_jump=0) {
    // GameMaker's look-at matrix and Unity both use +X as camera-right at yaw 0.
    var _eye=global.cr_map.spawn[1]+_jump+cr_value(global.bbcr,"world_y",0);
    var _roll=global.bbcr.style=="demo" && is_struct(global.bbcr.demo)?degtorad(global.bbcr.demo.roll):0;
    return matrix_build_lookat(_x,_eye,_z,_x+sin(_yaw),_eye,_z+cos(_yaw),-cos(_yaw)*sin(_roll),cos(_roll),sin(_yaw)*sin(_roll));
}
function cr_ui_math_face() {
    var _g=global.bbcr,_n=cr_ui_node("YCTP/YCTP_Canvas/YCTP_Baldi"),_name="BaldiTalk",_time=0;
    if(_g.wrong>0){_name="BaldiFrown";_time=max(0,5-_g.math_delay);}
    else if(audio_is_playing(_g.voice) && variable_struct_exists(global.cr_ui_data.voice_envelopes,_g.voice_key)){
        var _e=global.cr_ui_data.voice_envelopes[$ _g.voice_key],_i=clamp(floor(audio_sound_get_track_position(_g.voice)*60),0,array_length(_e)-1);
        _time=cr_curve(_n.scripts.VolumeAnimator.sensitivity.m_Curve,_e[_i])*global.cr_ui_data.animations.BaldiTalk.length;
    }
    var _anim=global.cr_ui_data.animations[$ _name],_frames=_anim.frames;_n.image_override=_frames[0][1];
    for(var _i=0;_i<array_length(_frames);_i++)if(_time>=_frames[_i][0])_n.image_override=_frames[_i][1];
}
function cr_ui_animation_sprite(_anim,_time) {
    var _key=_anim.frames[0][1];for(var _i=0;_i<array_length(_anim.frames);_i++)if(_time>=_anim.frames[_i][0])_key=_anim.frames[_i][1];return _key;
}
