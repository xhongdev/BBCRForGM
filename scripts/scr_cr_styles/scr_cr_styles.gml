function cr_weighted_item(_entries) {
    var _total=0;for(var _i=0;_i<array_length(_entries);_i++)_total+=_entries[_i].weight;
    if(_total<=0)return "";
    var _pick=random(_total);for(var _i=0;_i<array_length(_entries);_i++){_pick-=_entries[_i].weight;if(_pick<0)return _entries[_i].item;}
    return _entries[array_length(_entries)-1].item;
}
function cr_style_balloon(_spec,_room,_x=undefined,_z=undefined) {
    var _tile=_room.tiles[irandom(array_length(_room.tiles)-1)];
    if(is_undefined(_x))_x=_tile[0]*10+5;if(is_undefined(_z))_z=_tile[1]*10+5;
    return {spec:_spec,px:_x,pz:_z,py:0,room:_room,minx:_room.bounds[0],minz:_room.bounds[1],maxx:_room.bounds[2],maxz:_room.bounds[3],
        angle:random(2*pi),timer:random_range(_spec.min_direction_time,_spec.max_direction_time),ending:false};
}
function cr_style_room(_room_index) {
    var _tiles=[],_minx=1000000000,_minz=1000000000,_maxx=-1,_maxz=-1;
    for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){
        var _t=global.cr_map.tiles[_i];if(_t.room!=_room_index)continue;
        array_push(_tiles,[_t.x,_t.z]);_minx=min(_minx,_t.x*10);_minz=min(_minz,_t.z*10);_maxx=max(_maxx,(_t.x+1)*10);_maxz=max(_maxz,(_t.z+1)*10);
    }
    return {tiles:_tiles,bounds:[_minx,_minz,_maxx,_maxz]};
}
function cr_style_shuffle_items(_present) {
    var _items=global.bbcr.items,_positions=[];
    for(var _i=0;_i<array_length(_items);_i++)array_push(_positions,[_items[_i].x,_items[_i].z]);
    for(var _i=array_length(_positions)-1;_i>0;_i--){var _j=irandom(_i),_p=_positions[_i];_positions[_i]=_positions[_j];_positions[_j]=_p;}
    for(var _i=0;_i<array_length(_items);_i++){_items[_i].x=_positions[_i][0];_items[_i].z=_positions[_i][1];_items[_i].sprite_override=_present;}
}
function cr_party_init() {
    var _g=global.bbcr,_data=global.cr_map.party;
    // Party's ending environment is pre-generated in Unity and temporarily adds
    // two activities to the shared total. BeginPlay subtracts those two again;
    // the seven activities in the school are still all required.
    _g.needed=array_length(_g.books);_g.balloons=[];
    _g.party={data:_data,phase:"school",elevator_y:0,lift_height:5,spawner:4,spawns:0,values:[0,0,0,0],puzzle:[0,0,0,0],puzzle_timers:[0,0,0,0],puzzle_open:false,tutor:undefined,secret_ready:false,angry_secret:false};
    cr_style_shuffle_items(_data.present_sprite);
    for(var _ri=0;_ri<array_length(_data.balloon_rooms);_ri++){
        var _room=_data.balloon_rooms[_ri],_count=irandom_range(_data.balloon_min,_data.balloon_max_exclusive-1);
        repeat(_count){var _spec=_data.school_balloons[irandom(array_length(_data.school_balloons)-1)];array_push(_g.balloons,cr_style_balloon(_spec,_room));}
    }
}
function cr_party_balloon_step(_dt) {
    var _list=global.bbcr.balloons;
    for(var _i=0;_i<array_length(_list);_i++){
        var _b=_list[_i],_s=_b.spec;_b.timer-=_dt;
        if(_b.timer<=0){_b.angle=random(2*pi);_b.timer=random_range(_s.min_direction_time,_s.max_direction_time);}
        var _nx=_b.px+cos(_b.angle)*_s.speed*_dt,_nz=_b.pz+sin(_b.angle)*_s.speed*_dt;
        if(!cr_blocked(_nx,_b.pz,_s.radius,false))_b.px=_nx;else _b.angle=pi-_b.angle;
        if(!cr_blocked(_b.px,_nz,_s.radius,false))_b.pz=_nz;else _b.angle=-_b.angle;
        if(_b.px-_s.radius<_b.minx){_b.px=_b.minx+_s.radius;_b.angle=pi-_b.angle;}
        if(_b.px+_s.radius>_b.maxx){_b.px=_b.maxx-_s.radius;_b.angle=pi-_b.angle;}
        if(_b.pz-_s.radius<_b.minz){_b.pz=_b.minz+_s.radius;_b.angle=-_b.angle;}
        if(_b.pz+_s.radius>_b.maxz){_b.pz=_b.maxz-_s.radius;_b.angle=-_b.angle;}
    }
}
function cr_party_final_exit() {
    var _g=global.bbcr;if(_g.style!="party" || !is_struct(_g.party) || _g.party.phase!="school")return;
    cr_progress_complete_style("party");cr_rope_end(false);cr_caption_world_end();_g.party.phase="elevator_ready";_g.party.elevator_y=-30;
    for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].hidden=true;
    _g.spoop=false;_g.exit_fx.active=false;cr_exit_stop_file();_g.exit_fx.pending=[];_g.exit_fx.flicker=false;
    if(_g.game_music>=0)audio_stop_sound(_g.game_music);_g.game_music=cr_sound("DanceV0_5");if(_g.game_music>=0)audio_sound_loop(_g.game_music,true);
}
function cr_party_begin_lift() {
    var _g=global.bbcr,_p=_g.party;if(_p.phase!="elevator_ready")return;
    _p.phase="lift";_p.lift_height=5;_p.elevator_y=-30;
    var _b=_p.data.elevator_trigger;_g.px=_b.center[0];_g.pz=_b.center[2];_g.items_disabled=true;
}
function cr_party_enter_ending() {
    var _g=global.bbcr,_party=_g.party,_data=_party.data;
    _party.school={map:global.cr_map,doors:_g.doors,exits:_g.exits,items:_g.items,books:_g.books,balloons:_g.balloons,portals:_g.portals};
    cr_world_cleanup();global.cr_map=cr_json("bbcr/PartyEnding.json");global.cr_map.spawn[1]=5;
    cr_extra_items_init();
    _g.world_y=_data.ending_y;
    _g.party=_party;_party.phase="ending";_party.secret_ready=true;_g.jump_height=0;_g.items_disabled=false;_g.balloons=[];
    _g.doors=global.cr_map.doors;for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];_d.open=0;_d.lock=0;_d.silent=0;_d.player_inside=false;_d.need_voice=-1;_d.tx=cos(degtorad(_d.dir*90));_d.tz=-sin(degtorad(_d.dir*90));_d.half=5;}
    _g.exits=[];_g.items=[];_g.books=[];_g.projectiles=[];_g.alarms=[];
    for(var _i=0;_i<array_length(global.cr_map.windows);_i++)global.cr_map.windows[_i].broken=false;
    global.cr_tiles=array_create(global.cr_map.size.x*global.cr_map.size.z,undefined);
    for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){var _t=global.cr_map.tiles[_i];_t.index=_i;global.cr_tiles[_t.x+_t.z*global.cr_map.size.x]=_t;}
    cr_exit_init();cr_build_world();cr_build_navigation();_g.loaded=true;
    do{for(var _i=0;_i<4;_i++)_party.values[_i]=irandom(9);}until(_party.values[0]+_party.values[1]+_party.values[2]+_party.values[3]>=10);
    var _rooms=[];for(var _i=0;_i<array_length(global.cr_map.rooms);_i++)if(global.cr_map.rooms[_i].category==2 || global.cr_map.rooms[_i].category==3)array_push(_rooms,_i);
    for(var _color=0;_color<4;_color++)repeat(_party.values[_color]){
        var _room=cr_style_room(_rooms[irandom(array_length(_rooms)-1)]),_spec=_data.ending_balloons[_color];array_push(_g.balloons,cr_style_balloon(_spec,_room));
    }
    if(audio_is_playing(_g.game_music))audio_stop_sound(_g.game_music);_g.game_music=-1;cr_sound(_data.aud_blow);cr_exit_queue(_data.glitch_sounds);
}
function cr_party_return_school() {
    var _g=global.bbcr,_p=_g.party,_s=_p.school;cr_world_cleanup();cr_exit_stop_file();
    global.cr_map=_s.map;_g.doors=_s.doors;_g.exits=_s.exits;_g.items=_s.items;_g.books=_s.books;_g.balloons=_s.balloons;
    cr_extra_items_init();_g.portals=_s.portals;_g.world_y=0;_g.jump_height=0;_p.phase="returned";
    global.cr_tiles=array_create(global.cr_map.size.x*global.cr_map.size.z,undefined);
    for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){var _t=global.cr_map.tiles[_i];global.cr_tiles[_t.x+_t.z*global.cr_map.size.x]=_t;}
    cr_exit_init();cr_build_world();cr_build_navigation();_g.loaded=true;
}
function cr_party_candle() {
    var _g=global.bbcr;if(_g.party.phase!="candle")return;
    cr_party_enter_ending();
}
function cr_party_step(_dt) {
    var _g=global.bbcr,_p=_g.party;cr_party_balloon_step(_dt);
    for(var _i=0;_i<4;_i++){
        var _was=_p.puzzle_timers[_i];_p.puzzle_timers[_i]=max(0,_was-_dt);
        if(_was>0 && _p.puzzle_timers[_i]<=0 && variable_struct_exists(global.cr_map,"puzzle"))cr_sound(global.cr_map.puzzle.buttons[_i].release);
    }
    if(_p.phase=="returned")cr_party_tutor_step();
    switch(_p.phase){
        case "elevator_ready":if(cr_box_overlap(_p.data.elevator_trigger,_g.px,_g.pz,global.cr_catalog.movement.radius))cr_party_begin_lift();break;
        case "lift":
            _p.lift_height=min(35,_p.lift_height+10*_dt);_p.elevator_y=_p.lift_height-35;_g.jump_height=_p.lift_height-5;
            if(_p.lift_height>=35)_p.phase="candle";break;
        case "ending":
            _g.stamina=global.cr_catalog.movement.staminaMax*2;
            var _trigger=_p.data.ending_trigger;if(point_distance(_g.px,_g.pz,_trigger.center[0],_trigger.center[2])<_trigger.radius){_p.phase="corrupt";_p.angry_secret=true;_p.spawner=4;}
            break;
        case "corrupt":
            _g.stamina=global.cr_catalog.movement.staminaMax*2;_p.spawner-=_dt;
            if(_p.spawner<=0){_p.spawns++;_p.spawner=max(.05,4-_p.spawns*.05);}
            break;
    }
}
function cr_party_puzzle_press(_index) {
    var _g=global.bbcr,_p=_g.party;if(!variable_struct_exists(global.cr_map,"puzzle"))return;
    if(_p.puzzle_timers[_index]>0)return;
    var _b=global.cr_map.puzzle.buttons[_index];_p.puzzle[_index]=(_p.puzzle[_index]+1) mod 10;_p.puzzle_timers[_index]=_b.reset;cr_sound(_b.press);
    var _correct=true;for(var _i=0;_i<4;_i++)if(_p.puzzle[_i]!=_p.values[_i])_correct=false;
    if(_correct && !_p.puzzle_open){_p.puzzle_open=true;cr_sound(global.cr_map.puzzle.sound);}
}
function cr_party_tutor_key() {
    return global.bbcr.progress.flags[4]?"secretBaldi":(global.bbcr.party.angry_secret?"angryNull":"secretNull");
}
function cr_party_tutor_step() {
    var _g=global.bbcr,_p=_g.party;if(!_p.secret_ready)return;
    var _spec=_p.data.tutors[$ cr_party_tutor_key()];
    if(!is_struct(_p.tutor)){
        if(sqrt(sqr(_g.px-_spec.position[0])+sqr(_g.pz-_spec.position[2])+sqr(5-_spec.position[1]))>=_spec.radius)return;
        _p.tutor={handle:cr_sound(_spec.speech,_spec.position[0],_spec.position[2],false,undefined,_spec.audio),spec:_spec,started:true};
        if(cr_progress_set_flag(2))cr_save();
    }else if(!audio_is_playing(_p.tutor.handle)){
        cr_party_tutor_complete();
    }
}
function cr_party_tutor_complete() {
    var _t=global.bbcr.party.tutor;
    if(_t.spec.quit){game_end();return;}
    if(_t.spec.menu)cr_return_menu();
}
function cr_party_move_scale() {
    if(global.bbcr.style!="party" || !is_struct(global.bbcr.party))return 1;
    return (global.bbcr.party.phase=="lift" || global.bbcr.party.phase=="candle")?0:1;
}
function cr_demo_new_problem(_book) {
    var _addition=irandom(1)==0,_a=irandom(9),_b=_addition?irandom(9-_a):irandom(_a);
    _book.a=_a;_book.b=_b;_book.op=_addition?"+":"-";_book.answer=_addition?_a+_b:_a-_b;_book.held=-1;
}
function cr_demo_init() {
    var _g=global.bbcr;_g.demo={problems:0,last:-1,held_machine:-1,held_number:-1,bonus_wins:0};
    for(var _i=0;_i<array_length(_g.books);_i++){
        var _b=_g.books[_i],_m=_b.machine,_room=cr_style_room(_b.room);_b.bonus=false;_b.state="active";_b.book_ready=false;_b.corrupted=false;_b.answered=0;_b.required=_g.hard?_m.hard_problems:_m.total_problems;_b.numbers=[];
        var _yaw=degtorad(_m.direction*90);_b.book_x=_m.x+sin(_yaw)*_m.notebook_distance;_b.book_z=_m.z+cos(_yaw)*_m.notebook_distance;
        for(var _j=0;_j<array_length(_m.numbers);_j++){
            var _tile=_room.tiles[irandom(array_length(_room.tiles)-1)],_spec=_m.numbers[_j];
            array_push(_b.numbers,{spec:_spec,px:_tile[0]*10+5,pz:_tile[1]*10+5,minx:_room.bounds[0],minz:_room.bounds[1],maxx:_room.bounds[2],maxz:_room.bounds[3],angle:random(2*pi),timer:random_range(2.5,10),active:true,held:false});
        }
        cr_demo_new_problem(_b);
    }
}
function cr_demo_number_step(_dt) {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(_g.books);_i++){
        var _b=_g.books[_i];if(_b.activity!="MathMachine" || _b.state!="active")continue;
        for(var _j=0;_j<array_length(_b.numbers);_j++){
            var _n=_b.numbers[_j];if(!_n.active)continue;
            if(_n.held){var _yaw=cr_view_yaw();_n.px=_g.px+sin(_yaw)*4;_n.pz=_g.pz+cos(_yaw)*4;continue;}
            _n.timer-=_dt;if(_n.timer<=0){_n.angle=random(2*pi);_n.timer=random_range(2.5,10);}
            _n.px+=cos(_n.angle)*_n.spec.speed*_dt;_n.pz+=sin(_n.angle)*_n.spec.speed*_dt;
            if(_n.px-_n.spec.radius<_n.minx){_n.px=_n.minx+_n.spec.radius;_n.angle=pi-_n.angle;}
            if(_n.px+_n.spec.radius>_n.maxx){_n.px=_n.maxx-_n.spec.radius;_n.angle=pi-_n.angle;}
            if(_n.pz-_n.spec.radius<_n.minz){_n.pz=_n.minz+_n.spec.radius;_n.angle=-_n.angle;}
            if(_n.pz+_n.spec.radius>_n.maxz){_n.pz=_n.maxz-_n.spec.radius;_n.angle=-_n.angle;}
        }
    }
}
function cr_demo_hold_number(_encoded) {
    var _g=global.bbcr,_machine=floor(_encoded/10),_number=_encoded mod 10;
    if(_g.demo.held_machine>=0){var _old=_g.books[_g.demo.held_machine].numbers[_g.demo.held_number];_old.held=false;_old.px=_g.px;_old.pz=_g.pz;}
    var _n=_g.books[_machine].numbers[_number];if(!_n.active)return;_n.held=true;_g.demo.held_machine=_machine;_g.demo.held_number=_number;
}
function cr_demo_complete(_index,_correct) {
    var _g=global.bbcr,_b=_g.books[_index],_m=_b.machine;_b.state=_correct?"correct":"wrong";_b.book_ready=true;
    _g.demo.last=_index;
    if(_b.bonus){
        _g.demo.bonus_wins++;_b.bonus_number=_g.demo.bonus_wins;_b.book_ready=false;
        if(_g.demo.bonus_wins>=6)array_push(_g.items,{x:_b.book_x,z:_b.book_z,item:_m.bonus_item,done:false});
    }else _g.demo.bonus_wins=0;
    _b.pop_timer=0;_b.pop_count=0;
    _g.demo.held_machine=-1;_g.demo.held_number=-1;cr_sound(_correct?_m.aud_win:_m.aud_lose,_m.x,_m.z);_g.demo.problems++;
    if(!_correct){
        // MathMachine broadcasts/angers before ActivityCompleted spawns NPCs.
        // A dormant prefab is not an NPC in EnvironmentController.Npcs yet.
        if(_g.spoop){_g.anger++;cr_noise(_m.x,_m.z,_m.wrong_noise);}
        else if(_g.mode!="free"){cr_spoop();_g.demo.events_started=true;}
    }
    else if(_g.spoop && array_length(_g.npcs)>0)cr_baldi_please(_g.npcs[0],_m.baldi_pause);
    if(_g.demo.problems==1){for(var _i=0;_i<array_length(_g.books);_i++)if(_g.books[_i].state=="active")_g.books[_i].corrupted=true;
        if(_correct){var _p=global.cr_map.spawn,_o=global.cr_map.happy.quarter_offset,_yaw=degtorad(global.cr_map.yaw);array_push(_g.items,{x:_p[0]+sin(_yaw)*15+_o[0],z:_p[2]+cos(_yaw)*15+_o[2],item:"Quarter",done:false});
            cr_voice_clear();var _sounds=global.cr_map.manager_sounds.audQuarter;for(var _i=0;_i<array_length(_sounds);_i++)array_push(_g.voice_queue,{key:_sounds[_i],x:_p[0]+sin(_yaw)*15,z:_p[2]+cos(_yaw)*15});cr_voice_tick();}}
    else if(_g.demo.problems==2)for(var _i=0;_i<array_length(_g.books);_i++)if(_g.books[_i].state=="active")_g.books[_i].corrupted=false;
}
function cr_demo_submit_machine(_index) {
    var _g=global.bbcr;if(_g.demo.held_machine!=_index)return;
    var _b=_g.books[_index],_number=_g.demo.held_number,_n=_b.numbers[_number],_correct=!_b.corrupted && _n.spec.value==_b.answer;
    _n.active=false;_n.held=false;_g.demo.held_machine=-1;_g.demo.held_number=-1;
    if(_correct){_b.answered++;if(_b.answered>=_b.required)cr_demo_complete(_index,true);else cr_demo_new_problem(_b);}else cr_demo_complete(_index,false);
}
function cr_demo_collect_book(_index) {
    var _g=global.bbcr,_b=_g.books[_index];if(!_b.book_ready || _b.done)return;
    _b.done=true;_g.notebooks++;_g.stamina=global.cr_catalog.movement.staminaMax;if(_g.spoop)_g.anger+=1;
    if(_g.notebooks>=2)for(var _i=0;_i<array_length(_g.doors);_i++)_g.doors[_i].locked=false;
    if(_g.notebooks>=_g.needed && _g.mode=="story"){
        cr_sound(global.cr_map.manager_sounds[$ (_g.progress.flags[4]?"audAllNotebooksNorm":"audAllNotebooks")]);
        for(var _i=0;_i<array_length(_g.exits);_i++){_g.exits[_i].state=0;_g.exits[_i].prepared=true;}
        cr_exit_music("exit_music",1);
        for(var _i=0;_i<array_length(_g.books);_i++)if(_i!=_g.demo.last)cr_demo_bonus_reset(_g.books[_i]);
    }
}
function cr_style_step(_dt) {
    if(global.bbcr.style=="party" && is_struct(global.bbcr.party))cr_party_step(_dt);
    if(global.bbcr.style=="demo" && is_struct(global.bbcr.demo)){cr_demo_number_step(_dt);cr_demo_pop_step(_dt);cr_demo_events_step(_dt);cr_demo_gum_step(_dt);cr_demo_hatch_step();}
}
function cr_demo_bonus_reset(_b) {
    _b.bonus=true;_b.state="active";_b.corrupted=false;_b.book_ready=false;_b.answered=0;
    var _room=cr_style_room(_b.room);
    for(var _j=0;_j<array_length(_b.numbers);_j++){var _n=_b.numbers[_j],_t=_room.tiles[irandom(array_length(_room.tiles)-1)];_n.px=_t[0]*10+5;_n.pz=_t[1]*10+5;_n.active=true;_n.held=false;}
    cr_demo_new_problem(_b);
}
function cr_demo_hatch_step() {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(global.cr_map.triggers);_i++){
        var _t=global.cr_map.triggers[_i];if(_t.source!="HatchTrigger")continue;
        for(var _j=0;_j<array_length(_t.spheres);_j++){
            var _s=_t.spheres[_j];if(point_distance(_g.px,_g.pz,_s.position[0],_s.position[2])>=_s.radius+global.cr_catalog.movement.radius)continue;
            cr_progress_complete_style("demo");if(cr_progress_set_flag(3))cr_save();
            cr_secret_load(global.cr_map.next_level);return;
        }
    }
}
function cr_demo_pop_step(_dt) {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(_g.books);_i++){
        var _b=_g.books[_i];if(_b.state=="active")continue;_b.pop_timer-=_dt;
        if(_b.pop_timer>0)continue;
        var _pool=[];for(var _j=0;_j<array_length(_b.numbers);_j++)if(_b.numbers[_j].active)array_push(_pool,_j);
        if(array_length(_pool)>0){var _n=_b.numbers[_pool[irandom(array_length(_pool)-1)]];_n.active=false;_b.pop_count++;cr_sound(_n.spec.pop_sound,_n.px,_n.pz);_b.pop_timer=random_range(.1,.3);}
    }
}
