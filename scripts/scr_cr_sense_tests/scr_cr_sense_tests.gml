function cr_sense_npc(_name) {
    for(var _i=0;_i<array_length(global.bbcr.npcs);_i++)if(global.bbcr.npcs[_i].name==_name)return global.bbcr.npcs[_i];
    return undefined;
}
function cr_sense_audio_tests(_principal) {
    var _g=global.bbcr,_old=[_g.px,_g.pz,_principal.px,_principal.pz];_g.px=100;_g.pz=100;
    _principal.px=105;_principal.pz=100;var _handle=cr_npc_sound(_principal,_principal.params.audNoRunning);
    var _entry=_g.sound_instances[array_length(_g.sound_instances)-1],_near=cr_sound_attenuation(_entry);
    _principal.px=200;var _far=cr_sound_attenuation(_entry),_expected=cr_curve(_principal.params.audio.rolloff_curve,100/_principal.params.audio.max_distance);
    _principal.px=700;var _silent=cr_sound_attenuation(_entry);
    cr_assert(abs(_near-1)<=.00001,"NPC AudioSource keeps full source gain inside MinDistance");
    cr_assert(abs(_far-_expected)<.0002 && _far<_near,"moving NPC voice follows its source custom rolloff curve");
    cr_assert(_silent<=.00001,"NPC voice reaches zero at its source MaxDistance");
    show_debug_message("BBCR_SENSE_AUDIO: "+json_stringify({near:_near,far:_far,expected:_expected,silent:_silent,distance:100}));
    if(audio_is_playing(_handle))audio_stop_sound(_handle);_g.px=_old[0];_g.pz=_old[1];_principal.px=_old[2];_principal.pz=_old[3];
}
function cr_sense_source_tests() {
    var _g=global.bbcr,_b=cr_sense_npc("Baldi"),_c=cr_sense_npc("ArtsAndCrafters"),_p=cr_sense_npc("Principal");
    _g.spoop=true;global.cr_cheat.freeze_npcs=false;
    cr_baldi_clear_sounds(_b);cr_noise(105,205,1);
    cr_assert(_b.current_sound==1 && _b.gx==105 && _b.gz==205,"door-level sound immediately becomes Baldi's target");
    cr_noise(115,215,31);cr_assert(_b.current_sound==31 && _b.gx==115 && _g.indicator_state=="Baldicator_Look","higher sound replaces current target and shows coming indicator");
    cr_noise(125,225,7);cr_assert(_b.current_sound==31 && is_array(_b.sound_locations[7]) && _g.indicator_state=="Baldicator_Think","lower sound remains queued and shows thinking indicator");
    cr_noise(130,230,7);cr_assert(_b.sound_locations[7][0]==130 && _b.sound_locations[7][1]==230,"same sound level keeps its newest source position");
    _b.px=_b.gx;_b.pz=_b.gz;cr_baldi_destination(_b);
    cr_assert(_b.current_sound==7 && _b.gx==130 && _b.gz==230,"Baldi takes the next-highest queued sound after reaching a target");
    cr_noise(140,240,5);cr_baldi_clear_sounds(_b);cr_baldi_hear(_b,_g.px,_g.pz,127,false);
    var _empty=true;for(var _i=0;_i<127;_i++)if(!is_undefined(_b.sound_locations[_i]))_empty=false;
    cr_assert(_empty && _b.current_sound==127,"visual PlayerInSight clears queued sounds and uses source priority 127");
    cr_baldi_clear_sounds(_b);_g.deaf=1;cr_noise(150,250,120);cr_assert(!_b.targeting_sound,"environment silence blocks MakeNoise broadcasts");_g.deaf=0;
    var _door=undefined;for(var _i=0;_i<array_length(_g.doors);_i++)if(!_g.doors[_i].swing){_door=_g.doors[_i];break;}
    _door.open=0;_door.lock=0;_door.locked=false;_door.silent=0;cr_door_open(_door,true);
    cr_assert(_door.noise==1 && _b.current_sound==1 && _b.gx==_door.cx && _b.gz==_door.cz,"actual player-opened standard door broadcasts source level 1");
    cr_assert(global.cr_ui_data.yctp.noiseVal==79 && global.cr_catalog.effects.alarm_noise==112 && global.cr_catalog.effects.exit_noise==31,"YCTP, alarm and false exit retain source noise levels 79, 112 and 31");
    cr_assert(_p.params.detentionNoise==95 && cr_sense_npc("FirstPrize").params.slamNoiseValue==64,"Principal detention and First Prize slam retain levels 95 and 64");
    cr_assert(global.cr_map.windows[0].noise==120 && _c.params.noiseValue==64,"broken windows and Crafters teleport retain levels 120 and 64");
    for(var _i=0;_i<array_length(_g.npcs);_i++)cr_assert(is_struct(_g.npcs[_i].params.audio) && array_length(_g.npcs[_i].params.audio.rolloff_curve)>2,"source AudioSource rolloff imported for "+_g.npcs[_i].name);
    cr_sense_audio_tests(_p);
    cr_assert(array_length(global.cr_map.crafters_triggers)>0,"source hall analysis creates Crafters sightline triggers");
    for(var _i=0;_i<array_length(global.cr_map.crafters_triggers);_i++)cr_assert(global.cr_map.crafters_triggers[_i].length>=_c.params.minHallLength,"Crafters trigger satisfies source minimum hall length "+string(_i));
    var _old=global.cr_ui;global.cr_ui=global.cr_detention_ui;
    cr_assert(cr_ui_node("DetentionUi/MainText").graphics[0].layout.text=="You get detention!\n  seconds remain.","detention main text comes directly from source prefab");
    cr_assert(global.cr_ui_data.detention.timer==cr_ui_node("DetentionUi/Time").id,"detention timer targets the source Time TMP node");global.cr_ui=_old;
    var _secret=cr_json("bbcr/ClassicTrue.json"),_green=_secret.doors[0];
    cr_assert(_green.default_time==3,"ClassicTrue green standard door keeps source three-second timer");
    cr_assert(string_pos("ClassStandard",_green.sides[0].closed)>0 && string_pos("BaldisOffice",_green.sides[1].closed)>0,"ClassicTrue door preserves source cross-room blue/green faces");
}
function cr_sense_crafters_spawn(_c,_trigger) {
    var _g=global.bbcr,_tr=global.cr_map.crafters_triggers[_trigger],_tile=global.cr_map.tiles[_tr.trigger],_target=global.cr_map.tiles[_tr.target];
    _g.px=_tile.x*10+5;_g.pz=_tile.z*10+5;_g.yaw=arctan2(_c.px-_g.px,_c.pz-_g.pz)+pi;_c.trigger_tile=-1;
    cr_crafters_step(_c,.016,false);cr_assert(_c.spawn_target==_tr.target,"CraftersTrigger calls SpawnAt for source hall endpoint "+string(_trigger));
    if(_c.spawn_phase==0){_g.yaw=arctan2(_c.px-_g.px,_c.pz-_g.pz)+pi;cr_crafters_step(_c,.016,false);}
    cr_assert(_c.hidden && _c.spawn_phase==1,"Crafters hides before moving to its source target tile");
    cr_crafters_step(_c,.016,false);_g.yaw=arctan2(_c.px-_g.px,_c.pz-_g.pz)+pi;cr_crafters_step(_c,.016,false);
    cr_assert(!_c.hidden && _c.spawn_target<0 && abs(_c.px-(_target.x*10+5))<.001 && abs(_c.pz-(_target.z*10+5))<.001,"Crafters reappears only after its new renderer position leaves the camera");
}
function cr_sense_principal_rule(_p,_rule) {
    var _g=global.bbcr;_p.angry=false;_p.sight=0;_g.guilt="";_g.guilt_time=0;cr_rule_break(_rule,1);
    cr_principal_notice(_p,true,_p.params.timeToScold+.01);var _result=_p.angry;
    if(audio_is_playing(_p.voice))audio_stop_sound(_p.voice);_p.voice=-1;_p.angry=false;_p.sight=0;return _result;
}
function cr_sense_test_step() {
    var _g=global.bbcr,_c=cr_sense_npc("ArtsAndCrafters"),_b=cr_sense_npc("Baldi");
    switch(_g.sense_test_stage){
        case 0:
            cr_sense_source_tests();bbcr_start_game("story");global.cr_cheat_hint_visible=false;_g.spoop=true;global.cr_cheat.god=true;
            _c=cr_sense_npc("ArtsAndCrafters");_c.params.spawnChance=1;cr_sense_crafters_spawn(_c,0);
            var _second=min(1,array_length(global.cr_map.crafters_triggers)-1);cr_sense_crafters_spawn(_c,_second);
            for(var _i=0;_i<array_length(_g.npcs);_i++)if(_g.npcs[_i].name!="ArtsAndCrafters")_g.npcs[_i].hidden=true;_g.sense_crafters_fixture=true;
            _c.hidden=false;_c.crafters_state="idle";_c.spawn_target=-1;_c.running=false;_c.angry=false;_c.run_time=100;_c.params.spawnChance=.2;
            _g.px=175;_g.pz=55;_g.yaw=0;_g.notebooks=_g.needed-1;_c.px=175;_c.pz=75;_c.gx=_c.px;_c.gz=_c.pz;
            _c.trigger_tile=cr_tile(_g.px,_g.pz).index;
            cr_assert(cr_clear_line(_c.px,_c.pz,_g.px,_g.pz,_c.params.sight_mask) && cr_crafters_camera_visible(_c),"centered Crafters has source Looker sight and camera visibility");_g.capture_scene="sense_crafters_normal";break;
        case 1:
            repeat(75)cr_npc_step(_c,1/60);
            cr_assert(!_c.angry,"Crafters cannot become angry before all notebooks are collected");
            _c.sight=0;_c.viewtime=0;_g.notebooks=_g.needed;_g.yaw=pi;repeat(75)cr_npc_step(_c,1/60);
            cr_assert(!_c.angry && _c.sight==0,"line of sight without player-camera visibility does not trigger Crafters");
            _g.yaw=0;repeat(59)cr_npc_step(_c,1/60);
            cr_assert(!_c.angry,"Crafters waits the full one-second source gaze threshold");break;
        case 2:
            repeat(2)cr_npc_step(_c,1/60);
            cr_assert(_c.angry && _c.crafters_state=="angry" && _c.params.angry_sprite=="CraftersSprites_1","sustained source-visible gaze switches to angry sprite and pursuit");
            cr_assert(audio_is_playing(_c.voice),"Crafters anger starts original intro audio");_g.capture_scene="sense_crafters_angry";break;
        case 3:
            _c.px=_g.px;_c.pz=_g.pz+3;cr_npc_step(_c,.01);cr_assert(_c.crafters_state=="attack","Crafters trigger contact starts teleport attack");
            cr_npc_step(_c,.5);var _r=point_distance(_g.px,_g.pz,_c.px,_c.pz);
            cr_assert(abs(_r-_c.params.spinDistance)<.001 && array_length(_c.echoes)==_c.params.echo_count,"attack circles player at source radius with all echo transforms");
            cr_assert(_c.params.angry_sprite=="CraftersSprites_1","main and echo renderers use the serialized angry form during attack");
            cr_assert(_c.attack_time<10 && !_c.hidden,"teleport remains pending during the ten-second orbit");_g.capture_scene="sense_crafters_orbit";break;
        case 4:
            repeat(560)cr_npc_step(_c,1/60);
            cr_assert(_c.crafters_state=="attack" && _c.attack_time<10,"Crafters remains visible immediately before source teleport deadline");_g.capture_scene="sense_crafters_countdown";break;
        case 5:
            var _before=[_g.px,_g.pz];repeat(20)cr_npc_step(_c,1/60);
            cr_assert(_c.crafters_state=="gone" && _c.hidden && point_distance(_before[0],_before[1],_g.px,_g.pz)>1,"ten-second attack teleports player then disables Crafters");
            cr_assert(_b.current_sound==_c.params.noiseValue && _b.gx==_g.px && _b.gz==_g.pz,"teleport emits source level 64 at the player's destination");
            cr_assert(point_distance(_b.px,_b.pz,_g.px,_g.pz)>1,"teleport places Baldi farther down the selected source path");
            bbcr_start_game("story");global.cr_cheat_hint_visible=false;_g.sense_crafters_fixture=false;_g.capture_scene="sense_detention_base";break;
        case 6:
            _g.spoop=true;_g.sense_detention_fixture=true;var _p=cr_sense_npc("Principal");cr_principal_detain(_p);
            cr_assert(_g.detention==_p.params.detentionInit && _g.detention_level==1,"first detention uses source 15-second duration and level increment");
            cr_assert(_b.current_sound==_p.params.detentionNoise,"detention broadcasts its source noise priority");_g.capture_scene="sense_detention_15";break;
        case 7:
            _g.detention=13.2;_g.capture_scene="sense_detention_14";break;
        case 8:
            _g.sense_detention_fixture=false;var _p=cr_sense_npc("Principal");_g.px=175;_g.pz=55;cr_detention_step(.05);
            cr_assert(_g.guilt=="Escaping" && _g.guilt_time>_p.params.timeToScold,"leaving the active detention room raises source Escaping guilt");
            _p.px=175;_p.pz=75;_p.gx=_p.px;_p.gz=_p.pz;_p.cooldown=0;_p.angry=false;_p.sight=0;
            cr_npc_step(_p,_p.params.timeToScold+.01);cr_assert(_p.angry,"Principal reacquires an escaping player through normal sight logic");
            _p.px=_g.px;_p.pz=_g.pz+3;cr_npc_step(_p,.01);
            cr_assert(_g.detention_level==2 && _g.detention>=20-.01,"Principal contact applies a second, longer detention after escape");
            cr_assert(cr_sense_principal_rule(_p,"Running") && cr_sense_principal_rule(_p,"Faculty") && cr_sense_principal_rule(_p,"Drinking"),"running, faculty and drinking guilt all activate Principal's source scold threshold");
            var _office=_g.detention_room,_door=undefined;for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(_d.a_room==_office || _d.b_room==_office){_door=_d;break;}}
            cr_assert(is_struct(_door) && _door.lock>0,"detention office door remains source-locked");
            _door.open=0;_p.px=_door.cx;_p.pz=_door.cz;_p.gx=_door.cx+sin(degtorad(_door.dir*90))*10;_p.gz=_door.cz+cos(degtorad(_door.dir*90))*10;
            path_clear_points(_p.path);path_add_point(_p.path,_p.px,_p.pz,100);path_add_point(_p.path,_p.gx,_p.gz,100);_p.node=0;_p.route_timer=100;cr_npc_move(_p,10,.1);
            cr_assert(_door.open<=0,"Principal cannot open or expose a player passage through a locked office door");
            _g.inventory=["Bsoda","Quarter","Zesty"];_g.ending={kind:"secret",time:0,phase:0,next:"ClassicTrue"};cr_ending_step(.01);repeat(16)cr_loading_exit_tick(.017);
            cr_assert(_g.secret_level && _g.inventory[0]=="" && _g.inventory[1]=="" && _g.inventory[2]=="" && _g.items_disabled,"actual secret-level transition clears inventory and disables item use");
            cr_cheat_give("Bsoda");var _held=_g.inventory[0];cr_use_item();
            cr_assert(_held=="Bsoda" && _g.inventory[0]==_held && array_length(_g.projectiles)==0,"built-in cheat item remains unusable in ClassicTrue");
            array_push(_g.projectiles,{px:_g.px,pz:_g.pz,dx:1,dz:0,life:30});cr_world_step(.05);
            cr_assert(array_length(_g.projectiles)==0,"externally injected BSODA entities are neutralized before movement in ClassicTrue");
            _door=_g.doors[0];cr_door_open(_door,true);repeat(59)cr_world_step(.05);cr_assert(_door.open>0,"ClassicTrue green door remains open until its source three-second deadline");repeat(2)cr_world_step(.05);cr_assert(_door.open<=0,"ClassicTrue green door automatically shuts at three seconds");
            var _nx=sin(degtorad(_door.dir*90)),_nz=cos(degtorad(_door.dir*90));
            _g.px=_door.cx-_nx*5;_g.pz=_door.cz-_nz*5;_g.yaw=arctan2(_door.cx-_g.px,_door.cz-_g.pz);
            cr_assert(cr_door_side_index(_door,_g.px,_g.pz)==0 && string_pos("ClassStandard",_door.sides[0].closed)>0,"office-facing green-door back uses the source hallway-blue material");_g.capture_scene="sense_secret_door_blue";break;
        case 9:
            var _door=_g.doors[0],_nx=sin(degtorad(_door.dir*90)),_nz=cos(degtorad(_door.dir*90));
            _g.px=_door.cx+_nx*5;_g.pz=_door.cz+_nz*5;_g.yaw=arctan2(_door.cx-_g.px,_door.cz-_g.pz);
            cr_assert(cr_door_side_index(_door,_g.px,_g.pz)==1 && string_pos("BaldisOffice",_door.sides[1].closed)>0,"hall-facing green door uses the source Baldi-office material");_g.capture_scene="sense_secret_door_green";break;
        case 10:
            var _distorted=undefined;for(var _i=0;_i<array_length(global.cr_map.decorations);_i++){var _s=global.cr_map.decorations[_i];if(variable_struct_exists(_s,"billboard_deform")){_distorted=_s;break;}}
            cr_assert(is_struct(_distorted) && _distorted.billboard_deform.size[0]==3.3125 && _distorted.billboard_deform.size[1]==8,"distorted Baldi keeps source sprite size before parent deformation");
            var _columns=_distorted.billboard_deform.columns,_largest=0;for(var _i=0;_i<3;_i++)_largest=max(_largest,point_distance(0,0,_columns[_i][0],_columns[_i][2]));
            cr_assert(_largest>15,"distorted Baldi applies the source non-uniform 3x5x23 parent deformation");
            _g.px=_distorted.p[0];_g.pz=_distorted.p[2]-200;_g.yaw=0;_g.sense_distorted_fixture=true;_g.sense_hide_distorted=true;_g.capture_scene="sense_distorted_base";break;
        case 11:
            _g.sense_hide_distorted=false;_g.capture_scene="sense_distorted";break;
        case 12:
            show_debug_message("BBCR_SENSE_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
    _g.sense_test_stage++;
}
