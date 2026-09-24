/// Party/Demo items use the same source ItemObjects as the give menu.
function cr_extra_items_init() {
    global.bbcr.teleporter=undefined;global.bbcr.chalk_clouds=[];global.bbcr.portals=[];
}
function cr_teleporter_begin() {
    var _g=global.bbcr;
    if(_g.style=="party" && _g.world_y>0)cr_party_return_school();
    _g.teleporter={remaining:irandom_range(12,15),interval:.2,timer:.2,count:0};
    cr_rope_end(false);
}
function cr_extra_move_scale() {return is_struct(global.bbcr.teleporter)?0:1;}
function cr_extra_items_step(_dt) {
    var _g=global.bbcr;
    if(is_struct(_g.teleporter)){
        var _tp=_g.teleporter;_tp.timer-=_dt;
        if(_tp.timer<=0){
            var _tiles=global.cr_map.tiles,_pool=[];
            for(var _i=0;_i<array_length(_tiles);_i++){
                var _t=_tiles[_i];if(!global.cr_map.rooms[_t.room].offlimits && !_t.contains_object && !cr_blocked(_t.x*10+5,_t.z*10+5,global.cr_catalog.movement.radius))array_push(_pool,_i);
            }
            if(array_length(_pool)>0){var _t=_tiles[_pool[irandom(array_length(_pool)-1)]];_g.px=_t.x*10+5;_g.pz=_t.z*10+5;cr_sound(global.cr_catalog.effects.teleport_sound);}
            _tp.count++;_tp.remaining--;_tp.interval*=1.1;_tp.timer=_tp.interval;
            if(_tp.remaining<=0)_g.teleporter=undefined;
        }
    }
    var _ps=global.cr_catalog.effects.chalk_particles;
    for(var _i=array_length(_g.chalk_clouds)-1;_i>=0;_i--){
        var _c=_g.chalk_clouds[_i],_elapsed=global.cr_catalog.effects.chalk_time-_c.time;
        _c.time-=_dt;_c.emit+=_ps.rate*max(0,min(_dt,_ps.duration-_elapsed));
        while(_c.emit>=1){
            _c.emit-=1;
            // ChalkCloud uses a scaled box emitter, not its unused cone angle.
            array_push(_c.particles,{px:_c.px+random_range(-.5,.5)*_ps.scale[0],py:5+random_range(-.5,.5)*_ps.scale[1],pz:_c.pz+random_range(-.5,.5)*_ps.scale[2],
                dx:0,dy:0,dz:_ps.speed*_ps.velocity_multiplier,age:0,size:_ps.size*_ps.scale[0]*random_range(_ps.size_range[0],_ps.size_range[1])});
        }
        for(var _j=array_length(_c.particles)-1;_j>=0;_j--){var _p=_c.particles[_j];_p.age+=_dt;_p.px+=_p.dx*_dt;_p.py+=_p.dy*_dt;_p.pz+=_p.dz*_dt;if(_p.age>=_ps.lifetime)array_delete(_c.particles,_j,1);}
        if(_c.time<=0)array_delete(_g.chalk_clouds,_i,1);
    }
}
function cr_chalk_use() {
    var _g=global.bbcr,_x=floor(_g.px/10)*10+5,_z=floor(_g.pz/10)*10+5;
    array_push(_g.chalk_clouds,{px:_x,pz:_z,time:global.cr_catalog.effects.chalk_time,emit:0,particles:[],
        box:{center:[_x,5,_z],half:[5,5,5],axes:[[1,0,0],[0,1,0],[0,0,1]]}});
}
function cr_portal_at(_x,_z) {
    var _p=global.bbcr.portals;
    for(var _i=0;_i<array_length(_p);_i++)if(abs(_p[_i].cx-_x)<.01 && abs(_p[_i].cz-_z)<.01)return _i;
    return -1;
}
function cr_portal_use() {
    var _g=global.bbcr,_dx=sin(cr_view_yaw()),_dz=cos(cr_view_yaw()),_best=global.cr_catalog.movement.reach,_wi=-1;
    for(var _i=0;_i<array_length(global.cr_walls);_i++){
        var _w=global.cr_walls[_i];if(array_length(_w)>4 && _w[4]>=0)continue;
        var _t=cr_ray_segment(_g.px,_g.pz,_dx,_dz,_w);if(_t<_best){_best=_t;_wi=_i;}
    }
    if(_wi<0)return false;
    // Physical furniture and door colliders still block the source wall ray.
    var _hit=cr_interaction_target();if(_hit.kind!="" && _hit.distance<_best-.001)return false;
    for(var _i=0;_i<array_length(global.cr_map.colliders);_i++)if(cr_ray_box(global.cr_map.colliders[_i],_g.px,5,_g.pz,_dx,_dz)<_best-.001)return false;
    var _w=global.cr_walls[_wi],_cx=(_w[0]+_w[2])/2,_cz=(_w[1]+_w[3])/2,_len=point_distance(_w[0],_w[1],_w[2],_w[3]);
    if(_len<9.9 || cr_portal_at(_cx,_cz)>=0)return false;
    var _tx=(_w[2]-_w[0])/_len,_tz=(_w[3]-_w[1])/_len,_nx=-_tz,_nz=_tx;
    var _a=cr_tile(_cx+_nx*5,_cz+_nz*5),_b=cr_tile(_cx-_nx*5,_cz-_nz*5);
    if(is_undefined(_a) || is_undefined(_b) || _a.contains_object || _b.contains_object){cr_sound(global.cr_catalog.effects.portal_no);return false;}
    array_push(_g.portals,{cx:_cx,cz:_cz});cr_sound(global.cr_catalog.effects.portal_yes);
    cr_rebuild_geometry();return true;
}
function cr_rebuild_geometry() {
    for(var _i=0;_i<array_length(global.cr_batches);_i++)vertex_delete_buffer(global.cr_batches[_i].vb);global.cr_batches=[];
    if(global.cr_nav>=0)mp_grid_destroy(global.cr_nav);global.cr_nav=-1;
    cr_build_world();cr_build_navigation();
    for(var _i=0;_i<array_length(global.bbcr.npcs);_i++){path_clear_points(global.bbcr.npcs[_i].path);global.bbcr.npcs[_i].route_timer=0;}
}
function cr_extra_items_draw() {
    var _g=global.bbcr,_particles=[];
    for(var _i=0;_i<array_length(_g.chalk_clouds);_i++){
        var _c=_g.chalk_clouds[_i];
        for(var _j=0;_j<array_length(_c.particles);_j++)array_push(_particles,_c.particles[_j]);
    }
    array_sort(_particles,function(_a,_b){return sign(point_distance(global.bbcr.px,global.bbcr.pz,_b.px,_b.pz)-point_distance(global.bbcr.px,global.bbcr.pz,_a.px,_a.pz));});
    gpu_set_zwriteenable(false);gpu_set_alphatestenable(false);gpu_set_cullmode(cull_noculling);
    for(var _j=0;_j<array_length(_particles);_j++){
            var _p=_particles[_j],_ps=global.cr_catalog.effects.chalk_particles,_t=_p.age/_ps.lifetime,_fade=0;
            for(var _k=1;_k<array_length(_ps.alpha);_k++)if(_t<=_ps.alpha[_k][0]){var _a=_ps.alpha[_k-1],_b=_ps.alpha[_k];_fade=lerp(_a[1],_b[1],(_t-_a[0])/(_b[0]-_a[0]));break;}
            cr_billboard(global.cr_catalog.effects.chalk_texture,_p.px,_p.py,_p.pz,_p.size,_p.size,.5,c_white,undefined,_fade);
    }
    gpu_set_zwriteenable(true);gpu_set_alphatestenable(true);
}
