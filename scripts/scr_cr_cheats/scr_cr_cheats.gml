/// Session-only test controls. Source gameplay values and imported data stay intact.
function cr_cheat_init(_continue_run=false) {
    // Hint visibility is a session preference, independent of per-run modifiers.
    if(!variable_global_exists("cr_cheat_hint_visible"))global.cr_cheat_hint_visible=true;
    if(!variable_global_exists("cr_cheat_events"))global.cr_cheat_events={enabled:false,error_percent:100,loading_percent:100,skip_gate:false};
    var _used=false,_baseline=undefined;
    if(variable_global_exists("cr_cheat")){
        if(_continue_run){_used=global.cr_cheat.used;_baseline=global.cr_cheat.record_baseline;}
        else cr_cheat_restore_records();
    }
    global.cr_cheat={open:false,used:_used,record_baseline:_baseline,god:false,noclip:false,stamina:false,keep_items:false,
        freeze_npcs:false,speed:1,time_scale:1,category:0,selected:0,scroll:0,slot:0,
        mark:undefined,message:"Changes apply to this run only.",drag:-1,edit:undefined,camera_yaw:0,reset_confirm:false,menu_context:false};
}
function cr_cheat_mark_used() {
    var _c=global.cr_cheat,_g=global.bbcr;
    if(!_c.used)_c.record_baseline={progress:json_parse(json_stringify(_g.progress)),score:_g.high_score,
        games:_g.games_since_error,errors:_g.error_count,boss:_g.boss_seen,notice:_g.unlock_notice};
    _c.used=true;
}
function cr_cheat_restore_records() {
    var _c=global.cr_cheat,_g=global.bbcr,_b=_c.record_baseline;
    if(!_c.used || CR_CHEATS_CAN_RECORD_PROGRESS || !is_struct(_b))return;
    _g.progress=_b.progress;_g.high_score=_b.score;_g.games_since_error=_b.games;
    _g.error_count=_b.errors;_g.boss_seen=_b.boss;_g.unlock_notice=_b.notice;
}
function cr_cheat_event_key(_key) {return array_contains(["enabled","error_percent","loading_percent","skip_gate"],_key);}
function cr_cheat_event_rows() {
    return [cr_cheat_row("Use custom event probabilities","toggle","enabled"),
        cr_cheat_row("Capture event chance (%)","number","error_percent",[0,100,.01]),
        cr_cheat_row("Loading face chance (%)","number","loading_percent",[0,100,.01]),
        cr_cheat_row("Ignore capture game-count gate","toggle","skip_gate"),
        cr_cheat_row("Restore source probabilities","action","event_reset")];
}
function cr_cheat_in_menu() {return global.bbcr.scene=="menu" && global.cr_ui.scene=="MainMenu";}
function cr_cheat_flag(_key) {
    return variable_global_exists("cr_cheat") && global.cr_cheat[$ _key];
}
function cr_cheat_multiplier(_key) {
    return variable_global_exists("cr_cheat")?global.cr_cheat[$ _key]:1;
}
function cr_cheat_set_open(_on) {
    if(_on && !CR_CHEATS_CAN_OPEN_MENU)return;
    var _c=global.cr_cheat,_g=global.bbcr;if(_c.open==_on)return;
    if(_on){
        var _menu=cr_cheat_in_menu();
        if(_menu!=_c.menu_context){_c.category=0;_c.selected=0;_c.scroll=0;_c.menu_context=_menu;}
        if(!_menu){_c.camera_yaw=cr_view_yaw();cr_cheat_mark_used();}
        else _c.message=CR_CHEATS_CAN_RECORD_PROGRESS?"Unlock shortcuts save immediately.":"Score / unlock recording is disabled for cheat runs.";
    }
    _c.reset_confirm=false;
    _c.open=_on;_c.drag=-1;_c.edit=undefined;_g.mouse_skip=true;_g.move_latch=true;keyboard_string="";
    if(_on){audio_pause_all();window_mouse_set_locked(false);window_set_cursor(cr_default);}
    else {
        if(_c.menu_context){
            // A title-only session has no world or math/audio-pause context.
            audio_resume_all();window_mouse_set_locked(false);window_set_cursor(cr_none);
            global.cr_ui.held="";global.cr_ui.hover="";
            return;
        }
        if(!_g.paused){audio_resume_all();cr_math_restore_audio_pause();cr_audio_update_volume();}
        window_mouse_set_locked(_g.scene=="game" && !_g.paused && !_g.testing);window_set_cursor(cr_none);
    }
}
function cr_cheat_safe_point(_x,_z,_range=20) {
    var _r=global.cr_catalog.movement.radius;
    if(!cr_blocked(_x,_z,_r))return [_x,_z];
    // Find a local landing pad, including either side of desks and closed doors.
    for(var _radius=1;_radius<=_range;_radius++)for(var _a=0;_a<360;_a+=15){
        var _px=_x+lengthdir_x(_radius,_a),_pz=_z+lengthdir_y(_radius,_a);
        if(!cr_blocked(_px,_pz,_r))return [_px,_pz];
    }return [];
}
function cr_cheat_teleport(_x,_z,_yaw=undefined) {
    var _c=global.cr_cheat,_g=global.bbcr,_p=cr_cheat_safe_point(_x,_z);
    if(array_length(_p)==0){_c.message="No clear landing nearby.";return false;}
    _g.px=_p[0];_g.pz=_p[1];if(!is_undefined(_yaw))_g.yaw=_yaw;
    cr_rope_end(false);_g.jump_height=0;_g.jump_velocity=0;_g.mouse_skip=true;_g.move_latch=true;
    cr_cheat_mark_used();_c.message="Teleported to a clear landing.";return true;
}
function cr_cheat_noclip(_on) {
    var _c=global.cr_cheat,_g=global.bbcr;
    if(!_on && cr_blocked(_g.px,_g.pz,global.cr_catalog.movement.radius)){
        var _p=cr_cheat_safe_point(_g.px,_g.pz);
        if(array_length(_p)==0)_p=cr_cheat_safe_point(global.cr_map.spawn[0],global.cr_map.spawn[2]);
        if(array_length(_p)==0){_c.message="No safe landing. Noclip remains on.";return false;}
        _g.px=_p[0];_g.pz=_p[1];
    }
    _c.noclip=_on;cr_cheat_mark_used();_c.message=_on?"Noclip on. Movement stays on the floor plane.":"Noclip off. Collision restored.";return true;
}
function cr_cheat_supported_item(_key) {
    if(!variable_struct_exists(global.cr_catalog.items,_key))return false;
    var _type=global.cr_catalog.items[$ _key].type;
    return array_contains([1,2,3,4,5,6,8,9,12,13,14,17,18],_type);
}
function cr_cheat_give(_key) {
    if(cr_cheat_in_menu() || !cr_cheat_supported_item(_key))return false;
    var _c=global.cr_cheat,_g=global.bbcr;_g.inventory[_c.slot]=_key;_g.slot=_c.slot;cr_cheat_mark_used();
    _c.message="Given to slot "+string(_c.slot+1)+" (replaces its item).";return true;
}
function cr_cheat_row(_label,_kind,_key,_value=undefined) {
    return {label:_label,kind:_kind,key:_key,value:_value};
}
function cr_cheat_menu_unlock(_key) {
    if(!cr_cheat_in_menu())return false;
    var _c=global.cr_cheat,_g=global.bbcr,_p=_g.progress;
    if(!CR_CHEATS_CAN_OPEN_MENU || !CR_CHEATS_CAN_RECORD_PROGRESS){_c.message="Cheat unlocks are disabled by the compile-time policy.";return false;}
    cr_cheat_mark_used();
    switch(_key){
        case "menu_unlock_mirror":_p.classic_won=true;_c.message="Mirror unlocked. Enable it in Mode Select / Fun Settings.";break;
        case "menu_unlock_lights":_p.party_won=true;_c.message="Lights Out unlocked. Enable it in Mode Select / Fun Settings.";break;
        case "menu_unlock_hard":_p.demo_won=true;_c.message="Hard Mode unlocked. Enable it in Mode Select / Fun Settings.";break;
        case "menu_unlock_all":
        case "menu_unlock_null":
        case "menu_unlock_glitch":
            if(_key=="menu_unlock_all"){_p.classic_won=true;_p.party_won=true;_p.demo_won=true;}
            // flags 1..3 are the actual NULL notebook prerequisites. flag 4
            // replaces its selector with Glitch and changes several secret rooms.
            for(var _i=0;_i<4;_i++)_p.flags[_i]=true;
            _p.flags[4]=_key=="menu_unlock_glitch";
            _c.message=_p.flags[4]?"Glitch selected and saved. Use the NULL shortcut to switch back.":"NULL selected and saved, including all three secret prerequisites.";
            if(_key=="menu_unlock_all")_c.message="All mode unlocks saved; NULL selected. Glitch is one click away.";
            break;
        default:return false;
    }
    _c.reset_confirm=false;cr_progress_menu_sync();
    // If the source NULL/Glitch mode page is already open, refresh its label
    // and listings from the newly selected button's serialized callbacks.
    if(_g.style=="null" && cr_ui_visible(cr_ui_node("ModeSelect"))){
        var _n=cr_ui_node(_p.flags[4]?"StyleSelect/BaldiGlitch":"StyleSelect/Baldi");
        for(var _i=0;_i<array_length(_n.button.press);_i++){
            var _a=_n.button.press[_i];
            if(_a.method=="AssignLevelKey" || _a.method=="LoadScores")cr_ui_actions([_a]);
        }
    }
    cr_progress_save();return true;
}
function cr_cheat_rows() {
    var _c=global.cr_cheat,_g=global.bbcr,_rows=[];
    if(cr_cheat_in_menu()){
        if(_c.category==3)return cr_cheat_event_rows();
        if(_c.category==0)return [
            cr_cheat_row("Unlock Mirror","action","menu_unlock_mirror"),
            cr_cheat_row("Unlock Lights Out","action","menu_unlock_lights"),
            cr_cheat_row("Unlock Hard Mode","action","menu_unlock_hard"),
            cr_cheat_row("Unlock / switch to NULL (all secrets)","action","menu_unlock_null"),
            cr_cheat_row("Unlock / switch to Glitch","action","menu_unlock_glitch"),
            cr_cheat_row("Unlock all + NULL (replaces Glitch)","action","menu_unlock_all")];
        if(_c.category==1)return [cr_cheat_row(_c.reset_confirm?"CONFIRM: erase all user data":"Reset all user data...","action","menu_reset"),cr_cheat_row("Cancel data reset","action","menu_cancel")];
        return [cr_cheat_row("Preview Lights Out notification","action","menu_preview_party"),cr_cheat_row("Preview Hard Mode notification","action","menu_preview_demo"),cr_cheat_row("Restart title presentation","action","menu_title")];
    }
    switch(_c.category){
        case 0:
            _rows=[cr_cheat_row("Invincible (Baldi cannot catch)","toggle","god"),
                cr_cheat_row("Noclip / walk through walls","toggle","noclip"),
                cr_cheat_row("Unlimited stamina","toggle","stamina"),
                cr_cheat_row("Keep items after use","toggle","keep_items"),
                cr_cheat_row("Player speed","number","speed",[.25,5,.25]),
                cr_cheat_row("Refill stamina","action","refill"),
                cr_cheat_row("Clear rope / detention / guilt","action","release"),
                cr_cheat_row("Reset test modifiers","action","reset")];break;
        case 1:
            array_push(_rows,cr_cheat_row("Give / replace in slot","slot","slot"));
            var _keys=variable_struct_get_names(global.cr_catalog.items);array_sort(_keys,true);
            for(var _i=0;_i<array_length(_keys);_i++)if(cr_cheat_supported_item(_keys[_i])){
                var _item=global.cr_catalog.items[$ _keys[_i]],_name=cr_value(global.cr_text,_item.name,_keys[_i]);
                array_push(_rows,cr_cheat_row(_name,"item","give",_keys[_i]));
            }
            array_push(_rows,cr_cheat_row("Clear selected slot","action","clear_slot"));
            array_push(_rows,cr_cheat_row("Clear all three slots","action","clear_items"));break;
        case 2:
            array_push(_rows,cr_cheat_row("School entrance","teleport","spawn"));
            array_push(_rows,cr_cheat_row("Mark current position","action","mark"));
            array_push(_rows,cr_cheat_row("Return to marked position","teleport","mark"));
            for(var _i=0;_i<array_length(_g.books);_i++)array_push(_rows,cr_cheat_row("Notebook "+string(_i+1)+(_g.books[_i].done?" (collected)":""),"teleport","book",_i));
            for(var _i=0;_i<array_length(_g.exits);_i++)array_push(_rows,cr_cheat_row("Exit "+string(_i+1),"teleport","exit",_i));
            for(var _i=0;_i<array_length(_g.npcs);_i++)array_push(_rows,cr_cheat_row("Near "+_g.npcs[_i].name,"teleport","npc",_i));break;
        case 3:
            _rows=[cr_cheat_row("Freeze NPCs","toggle","freeze_npcs"),
                cr_cheat_row("Game time scale","number","time_scale",[.1,3,.1]),
                cr_cheat_row("Baldi anger","number","anger",[.1,100,1]),
                cr_cheat_row("Activate chase","action","chase"),
                cr_cheat_row("Unlock all doors","action","unlock"),
                cr_cheat_row("Complete current Style unlock","action","progress_style"),
                cr_cheat_row("Complete All Fun unlock (NULL)","action","progress_fun"),
                cr_cheat_row("Complete NULL route (Glitch)","action","progress_null"),
                cr_cheat_row("Restock vending machines","action","restock"),
                cr_cheat_row("Restore floor pickups","action","pickups"),
                cr_cheat_row("Clear sprays / alarms","action","clear_world")];break;
        case 4:_rows=cr_cheat_event_rows();break;
    }return _rows;
}
function cr_cheat_number(_row) {return cr_cheat_event_key(_row.key)?global.cr_cheat_events[$ _row.key]:(_row.key=="anger"?global.bbcr.anger:global.cr_cheat[$ _row.key]);}
function cr_cheat_number_set(_row,_value) {
    if(!CR_CHEATS_CAN_OPEN_MENU)return;
    var _range=_row.value,_v=clamp(_range[0]+round((_value-_range[0])/_range[2])*_range[2],_range[0],_range[1]);
    cr_cheat_mark_used();
    if(cr_cheat_event_key(_row.key))global.cr_cheat_events[$ _row.key]=_v;
    else if(_row.key=="anger"){
        global.bbcr.anger=_v;global.bbcr.extra_anger=0;
        var _n=global.bbcr.npcs[0];_n.slap_timer=cr_curve(_n.params.slapCurve,_v);_n.slap_distance=0;_n.slap_left=0;
    }else global.cr_cheat[$ _row.key]=_v;
    global.cr_cheat.message=_row.label+" updated.";
}
function cr_cheat_edit_number(_row) {
    global.cr_cheat.edit=_row;keyboard_string="";
}
function cr_cheat_edit_commit() {
    var _text=keyboard_string,_dots=0,_digits=0;
    for(var _i=1;_i<=string_length(_text);_i++){
        var _ch=string_char_at(_text,_i);
        if(_ch==".")_dots++;else if(_ch>="0" && _ch<="9")_digits++;else return false;
    }
    if(_dots>1 || _digits==0)return false;
    cr_cheat_number_set(global.cr_cheat.edit,real(_text));global.cr_cheat.edit=undefined;keyboard_string="";return true;
}
function cr_cheat_action(_row,_direction=1) {
    if(!CR_CHEATS_CAN_OPEN_MENU)return;
    var _c=global.cr_cheat,_g=global.bbcr,_key=_row.key;
    if(cr_cheat_event_key(_key)){
        cr_cheat_mark_used();
        if(_row.kind=="number")cr_cheat_number_set(_row,cr_cheat_number(_row)+_direction*_row.value[2]);
        else global.cr_cheat_events[$ _key]=!global.cr_cheat_events[$ _key];
        _c.message="Session-only probabilities; Enter or click the value to type %.";return;
    }
    if(_key=="event_reset"){
        global.cr_cheat_events.enabled=false;global.cr_cheat_events.skip_gate=false;
        _c.message="Source probabilities restored. This run stays marked as a cheat run.";return;
    }
    if(cr_cheat_in_menu()){
        if(string_pos("menu_unlock_",_key)==1){cr_cheat_menu_unlock(_key);return;}
        switch(_key){
            case "menu_reset":
                if(!_c.reset_confirm){_c.reset_confirm=true;_c.message="Press CONFIRM again to erase scores, unlocks and settings.";return;}
                cr_user_data_reset();_c.reset_confirm=false;_c.message="All user data reset. Scores, unlocks and settings are at defaults.";break;
            case "menu_cancel":_c.reset_confirm=false;_c.message="Data reset cancelled.";break;
            case "menu_preview_party":case "menu_preview_demo":
                cr_cheat_set_open(false);cr_audio_clear_all();_g.unlock_notice=global.cr_text.Men_UnlockNotif+global.cr_text[$ (_key=="menu_preview_party"?"But_LightsOut":"But_HardMode")];cr_ui_scene("MainMenu");break;
            case "menu_title":cr_cheat_set_open(false);cr_audio_clear_all();_g.unlock_notice="";cr_ui_scene("MainMenu");break;
        }return;
    }
    if(_row.kind=="number"){cr_cheat_number_set(_row,cr_cheat_number(_row)+_direction*_row.value[2]);return;}
    if(_row.kind=="slot"){_c.slot=(_c.slot+3+_direction) mod 3;return;}
    if(_row.kind=="toggle"){
        if(_key=="noclip"){cr_cheat_noclip(!_c.noclip);return;}
        _c[$ _key]=!_c[$ _key];cr_cheat_mark_used();_c.message=_row.label+": "+(_c[$ _key]?"ON":"OFF");
        if(_key=="stamina" && _c.stamina)_g.stamina=max(_g.stamina,100);return;
    }
    if(_row.kind=="item"){cr_cheat_give(_row.value);return;}
    if(_row.kind=="teleport"){
        if(_g.scene!="game"){_c.message="Finish the notebook before teleporting.";return;}
        switch(_key){
            case "spawn":cr_cheat_teleport(global.cr_map.spawn[0],global.cr_map.spawn[2],degtorad(global.cr_map.yaw));break;
            case "mark":if(is_undefined(_c.mark))_c.message="Mark a position first.";else cr_cheat_teleport(_c.mark[0],_c.mark[1],_c.mark[2]);break;
            case "book":var _b=_g.books[_row.value];cr_cheat_teleport(_b.x,_b.z);break;
            case "exit":var _e=_g.exits[_row.value];cr_cheat_teleport(_e.x,_e.z);break;
            case "npc":var _n=_g.npcs[_row.value];cr_cheat_teleport(_n.px+sin(_n.yaw)*8,_n.pz+cos(_n.yaw)*8);break;
        }return;
    }
    switch(_key){
        case "refill":_g.stamina=100;break;
        case "release":
            cr_rope_end(false);_g.jump_height=0;_g.jump_velocity=0;_g.detention=0;_g.detention_escape=0;_g.detention_room=-1;_g.detention_inside=false;_g.guilt="";_g.guilt_time=0;
            for(var _i=0;_i<array_length(_g.npcs);_i++)if(_g.npcs[_i].name=="Principal"){_g.npcs[_i].angry=false;_g.npcs[_i].sight=0;}
            for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].room==13)_g.doors[_i].lock=0;break;
        case "reset":
            if(!cr_cheat_noclip(false))return;
            _c.god=false;_c.stamina=false;_c.keep_items=false;_c.freeze_npcs=false;_c.speed=1;_c.time_scale=1;
            _c.message="Modifiers reset; world edits remain for this run.";return;
        case "clear_slot":_g.inventory[_c.slot]="";break;
        case "clear_items":_g.inventory=["","",""];break;
        case "mark":_c.mark=[_g.px,_g.pz,_g.yaw];_c.message="Position marked for this run.";return;
        case "chase":if(_g.mode=="free"){_c.message="Chase is available in Story / Endless.";return;}cr_spoop();audio_pause_all();break;
        case "unlock":for(var _i=0;_i<array_length(_g.doors);_i++){_g.doors[_i].locked=false;_g.doors[_i].lock=0;}break;
        case "progress_style":
            cr_cheat_mark_used();
            if(cr_progress_complete_style(_g.style))_c.message="Source "+_g.style+" Story unlock completed; no score recorded.";
            else _c.message=CR_CHEATS_CAN_RECORD_PROGRESS?"This Style has no Story fun-setting unlock.":"Cheat score / unlock recording is disabled.";
            return;
        case "progress_fun":
            cr_cheat_mark_used();
            if(!_g.progress.classic_won || !_g.progress.party_won || !_g.progress.demo_won)_c.message="Complete Classic, Party and Demo Story unlocks first.";
            else {_g.mirror=true;_g.lightsout=true;_g.hard=true;if(cr_progress_check_all_fun())_c.message="All Fun condition completed; NULL Style unlocked.";else _c.message="Cheat score / unlock recording is disabled.";}
            return;
        case "progress_null":
            cr_cheat_mark_used();
            if(cr_progress_complete_null())_c.message="NULL route completion recorded; Glitch Style unlocked.";
            else _c.message=!_g.progress.flags[0]?"Unlock NULL Style first.":"Cheat score / unlock recording is disabled.";
            return;
        case "restock":for(var _i=0;_i<array_length(global.cr_map.facilities);_i++){var _f=global.cr_map.facilities[_i];if(variable_struct_exists(_f,"uses"))_f.uses=1;}break;
        case "pickups":for(var _i=0;_i<array_length(_g.items);_i++)_g.items[_i].done=false;break;
        case "clear_world":_g.projectiles=[];_g.alarms=[];break;
    }
    cr_cheat_mark_used();_c.message=_row.label+": done.";
}
function cr_cheat_category(_index) {
    var _c=global.cr_cheat,_count=cr_cheat_in_menu()?4:5;_c.category=(_index+_count) mod _count;_c.selected=0;_c.scroll=0;_c.drag=-1;_c.reset_confirm=false;
}
function cr_cheat_pointer(_x,_y) {
    var _v=cr_game_viewport();return [(_x-_v[0])/_v[2],(_y-_v[1])/_v[2]];
}
function cr_cheat_click(_x,_y) {
    if(!CR_CHEATS_CAN_OPEN_MENU)return;
    var _c=global.cr_cheat;
    if(point_in_rectangle(_x,_y,585,64,617,94)){cr_cheat_set_open(false);return;}
    for(var _i=0;_i<(cr_cheat_in_menu()?4:5);_i++)if(point_in_rectangle(_x,_y,26,116+_i*38,162,148+_i*38)){cr_cheat_category(_i);return;}
    var _rows=cr_cheat_rows(),_index=floor((_y-116)/34)+_c.scroll;
    if(_x>=182 && _x<=614 && _y>=116 && _y<388 && _index<array_length(_rows)){
        _c.selected=_index;var _row=_rows[_index];
        if(_row.kind=="number" && cr_cheat_event_key(_row.key) && _x>=420 && _x<=540 && _y<116+(_index-_c.scroll)*34+18)cr_cheat_edit_number(_row);
        else if(_row.kind=="number" && _x>=420 && _x<=540){_c.drag=_index;cr_cheat_number_set(_row,lerp(_row.value[0],_row.value[1],clamp((_x-420)/120,0,1)));}
        else cr_cheat_action(_row,(_row.kind=="number" || _row.kind=="slot") && _x<573?-1:1);
    }
    if(point_in_rectangle(_x,_y,508,399,556,421)){_c.scroll=max(0,_c.scroll-8);_c.selected=_c.scroll;}
    if(point_in_rectangle(_x,_y,565,399,613,421)){_c.scroll=min(max(0,array_length(_rows)-8),_c.scroll+8);_c.selected=_c.scroll;}
}
function cr_cheat_step() {
    if(!CR_CHEATS_CAN_OPEN_MENU)return false;
    var _c=global.cr_cheat,_g=global.bbcr;
    if(keyboard_check_pressed(vk_f2))global.cr_cheat_hint_visible=!global.cr_cheat_hint_visible;
    if(keyboard_check_pressed(vk_f1) && (cr_cheat_in_menu() || (!cr_value(_g,"dead",false) && !cr_value(_g,"won",false)))){cr_cheat_set_open(!_c.open);return true;}
    if(!_c.open)return false;
    window_mouse_set_locked(false);window_set_cursor(cr_default);
    if(is_struct(_c.edit)){
        if(keyboard_check_pressed(vk_escape)){_c.edit=undefined;keyboard_string="";}
        else if(keyboard_check_pressed(vk_enter) && !cr_cheat_edit_commit())_c.message="Enter a number from 0 to 100 (up to two decimal places).";
        return true;
    }
    if(keyboard_check_pressed(vk_escape)){cr_cheat_set_open(false);return true;}
    if(keyboard_check_pressed(vk_tab))cr_cheat_category(_c.category+(keyboard_check(vk_shift)?-1:1));
    for(var _i=0;_i<(cr_cheat_in_menu()?4:5);_i++)if(keyboard_check_pressed(ord("1")+_i))cr_cheat_category(_i);
    var _rows=cr_cheat_rows(),_count=array_length(_rows),_move=keyboard_check_pressed(vk_down)-keyboard_check_pressed(vk_up);
    if(_move!=0){_c.selected=clamp(_c.selected+_move,0,_count-1);_c.scroll=clamp(_c.scroll,max(0,_c.selected-7),_c.selected);}
    var _dir=keyboard_check_pressed(vk_right)-keyboard_check_pressed(vk_left);
    if(_dir!=0 && (_rows[_c.selected].kind=="number" || _rows[_c.selected].kind=="slot"))cr_cheat_action(_rows[_c.selected],_dir);
    if(keyboard_check_pressed(vk_enter) && _rows[_c.selected].kind=="number" && cr_cheat_event_key(_rows[_c.selected].key))cr_cheat_edit_number(_rows[_c.selected]);
    else if(keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))cr_cheat_action(_rows[_c.selected]);
    var _wheel=mouse_wheel_down()-mouse_wheel_up();
    if(keyboard_check_pressed(vk_pagedown))_wheel+=8;if(keyboard_check_pressed(vk_pageup))_wheel-=8;
    _c.scroll=clamp(_c.scroll+_wheel,0,max(0,_count-8));
    if(_wheel!=0)_c.selected=clamp(_c.selected,_c.scroll,min(_count-1,_c.scroll+7));
    var _p=cr_cheat_pointer(window_mouse_get_x(),window_mouse_get_y());
    if(mouse_check_button_pressed(mb_left))cr_cheat_click(_p[0],_p[1]);
    if(_c.open && _c.drag>=0 && mouse_check_button(mb_left)){
        var _row=_rows[_c.drag];cr_cheat_number_set(_row,lerp(_row.value[0],_row.value[1],clamp((_p[0]-420)/120,0,1)));
    }
    if(!mouse_check_button(mb_left))_c.drag=-1;
    return true;
}
function cr_cheat_text(_text,_x,_y,_size=13,_color=c_white,_max_width=1000) {
    // Reuse the rounded source Comic atlas, including its actual glyph bearings.
    var _f=global.cr_ui_data.fonts.COMIC_24_Pro,_scale=_size/_f.face.m_PointSize*_f.face.m_Scale;
    var _sprite=cr_sprite(_f.file),_pen=0,_base=_y+_f.face.m_AscentLine*_scale;
    for(var _i=1;_i<=string_length(_text);_i++){
        var _g=cr_ui_glyph(_f,string_char_at(_text,_i)),_r=_g.rect,_s=_scale*_g.scale;
        if(_pen+_g.advance*_s>_max_width)break;
        if(_r[2]>0 && _r[3]>0)draw_sprite_part_ext(_sprite,0,_r[0],_r[1],_r[2],_r[3],_x+_pen+_g.bearing[0]*_s,_base-_g.bearing[1]*_s,_g.size[0]*_s/_r[2],_g.size[1]*_s/_r[3],_color,1);
        _pen+=_g.advance*_s;
    }
}
function cr_cheat_box(_x,_y,_w,_h,_color) {
    draw_set_color(_color);draw_roundrect_ext(_x,_y,_x+_w,_y+_h,6,6,false);
}
function cr_cheat_draw() {
    if(!CR_CHEATS_CAN_OPEN_MENU)return;
    var _c=global.cr_cheat,_g=global.bbcr,_menu=cr_cheat_in_menu();if(!_menu && (!_g.loaded || _g.dead || _g.won || (!_c.open && (_g.scene!="game" || _g.paused))))return;
    var _old=matrix_get(matrix_world),_v=cr_game_viewport(),_filter=gpu_get_texfilter();
    matrix_set(matrix_world,matrix_build(_v[0],_v[1],0,0,0,0,_v[2],_v[2],1));gpu_set_texfilter(true);
    var _bg=make_color_rgb(23,29,42),_panel=make_color_rgb(36,44,60),_accent=make_color_rgb(117,224,192),_muted=make_color_rgb(182,196,214);
    if(global.cr_cheat_hint_visible){
        draw_set_alpha(.86);cr_cheat_box(6,31,220,18,_bg);draw_set_alpha(1);
        cr_cheat_text(_c.open?"F1 / Esc  Close   /   F2  Hide hint":(_c.used?"F1  Test menu *   /   F2  Hide hint":"F1  Test menu   /   F2  Hide hint"),12,31,11,_accent);
    }
    if(_c.open){
        draw_set_alpha(.65);draw_set_color(c_black);draw_rectangle(0,52,640,480,false);draw_set_alpha(1);
        cr_cheat_box(12,54,616,410,_bg);cr_cheat_text("Test menu",28,67,20);cr_cheat_text(_menu?"Main menu tools":"Game paused",184,72,12,_accent);
        cr_cheat_box(585,64,32,30,_panel);cr_cheat_text("X",596,68,16);
        var _names=_menu?["Unlocks","User data","Preview","Events"]:["Player","Items","Teleport","World","Events"];
        for(var _i=0;_i<array_length(_names);_i++){
            cr_cheat_box(26,116+_i*38,136,32,_c.category==_i?_accent:_panel);
            cr_cheat_text(string(_i+1)+"  "+_names[_i],38,121+_i*38,15,_c.category==_i?_bg:c_white);
        }
        cr_cheat_text("Tab: category",28,312,11,_muted);cr_cheat_text("Arrows: select / adjust",28,331,10,_muted);
        cr_cheat_text("Enter: apply",28,350,11,_muted);cr_cheat_text("Wheel / PgUp / PgDn",28,369,10,_muted);
        var _status="X ";
        if(_menu){
            var _p=_g.progress;
            _status="Mirror: "+string(_p.classic_won?"ON":"--")+"   Lights: "+string(_p.party_won?"ON":"--")+"   Hard: "+string(_p.demo_won?"ON":"--")+"   "+(_p.flags[0]?(_p.flags[4]?"Glitch":"NULL"):"NULL locked");
        }else _status+=""+string_format(_g.px,0,1)+"   Z "+string_format(_g.pz,0,1)+"   Speed "+string_format(_c.speed,0,2)+"x";
        cr_cheat_text(_status,184,95,11,_muted);
        var _rows=cr_cheat_rows(),_p=cr_cheat_pointer(window_mouse_get_x(),window_mouse_get_y());
        for(var _i=_c.scroll;_i<min(_c.scroll+8,array_length(_rows));_i++){
            var _row=_rows[_i],_y=116+(_i-_c.scroll)*34,_hover=point_in_rectangle(_p[0],_p[1],182,_y,614,_y+31);
            cr_cheat_box(182,_y,432,31,(_hover || _i==_c.selected)?make_color_rgb(53,68,86):_panel);
            var _left=192;if(_row.kind=="item"){cr_image(global.cr_catalog.items[$ _row.value].small,190,_y+3,25,25);_left=223;}
            cr_cheat_text(_row.label,_left,_y+5,12,c_white,_row.kind=="number"?205:(_row.kind=="item"?325:342));
            switch(_row.kind){
                case "toggle":var _on=cr_cheat_event_key(_row.key)?global.cr_cheat_events[$ _row.key]:_c[$ _row.key];cr_cheat_text(_on?"ON":"OFF",568,_y+5,12,_on?_accent:_muted);break;
                case "number":
                    var _value=cr_cheat_number(_row),_t=(_value-_row.value[0])/(_row.value[1]-_row.value[0]);
                    draw_set_color(_muted);draw_line_width(420,_y+24,540,_y+24,2);draw_set_color(_accent);draw_circle(420+120*_t,_y+24,3,false);
                    cr_cheat_text(string_format(_value,0,_row.key=="anger"?1:2)+(cr_cheat_event_key(_row.key)?"%":(_row.key=="anger"?"":"x")),450,_y,10,_accent);
                    cr_cheat_text("-",551,_y+3,16);cr_cheat_text("+",587,_y+3,16);break;
                case "slot":cr_cheat_text("<   "+string(_c.slot+1)+"   >",546,_y+5,12,_accent);break;
                case "item":cr_cheat_text("Give",574,_y+5,11,_accent);break;
                default:cr_cheat_text(">",589,_y+5,13,_accent);break;
            }
        }
        cr_cheat_text(string(_c.scroll+1)+"-"+string(min(_c.scroll+8,array_length(_rows)))+" / "+string(array_length(_rows)),184,402,11,_muted);
        cr_cheat_box(508,399,48,23,_panel);cr_cheat_text("Up",522,399,12);
        cr_cheat_box(565,399,48,23,_panel);cr_cheat_text("Down",573,399,12);
        cr_cheat_text(_c.message,28,434,11,_accent,570);
        if(is_struct(_c.edit)){
            cr_cheat_box(190,200,414,120,_bg);cr_cheat_text(_c.edit.label,208,211,15);
            cr_cheat_box(208,242,378,30,_panel);cr_cheat_text(keyboard_string+"_ %",220,245,15,_accent);
            cr_cheat_text("0-100   Enter: apply   Esc: cancel",208,285,12,_muted);
        }
    }
    draw_set_color(c_white);draw_set_alpha(1);gpu_set_texfilter(_filter);matrix_set(matrix_world,_old);
}
function cr_user_data_reset(_file="bbcr.ini") {
    var _g=global.bbcr;
    if(_file=="bbcr.ini" && variable_struct_exists(_g,"crypto") && _g.crypto.enabled){
        var _sealed=cr_crypto_path(_g.crypto.sealed),_legacy=cr_crypto_path(_g.crypto.legacy);
        if(file_exists(_sealed))file_delete(_sealed);
        if(file_exists(_legacy))file_delete(_legacy);
        if(file_exists(_sealed) || file_exists(_legacy)){cr_crypto_report("Unable to reset the user save.");return false;}
        _g.crypto.text="";_g.crypto.corrupt=false;_g.crypto.ready=true;_g.crypto.write_failed=false;_g.crypto.notified=false;
    }else if((!_g.testing || _file!="bbcr.ini") && file_exists(_file))file_delete(_file);
    _g.progress=cr_progress_default();_g.high_score=0;_g.unlock_notice="";
    _g.games_since_error=0;_g.error_count=0;_g.boss_seen=false;
    global.cr_cheat.used=false;global.cr_cheat.record_baseline=undefined;
    _g.volumes=[1,1,.8];_g.sensitivities=[.29,1,400,400];_g.sensitivity=.29;_g.volume=1;
    _g.skip_launcher=false;_g.subtitles=false;_g.vsync=true;_g.pixel_filter=true;_g.reduce_flashing=false;_g.rumble=true;
    _g.mirror=false;_g.lightsout=false;_g.hard=false;_g.style="classic";global.cr_ui.free=false;
    window_set_fullscreen(false);audio_master_gain(1);cr_audio_update_volume();cr_progress_menu_sync();
    if(cr_store_encrypted(_file))return cr_save();
    return true;
}
