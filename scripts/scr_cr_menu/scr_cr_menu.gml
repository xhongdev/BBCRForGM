/// Menu geometry, graphics, glyph quads and callbacks are imported from BBCR Unity scenes.
function cr_ui_init() {
    global.cr_ui_data=cr_json("bbcr/menu.json");
    cr_session_data_init();
    var _keys=variable_struct_get_names(global.cr_ui_data.images);
    for(var _i=0;_i<array_length(_keys);_i++)global.cr_catalog.sprites[$ _keys[_i]]=global.cr_ui_data.images[$ _keys[_i]];
    _keys=variable_struct_get_names(global.cr_ui_data.sounds);
    for(var _i=0;_i<array_length(_keys);_i++)global.cr_catalog.sounds[$ _keys[_i]]=global.cr_ui_data.sounds[$ _keys[_i]];
    global.cr_ui=cr_ui_context("ClassicLauncher");
    cr_ui_scene("ClassicLauncher");
}
function cr_ui_node(_path) {
    var _u=global.cr_ui;
    if(variable_struct_exists(_u.paths,_path))return _u.lookup[$ _u.paths[$ _path]];
    if(variable_struct_exists(_u.lookup,_path))return _u.lookup[$ _path];
    return undefined;
}
function cr_ui_active(_path,_active) {
    var _n=cr_ui_node(_path);if(is_undefined(_n))return;
    if(_active && !_n.active)cr_menu_on_enable(_n);
    _n.active=_active;
    if(!_active){
        var _nodes=global.cr_ui.nodes;
        for(var _i=0;_i<array_length(_nodes);_i++){
            var _child=_nodes[_i];
            if(_child.high && !cr_ui_visible(_child)){
                _child.high=false;cr_ui_actions(_child.button.off);
                if(global.cr_ui.hover==_child.id)global.cr_ui.hover="";
            }
        }
    }
    if(_active && variable_struct_exists(_n.scripts,"OptionsMenu"))cr_ui_options_init();
    if(_active && _n.parent==""){
        global.bbcr.page=string_lower(_n.path);global.cr_ui.time=0;
    }
}
function cr_ui_visible(_n) {
    if(!_n.active)return false;
    if(_n.parent!="" && variable_struct_exists(global.cr_ui.lookup,_n.parent))return cr_ui_visible(global.cr_ui.lookup[$ _n.parent]);
    return true;
}
function cr_ui_scene(_scene) {
    var _u=global.cr_ui,_s=global.cr_ui_data.scenes[$ _scene];
    cr_ui_load_nodes(_u,_scene);
    _u.hover="";_u.held="";_u.time=0;_u.wait="";_u.stage=16;_u.cx=_s.size[0]/2;_u.cy=_s.size[1]/2;_u.intro_time=-1;_u.pointer_inside=true;
    if(surface_exists(_u.surface))surface_free(_u.surface);_u.surface=-1;
    global.bbcr.scene="menu";window_mouse_set_locked(false);window_set_cursor(cr_none);
    switch(_scene){
        case "ClassicLauncher":global.bbcr.page="launcher";cr_ui_active("Canvas/Cover",false);_u.music=cr_sound("BaldiLauncher");break;
        case "Logo":global.bbcr.page="logo";audio_stop_all();break;
        case "Warnings":global.bbcr.page="warning";_u.music=cr_sound("ErrorScreen");if(_u.music>=0)audio_sound_loop(_u.music,true);break;
        case "MainMenu":
            cr_ui_active("BlackCover",false);global.bbcr.page="title";_u.unlock_time=0;cr_ui_active("LoadingScreen",false);
            _u.music=-1;
            cr_progress_menu_sync();
            if(global.bbcr.unlock_notice!=""){
                cr_ui_active("LoadingScreen",true);cr_ui_set_text(cr_ui_node("LoadingScreen/Text/Text1"),global.bbcr.unlock_notice);
                _u.unlock_time=7;_u.sound=cr_sound("BAL_Wow");_u.intro_time=-1;
            }else {_u.intro_time=1.5;_u.music=cr_sound("titleFixed");}
            cr_ui_transition(.0666666,true);break;
    }
}
function cr_ui_transition(_interval,_black=false) {
    var _u=global.cr_ui;
    if(surface_exists(_u.previous))surface_free(_u.previous);
    _u.previous=surface_create(_u.size[0],_u.size[1]);
    if(_black || !surface_exists(_u.surface)){surface_set_target(_u.previous);draw_clear(c_black);surface_reset_target();}
    else surface_copy(_u.previous,0,0,_u.surface);
    _u.interval=_interval;_u.timer=_interval;_u.stage=0;_u.hover="";_u.reveal=false;
    _u.transition_type="dither";_u.swipe_time=0;
}
function cr_ui_text_key(_n,_key) {
    if(is_undefined(_n))return;_n.text_key=_key;
}
function cr_ui_options_init() {
    var _u=global.cr_ui,_g=global.bbcr,_n=cr_ui_node("Options");if(is_undefined(_n))return;
    var _o=_n.scripts.OptionsMenu;_u.option_category=0;_u.sensitivity_category=0;
    _u.tooltip_owner=_n.id;_u.tooltip_key="";_u.tooltip_count=0;cr_tooltip_update();
    for(var _i=0;_i<array_length(_o.categories);_i++)cr_ui_active(_o.categories[_i],_i==0);
    for(var _i=0;_i<array_length(_o.sensitivityCategories);_i++)cr_ui_active(_o.sensitivityCategories[_i],_i==0);
    for(var _i=0;_i<array_length(_o.soundAdj);_i++)cr_ui_bar_set(cr_ui_node(_o.soundAdj[_i]),_g.volumes[_i]);
    for(var _i=0;_i<array_length(_o.sensitivityAdj);_i++)cr_ui_bar_set(cr_ui_node(_o.sensitivityAdj[_i]),_g.sensitivities[_i]);
    var _keys=["subtitlesToggle","fullScreenToggle","vsyncToggle","pixelFilterToggle","flashToggle","rumbleToggle","launcherToggle"];
    var _values=[_g.subtitles,window_get_fullscreen(),_g.vsync,_g.pixel_filter,_g.reduce_flashing,_g.rumble,_g.skip_launcher];
    for(var _i=0;_i<array_length(_keys);_i++)cr_ui_toggle_set(cr_ui_node(_o[$ _keys[_i]]),_values[_i]);
    cr_ui_set_text(cr_ui_node(_o.resolutionTMP),string(window_get_width())+"x"+string(window_get_height()));
}
function cr_ui_actions(_calls) {
    var _u=global.cr_ui,_g=global.bbcr;
    for(var _i=0;_i<array_length(_calls);_i++){
        var _a=_calls[_i],_n=cr_ui_node(_a.target);
        switch(_a.method){
            case "SetActive":cr_ui_active(_a.target,_a.bool);break;
            case "GetLocalizedText":cr_ui_text_key(_n,_a.string);break;
            case "AssignLevelKey":
                _n.level_key=_a.string;break;
            case "SetStyle":_g.style=["classic","party","demo","null"][_a.int];break;
            case "LoadScores":
                var _overview=_n.scripts.EndlessMapOverview;
                var _key=cr_value(_n,"level_key","Men_ClassicStyle");
                // The source NULL button deliberately passes an empty key to
                // EndlessMapOverview. Its panel still identifies the selected
                // style; do not render an implementation-language "undefined"
                // or an empty blackboard in the port.
                if(_key=="")_key="NULL";
                cr_ui_set_text(cr_ui_node(_overview.levelName),cr_value(global.cr_text,_key,_key));
                if(_a.string=="Glitch")for(var _j=0;_j<array_length(_overview.listings);_j++){
                    var _listing=cr_ui_node(_overview.listings[_j]).scripts.HighScoreListing;
                    cr_ui_set_text(cr_ui_node(_listing.name),_g.progress.flags[4]?"ERROR":"NULL");
                    cr_ui_set_text(cr_ui_node(_listing.score),_g.progress.flags[4]?"0":"NULL");
                }
                cr_ui_active(_overview.plusInfoButton,_a.string=="Demo");break;
            case "Activate":case "Deactivate":
                if(_a.component=="GlitchBaldiButton"){
                    var _images=_n.scripts.GlitchBaldiButton.image;
                    for(var _j=0;_j<array_length(_images);_j++){var _image=cr_ui_node(_images[_j]);_image.glitch=_a.method=="Activate";if(_image.glitch)_image.glitch_seed=random(4096);}
                }break;
            case "UpdateFunSettings":cr_progress_menu_sync();break;
            case "StartGame":
                _g.mode=_a.int==1?"endless":(_u.free?"free":"story");cr_ui_active("ModeSelect",false);cr_ui_active("LoadingScreen",true);
                _u.wait="game";_u.wait_time=1;_g.loading_drawn=false;audio_stop_all();break;
            case "ToggleFree":_u.free=!_u.free;cr_ui_active("ModeSelect/FunSettings/FunSetting4/Check",_u.free);break;
            case "ToggleMirror":
                if(_g.progress.classic_won){_g.mirror=!_g.mirror;cr_progress_menu_sync();}break;
            case "ToggleLights":
                if(_g.progress.party_won){_g.lightsout=!_g.lightsout;cr_progress_menu_sync();}break;
            case "ToggleHard":
                if(_g.progress.demo_won){_g.hard=!_g.hard;cr_progress_menu_sync();}break;
            case "Play":_u.wait="logo";break;
            case "Exit":_u.wait="exit";break;
            case "Quit":if(_a.component=="CoreGameManager"){if(cr_null_pause_confirm())return;cr_return_menu();return;}_u.sound=cr_sound("BAL_ThanksForPlaying");_u.wait="quit_voice";break;
            case "Pause":cr_pause(false);return;
            case "HoverQuit":
                // User-requested click semantics, including the Glitch route.
                // Highlight retains the source button animation only.
                break;
            case "UpdateTooltip":cr_tooltip_open(_n,_a.string);break;
            case "CloseTooltip":cr_tooltip_close(_n);break;
            case "Okay":cr_null_pad_close();return;
            case "Open":if(_a.component=="ClassicMathBook")cr_secret_book_turn(_a.bool);break;
            case "NumberEntered":cr_math_input(_a.int<0?"-":string(_a.int));break;
            case "Clear":cr_math_input("C");break;
            case "SubmitAnswer":bbcr_submit_math();break;
            case "PlaySingle":_u.sound=cr_sound(_a.object,undefined,undefined,true,undefined,undefined,false,"ui:"+_u.scene+":"+_a.target);break;
            case "OpenPage":if(_a.url!="")url_open(_a.url);break;
            case "Close":
                if(_a.component=="ClassicMathBook"){cr_secret_book_close();return;}
                if(_a.component=="Credits"){cr_ui_active("Credits",false);cr_ui_active("Menu",true);audio_stop_all();}
                else if(_a.component=="OptionsMenu"){cr_save();}
                break;
            case "ChangeCategory":
                var _categories=_n.scripts.OptionsMenu.categories;
                _u.option_category=(_u.option_category+_a.int+array_length(_categories)) mod array_length(_categories);
                for(var _j=0;_j<array_length(_categories);_j++)cr_ui_active(_categories[_j],_j==_u.option_category);break;
            case "ChangeSensitivityCategory":
                _u.sensitivity_category=1-_u.sensitivity_category;
                var _cats=_n.scripts.OptionsMenu.sensitivityCategories;for(var _j=0;_j<2;_j++)cr_ui_active(_cats[_j],_j==_u.sensitivity_category);break;
            case "ToggleFullScreen":case "ToggleFullscreen":window_set_fullscreen(!window_get_fullscreen());cr_ui_active("Options/Graphics/FullScreenToggle/Box/Check",window_get_fullscreen());break;
            case "ToggleLauncher":_g.skip_launcher=!_g.skip_launcher;cr_ui_active("Options/General/LauncherToggle/Box/Check",_g.skip_launcher);cr_save();break;
            case "Adjust":
                cr_ui_bar_adjust(_n,_a.int);break;
            case "Toggle":cr_ui_toggle_set(_n,!_n.toggle_value);break;
            case "VolumeChanged":
                var _o=_n.scripts.OptionsMenu;_g.volumes[_a.int]=cr_ui_bar_value(cr_ui_node(_o.soundAdj[_a.int]));
                if(_u.sound>=0)audio_stop_sound(_u.sound);
                if(_a.int<2)_u.sound=cr_sound(_a.int==0?_o.audVoiceTest:_o.audEffectTest);
                else {if(!audio_is_playing(_u.music))_u.music=cr_sound(_o.musicTest);}
                cr_audio_update_volume();cr_save();break;
            case "SensitivityChanged":
                _g.sensitivities[_a.int]=cr_ui_bar_value(cr_ui_node(_n.scripts.OptionsMenu.sensitivityAdj[_a.int]));_g.sensitivity=_g.sensitivities[0];cr_save();break;
            case "FlashingChanged":case "SubtitlesChanged":case "RumbleChanged":case "LauncherChanged":
                var _o=_n.scripts.OptionsMenu;
                if(_a.method=="FlashingChanged")_g.reduce_flashing=cr_ui_node(_o.flashToggle).toggle_value;
                if(_a.method=="SubtitlesChanged")_g.subtitles=cr_ui_node(_o.subtitlesToggle).toggle_value;
                if(_a.method=="RumbleChanged")_g.rumble=cr_ui_node(_o.rumbleToggle).toggle_value;
                if(_a.method=="LauncherChanged")_g.skip_launcher=cr_ui_node(_o.launcherToggle).toggle_value;cr_save();break;
            case "ApplyGraphics":
                var _o=_n.scripts.OptionsMenu;window_set_fullscreen(cr_ui_node(_o.fullScreenToggle).toggle_value);
                _g.pixel_filter=cr_ui_node(_o.pixelFilterToggle).toggle_value;_g.vsync=cr_ui_node(_o.vsyncToggle).toggle_value;cr_save();break;
            default:show_debug_message("BBCR_UI_CALLBACK: "+_a.component+"."+_a.method);break;
        }
    }
}
function cr_ui_press(_n) {
    if(is_undefined(_n) || is_undefined(_n.button))return;
    var _u=global.cr_ui;_u.held=_n.id;
    if(_n.button.transition)cr_ui_transition(_n.button.interval);
    cr_ui_actions(_n.button.press);
}
function cr_ui_hit(_x,_y) {
    var _u=global.cr_ui;
    for(var _i=array_length(_u.nodes)-1;_i>=0;_i--){
        var _n=_u.nodes[_i];if(!cr_ui_visible(_n))continue;var _r=_n.rect;
        if(_x<_r[0] || _y<_r[1] || _x>=_r[0]+_r[2] || _y>=_r[1]+_r[3])continue;
        for(var _j=0;_j<array_length(_n.graphics);_j++)if(_n.graphics[_j].raycast)return is_undefined(_n.button)?"":_n.id;
    }
    return "";
}
function cr_ui_hover(_id) {
    var _u=global.cr_ui;if(_id==_u.hover)return;
    var _old=cr_ui_node(_u.hover);if(!is_undefined(_old)){_old.high=false;cr_ui_button_animation(_old,false);cr_ui_actions(_old.button.off);}
    _u.hover=_id;var _new=cr_ui_node(_id);if(!is_undefined(_new)){_new.high=true;cr_ui_button_animation(_new,true);cr_ui_actions(_new.button.highlight);}
}
function cr_ui_viewport() {
    var _u=global.cr_ui,_ww=max(1,window_get_width()),_wh=max(1,window_get_height()),_scale=min(_ww/_u.size[0],_wh/_u.size[1]);
    if(_u.scene=="ClassicLauncher")_scale=_scale>1?floor(_scale):_scale;
    return [(_ww-_u.size[0]*_scale)/2,(_wh-_u.size[1]*_scale)/2,_scale];
}
function cr_ui_warning_advance() {
    var _u=global.cr_ui;if(_u.scene!="Warnings" || _u.wait!="")return;
    cr_ui_transition(.01666667);_u.wait="warning";_u.wait_time=1;
}
function cr_ui_pointer(_x,_y) {
    var _v=cr_ui_viewport();return [(_x-_v[0])/_v[2],(_y-_v[1])/_v[2]];
}
function bbcr_menu_step(_dt=delta_time/1000000) {
    var _u=global.cr_ui,_g=global.bbcr;_u.time+=_dt;
    cr_caption_tick(_dt);cr_audio_update_volume();cr_menu_special_step(_dt);
    cr_ui_loading_tick(_dt);
    if(_u.intro_time>=0){_u.intro_time-=_dt;if(_u.intro_time<0)_u.intro_sound=cr_sound("BAL_MenuIntro");}
    if(cr_value(_u,"transition_type","")=="swipe"){
        _u.swipe_time+=_dt;_u.stage=_u.swipe_time>=.25?16:0;
    }else if(_u.stage<16){if(_u.timer<=0){_u.stage++;_u.timer=_u.interval;}else _u.timer-=_dt;}
    if(_u.scene=="MainMenu" && _u.unlock_time>0){
        _u.unlock_time-=_dt;
        if(_u.unlock_time<=0){cr_ui_transition(.0666666);cr_ui_active("LoadingScreen",false);cr_ui_set_text(cr_ui_node("LoadingScreen/Text/Text1"),global.cr_text.Men_Load);_g.unlock_notice="";_u.music=cr_sound("titleFixed");_u.intro_time=1.5;}
        return;
    }
    if(_u.scene=="Logo"){if(_u.time>=5)cr_ui_scene("Warnings");return;}
    if(_u.wait!=""){
        switch(_u.wait){
            case "logo":case "exit":if(!audio_is_playing(_u.sound)){if(_u.wait=="logo")cr_ui_scene("Logo");else game_end();}break;
            case "warning":_u.wait_time-=_dt;audio_sound_gain(_u.music,max(0,_u.wait_time),0);if(_u.wait_time<=0){audio_stop_all();cr_ui_scene("MainMenu");}break;
            case "quit_voice":if(!audio_is_playing(_u.sound)){cr_ui_transition(.01666667);_u.wait="quit_black";}break;
            case "quit_black":if(_u.stage>=16)game_end();break;
            case "game":if(_u.stage>=16){_u.wait_time-=_dt;if(_u.wait_time<=0 && _g.loading_drawn)bbcr_start_game(_g.mode);}break;
        }return;
    }
    if(_u.scene=="Warnings"){
        if(keyboard_check_pressed(vk_anykey) || mouse_check_button_pressed(mb_any))cr_ui_warning_advance();return;
    }
    if(_u.stage<16)return;
    if(window_has_focus() && !_g.testing){
        // An unlocked OS pointer makes the window border reachable for resizing.
        var _mx=window_mouse_get_x(),_my=window_mouse_get_y();
        if(_mx!=_u.mouse_x || _my!=_u.mouse_y){var _p=cr_ui_pointer(_mx,_my);_u.cx=_p[0];_u.cy=_p[1];}
        _u.mouse_x=_mx;_u.mouse_y=_my;
        _u.pointer_inside=_u.cx>=0 && _u.cx<_u.size[0] && _u.cy>=0 && _u.cy<_u.size[1];
        window_set_cursor(_u.pointer_inside?cr_none:cr_default);
    }
    var _boost=keyboard_check(vk_shift)?4:1;
    var _dx=keyboard_check(vk_right)-keyboard_check(vk_left),_dy=keyboard_check(vk_down)-keyboard_check(vk_up);
    if(_dx!=0 || _dy!=0){
        _u.cx=clamp(_u.cx+_dx*400*_boost*_dt,0,_u.size[0]);_u.cy=clamp(_u.cy+_dy*400*_boost*_dt,0,_u.size[1]);_u.pointer_inside=true;
    }
    cr_ui_hover(_u.pointer_inside?cr_ui_hit(round(_u.cx),round(_u.cy)):"");
    if(_u.scene=="ClassicLauncher" && (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape))){_u.sound=cr_sound("BAL_Slap");_u.wait="logo";return;}
    if(mouse_check_button_pressed(mb_left) || keyboard_check_pressed(vk_enter))cr_ui_press(cr_ui_node(_u.hover));
    if(!mouse_check_button(mb_left) && !keyboard_check(vk_enter) && _u.held!=""){
        var _held=cr_ui_node(_u.held);if(!is_undefined(_held))cr_ui_actions(_held.button.release);_u.held="";
    }
}
function cr_ui_quad(_sprite,_q,_x,_y,_sx=1,_sy=1) {
    if(_q[2]<=0 || _q[3]<=0 || _q[6]<=0 || _q[7]<=0)return;
    draw_sprite_part_ext(_sprite,0,_q[0],_q[1],_q[2],_q[3],_x+_q[4]*_sx,_y+_q[5]*_sy,_q[6]/_q[2]*_sx,_q[7]/_q[3]*_sy,make_color_rgb(_q[8],_q[9],_q[10]),_q[11]/255);
}
function cr_ui_image(_name,_r,_rgba,_type=0,_mult=1,_reference_ppu=16) {
    var _spr=cr_sprite(_name);if(_spr<0)return;var _c=make_color_rgb(_rgba[0],_rgba[1],_rgba[2]),_a=_rgba[3]/255;
    if(_type==0 || !variable_struct_exists(global.cr_ui_data.images,_name)){
        draw_sprite_ext(_spr,0,_r[0],_r[1],_r[2]/sprite_get_width(_spr),_r[3]/sprite_get_height(_spr),0,_c,_a);return;
    }
    var _d=global.cr_ui_data.images[$ _name],_b=_d.border,_w=_d.width,_h=_d.height,_ppu=_d.ppu/_reference_ppu*_mult;
    if(_b[0]+_b[1]+_b[2]+_b[3]<=0){draw_sprite_ext(_spr,0,_r[0],_r[1],_r[2]/_w,_r[3]/_h,0,_c,_a);return;}
    var _xs=[0,_b[0],_w-_b[2],_w],_ys=[0,_b[3],_h-_b[1],_h];
    var _xd=[_r[0],_r[0]+_b[0]/_ppu,_r[0]+_r[2]-_b[2]/_ppu,_r[0]+_r[2]],_yd=[_r[1],_r[1]+_b[3]/_ppu,_r[1]+_r[3]-_b[1]/_ppu,_r[1]+_r[3]];
    for(var _y=0;_y<3;_y++)for(var _x=0;_x<3;_x++){
        var _sw=_xs[_x+1]-_xs[_x],_sh=_ys[_y+1]-_ys[_y],_dw=_xd[_x+1]-_xd[_x],_dh=_yd[_y+1]-_yd[_y];
        if(_sw>0 && _sh>0)draw_sprite_part_ext(_spr,0,_xs[_x],_ys[_y],_sw,_sh,_xd[_x],_yd[_y],_dw/_sw,_dh/_sh,_c,_a);
    }
}
function cr_ui_draw_nodes() {
    var _u=global.cr_ui;
    cr_tooltip_update();
    for(var _i=0;_i<array_length(_u.nodes);_i++){
        var _n=_u.nodes[_i];if(!cr_ui_visible(_n))continue;var _r=_n.rect;
        if(min(_r[0],_r[0]+_r[2])>=_u.size[0] || min(_r[1],_r[1]+_r[3])>=_u.size[1] || max(_r[0],_r[0]+_r[2])<=0 || max(_r[1],_r[1]+_r[3])<=0)continue;
        for(var _j=0;_j<array_length(_n.graphics);_j++){
            var _g=_n.graphics[_j];
            if(_g.type=="text"){
                var _layout=_g.layout;if(_n.text_key!="" && variable_struct_exists(_g.variants,_n.text_key))_layout=_g.variants[$ _n.text_key];
                var _spr=cr_sprite(_layout.atlas);if(_spr<0)continue;
                for(var _k=0;_k<array_length(_layout.quads);_k++)cr_ui_quad(_spr,_layout.quads[_k],_r[0],_r[1],_n.scale[0],_n.scale[1]);
                var _parent=cr_ui_node(_n.parent),_high=(!is_undefined(_parent) && !is_undefined(_parent.button) && _parent.high && _parent.button.underline) || (!is_undefined(_n.button) && _n.high && _n.button.underline);
                if(_high)for(var _k=0;_k<array_length(_layout.underlines);_k++)cr_ui_quad(_spr,_layout.underlines[_k],_r[0],_r[1],_n.scale[0],_n.scale[1]);
            }else{
                var _name=_g.image,_material=cr_value(_g,"material","");
                if(!is_undefined(_n.button)){
                    if(_n.button.swap_high && _n.high)_name=_n.button.hover;
                    if(_n.button.swap_hold && _u.held==_n.id)_name=_n.button.held;
                }
                if(_n.image_override!="")_name=_n.image_override;
                if(variable_struct_exists(_n,"event_effect")){cr_event_image_draw(_n,_name,_r,_g.color);continue;}
                if(_n.glitch || _material=="ShiftDistortion"){
                    shader_set(shd_cr_glitch);shader_set_uniform_f(shader_get_uniform(shd_cr_glitch,"u_shift"),_material=="ShiftDistortion"?cr_value(_u,"shift_intensity",.002):0);
                    shader_set_uniform_f(shader_get_uniform(shd_cr_glitch,"u_seed"),_material=="ShiftDistortion"?floor(cr_value(_u,"effect_time",current_time)/16):cr_value(_n,"glitch_seed",17));
                }
                if(_material=="StaticMax" || _material=="Static")cr_ui_static_rect(_r,_material=="StaticMax"?1:cr_value(_u,"static_max",.7));
                else if(_name=="")cr_ui_fill(_r,_g.color);
                else cr_ui_image(_name,_r,_g.color,cr_value(_g,"image_type",0),cr_value(_g,"ppu_multiplier",1),cr_value(_g,"reference_ppu",16));
                if(_n.glitch || _material=="ShiftDistortion")shader_reset();
            }
        }
    }
}
function cr_ui_static_rect(_r,_strength) {
    var _cols=ceil(_r[2]),_rows=ceil(_r[3]),_cw=_r[2]/_cols,_ch=_r[3]/_rows,_time=floor(cr_value(global.cr_ui,"effect_time",current_time)/32);
    draw_set_alpha(_strength);draw_set_color(c_white);
    for(var _y=0;_y<_rows;_y++)for(var _x=0;_x<_cols;_x++){
        var _v=abs(sin((_x*17.13+_y*43.71+_time*1.91)*1.731))*255;
        _v=round(_v);var _c=make_color_rgb(_v,_v,_v);
        draw_set_color(_c);draw_rectangle(_r[0]+_x*_cw,_r[1]+_y*_ch,_r[0]+(_x+1)*_cw+.2,_r[1]+(_y+1)*_ch+.2,false);
    }
    draw_set_color(c_white);draw_set_alpha(1);
}
function cr_ui_fill(_r,_rgba) {
    // UI RectTransforms describe geometric edges, not inclusive pixel indices.
    var _c=make_color_rgb(_rgba[0],_rgba[1],_rgba[2]),_a=_rgba[3]/255,_x=_r[0],_y=_r[1],_right=_x+_r[2],_bottom=_y+_r[3];
    draw_primitive_begin(pr_trianglelist);
    draw_vertex_color(_x,_y,_c,_a);draw_vertex_color(_right,_y,_c,_a);draw_vertex_color(_right,_bottom,_c,_a);
    draw_vertex_color(_x,_y,_c,_a);draw_vertex_color(_right,_bottom,_c,_a);draw_vertex_color(_x,_bottom,_c,_a);
    draw_primitive_end();
}
function bbcr_draw_menu() {
    var _u=global.cr_ui,_w=_u.size[0],_h=_u.size[1];
    if(!surface_exists(_u.surface))_u.surface=surface_create(_w,_h);
    var _world=matrix_get(matrix_world),_view=matrix_get(matrix_view),_proj=matrix_get(matrix_projection);
    surface_set_target(_u.surface);draw_clear(c_black);gpu_set_texfilter(false);gpu_set_ztestenable(false);gpu_set_zwriteenable(false);
    gpu_set_blendmode_ext_sepalpha(bm_src_alpha,bm_inv_src_alpha,bm_one,bm_inv_src_alpha);
    matrix_set(matrix_world,matrix_build_identity());matrix_set(matrix_view,matrix_build(-_w/2,-_h/2,16000,0,0,0,1,1,1));matrix_set(matrix_projection,matrix_build_projection_ortho(_w,-_h,1,32000));
    if(_u.wait!="warning" && _u.wait!="quit_black")cr_ui_draw_nodes();
    surface_reset_target();gpu_set_blendmode(bm_normal);matrix_set(matrix_world,_world);matrix_set(matrix_view,_view);matrix_set(matrix_projection,_proj);
    draw_clear(c_black);draw_set_color(c_white);draw_set_alpha(1);
    var _v=cr_ui_viewport(),_sx=room_width/max(1,window_get_width()),_sy=room_height/max(1,window_get_height());
    draw_surface_stretched(_u.surface,_v[0]*_sx,_v[1]*_sy,_w*_v[2]*_sx,_h*_v[2]*_sy);
    if(_u.stage<16 && surface_exists(_u.previous)){
        if(cr_value(_u,"transition_type","")=="swipe"){
            var _offset=clamp(_u.swipe_time/.25,0,1)*_w;
            draw_surface_part_ext(_u.previous,_offset,0,_w-_offset,_h,_v[0]*_sx,_v[1]*_sy,_v[2]*_sx,_v[2]*_sy,c_white,1);
        }else{
        shader_set(shd_cr_dither);shader_set_uniform_f(shader_get_uniform(shd_cr_dither,"u_stage"),_u.stage);shader_set_uniform_f(shader_get_uniform(shd_cr_dither,"u_size"),_w,_h);
        shader_set_uniform_f(shader_get_uniform(shd_cr_dither,"u_reveal"),0);
        draw_surface_stretched(_u.previous,_v[0]*_sx,_v[1]*_sy,_w*_v[2]*_sx,_h*_v[2]*_sy);shader_reset();
        }
    }
    if(_u.scene!="Logo" && _u.scene!="Warnings" && _u.stage>=16 && _u.wait=="" && _u.unlock_time<=0 && _u.pointer_inside){
        var _name=_u.scene=="ClassicLauncher"?"ComputerCursor":global.cr_ui_data.cursor;
        cr_ui_image(_name,[(_v[0]+(round(_u.cx)-24)*_v[2])*_sx,(_v[1]+(round(_u.cy)-18)*_v[2])*_sy,64*_v[2]*_sx,64*_v[2]*_sy],[255,255,255,255]);
    }
    if(_u.wait=="game")global.bbcr.loading_drawn=true;
}
function cr_ui_display_resize() {
    // Render directly at the window's resolution; avoid 480 -> 640 -> window sampling.
    var _w=max(1,window_get_width()),_h=max(1,window_get_height());
    view_xport[0]=0;view_yport[0]=0;
    view_wport[0]=_w;view_hport[0]=_h;
    if(surface_exists(application_surface) && (surface_get_width(application_surface)!=_w || surface_get_height(application_surface)!=_h)){
        surface_resize(application_surface,_w,_h);global.cr_ui.mouse_x=-999;
    }
    display_set_gui_size(_w,_h);
}
