function cr_geometry_draw(_geometry,_texture=undefined,_color=c_white) {
    for(var _i=0;_i<array_length(_geometry.batches);_i++){var _b=_geometry.batches[_i];cr_draw_mesh(_b.vertices,is_undefined(_texture)?_b.texture:_texture,_color);}
    for(var _i=0;_i<array_length(_geometry.decorations);_i++){
        var _s=_geometry.decorations[_i];
        if(variable_struct_exists(_s,"billboard_deform"))cr_billboard_deformed(_s);
        else cr_billboard(_s.sprite,_s.p[0],_s.p[1],_s.p[2],_s.w,_s.h,_s.pivot.y);
    }
}
function cr_world_glyph(_descriptor,_text) {
    var _f=global.cr_ui_data.fonts[$ _descriptor.font],_g=cr_ui_glyph(_f,_text),_r=_g.rect,_spr=cr_sprite(_f.file);
    var _scale=_descriptor.size/_f.face.m_PointSize*_f.face.m_Scale*_g.scale*.1,_w=_g.size[0]*_scale,_h=_g.size[1]*_scale;
    var _p=_descriptor.position,_right=_descriptor.right,_up=_descriptor.up,_vertices=[];
    for(var _i=0;_i<4;_i++){var _x=(_i==1 || _i==2)?.5:-.5,_y=_i>=2?.5:-.5;
        array_push(_vertices,[_p[0]+_right[0]*_x*_w+_up[0]*_y*_h,_p[1]+_right[1]*_x*_w+_up[1]*_y*_h,_p[2]+_right[2]*_x*_w+_up[2]*_y*_h]);}
    var _uv=sprite_get_uvs(_spr,0),_u0=lerp(_uv[0],_uv[2],_r[0]/sprite_get_width(_spr)),_u1=lerp(_uv[0],_uv[2],(_r[0]+_r[2])/sprite_get_width(_spr));
    var _v0=lerp(_uv[1],_uv[3],_r[1]/sprite_get_height(_spr)),_v1=lerp(_uv[1],_uv[3],(_r[1]+_r[3])/sprite_get_height(_spr));
    var _vb=global.cr_dynamic,_order=[0,2,1,0,3,2],_color=make_color_rgb(_descriptor.color[0],_descriptor.color[1],_descriptor.color[2]);vertex_begin(_vb,global.cr_format);
    for(var _i=0;_i<6;_i++){var _j=_order[_i],_v=_vertices[_j];cr_vertex(_vb,_v[0],_v[1],_v[2],(_j==1 || _j==2)?_u1:_u0,_j>=2?_v0:_v1,_color);}
    vertex_end(_vb);vertex_submit(_vb,pr_trianglelist,sprite_get_texture(_spr,0));
}
function cr_demo_geometry_at(_geometry,_x,_y,_z,_yaw=0) {
    var _old=matrix_get(matrix_world);matrix_set(matrix_world,matrix_build(_x,_y,_z,0,_yaw,0,1,1,1));cr_geometry_draw(_geometry);matrix_set(matrix_world,_old);
}
function cr_demo_chalk_draw(_n) {
    var _v=_n.actor_state=="form"?_n.params.chalk_visual:_n.params.flying_visual;
    var _old=matrix_get(matrix_world);matrix_set(matrix_world,matrix_build(0,_n.height-5,0,0,0,0,1,1,1));cr_actor_draw(_v,_n.sprite,_n.px,_n.pz,0,cr_value(_n,"flipped",false));matrix_set(matrix_world,_old);
}
function cr_demo_world_draw() {
    var _g=global.bbcr,_d=_g.demo;if(!is_struct(_d))return;
    gpu_set_cullmode(cull_noculling);
    for(var _i=0;_i<array_length(_d.boards);_i++){var _b=_d.boards[_i];cr_demo_geometry_at(_g.npcs[_b.npc].params.board,_b.x-sin(_b.dir*pi/2)*.015,0,_b.z-cos(_b.dir*pi/2)*.015,_b.dir*90);}
    for(var _i=0;_i<array_length(_d.gum);_i++){var _s=_d.gum[_i];if(is_undefined(_s.target))cr_demo_geometry_at(_s.owner.params.gum.flying,_s.px,5,_s.pz);}
    for(var _i=0;_i<array_length(_g.npcs);_i++){
        var _n=_g.npcs[_i];if(_n.name!="Cumulo" || _n.actor_state!="blow" || _n.optional_pending)continue;
        cr_demo_wind_draw(_n);
    }
    for(var _i=0;_i<array_length(_d.events);_i++){
        var _e=_d.events[_i],_s=_e.spec;if(_e.state!="active" && _e.state!="ending")continue;
        if(_s.name=="FloodEvent" && _d.water>0){
            cr_demo_geometry_at(_s.water,(_d.event_clock*_s.speed.x) mod _s.limit.x,_d.water,(_d.event_clock*_s.speed.z) mod _s.limit.y);
            for(var _j=0;_j<array_length(_e.objects);_j++){var _o=_e.objects[_j];if(!_o.dead)cr_demo_geometry_at(_s.whirlpool,_o.px,0,_o.pz,_o.time*_s.pool.rotationSpeed);}
        }
        if(_s.name=="GravityEvent")for(var _j=0;_j<array_length(_e.objects);_j++){
            var _o=_e.objects[_j],_old=matrix_get(matrix_world);
            var _rot=matrix_multiply(_o.rotation,matrix_build(_o.px,5,_o.pz,0,0,0,1,1,1));matrix_set(matrix_world,_rot);
            cr_geometry_draw(_s.flippers[_o.variant]);matrix_set(matrix_world,_old);
        }
    }
    gpu_set_cullmode(cull_counterclockwise);
}
function cr_quat_rotate(_p,_q) {
    var _x=_p[0],_y=_p[1],_z=_p[2],_tx=2*(_q.y*_z-_q.z*_y),_ty=2*(_q.z*_x-_q.x*_z),_tz=2*(_q.x*_y-_q.y*_x);
    return [_x+_q.w*_tx+_q.y*_tz-_q.z*_ty,_y+_q.w*_ty+_q.z*_tx-_q.x*_tz,_z+_q.w*_tz+_q.x*_ty-_q.y*_tx];
}
function cr_demo_wind_draw(_n) {
    var _h=_n.hall,_w=_n.params.wind,_length=point_distance(_h[0],_h[1],_h[2],_h[3])+10;
    var _yaw=arctan2(_h[2]-_h[0],_h[3]-_h[1]),_cx=(_h[0]+_h[2])/2,_cz=(_h[1]+_h[3])/2;
    var _vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
    for(var _i=0;_i<array_length(_w.surfaces);_i++){
        var _s=_w.surfaces[_i];for(var _j=0;_j<array_length(_s.vertices);_j++){
            var _v=_s.vertices[_j],_p=cr_quat_rotate([_v[0]*10,_v[1]*_length,_v[2]],_s.rotation);
            _p[0]+=_s.position[0];_p[1]+=_s.position[1];_p[2]+=_s.position[2];
            cr_vertex(_vb,_cx+_p[0]*cos(_yaw)+_p[2]*sin(_yaw),5+_p[1],_cz-_p[0]*sin(_yaw)+_p[2]*cos(_yaw),_v[3],1-(1-_v[4])*_length/10-global.bbcr.time*_w.scroll.y);
        }
    }vertex_end(_vb);cr_submit(_vb,_w.texture);
}
function cr_demo_gui_draw() {
    var _d=global.bbcr.demo;if(!is_struct(_d))return;
    if(global.bbcr.gum_time>0)for(var _i=0;_i<array_length(_d.gum);_i++)if(_d.gum[_i].target==global.bbcr){cr_image(_d.gum[_i].owner.params.gum.overlay,0,0,640,480);break;}
}
