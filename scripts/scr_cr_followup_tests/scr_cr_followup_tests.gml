function cr_followup_npc(_name) {
    for(var _i=0;_i<array_length(global.bbcr.npcs);_i++)if(global.bbcr.npcs[_i].name==_name)return global.bbcr.npcs[_i];
    return undefined;
}
function cr_followup_office_test() {
    var _g=global.bbcr,_p=cr_followup_npc("Principal"),_door=undefined,_office=-1;
    for(var _i=0;_i<array_length(global.cr_map.rooms);_i++)if(global.cr_map.rooms[_i].category==3){_office=_i;break;}
    for(var _i=0;_i<array_length(_g.doors);_i++){
        var _d=_g.doors[_i];if(_d.a_room==_office || _d.b_room==_office){_door=_d;break;}
    }
    cr_assert(_office>=0 && is_struct(_door),"source office and adjacent detention door are available");
    var _nx=sin(degtorad(_door.dir*90)),_nz=cos(degtorad(_door.dir*90));
    var _inside_sign=_door.a_room==_office?-1:1;
    _g.detention_room=_office;_g.detention=15;_g.detention_escape=15;_door.lock=15;_door.open=0;
    _p.px=_door.cx+_nx*_inside_sign*4;_p.pz=_door.cz+_nz*_inside_sign*4;
    _p.gx=_door.cx-_nx*_inside_sign*10;_p.gz=_door.cz-_nz*_inside_sign*10;
    path_clear_points(_p.path);_p.node=0;_p.route_timer=0;
    repeat(120)cr_npc_move(_p,10,1/60);
    var _principal_side=((_p.px-_door.cx)*_nx+(_p.pz-_door.cz)*_nz)*_inside_sign;
    cr_assert(_principal_side<0 && _door.open<=0 && _door.lock>0,"Principal exits detention through the locked plane without opening the door");
    _g.px=_door.cx+_nx*_inside_sign*4;_g.pz=_door.cz+_nz*_inside_sign*4;
    repeat(120)cr_move(_g,-_nx*_inside_sign*10/120,-_nz*_inside_sign*10/120,global.cr_catalog.movement.radius);
    var _player_side=((_g.px-_door.cx)*_nx+(_g.pz-_door.cz)*_nz)*_inside_sign;
    cr_assert(_player_side>0 && cr_blocked(_door.cx,_door.cz,global.cr_catalog.movement.radius),"the same closed locked plane still contains the player without a key");
    show_debug_message("BBCR_FOLLOWUP_OFFICE: "+json_stringify({office:_office,principal_side:_principal_side,player_side:_player_side,open:_door.open,lock:_door.lock}));
}
function cr_followup_crafters_test() {
    bbcr_start_game("story");var _g=global.bbcr,_c=cr_followup_npc("ArtsAndCrafters"),_choice_e=-1,_choice_h=-1,_expected=[];
    for(var _ei=0;_ei<array_length(_g.exits) && _choice_e<0;_ei++){
        var _e=_g.exits[_ei],_start=cr_tile(_e.door_tile[0]*10+5,_e.door_tile[1]*10+5);
        if(is_undefined(_start))continue;
        for(var _hi=0;_hi<array_length(global.cr_map.tiles);_hi++){
            if(global.cr_map.tiles[_hi].room!=0)continue;
            var _path=cr_map_tile_path(_start.index,_hi);
            if(array_length(_path)>_c.params.baldiSpawnDistance){_choice_e=_ei;_choice_h=_hi;_expected=_path;break;}
        }
    }
    cr_assert(_choice_e>=0 && array_length(_expected)>_c.params.baldiSpawnDistance,"source exit door tile has a valid Crafters teleport path");
    _g.spoop=true;cr_baldi_clear_sounds(_g.npcs[0]);cr_crafters_finish(_c,_choice_e,_choice_h);
    var _player=global.cr_map.tiles[_expected[_c.params.playerSpawnDistance]],_baldi=global.cr_map.tiles[_expected[_c.params.baldiSpawnDistance]];
    var _e=_g.exits[_choice_e],_root=cr_tile(_e.x,_e.z),_start=global.cr_map.tiles[_expected[0]];
    cr_assert(_start.x==_e.door_tile[0] && _start.z==_e.door_tile[1],"Crafters path begins at Elevator.Door.position instead of the exit prefab root");
    cr_assert(_root.index!=_start.index,"the tested source elevator door tile is distinct from its prefab root tile");
    cr_assert(_g.px==_player.x*10+5 && _g.pz==_player.z*10+5,"Crafters teleports the player to source path index 8");
    cr_assert(_g.npcs[0].px==_baldi.x*10+5 && _g.npcs[0].pz==_baldi.z*10+5,"Crafters moves Baldi to source path index 16");
    cr_assert(_g.npcs[0].current_sound==_c.params.noiseValue && _g.npcs[0].gx==_g.px && _g.npcs[0].gz==_g.pz,"Crafters destination emits source level-64 noise at the teleported player");
    show_debug_message("BBCR_FOLLOWUP_CRAFTERS: "+json_stringify({exit:_choice_e,door:_e.door_tile,root:[_root.x,_root.z],length:array_length(_expected),player:[_player.x,_player.z],baldi:[_baldi.x,_baldi.z]}));
}
function cr_followup_playtime_test() {
    bbcr_start_game("story");var _g=global.bbcr,_p=cr_followup_npc("Playtime");
    _g.rope=true;_g.rope_npc=_p;_p.playing=true;cr_rope_end(false);
    cr_assert(_p.cooldown==_p.params.initialCooldown && _p.cooldown==15,"Playtime cooldown starts at the serialized fifteen seconds");
    repeat(899)cr_playtime_cooldown_step(_p,1/60);
    cr_assert(_p.cooldown>0 && _p.cooldown<.02,"Playtime remains on cooldown immediately before fifteen seconds");
    cr_playtime_cooldown_step(_p,1/60);
    cr_assert(_p.cooldown<=0,"Playtime becomes available only at the full fifteen-second boundary");
    show_debug_message("BBCR_FOLLOWUP_PLAYTIME: "+json_stringify({source:_p.params.initialCooldown,frames:900,remaining:_p.cooldown}));
}
function cr_followup_progress_test() {
    var _g=global.bbcr,_c=global.cr_cheat,_score=37;_g.high_score=_score;_g.progress=cr_progress_default();
    _g.mirror=false;_g.lightsout=false;_g.hard=false;_c.used=false;
    cr_ui_dispose(global.cr_ui);global.cr_ui=cr_ui_context("MainMenu");cr_progress_menu_sync();
    var _mirror=cr_ui_node("ModeSelect/FunSettings/FunSetting1").scripts.FunSetting;
    cr_assert(cr_ui_node(_mirror.lockedText).active && !cr_ui_node(_mirror.unlockedText).active,"Mirror Mode starts with the source locked label before Classic clear");
    cr_ui_actions([{method:"ToggleMirror",target:""}]);cr_assert(!_g.mirror,"locked Mirror Mode ignores its source toggle callback");
    for(var _i=0;_i<3;_i++){
        _g.style=["classic","party","demo"][_i];cr_cheat_action(cr_cheat_row("progress","action","progress_style"));
    }
    cr_assert(CR_CHEATS_CAN_UNLOCK_MODES!=0 && _g.progress.classic_won && _g.progress.party_won && _g.progress.demo_won,"macro-enabled test completion records all three source Story unlocks");
    cr_assert(_g.high_score==_score && _c.used,"test completion marks the run modified without recording a score");
    cr_progress_menu_sync();
    var _paths=["ModeSelect/FunSettings/FunSetting1","ModeSelect/FunSettings/FunSetting2","ModeSelect/FunSettings/FunSetting3"];
    for(var _i=0;_i<3;_i++){var _f=cr_ui_node(_paths[_i]).scripts.FunSetting;cr_assert(!cr_ui_node(_f.lockedText).active && cr_ui_node(_f.unlockedText).active,"source fun setting unlock label is enabled "+string(_i+1));}
    cr_ui_actions([{method:"ToggleMirror",target:""},{method:"ToggleLights",target:""},{method:"ToggleHard",target:""}]);
    cr_assert(_g.mirror && _g.lightsout && _g.hard,"unlocked Mirror, Lights Out and Hard callbacks can all be selected");
    cr_cheat_action(cr_cheat_row("progress","action","progress_fun"));cr_progress_menu_sync();
    var _null=cr_ui_node("StyleSelect/Baldi");cr_assert(_g.progress.flags[0] && _null.active && _null.graphics[0].raycast,"all three selected fun modes unlock the source NULL Style target");
    cr_cheat_action(cr_cheat_row("progress","action","progress_null"));cr_progress_menu_sync();
    cr_assert(_g.progress.flags[4] && !_null.active && cr_ui_node("StyleSelect/BaldiGlitch").active,"NULL route completion swaps the source selector to Glitch Style");
    cr_assert(_g.high_score==_score,"all cheat unlock actions leave the score unchanged");
    show_debug_message("BBCR_FOLLOWUP_PROGRESS: "+json_stringify({macro:CR_CHEATS_CAN_UNLOCK_MODES,classic:_g.progress.classic_won,party:_g.progress.party_won,demo:_g.progress.demo_won,null:_g.progress.flags[0],glitch:_g.progress.flags[4],score:_g.high_score}));
}
function cr_followup_test_step() {
    var _g=global.bbcr;if(cr_value(_g,"followup_done",false))return;_g.followup_done=true;
    global.cr_cheat_hint_visible=false;global.cr_cheat.god=true;
    cr_followup_office_test();cr_followup_crafters_test();cr_followup_playtime_test();cr_followup_progress_test();
    show_debug_message("BBCR_FOLLOWUP_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();
}
