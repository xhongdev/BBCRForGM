function cr_demo_select_npcs() {
    var _m=global.cr_map,_pool=array_create(0);
    for(var _i=0;_i<array_length(_m.demo.potential_npcs);_i++)array_push(_pool,_m.demo.potential_npcs[_i]);
    repeat(min(_m.demo.count,array_length(_pool))){
        var _total=0;for(var _i=0;_i<array_length(_pool);_i++)_total+=_pool[_i].weight;
        var _roll=random(_total),_pick=0;for(var _i=0;_i<array_length(_pool);_i++){_roll-=_pool[_i].weight;if(_roll<0){_pick=_i;break;}}
        var _src=json_parse(json_stringify(_pool[_pick].npc)),_tiles=[];array_delete(_pool,_pick,1);
        for(var _i=0;_i<array_length(_m.tiles);_i++){var _t=_m.tiles[_i],_r=_m.rooms[_t.room];if(!_r.offlimits && array_contains(_src.params.spawn_rooms,_r.category))array_push(_tiles,_t);}
        if(array_length(_tiles)>0){var _t=_tiles[irandom(array_length(_tiles)-1)];_src.x=_t.x*10+5;_src.z=_t.z*10+5;_src.optional=true;array_push(_m.npcs,_src);}
    }
}
function cr_demo_actors_init() {
    var _g=global.bbcr;_g.demo.gum=[];_g.demo.boards=[];
    for(var _i=0;_i<array_length(_g.npcs);_i++){
        var _n=_g.npcs[_i];_n.optional_pending=cr_value(global.cr_map.npcs[_i],"optional",false) && !_n.params.ignorePlayerOnSpawn;
        _n.actor_state="wander";_n.actor_timer=0;_n.gum_time=0;_n.flipped=false;
        if(_n.name=="Beans"){_n.sprint_wait=random_range(_n.params.minSprintWait,_n.params.maxSprintWait);_n.sprint_time=0;_n.targeting=false;_n.gum=undefined;}
        if(_n.name=="Cumulo"){_n.hall=undefined;_n.actor_state="find";}
        if(_n.name=="ChalkFace"){
            _n.hidden=true;_n.board_room=-1;_n.height=5;var _rooms=[];
            if(!_g.spoop)continue;
            for(var _j=0;_j<array_length(global.cr_map.rooms);_j++)if(global.cr_map.rooms[_j].category==2)array_push(_rooms,_j);
            repeat(round(array_length(_rooms)*_n.params.spawnPercent/100)){
                var _ri=irandom(array_length(_rooms)-1),_room=_rooms[_ri],_walls=[];array_delete(_rooms,_ri,1);
                for(var _j=0;_j<array_length(global.cr_map.tiles);_j++){
                    var _t=global.cr_map.tiles[_j];if(_t.room!=_room || !array_contains(_n.params.tile_shapes,cr_tile_shape(_t.walls)))continue;
                    for(var _d=0;_d<4;_d++)if((_t.walls & (1<<_d))!=0){
                        var _cx=_t.x*10+5+sin(_d*pi/2)*5,_cz=_t.z*10+5+cos(_d*pi/2)*5,_used=false;
                        for(var _k=0;_k<array_length(_g.doors);_k++)if(point_distance(_cx,_cz,_g.doors[_k].cx,_g.doors[_k].cz)<.1)_used=true;
                        for(var _k=0;_k<array_length(global.cr_map.posters);_k++){var _p=global.cr_map.posters[_k];if(_p.x==_t.x && _p.z==_t.z && _p.dir==_d)_used=true;}
                        for(var _k=0;_k<array_length(global.cr_map.windows);_k++){var _w=global.cr_map.windows[_k];if(point_distance(_cx,_cz,_w.cx,_w.cz)<.1)_used=true;}
                        if(!_used)array_push(_walls,{x:_t.x*10+5,z:_t.z*10+5,dir:_d,tile:_j});
                    }
                }
                if(array_length(_walls)>0){var _w=_walls[irandom(array_length(_walls)-1)];_w.room=_room;_w.npc=_i;global.cr_map.tiles[_w.tile].contains_object=true;array_push(_g.demo.boards,_w);}
            }
        }
    }
}
function cr_demo_actor_pending(_n) {
    if(!_n.optional_pending)return false;
    var _g=global.bbcr;if(sqrt(sqr(_n.px-_g.px)+sqr(_n.pz-_g.pz)+25)<=75 || abs(_n.px-_g.px)<=15 || abs(_n.pz-_g.pz)<=15)return true;
    _n.optional_pending=false;return false;
}
function cr_demo_actor_voice(_n,_field) {
    var _list=_n.params[$ _field];if(array_length(_list)>0){array_push(_n.voice_queue,_list[irandom(array_length(_list)-1)]);cr_npc_voice_tick(_n);}
}
function cr_demo_beans(_n,_dt,_seen) {
    var _g=global.bbcr,_p=_n.params;
    if(_n.actor_state=="chew"){
        _n.actor_timer-=_dt;if(_n.actor_timer<=0){
            var _dir=round(arctan2(_g.px-_n.px,_g.pz-_n.pz)/(pi/2)),_dx=sin(_dir*pi/2),_dz=cos(_dir*pi/2);
            _n.gum={px:_n.px+_dx*4,pz:_n.pz+_dz*4,dx:_dx,dz:_dz,life:30,target:undefined,owner:_n};array_push(_g.demo.gum,_n.gum);
            _n.actor_state="spit";_n.actor_timer=.4;_n.anim_time=0;_n.cooldown=_p.cooldownTime;
            cr_npc_sound(_n,_p.audSpit);cr_demo_actor_voice(_n,"audSpitSounds");_n.targeting=false;
        }_n.anim_time+=_dt;return;
    }
    if(_n.actor_state=="spit"){_n.actor_timer-=_dt;if(_n.actor_timer<=0)_n.actor_state="wander";else return;}
    if(_seen && !_n.targeting && !is_struct(_n.gum)){_n.targeting=true;if(_n.cooldown<=0)cr_demo_actor_voice(_n,"audTargetSounds");}
    if(!_seen)_n.targeting=false;
    if(point_distance(_n.px,_n.pz,_n.gx,_n.gz)<3 || cr_value(_n,"destination_empty",false)){
        _n.destination_empty=false;
        if(_n.targeting && _n.cooldown<=0){_n.actor_state="chew";_n.actor_timer=3;_n.anim_time=0;_n.cooldown=_p.cooldownTime;return;}cr_wander(_n);
    }
    if(_n.sprint_time>0)_n.sprint_time=max(0,_n.sprint_time-_dt);
    else {_n.sprint_wait-=_dt;if(_n.sprint_wait<=0){_n.sprint_time=random_range(_p.minSprint,_p.maxSprint);_n.sprint_wait=random_range(_p.minSprintWait,_p.maxSprintWait);if(random(1)<=_p.sprintAudChance)cr_demo_actor_voice(_n,"audSkipSounds");}}
    _n.anim_time+=_dt;cr_npc_move(_n,_n.sprint_time>0?_p.sprintSpeed:_p.normSpeed,_dt);
}
function cr_demo_gum_step(_dt) {
    var _g=global.bbcr;
    _g.gum_time=max(0,_g.gum_time-_dt);
    for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].gum_time=max(0,_g.npcs[_i].gum_time-_dt);
    for(var _i=array_length(_g.demo.gum)-1;_i>=0;_i--){
        var _s=_g.demo.gum[_i],_p=_s.owner.params.gum;_s.life-=_dt;
        if(!is_undefined(_s.target)){_s.px=_s.target.px;_s.pz=_s.target.pz;_s.target.gum_time=max(0,_s.life);}
        else {
            var _step=max(1,ceil(_p.speed*_dt/.5));repeat(_step){
                _s.px+=_s.dx*_p.speed*_dt/_step;_s.pz+=_s.dz*_p.speed*_dt/_step;
                if(cr_blocked(_s.px,_s.pz,.2)){_s.life=0;break;}
                var _targets=[_g];for(var _j=0;_j<array_length(_g.npcs);_j++)if(_g.npcs[_j]!=_s.owner && !_g.npcs[_j].hidden)array_push(_targets,_g.npcs[_j]);
                for(var _j=0;_j<array_length(_targets);_j++)if(point_distance(_s.px,_s.pz,_targets[_j].px,_targets[_j].pz)<2){
                    _s.target=_targets[_j];_s.life=_p.setTime;_s.target.gum_time=_s.life;_s.target.gum_scale=_s.target==_g?_p.playerMod.movementMultiplier:_p.moveMod.movementMultiplier;
                    cr_demo_actor_voice(_s.owner,_s.target==_g?"audPlayerHitSounds":"audNPCHitSounds");break;
                }if(!is_undefined(_s.target))break;
            }
        }
        if(_s.life<=0){if(!is_undefined(_s.target))_s.target.gum_time=0;_s.owner.gum=undefined;array_delete(_g.demo.gum,_i,1);}
    }
}
function cr_demo_chalk(_n,_dt) {
    var _g=global.bbcr,_tile=cr_tile(_g.px,_g.pz),_board=undefined;
    for(var _i=0;_i<array_length(_g.demo.boards);_i++){var _b=_g.demo.boards[_i];if(!is_undefined(_tile) && _b.room==_tile.room && _g.npcs[_b.npc]==_n){_board=_b;break;}}
    if(is_undefined(_board)){
        if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);_n.voice=-1;_n.hidden=true;_n.board_room=-1;return;
    }
    var _p=_n.params;
    if(_n.board_room!=_board.room){_n.board_room=_board.room;_n.px=_board.x+sin(_board.dir*pi/2)*4.9;_n.pz=_board.z+cos(_board.dir*pi/2)*4.9;_n.height=5;_n.actor_state="form";_n.actor_timer=_p.setTime;_n.hidden=false;_n.spoken=false;}
    _n.actor_timer-=_dt;
    if(_n.actor_state=="form"){
        _n.sprite=_p.chalk_sprite;if(_n.actor_timer<=15 && !_n.spoken){_n.voice=cr_npc_sound(_n,_p.audSpawn);_n.spoken=true;}
        if(_n.actor_timer<=0){
            _n.actor_state="orbit";_n.actor_timer=_p.lockTime;_n.sprite=_p.flying_sprite;
            for(var _i=0;_i<array_length(_g.doors);_i++){var _d=_g.doors[_i];if(_d.a_room==_board.room || _d.b_room==_board.room){_d.lock=_p.lockTime;_d.open=0;}}
            cr_noise(_n.px,_n.pz,_p.noiseVal);_n.voice=cr_npc_sound(_n,_p.audLaugh);if(_n.voice>=0)audio_sound_loop(_n.voice,true);
        }return;
    }
    var _room=cr_style_room(_board.room),_cx=(_room.bounds[0]+_room.bounds[2])/2,_cz=(_room.bounds[1]+_room.bounds[3])/2;
    var _radius=max(0,point_distance(_n.px,_n.pz,_cx,_cz)-_p.approachSpeed*_dt),_angle=arctan2(_n.pz-_cz,_n.px-_cx)+degtorad(_p.spinSpeed+max(0,-_n.actor_timer)*_p.acceleration)*_dt;
    _n.px=_cx+cos(_angle)*_radius;_n.pz=_cz+sin(_angle)*_radius;
    if(_n.actor_timer<=0){_n.height+=_p.approachSpeed*_dt;if(_n.height>=15){_n.hidden=true;if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);}}
}
function cr_demo_cloud(_n,_dt) {
    var _g=global.bbcr,_p=_n.params;
    if(_n.actor_state=="find"){
        var _halls=[];
        for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){
            var _t=global.cr_map.tiles[_i];if(_t.room!=0)continue;
            for(var _d=0;_d<2;_d++){
                var _dx=_d==1?1:0,_dz=_d==0?1:0,_prev=cr_tile((_t.x-_dx)*10+5,(_t.z-_dz)*10+5);
                if(!is_undefined(_prev) && _prev.room==0 && (_prev.walls & (1<<_d))==0)continue;
                var _last=_t,_len=1;repeat(100){var _next=cr_tile((_last.x+_dx)*10+5,(_last.z+_dz)*10+5);if((_last.walls & (1<<_d))!=0 || is_undefined(_next) || _next.room!=0)break;_last=_next;_len++;}
                if(_len>=_p.minHallLength)array_push(_halls,[_t.x*10+5,_t.z*10+5,_last.x*10+5,_last.z*10+5]);
            }
        }
        if(array_length(_halls)==0)return;_n.hall=_halls[irandom(array_length(_halls)-1)];
        if(irandom(1)==1)_n.hall=[_n.hall[2],_n.hall[3],_n.hall[0],_n.hall[1]];
        _n.gx=_n.hall[0];_n.gz=_n.hall[1];_n.route_timer=0;_n.actor_state="travel";
    }
    if(_n.actor_state=="travel"){
        _n.speed=min(_p.max_speed,_n.speed+_p.accel*_dt);cr_npc_move(_n,_n.speed,_dt);
        if(point_distance(_n.px,_n.pz,_n.gx,_n.gz)<.5){_n.actor_state="blow";_n.actor_timer=random_range(_p.minStay,_p.maxStay);_n.voice=cr_npc_sound(_n,_p.audBlowing);if(_n.voice>=0)audio_sound_loop(_n.voice,true);}return;
    }
    if(_n.actor_state=="blow"){
        _n.actor_timer-=_dt;var _h=_n.hall;
        if(_n.actor_timer<=0 || point_distance(_n.px,_n.pz,_h[0],_h[1])>.1){if(audio_is_playing(_n.voice))audio_stop_sound(_n.voice);_n.actor_state="find";return;}
        var _targets=[_g];for(var _i=0;_i<array_length(_g.npcs);_i++)if(_g.npcs[_i]!=_n && !_g.npcs[_i].params.ignoreBelts)array_push(_targets,_g.npcs[_i]);
        for(var _i=0;_i<array_length(_targets);_i++){var _t=_targets[_i];if(_t==_g && _g.boots>0)continue;
            if(point_in_rectangle(_t.px,_t.pz,min(_h[0],_h[2])-5,min(_h[1],_h[3])-5,max(_h[0],_h[2])+5,max(_h[1],_h[3])+5))cr_move(_t,sign(_h[2]-_h[0])*_p.wind_speed*_dt,sign(_h[3]-_h[1])*_p.wind_speed*_dt,_t==_g?2:_t.params.collision_radius);
        }
    }
}
