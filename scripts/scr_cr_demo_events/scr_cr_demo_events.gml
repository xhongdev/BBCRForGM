function cr_demo_events_init() {
    var _g=global.bbcr,_src=global.cr_map.demo.events,_pool=[],_time=_src.initial;
    _g.demo.events=[];_g.demo.event_clock=0;_g.demo.events_started=false;_g.demo.event_text="";_g.demo.event_text_time=0;
    _g.demo.fog=0;_g.demo.fog_color=make_color_rgb(212,212,212);_g.demo.max_sight=1000000000;_g.demo.water=0;_g.demo.flood=false;_g.demo.flipped=false;_g.demo.roll=0;_g.demo.roll_target=0;_g.demo.ruler=false;_g.demo.ruler_break=false;_g.gum_time=0;
    for(var _i=0;_i<array_length(_src.events);_i++)array_push(_pool,_src.events[_i]);
    while(array_length(_pool)>0){
        var _i=irandom(array_length(_pool)-1),_s=_pool[_i];array_delete(_pool,_i,1);
        _time+=random_range(_src.gap[0],_src.gap[1]);var _duration=random_range(_s.minEventTime,_s.maxEventTime);
        array_push(_g.demo.events,{spec:_s,start:_time,duration:_duration,state:"waiting",announced:false,time:0,voice:-1,objects:[],spawn_timer:10,door:0,door_timer:.5,settled:false});_time+=_duration;
    }
}
function cr_demo_event_begin(_e) {
    var _g=global.bbcr,_d=_g.demo,_s=_e.spec;_e.state="active";_e.time=0;
    _d.event_text=global.cr_text[$ _s.eventDescKey];_d.event_text_time=5;
    switch(_s.name){
        case "RulerEvent":_d.ruler=true;_d.ruler_break=true;break;
        case "FogEvent":_d.max_sight=_s.maxRaycast;_d.fog_color=make_color_rgb(_s.fogColor.r*255,_s.fogColor.g*255,_s.fogColor.b*255);_e.voice=cr_sound(_s.music);if(_e.voice>=0)audio_sound_loop(_e.voice,true);break;
        case "FloodEvent":_d.flood=true;_e.voice=cr_sound(_s.audWater);if(_e.voice>=0)audio_sound_loop(_e.voice,true);break;
        case "GravityEvent":
            for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].flipped=true;
            cr_demo_flip_player();_e.spawn_timer=_s.initialSpawnDelay;break;
    }
}
function cr_demo_flip_player() {
    var _d=global.bbcr.demo;_d.flipped=!_d.flipped;_d.roll_target+=180;
}
function cr_demo_event_end(_e) {
    var _g=global.bbcr,_d=_g.demo;_e.state="ending";
    switch(_e.spec.name){
        case "RulerEvent":_d.ruler=false;break;
        case "FogEvent":_d.max_sight=1000000000;break;
        case "FloodEvent":
            _d.flood=false;for(var _i=0;_i<array_length(_e.objects);_i++)if(!is_undefined(_e.objects[_i].target))_e.objects[_i].target.in_whirlpool=false;
            _g.jump_height=0;_e.objects=[];break;
        case "GravityEvent":_e.objects=[];if(_d.flipped)cr_demo_flip_player();for(var _i=0;_i<array_length(_g.npcs);_i++)_g.npcs[_i].flipped=false;break;
    }
    if(_e.spec.name!="FloodEvent" && audio_is_playing(_e.voice)){audio_stop_sound(_e.voice);_e.voice=-1;}
}
function cr_demo_random_tiles(_count,_hall) {
    var _pool=[],_result=[];
    for(var _i=0;_i<array_length(global.cr_map.tiles);_i++){var _t=global.cr_map.tiles[_i];if((!_hall || _t.room==0) && !global.cr_map.rooms[_t.room].offlimits && !cr_blocked(_t.x*10+5,_t.z*10+5,.5,false))array_push(_pool,_t);}
    repeat(min(_count,array_length(_pool))){var _i=irandom(array_length(_pool)-1);array_push(_result,_pool[_i]);array_delete(_pool,_i,1);}return _result;
}
function cr_demo_events_step(_dt) {
    var _g=global.bbcr,_d=_g.demo;if(!_d.events_started || _g.mode=="free")return;
    _d.event_clock+=_dt;_d.event_text_time=max(0,_d.event_text_time-_dt);var _fog=false;
    for(var _i=0;_i<array_length(_d.events);_i++){
        var _e=_d.events[_i],_s=_e.spec;
        if(_e.state=="waiting"){
            if(!_e.announced && _d.event_clock>=_e.start-3){_e.announced=true;cr_sound(global.cr_map.demo.events.bell);}
            if(_d.event_clock>=_e.start)cr_demo_event_begin(_e);else continue;
        }
        if(_e.state=="active"){
            _e.time+=_dt;
            switch(_s.name){
                case "FogEvent":_fog=true;break;
                case "FloodEvent":
                    _d.water=min(_s.height,_d.water+_s.riseSpeed*_dt);
                    if(_d.water>=_s.height && !_e.settled){
                        var _tiles=cr_demo_random_tiles(irandom_range(_s.minWhirlpools,_s.maxWhirlpools-1),false);
                        for(var _j=0;_j<array_length(_tiles);_j++)array_push(_e.objects,{px:_tiles[_j].x*10+5,pz:_tiles[_j].z*10+5,time:0,target:undefined,phase:0,destination:[],dead:false});_e.settled=true;
                    }
                    _e.door_timer-=_dt;if(_e.door_timer<=0 && _e.door<array_length(_g.doors)){
                        var _door=_g.doors[_e.door++];if(cr_door_open(_door,false))_door.open=_e.duration;_e.door_timer=.5;
                    }
                    cr_demo_whirlpools(_e,_dt);break;
                case "GravityEvent":
                    _e.spawn_timer-=_dt;if(_e.spawn_timer<=0){
                        var _tiles=cr_demo_random_tiles(irandom_range(_s.minFlippers,_s.maxFlippers-1),true);
                        for(var _j=0;_j<array_length(_tiles);_j++)array_push(_e.objects,{px:_tiles[_j].x*10+5,pz:_tiles[_j].z*10+5,variant:irandom(array_length(_s.flippers)-1),rotation:matrix_build_identity()});
                        _e.spawn_timer=random_range(_s.minRespawnTime,_s.maxRespawnTime);
                    }
                    for(var _j=array_length(_e.objects)-1;_j>=0;_j--){
                        var _o=_e.objects[_j],_hit=false;
                        _o.rotation=matrix_multiply(matrix_build(0,0,0,25*_dt,25*_dt,25*_dt,1,1,1),_o.rotation);
                        if(point_distance(_g.px,_g.pz,_o.px,_o.pz)<3){cr_demo_flip_player();_hit=true;}
                        else for(var _k=0;_k<array_length(_g.npcs);_k++){var _n=_g.npcs[_k];if(!_n.hidden && point_distance(_n.px,_n.pz,_o.px,_o.pz)<2){_n.flipped=!_n.flipped;_hit=true;break;}}
                        if(_hit)array_delete(_e.objects,_j,1);
                    }break;
            }
            if(_e.time>=_e.duration)cr_demo_event_end(_e);
        }
        if(_e.state=="ending"){
            if(_s.name=="FloodEvent"){
                _d.water=max(0,_d.water-_s.riseSpeed*_dt);if(_d.water>0)continue;
                if(audio_is_playing(_e.voice))audio_stop_sound(_e.voice);_e.voice=-1;
            }_e.state="done";
        }
    }
    _d.fog=clamp(_d.fog+(_fog?1:-1)*.25*_dt,0,1);_d.roll=min(_d.roll_target,_d.roll+180*_dt);
}
function cr_demo_whirlpools(_e,_dt) {
    var _g=global.bbcr,_p=_e.spec.pool;
    for(var _i=0;_i<array_length(_e.objects);_i++){
        var _o=_e.objects[_i];_o.time+=_dt;if(_o.dead)continue;
        if(!is_undefined(_o.target)){
            _o.phase+=_dt;var _t=_o.target,_half=4/_p.sinkSpeed;
            if(_o.phase<_half){if(_t==_g)_g.jump_height=-_o.phase*_p.sinkSpeed;}
            else {_t.px=_o.destination[0];_t.pz=_o.destination[1];if(_t==_g)_g.jump_height=-4+(_o.phase-_half)*_p.sinkSpeed;}
            if(_o.phase>=_half*2){if(_t==_g)_g.jump_height=0;_t.in_whirlpool=false;_o.dead=true;}continue;
        }
        if(_o.time<_p.formTime)continue;
        var _targets=[_g];for(var _j=0;_j<array_length(_g.npcs);_j++)if(!_g.npcs[_j].hidden)array_push(_targets,_g.npcs[_j]);
        for(var _j=0;_j<array_length(_targets);_j++){
            var _t=_targets[_j],_dist=point_distance(_t.px,_t.pz,_o.px,_o.pz);if(_dist>=_p.radius || cr_value(_t,"in_whirlpool",false) || !cr_clear_line(_t.px,_t.pz,_o.px,_o.pz))continue;
            var _angle=degtorad(_o.time*_p.rotationSpeed),_x=_o.px+cos(_angle)*_p.centerForceOffset,_z=_o.pz+sin(_angle)*_p.centerForceOffset;
            var _len=max(.001,point_distance(_t.px,_t.pz,_x,_z)),_force=min(_len,(_p.radius-min(_len,_p.radius))/_p.radius*_p.maxForce*_dt);
            cr_move(_t,(_x-_t.px)/_len*_force,(_z-_t.pz)/_len*_force,_t==_g?2:_t.params.collision_radius);
            if(_len<=5){var _tiles=cr_demo_random_tiles(1,false);if(array_length(_tiles)>0){_o.target=_t;_o.destination=[_tiles[0].x*10+5,_tiles[0].z*10+5];_t.in_whirlpool=true;}break;}
        }
    }
}
function cr_demo_move_scale(_actor) {
    if(global.bbcr.style!="demo" || !is_struct(global.bbcr.demo))return 1;
    if(cr_value(_actor,"in_whirlpool",false))return 0;
    return (global.bbcr.demo.flood?.75:1)*(cr_value(_actor,"gum_time",0)>0?_actor.gum_scale:1);
}
function cr_demo_can_touch(_n) {
    return global.bbcr.style!="demo" || cr_value(_n,"flipped",false)==global.bbcr.demo.flipped;
}
