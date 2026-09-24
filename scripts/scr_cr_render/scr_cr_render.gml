function cr_render_init() {
    vertex_format_begin();vertex_format_add_position_3d();vertex_format_add_colour();vertex_format_add_texcoord();global.cr_format=vertex_format_end();
    global.cr_dynamic=vertex_create_buffer();global.cr_batches=[];global.cr_walls=[];global.cr_nav=-1;global.cr_world_surface=-1;
    global.cr_load_transition={surface:-1,previous:-1,stage:16,timer:0,interval:.01666667};
    global.cr_light_surface=-1;
}
function cr_world_cleanup() {
    if(!variable_global_exists("cr_batches"))return;
    for(var _i=0;_i<array_length(global.cr_batches);_i++)vertex_delete_buffer(global.cr_batches[_i].vb);global.cr_batches=[];
    if(global.cr_nav>=0){mp_grid_destroy(global.cr_nav);global.cr_nav=-1;}
    if(variable_struct_exists(global.bbcr,"npcs")){
        for(var _i=0;_i<array_length(global.bbcr.npcs);_i++){
            var _n=global.bbcr.npcs[_i];if(path_exists(_n.path))path_delete(_n.path);_n.path=-1;
        }
        global.bbcr.npcs=[];
    }
    global.bbcr.loaded=false;
    if(surface_exists(global.cr_world_surface))surface_free(global.cr_world_surface);global.cr_world_surface=-1;
    if(surface_exists(global.cr_light_surface))surface_free(global.cr_light_surface);global.cr_light_surface=-1;
    if(variable_global_exists("cr_null_capture_surface") && surface_exists(global.cr_null_capture_surface))surface_free(global.cr_null_capture_surface);global.cr_null_capture_surface=-1;
    cr_ui_dispose(global.cr_load_transition);global.cr_load_transition.stage=16;
}
function cr_vertex(_vb,_x,_y,_z,_u,_v,_color=c_white,_alpha=1) {
    vertex_position_3d(_vb,_x,_y,_z);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u,_v);
}
function cr_quad(_vb,_a,_b,_c,_d,_color=c_white) {
    cr_vertex(_vb,_a[0],_a[1],_a[2],0,1,_color);cr_vertex(_vb,_c[0],_c[1],_c[2],1,0,_color);cr_vertex(_vb,_b[0],_b[1],_b[2],1,1,_color);
    cr_vertex(_vb,_a[0],_a[1],_a[2],0,1,_color);cr_vertex(_vb,_d[0],_d[1],_d[2],0,0,_color);cr_vertex(_vb,_c[0],_c[1],_c[2],1,0,_color);
}
function cr_batch(_texture) {
    for(var _i=0;_i<array_length(global.cr_batches);_i++)if(global.cr_batches[_i].texture==_texture)return global.cr_batches[_i].vb;
    var _vb=vertex_create_buffer();vertex_begin(_vb,global.cr_format);array_push(global.cr_batches,{texture:_texture,vb:_vb});return _vb;
}
function cr_wall_quad(_vb,_ax,_az,_bx,_bz,_bottom=0,_top=10) {
    cr_quad(_vb,[_ax,_bottom,_az],[_bx,_bottom,_bz],[_bx,_top,_bz],[_ax,_top,_az]);
}
function cr_build_spatial_index() {
    var _m=global.cr_map,_count=_m.size.x*_m.size.z;
    global.cr_wall_grid=array_create(_count);global.cr_furniture_grid=array_create(_count);
    for(var _i=0;_i<_count;_i++){global.cr_wall_grid[_i]=[];global.cr_furniture_grid[_i]=[];}
    for(var _i=0;_i<array_length(global.cr_walls);_i++){
        var _w=global.cr_walls[_i],_x0=max(0,floor(min(_w[0],_w[2])/10)-1),_x1=min(_m.size.x-1,floor(max(_w[0],_w[2])/10)+1);
        var _z0=max(0,floor(min(_w[1],_w[3])/10)-1),_z1=min(_m.size.z-1,floor(max(_w[1],_w[3])/10)+1);
        for(var _z=_z0;_z<=_z1;_z++)for(var _x=_x0;_x<=_x1;_x++)array_push(global.cr_wall_grid[_x+_z*_m.size.x],_i);
    }
    for(var _i=0;_i<array_length(_m.colliders);_i++){
        var _b=_m.colliders[_i].bounds,_x0=max(0,floor(_b[0]/10)-1),_x1=min(_m.size.x-1,floor(_b[3]/10)+1);
        var _z0=max(0,floor(_b[2]/10)-1),_z1=min(_m.size.z-1,floor(_b[5]/10)+1);
        for(var _z=_z0;_z<=_z1;_z++)for(var _x=_x0;_x<=_x1;_x++)array_push(global.cr_furniture_grid[_x+_z*_m.size.x],_i);
    }
}
function cr_build_world() {
    global.cr_walls=[];var _m=global.cr_map,_g=global.bbcr,_dirs=[[0,1],[1,0],[0,-1],[-1,0]];
    for(var _i=0;_i<array_length(_m.tiles);_i++){
        var _t=_m.tiles[_i],_r=_m.rooms[_t.room],_x=_t.x*10,_z=_t.z*10;
        var _lift_tile=_g.style=="party" && _m.manager=="ClassicPartyManager" && _t.x==13 && _t.z==35;
        if(!_lift_tile)cr_quad(cr_batch(_r.floor),[_x,0,_z],[_x+10,0,_z],[_x+10,0,_z+10],[_x,0,_z+10]);
        if(string_pos("Transparent",_r.ceiling)==0)cr_quad(cr_batch(_r.ceiling),[_x,10,_z+10],[_x+10,10,_z+10],[_x+10,10,_z],[_x,10,_z]);
        for(var _dir=0;_dir<4;_dir++){
            var _dx=_dirs[_dir][0],_dz=_dirs[_dir][1],_cx=_x+5+_dx*5,_cz=_z+5+_dz*5,_tx=_dz,_tz=-_dx;
            var _door=undefined;
            for(var _j=0;_j<array_length(_g.doors);_j++){var _d=_g.doors[_j];if(abs(_d.cx-_cx)<.01 && abs(_d.cz-_cz)<.01){_door=_d;break;}}
            if(!is_undefined(_door)){
                for(var _f=0;_f<array_length(_door.frame);_f++)array_push(global.cr_walls,_door.frame[_f]);
                continue;
            }
            if((_t.walls & (1<<_dir))==0)continue;
            if(cr_portal_at(_cx,_cz)>=0){
                cr_wall_quad(cr_batch(_r.portal),_cx-_tx*5-_dx*.002,_cz-_tz*5-_dz*.002,_cx+_tx*5-_dx*.002,_cz+_tz*5-_dz*.002);
                array_push(global.cr_walls,[_cx-_tx*5,_cz-_tz*5,_cx-_tx*3,_cz-_tz*3,-1]);
                array_push(global.cr_walls,[_cx+_tx*3,_cz+_tz*3,_cx+_tx*5,_cz+_tz*5,-1]);continue;
            }
            var _texture=_r.wall,_window=-1;
            for(var _j=0;_j<array_length(_m.windows);_j++){
                var _win=_m.windows[_j],_wd=_dirs[_win.direction],_wx=_win.position.x*10+5+_wd[0]*5,_wz=_win.position.z*10+5+_wd[1]*5;
                if(abs(_wx-_cx)<.01 && abs(_wz-_cz)<.01){_window=_j;break;}
            }
            if(_window<0)cr_wall_quad(cr_batch(_texture),_cx-_tx*5-_dx*.002,_cz-_tz*5-_dz*.002,_cx+_tx*5-_dx*.002,_cz+_tz*5-_dz*.002);
            array_push(global.cr_walls,[_cx-_tx*5,_cz-_tz*5,_cx+_tx*5,_cz+_tz*5,_window]);
        }
    }
    for(var _i=0;_i<array_length(_m.posters);_i++){
        var _p=_m.posters[_i];if(_p.texture=="")continue;var _d=_dirs[_p.dir],_cx=_p.x*10+5+_d[0]*4.97,_cz=_p.z*10+5+_d[1]*4.97;
        if(cr_portal_at(_p.x*10+5+_d[0]*5,_p.z*10+5+_d[1]*5)>=0)continue;
        cr_wall_quad(cr_batch(_p.texture),_cx-_d[1]*5,_cz+_d[0]*5,_cx+_d[1]*5,_cz-_d[0]*5);
    }
    for(var _i=0;_i<array_length(_m.batches);_i++){
        var _b=_m.batches[_i],_vb=cr_batch(_b.texture),_v=_b.vertices;
        for(var _j=0;_j<array_length(_v);_j+=5)cr_vertex(_vb,_v[_j],_v[_j+1],_v[_j+2],_v[_j+3],_v[_j+4]);
    }
    for(var _i=0;_i<array_length(global.cr_batches);_i++){vertex_end(global.cr_batches[_i].vb);vertex_freeze(global.cr_batches[_i].vb);cr_sprite(global.cr_batches[_i].texture);}
    cr_build_spatial_index();
}
function cr_submit(_vb,_key,_sprite=false,_cutoff=.5) {
    var _spr=cr_sprite(_key);if(_spr<0){vertex_submit(_vb,pr_trianglelist,-1);return;}
    var _uv=sprite_get_uvs(_spr,0);shader_set(shd_cr_world);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_sprite"),_sprite?1:0);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_rect"),_uv[0],_uv[1],_uv[2],_uv[3]);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_texel"),1/sprite_get_width(_spr),1/sprite_get_height(_spr));
    var _immune=cr_value(global.bbcr,"render_null_face",false);
    var _lit=!_immune && (global.bbcr.exit_fx.active || global.bbcr.lightsout) && surface_exists(global.cr_light_surface);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_lit"),_lit?1:0);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_cutoff"),_cutoff);
    var _null=global.bbcr.null_mode,_warp=is_struct(_null)?_null.glitch:0,_phase=is_struct(_null)?cr_value(_null,"warp_phase","beat"):"beat";
    var _seed=is_struct(_null)?_null.warp_seed:0,_color_glitch=is_struct(_null)?cr_value(_null,"color_glitch",0):0;
    var _route=global.bbcr.secret_route,_final=is_struct(_route) && _route.manager=="ClassicFinaleManager",_personal=_final && cr_value(global.bbcr,"render_final_null",false);
    if(_final){_warp=_route.visual.warp;_phase="finale";_seed=_route.visual.seed;_color_glitch=_route.visual.world_color;}
    if(_personal)_color_glitch=_route.visual.color_on?_route.visual.color:0;
    if(global.bbcr.dead)_warp=0;
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_warp"),_immune?0:cr_null_visual_warp(_warp,_phase));
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_warp_seed"),_seed);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_color_seed"),_seed);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_color_glitch"),_immune || global.bbcr.dead?0:_color_glitch);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_personal"),_personal?1:0);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_tiling"),_personal?_route.visual.tiling[0]:1,_personal?_route.visual.tiling[1]:1);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_offset"),_personal?_route.visual.uv_offset[0]:0,_personal?_route.visual.uv_offset[1]:0);
    var _demo=global.bbcr.style=="demo" && is_struct(global.bbcr.demo),_fog=_demo?global.bbcr.demo.fog:0;
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_fog"),_fog);
    shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_camera"),global.bbcr.px,global.bbcr.pz);
    if(_demo){var _fc=global.bbcr.demo.fog_color;shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_fog_color"),color_get_red(_fc)/255,color_get_green(_fc)/255,color_get_blue(_fc)/255);}
    if(_lit){
        var _sampler=shader_get_sampler_index(shd_cr_world,"u_lightmap");texture_set_stage(_sampler,surface_get_texture(global.cr_light_surface));gpu_set_texfilter_ext(_sampler,false);
        shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_mapsize"),global.cr_map.size.x,global.cr_map.size.z);
        shader_set_uniform_f(shader_get_uniform(shd_cr_world,"u_camera"),global.bbcr.px,global.bbcr.pz);
    }
    vertex_submit(_vb,pr_trianglelist,sprite_get_texture(_spr,0));shader_reset();
}
function cr_billboard(_key,_x,_y,_z,_width,_height,_pivot=.5,_color=c_white,_up=undefined,_alpha=1) {
    var _spr=cr_sprite(_key);if(_spr<0)return;
    var _yaw=cr_value(global.bbcr,"billboard_yaw_override",cr_view_yaw()),_dx=cos(_yaw)*_width/2,_dz=-sin(_yaw)*_width/2;
    var _uv=sprite_get_uvs(_spr,0),_vb=global.cr_dynamic;
    var _bot=_y-_height*_pivot,_top=_bot+_height;
    vertex_begin(_vb,global.cr_format);
    if(!is_undefined(_up)){
        var _fx=sin(_yaw),_fz=cos(_yaw),_rx=_up[1]*_fz,_ry=_up[2]*_fx-_up[0]*_fz,_rz=-_up[1]*_fx;
        var _rl=sqrt(_rx*_rx+_ry*_ry+_rz*_rz);_rx/=_rl;_ry/=_rl;_rz/=_rl;
        var _ux=_fz*_ry*-1,_uy=_fz*_rx-_fx*_rz,_uz=_fx*_ry,_low=-_height*_pivot,_high=_low+_height;
        var _a=[_x-_rx*_width/2+_ux*_low,_y-_ry*_width/2+_uy*_low,_z-_rz*_width/2+_uz*_low];
        var _b=[_x+_rx*_width/2+_ux*_low,_y+_ry*_width/2+_uy*_low,_z+_rz*_width/2+_uz*_low];
        var _c=[_x+_rx*_width/2+_ux*_high,_y+_ry*_width/2+_uy*_high,_z+_rz*_width/2+_uz*_high];
        var _d=[_x-_rx*_width/2+_ux*_high,_y-_ry*_width/2+_uy*_high,_z-_rz*_width/2+_uz*_high];
        cr_vertex(_vb,_a[0],_a[1],_a[2],_uv[0],_uv[3],_color);cr_vertex(_vb,_b[0],_b[1],_b[2],_uv[2],_uv[3],_color);cr_vertex(_vb,_c[0],_c[1],_c[2],_uv[2],_uv[1],_color);
        cr_vertex(_vb,_a[0],_a[1],_a[2],_uv[0],_uv[3],_color);cr_vertex(_vb,_c[0],_c[1],_c[2],_uv[2],_uv[1],_color);cr_vertex(_vb,_d[0],_d[1],_d[2],_uv[0],_uv[1],_color);
        vertex_end(_vb);cr_submit(_vb,_key,true);return;
    }
    cr_vertex(_vb,_x-_dx,_bot,_z-_dz,_uv[0],_uv[3],_color,_alpha);cr_vertex(_vb,_x+_dx,_bot,_z+_dz,_uv[2],_uv[3],_color,_alpha);cr_vertex(_vb,_x+_dx,_top,_z+_dz,_uv[2],_uv[1],_color,_alpha);
    cr_vertex(_vb,_x-_dx,_bot,_z-_dz,_uv[0],_uv[3],_color,_alpha);cr_vertex(_vb,_x+_dx,_top,_z+_dz,_uv[2],_uv[1],_color,_alpha);cr_vertex(_vb,_x-_dx,_top,_z-_dz,_uv[0],_uv[1],_color,_alpha);
    vertex_end(_vb);gpu_set_cullmode(cull_noculling);cr_submit(_vb,_key,true,_alpha<1?.001:.5);gpu_set_cullmode(cull_counterclockwise);
}
function cr_deform_vector(_columns,_v) {
    return [_columns[0][0]*_v[0]+_columns[1][0]*_v[1]+_columns[2][0]*_v[2],
        _columns[0][1]*_v[0]+_columns[1][1]*_v[1]+_columns[2][1]*_v[2],
        _columns[0][2]*_v[0]+_columns[1][2]*_v[1]+_columns[2][2]*_v[2]];
}
function cr_billboard_deformed(_entry) {
    var _key=_entry.sprite,_spr=cr_sprite(_key);if(_spr<0)return;
    var _d=_entry.billboard_deform,_up=_d.parent_up,_yaw=cr_value(global.bbcr,"billboard_yaw_override",cr_view_yaw()),_forward=[sin(_yaw),0,cos(_yaw)];
    var _right=[_up[1]*_forward[2]-_up[2]*_forward[1],_up[2]*_forward[0]-_up[0]*_forward[2],_up[0]*_forward[1]-_up[1]*_forward[0]];
    var _length=sqrt(sqr(_right[0])+sqr(_right[1])+sqr(_right[2]));if(_length<=.0001)return;
    _right=[_right[0]/_length,_right[1]/_length,_right[2]/_length];
    var _vertical=[_forward[1]*_right[2]-_forward[2]*_right[1],_forward[2]*_right[0]-_forward[0]*_right[2],_forward[0]*_right[1]-_forward[1]*_right[0]];
    _right=cr_deform_vector(_d.columns,_right);_vertical=cr_deform_vector(_d.columns,_vertical);
    var _p=_entry.p,_pivot=_entry.pivot,_x0=-_d.size[0]*_pivot.x,_x1=_d.size[0]*(1-_pivot.x),_y0=-_d.size[1]*_pivot.y,_y1=_d.size[1]*(1-_pivot.y);
    var _a=[_p[0]+_right[0]*_x0+_vertical[0]*_y0,_p[1]+_right[1]*_x0+_vertical[1]*_y0,_p[2]+_right[2]*_x0+_vertical[2]*_y0];
    var _b=[_p[0]+_right[0]*_x1+_vertical[0]*_y0,_p[1]+_right[1]*_x1+_vertical[1]*_y0,_p[2]+_right[2]*_x1+_vertical[2]*_y0];
    var _c=[_p[0]+_right[0]*_x1+_vertical[0]*_y1,_p[1]+_right[1]*_x1+_vertical[1]*_y1,_p[2]+_right[2]*_x1+_vertical[2]*_y1];
    var _e=[_p[0]+_right[0]*_x0+_vertical[0]*_y1,_p[1]+_right[1]*_x0+_vertical[1]*_y1,_p[2]+_right[2]*_x0+_vertical[2]*_y1];
    var _uv=sprite_get_uvs(_spr,0),_color=cr_exit_color_at(_p[0],_p[2]),_vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
    cr_vertex(_vb,_a[0],_a[1],_a[2],_uv[0],_uv[3],_color);cr_vertex(_vb,_b[0],_b[1],_b[2],_uv[2],_uv[3],_color);cr_vertex(_vb,_c[0],_c[1],_c[2],_uv[2],_uv[1],_color);
    cr_vertex(_vb,_a[0],_a[1],_a[2],_uv[0],_uv[3],_color);cr_vertex(_vb,_c[0],_c[1],_c[2],_uv[2],_uv[1],_color);cr_vertex(_vb,_e[0],_e[1],_e[2],_uv[0],_uv[1],_color);
    vertex_end(_vb);cr_submit(_vb,_key,true);
}
function cr_door_side_index(_door,_x,_z) {
    var _yaw=degtorad(_door.dir*90),_nx=sin(_yaw),_nz=cos(_yaw);
    return ((_x-_door.cx)*_nx+(_z-_door.cz)*_nz)>0?1:0;
}
function bbcr_draw_game() {
    var _g=global.bbcr;if(!_g.loaded){draw_clear(c_white);return;}
    if(_g.dead && _g.ending.phase>=1){draw_clear(c_black);return;}
    cr_exit_light_surface();
    var _world=matrix_get(matrix_world),_view=matrix_get(matrix_view),_projection=matrix_get(matrix_projection);
    // A full-target world surface keeps the 3D projection independent of the
    // Runner's application-surface/room-viewport scaling. Fit it once below.
    // Integer dimensions must also have exactly 4:3 aspect, so the final fit
    // uses the same scale on both axes even at odd client sizes.
    var _fit=cr_game_viewport(),_height=max(3,round(480*_fit[2]/3)*3),_width=_height/3*4;
    if(!surface_exists(global.cr_world_surface))global.cr_world_surface=surface_create(_width,_height);
    else if(surface_get_width(global.cr_world_surface)!=_width || surface_get_height(global.cr_world_surface)!=_height)surface_resize(global.cr_world_surface,_width,_height);
    surface_set_target(global.cr_world_surface);
    var _yaw=cr_view_yaw();
    var _sky=_g.dead || _g.lightsout?c_black:(_g.exit_fx.active && !is_struct(_g.null_mode) && !is_struct(_g.secret_route)?c_red:make_color_rgb(125,180,230));
    if(is_struct(_g.demo))_sky=merge_color(_sky,_g.demo.fog_color,_g.demo.fog);
    draw_clear(_sky);draw_clear_depth(1);
    matrix_set(matrix_world,matrix_build(0,cr_value(_g,"world_y",0),0,0,0,0,1,1,1));
    matrix_set(matrix_view,_g.dead?cr_camera_view(_g.ending.x,_g.ending.z,_g.ending.yaw,1):cr_camera_view(_g.px,_g.pz,_yaw,_g.jump_height));
    var _camera=global.cr_catalog.camera;
    matrix_set(matrix_projection,matrix_build_projection_perspective_fov(_camera.vertical_fov,_width/_height,_camera.near,_g.dead?_g.ending.far:_camera.far));
    gpu_set_ztestenable(true);gpu_set_zwriteenable(true);gpu_set_cullmode(cull_counterclockwise);gpu_set_alphatestenable(true);gpu_set_alphatestref(128);
    gpu_set_texrepeat(true);gpu_set_texfilter(true);gpu_set_tex_mip_filter(mip_on);
    for(var _i=0;_i<array_length(global.cr_batches);_i++)cr_submit(global.cr_batches[_i].vb,global.cr_batches[_i].texture);
    // Door/window overlays and sprite assets use point filtering and no mipmaps
    // in the source TextureImporters; do not inherit the floor mip state.
    gpu_set_texrepeat(false);gpu_set_texfilter(false);gpu_set_tex_mip_filter(mip_off);
    if(_g.style=="party" && is_struct(_g.party)){
        gpu_set_cullmode(cull_noculling);
        var _shells=_g.party.data.shells;
        for(var _i=0;_i<array_length(_shells);_i++)for(var _j=0;_j<array_length(_shells[_i].batches);_j++){
            var _b=_shells[_i].batches[_j];cr_draw_mesh_y(_b.vertices,_b.texture,-_g.world_y);
        }
        gpu_set_cullmode(cull_counterclockwise);
    }
    for(var _i=0;_i<array_length(global.cr_map.facilities);_i++){
        var _f=global.cr_map.facilities[_i];if(!variable_struct_exists(_f,"batches"))continue;
        for(var _j=0;_j<array_length(_f.batches);_j++){
            var _b=_f.batches[_j],_tex=_b.texture;if(_f.uses<=0 && _tex==_f.stock_texture)_tex=_f.sold_texture;
            cr_draw_mesh(_b.vertices,_tex);
        }
    }
    if(_g.style=="party" && is_struct(_g.party) && _g.world_y==0){
        var _party=_g.party,_data=_party.data;
        for(var _i=0;_i<array_length(_data.covers.batches);_i++){var _b=_data.covers.batches[_i];cr_draw_mesh(_b.vertices,_b.texture);}
        for(var _i=0;_i<array_length(_data.elevator.batches);_i++){var _b=_data.elevator.batches[_i];cr_draw_mesh_y(_b.vertices,_b.texture,_party.elevator_y);}
        if(_party.phase!="school" && _party.phase!="returned")for(var _i=0;_i<array_length(_data.surprise.decorations);_i++){
            var _s=_data.surprise.decorations[_i];cr_billboard(_s.sprite,_s.p[0],_s.p[1],_s.p[2],_s.w,_s.h,_s.pivot.y);
        }
        if(_party.phase=="candle")for(var _i=0;_i<array_length(_data.candle.decorations);_i++){
            var _s=_data.candle.decorations[_i];cr_billboard(_s.sprite,_s.p[0],_s.p[1],_s.p[2],_s.w,_s.h,_s.pivot.y);
        }
    }
    if(_g.style=="party" && is_struct(_g.party) && _g.world_y>0){
        var _party=_g.party,_data=_party.data;
        for(var _i=0;_i<array_length(_data.elevator.batches);_i++){var _b=_data.elevator.batches[_i];cr_draw_mesh_y(_b.vertices,_b.texture,-_g.world_y);}
        for(var _i=0;_i<array_length(_data.surprise.decorations);_i++){
            var _s=_data.surprise.decorations[_i];cr_billboard(_s.sprite,_s.p[0],_s.p[1]+5,_s.p[2],_s.w,_s.h,_s.pivot.y);
        }
    }
    if(_g.style=="demo" && is_struct(_g.demo))for(var _i=0;_i<array_length(_g.books);_i++){
        var _book=_g.books[_i],_machine=_book.machine;
        for(var _j=0;_j<array_length(_machine.batches);_j++){
            var _b=_machine.batches[_j],_texture=_b.texture;
            if(_texture==_machine.default_texture && _book.state=="correct")_texture=_machine.correct_texture;
            if(_texture==_machine.default_texture && _book.state=="wrong")_texture=_machine.incorrect_texture;
            cr_draw_mesh(_b.vertices,_texture);
        }
        cr_demo_machine_text(_book);
        if(_book.bonus)cr_geometry_draw(_machine.bonus_sign);
    }
    for(var _i=0;_i<array_length(_g.exits);_i++){
        var _e=_g.exits[_i];if(_e.state<=0)continue;var _batches=_e.walls[_e.state-1];
        for(var _j=0;_j<array_length(_batches);_j++)cr_draw_mesh(_batches[_j].vertices,_batches[_j].texture);
    }
    for(var _i=0;_i<array_length(global.cr_map.windows);_i++){
        var _w=global.cr_map.windows[_i],_yaw=degtorad(_w.direction*90);
        var _side=_w.sides[((_g.px-_w.cx)*sin(_yaw)+(_g.pz-_w.cz)*cos(_yaw))>0?1:0];
        cr_draw_mesh(_side.vertices,_w.broken?_side.open:_side.closed);
    }
    for(var _i=0;_i<array_length(_g.doors);_i++){
        var _d=_g.doors[_i],_side=_d.sides[cr_door_side_index(_d,_g.px,_g.pz)];
        var _key=_d.open>0?_side.open:(_d.swing && _d.lock>0?_side.locked:_side.closed);
        var _vb=global.cr_dynamic,_v=_side.vertices;vertex_begin(_vb,global.cr_format);
        for(var _j=0;_j<array_length(_v);_j+=5)cr_vertex(_vb,_v[_j],_v[_j+1],_v[_j+2],_v[_j+3],_v[_j+4]);
        vertex_end(_vb);cr_submit(_vb,_key);
    }
    gpu_set_cullmode(cull_noculling);
    if(_g.style=="party" && variable_struct_exists(global.cr_map,"puzzle")){
        var _p=global.cr_map.puzzle;
        if(!_g.party.puzzle_open)cr_geometry_draw(_p.wall);
        for(var _i=0;_i<4;_i++){
            var _b=_p.buttons[_i];cr_geometry_draw(_b.geometry,_g.party.puzzle_timers[_i]>0?_b.on_texture:_b.off_texture,make_color_rgb(_b.color[0],_b.color[1],_b.color[2]));cr_world_glyph(_b.text,string(_g.party.puzzle[_i]));
        }
    }
    if(_g.style=="party" && is_struct(_g.party) && _g.party.phase=="returned" && _g.party.secret_ready){
        var _key=cr_party_tutor_key(),_geometry=_g.party.data[$ (_key=="secretBaldi"?"secret_baldi":(_key=="angryNull"?"angry_null":"secret_null"))];cr_geometry_draw(_geometry);
    }
    cr_alarm_draw();
    cr_null_draw();cr_secret_route_draw();cr_rotators_draw();
    if(_g.style=="demo")cr_demo_world_draw();
    var _distorted_fixture=_g.testing && cr_value(_g,"sense_distorted_fixture",false);
    if(_distorted_fixture){draw_clear(c_black);draw_clear_depth(1);}
    for(var _i=0;_i<array_length(global.cr_map.decorations);_i++){
        var _s=global.cr_map.decorations[_i];if(_distorted_fixture && (!variable_struct_exists(_s,"billboard_deform") || cr_value(_g,"sense_hide_distorted",false)))continue;
        if(variable_struct_exists(_s,"billboard_deform"))cr_billboard_deformed(_s);else cr_billboard(_s.sprite,_s.p[0],_s.p[1]+(cr_value(_s,"bob",false)?sin(_g.time*5)/2:0),_s.p[2],_s.w,_s.h,_s.pivot.y,c_white,cr_value(_s,"up",undefined));
    }
    var _bob=sin(_g.time*5)/2;
    for(var _i=0;_i<array_length(_g.books);_i++){
        var _b=_g.books[_i];if(_b.done || (_g.style=="demo" && !_b.book_ready))continue;
        cr_pickup_sprite(_b.sprite,_g.style=="demo"?_b.book_x:_b.x,5+_bob,_g.style=="demo"?_b.book_z:_b.z,global.cr_catalog.pickups.Notebook.sprite_scale);
    }
    for(var _i=0;_i<array_length(_g.items);_i++){
        var _p=_g.items[_i];if(_p.done || !variable_struct_exists(global.cr_catalog.items,_p.item))continue;
        var _key=cr_value(_p,"sprite_override",global.cr_catalog.items[$ _p.item].large);cr_pickup_sprite(_key,_p.x,5+_bob,_p.z,global.cr_catalog.pickups.Pickup.sprite_scale);
    }
    if(_g.style=="demo" && is_struct(_g.demo))for(var _i=0;_i<array_length(_g.books);_i++){
        var _book=_g.books[_i];
        for(var _j=0;_j<array_length(_book.numbers);_j++){
            var _n=_book.numbers[_j];if(_n.active)cr_billboard(_n.spec.sprite,_n.px,_n.held?1:5,_n.pz,_n.spec.width,_n.spec.height,_n.spec.pivot.y);
        }
    }
    if(_g.style=="party" && is_struct(_g.party))for(var _i=0;_i<array_length(_g.balloons);_i++){
        var _b=_g.balloons[_i],_s=_b.spec;cr_billboard(_s.sprite,_b.px+_s.offset[0],_b.py+_s.offset[1],_b.pz+_s.offset[2],_s.width,_s.height,_s.pivot.y);
    }
    if(!_g.spoop && _g.mode!="free" && is_struct(global.cr_map.happy)){
        var _h=global.cr_map.happy,_p=global.cr_map.spawn,_yaw=degtorad(global.cr_map.yaw),_key=cr_actor_animation(_h,"BAL_Wave",_g.happy_time);
        cr_actor_draw(_h,_key,_p[0]+sin(_yaw)*15,_p[2]+cos(_yaw)*15,0);
    }
    if(_g.testing && cr_value(_g,"sense_crafters_fixture",false)){draw_clear(c_black);draw_clear_depth(1);}
    if(_g.spoop && _g.mode!="free")for(var _i=0;_i<array_length(_g.npcs);_i++){
        var _n=_g.npcs[_i];if(_n.hidden || cr_value(_n,"optional_pending",false) || (_n.name=="Bully" && _n.cooldown>0))continue;
        var _key=_n.sprite;
        if(_n.name=="Baldi")_key=cr_actor_animation(_n.visual,cr_value(_n,"math_pause",0)>0?"BAL_Smile":(_g.style=="demo" && _g.demo.ruler?"BAL_Slap_Broken":"BAL_Slap"),.4-_n.slap_frame);
        if(_n.name=="Beans")_key=cr_actor_animation(_n.visual,_n.actor_state=="chew"?"Beans_Chew":(_n.actor_state=="spit"?"Beans_Spit":(_n.sprint_time>0?"Beans_Sprint":"Beans_Idle")),_n.anim_time);
        if(_n.name=="Playtime")_key=cr_actor_animation(_n.visual,_n.sad?"PLAY_Sad":"PLAY_Jump",_n.anim_time);
        if(_n.name=="ArtsAndCrafters" && _n.angry)_key=_n.params.angry_sprite;
        if(is_struct(_n.visual) && variable_struct_exists(_n.visual,"directions")){
            var _frames=_n.visual.directions,_angle=(radtodeg(arctan2(_g.pz-_n.pz,_g.px-_n.px))+radtodeg(_n.yaw)+720) mod 360;
            _key=_frames[round(_angle/(360/array_length(_frames))) mod array_length(_frames)];
        }
        if(_n.name=="ChalkFace")cr_demo_chalk_draw(_n);
        else {
            _g.render_null_face=_g.dead && is_struct(_g.null_mode);
            cr_actor_draw(_n.visual,_key,_n.px,_n.pz,_n.yaw,cr_value(_n,"flipped",false));_g.render_null_face=false;
        }
        if(_n.name=="ArtsAndCrafters" && _n.crafters_state=="attack")for(var _j=0;_j<array_length(_n.echoes);_j++){
            var _e=_n.echoes[_j];cr_actor_draw(_n.visual,_n.params.angry_sprite,_e[0],_e[1],0);
        }
    }
    for(var _i=0;_i<array_length(_g.projectiles);_i++){var _s=_g.projectiles[_i];cr_billboard("BSODA_Spray",_s.px,5,_s.pz,10,10);}
    for(var _i=0;_i<array_length(_g.exits);_i++){
        var _list=_g.exits[_i].decorations;
        for(var _j=0;_j<array_length(_list);_j++){var _s=_list[_j];cr_billboard(_s.sprite,_s.p[0],_s.p[1],_s.p[2],_s.w,_s.h,_s.pivot.y);}
    }
    // Transparent clouds blend after every opaque/cutout school object. Their
    // depth test remains enabled so walls in front still occlude them.
    if(_g.nullsession_testing)cr_ns_render_fixture();
    cr_extra_items_draw();cr_null_held_draw();
    if(_g.testing && cr_value(_g,"sense_detention_fixture",false)){draw_clear(c_black);draw_clear_depth(1);}
    if(_g.testing && cr_value(_g,"projection_fixture",false)){
        gpu_set_cullmode(cull_counterclockwise);
        draw_clear(c_black);draw_clear_depth(1);var _vb=global.cr_dynamic,_x=_g.px,_z=_g.pz+10;
        vertex_begin(_vb,global.cr_format);
        cr_quad(_vb,[_x-2,3,_z],[_x+2,3,_z],[_x+2,7,_z],[_x-2,7,_z],c_white);
        cr_quad(_vb,[_x-2,6.5,_z-.01],[_x+2,6.5,_z-.01],[_x+2,7,_z-.01],[_x-2,7,_z-.01],c_lime);
        cr_quad(_vb,[_x-2,3,_z-.01],[_x+2,3,_z-.01],[_x+2,3.5,_z-.01],[_x-2,3.5,_z-.01],c_red);
        vertex_end(_vb);vertex_submit(_vb,pr_trianglelist,-1);
    }
    if(_g.current_testing && cr_value(_g,"current_portal_fixture",false)){
        var _p=_g.current_portal.portal,_dx=sin(_g.yaw),_dz=cos(_g.yaw),_tx=_dz,_tz=-_dx;
        matrix_set(matrix_view,cr_camera_view(_p.cx-_dx*10,_p.cz-_dz*10,_g.yaw));
        draw_clear(c_lime);draw_clear_depth(1);gpu_set_cullmode(cull_noculling);
        var _vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
        cr_wall_quad(_vb,_p.cx-_tx*5,_p.cz-_tz*5,_p.cx+_tx*5,_p.cz+_tz*5);
        vertex_end(_vb);cr_submit(_vb,_g.current_portal_mask);
    }
    if(_g.revision_testing){
        var _fixture=cr_value(_g,"revision_fixture","");
        if(_fixture=="fog"){
            draw_clear(_g.demo.fog_color);draw_clear_depth(1);matrix_set(matrix_view,cr_camera_view(_g.px,_g.pz,0));
            cr_actor_draw(_g.npcs[0].visual,_g.npcs[0].sprite,_g.px,_g.pz+150,0);
        }
        if(_fixture=="wind"){draw_clear(c_black);draw_clear_depth(1);gpu_set_cullmode(cull_noculling);cr_demo_wind_draw(_g.revision_cloud);}
    }
    if(_g.nulleffects_testing)cr_ne_render_fixture();
    gpu_set_ztestenable(false);gpu_set_zwriteenable(false);gpu_set_cullmode(cull_noculling);gpu_set_alphatestenable(false);gpu_set_texrepeat(false);gpu_set_texfilter(false);gpu_set_tex_mip_filter(mip_off);
    surface_reset_target();
    var _client_w=max(1,window_get_width()),_client_h=max(1,window_get_height());
    matrix_set(matrix_world,matrix_build_identity());
    matrix_set(matrix_view,matrix_build(-_client_w/2,-_client_h/2,16000,0,0,0,1,1,1));
    matrix_set(matrix_projection,matrix_build_projection_ortho(_client_w,-_client_h,1,32000));
    draw_clear(c_black);draw_set_color(c_white);draw_set_alpha(1);
    draw_surface_ext(global.cr_world_surface,_fit[0]+(_g.mirror?640*_fit[2]:0),_fit[1],(_g.mirror?-1:1)*640*_fit[2]/_width,480*_fit[2]/_height,0,c_white,1);
    matrix_set(matrix_world,_world);matrix_set(matrix_view,_view);matrix_set(matrix_projection,_projection);
}
function cr_draw_mesh(_vertices,_texture,_color=c_white) {
    var _vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
    for(var _j=0;_j<array_length(_vertices);_j+=5)cr_vertex(_vb,_vertices[_j],_vertices[_j+1],_vertices[_j+2],_vertices[_j+3],_vertices[_j+4],_color);
    vertex_end(_vb);cr_submit(_vb,_texture);
}
function cr_draw_mesh_y(_vertices,_texture,_offset_y) {
    var _vb=global.cr_dynamic;vertex_begin(_vb,global.cr_format);
    for(var _j=0;_j<array_length(_vertices);_j+=5)cr_vertex(_vb,_vertices[_j],_vertices[_j+1]+_offset_y,_vertices[_j+2],_vertices[_j+3],_vertices[_j+4]);
    vertex_end(_vb);cr_submit(_vb,_texture);
}
function cr_demo_glyph(_font,_descriptor,_machine,_text) {
    _text=string(_text);if(string_length(_text)<=0)return;
    var _glyph=variable_struct_exists(_font.chars,_text)?_font.chars[$ _text]:_font.chars[$ "?"],_spr=cr_sprite(_font.file);if(_spr<0)return;
    var _atlas_w=sprite_get_width(_spr),_atlas_h=sprite_get_height(_spr),_uv=sprite_get_uvs(_spr,0),_r=_glyph.rect;
    var _u0=lerp(_uv[0],_uv[2],_r[0]/_atlas_w),_v0=lerp(_uv[1],_uv[3],_r[1]/_atlas_h),_u1=lerp(_uv[0],_uv[2],(_r[0]+_r[2])/_atlas_w),_v1=lerp(_uv[1],_uv[3],(_r[1]+_r[3])/_atlas_h);
    var _scale=_descriptor.size/_font.face.m_PointSize*_font.face.m_Scale*_glyph.scale*.1,_w=_glyph.size[0]*_scale,_h=_glyph.size[1]*_scale;
    // Unity TMP overlays are coplanar with the panel. Separate the GM depth
    // samples along the panel normal by 0.015 world units to prevent z fighting.
    var _yaw=degtorad(_machine.direction*90),_p=_descriptor.position,_depth=_p[2]-.015,_cx=_machine.x+_p[0]*cos(_yaw)+_depth*sin(_yaw),_cz=_machine.z-_p[0]*sin(_yaw)+_depth*cos(_yaw);
    var _rx=cos(_yaw)*_w/2,_rz=-sin(_yaw)*_w/2,_bottom=_p[1]-_h/2,_top=_p[1]+_h/2,_color=make_color_rgb(_descriptor.color[0],_descriptor.color[1],_descriptor.color[2]),_alpha=_descriptor.color[3]/255,_vb=global.cr_dynamic;
    vertex_begin(_vb,global.cr_format);
    vertex_position_3d(_vb,_cx-_rx,_bottom,_cz-_rz);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u0,_v1);
    vertex_position_3d(_vb,_cx+_rx,_top,_cz+_rz);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u1,_v0);
    vertex_position_3d(_vb,_cx+_rx,_bottom,_cz+_rz);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u1,_v1);
    vertex_position_3d(_vb,_cx-_rx,_bottom,_cz-_rz);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u0,_v1);
    vertex_position_3d(_vb,_cx-_rx,_top,_cz-_rz);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u0,_v0);
    vertex_position_3d(_vb,_cx+_rx,_top,_cz+_rz);vertex_colour(_vb,_color,_alpha);vertex_texcoord(_vb,_u1,_v0);
    vertex_end(_vb);vertex_submit(_vb,pr_trianglelist,sprite_get_texture(_spr,0));
}
function cr_demo_machine_text(_book) {
    var _machine=_book.machine;if(!variable_struct_exists(_machine,"text") || array_length(_machine.text)<4)return;
    var _values;
    if(_book.corrupted)_values=[string(irandom(9)),choose("+","-","X","/"),string(irandom(9)),choose("?","!")];
    else if(_book.bonus && _book.state!="active")_values=[string(_book.bonus_number),"/","6","!"];
    else _values=[string(_book.a),_book.op,string(_book.b),_book.state=="active"?"?":string(_book.answer)];
    for(var _i=0;_i<4;_i++){var _d=_machine.text[_i],_font=global.cr_ui_data.fonts[$ _d.font];cr_demo_glyph(_font,_d,_machine,_values[_i]);}
}
function cr_actor_animation(_visual,_state,_time) {
    if(!variable_struct_exists(_visual.states,_state))return _visual.sprite;
    var _s=_visual.states[$ _state],_anim=global.cr_catalog.animations[$ _s.clip];_time*=_s.speed;
    if(_anim.loop)_time=_time mod _anim.length;
    if(array_length(_anim.frames)==0)return _visual.sprite;
    return cr_ui_animation_sprite(_anim,_time);
}
function cr_actor_draw(_visual,_key,_x,_z,_yaw,_flipped=false) {
    var _o=_visual.offset,_s=global.cr_catalog.sprites[$ _key];
    cr_billboard(_key,_x+_o[0]*cos(_yaw)+_o[2]*sin(_yaw),5+(_flipped?-_o[1]:_o[1]),_z-_o[0]*sin(_yaw)+_o[2]*cos(_yaw),_s.width/_s.ppu*_visual.scale[0],_s.height/_s.ppu*_visual.scale[1],_s.pivot.y,c_white,_flipped?[0,-1,0]:undefined);
}
function cr_pickup_sprite(_key,_x,_y,_z,_scale) {
    var _s=global.cr_catalog.sprites[$ _key];cr_billboard(_key,_x,_y,_z,_s.width/_s.ppu*_scale[0],_s.height/_s.ppu*_scale[1],_s.pivot.y);
}
function cr_image(_key,_x,_y,_w,_h) {var _s=cr_sprite(_key);if(_s>=0)draw_sprite_stretched(_s,0,_x,_y,_w,_h);}
function cr_text(_s,_x,_y,_color=c_black,_scale=1) {
    draw_set_color(_color);draw_text_transformed(_x,_y,_s,_scale,_scale,0);draw_set_color(c_white);
}
function cr_game_viewport() {
    var _w=max(1,window_get_width()),_h=max(1,window_get_height()),_s=min(_w/640,_h/480);
    return [(_w-640*_s)/2,(_h-480*_s)/2,_s];
}
function cr_game_display_resize() {
    var _w=max(1,window_get_width()),_h=max(1,window_get_height());
    // Application surface and room viewport cover the same complete client.
    // Letterboxing belongs to the single world/HUD composition below.
    view_xport[0]=0;view_yport[0]=0;view_wport[0]=_w;view_hport[0]=_h;
    if(surface_exists(application_surface) && (surface_get_width(application_surface)!=_w || surface_get_height(application_surface)!=_h))surface_resize(application_surface,_w,_h);
    display_set_gui_size(_w,_h);
}
function cr_game_gui_draw() {
    var _v=cr_game_viewport(),_old=matrix_get(matrix_world);
    matrix_set(matrix_world,matrix_build(_v[0],_v[1],0,0,0,0,_v[2]*4/3,_v[2]*4/3,1));
    cr_draw_gui();
    if(global.cr_load_transition.stage<16 && surface_exists(global.cr_load_transition.previous))cr_game_transition_draw(global.cr_load_transition,global.cr_load_transition.previous,false);
    matrix_set(matrix_world,_old);
    var _w=window_get_width(),_h=window_get_height();draw_set_color(c_black);draw_set_alpha(1);
    if(_v[0]>0){draw_rectangle(0,0,_v[0]-1,_h,false);draw_rectangle(_w-_v[0],0,_w,_h,false);}
    if(_v[1]>0){draw_rectangle(0,0,_w,_v[1]-1,false);draw_rectangle(0,_h-_v[1],_w,_h,false);}
    draw_set_color(c_white);
}
function cr_hit(_rect) {
    return cr_game_hit_at(_rect,window_mouse_get_x(),window_mouse_get_y());
}
function cr_game_hit_at(_rect,_window_x,_window_y) {
    var _v=cr_game_viewport(),_mx=(_window_x-_v[0])/_v[2],_my=(_window_y-_v[1])/_v[2];
    return point_in_rectangle(_mx,_my,_rect[0],_rect[1],_rect[0]+_rect[2],_rect[1]+_rect[3]);
}
function cr_math_buttons() {
    var _result=[],_nodes=global.cr_math_ui.nodes;
    for(var _i=0;_i<array_length(_nodes);_i++)if(!is_undefined(_nodes[_i].button)){
        var _n=_nodes[_i],_a=_n.button.press[0],_label=_a.method=="SubmitAnswer"?"OK":(_a.method=="Clear"?"C":(_a.int<0?"-":string(_a.int))),_r=_n.rect;
        array_push(_result,{label:_label,rect:[_r[0]*4/3,_r[1]*4/3,_r[2]*4/3,_r[3]*4/3]});
    }return _result;
}
function bbcr_draw_math() {
    var _g=global.bbcr,_old=global.cr_ui;global.cr_ui=global.cr_math_ui;
    var _src=global.cr_ui_data.yctp;
    cr_ui_set_text(cr_ui_node(_src.problemTxt),_g.problem_text);cr_ui_set_text(cr_ui_node(_src.answerTxt),_g.input);
    for(var _i=0;_i<3;_i++){var _n=cr_ui_node(_src.indicator[_i]);_n.active=_g.marks[_i]!=0;_n.image_override=_g.marks[_i]<0?_src.wrongSprite:"YCTP_IndicatorsSheet_0";}
    cr_ui_active(_src.blank,!_g.math_face);
    cr_ui_math_face();
    global.cr_ui=_old;
    cr_game_ui_draw(global.cr_math_ui,true);
}
function cr_draw_gui() {
    var _g=global.bbcr;draw_set_font(global.cr_font);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_alpha(1);draw_set_color(c_white);
    if(_g.nulleffects_testing)return;
    if(_g.nullsession_testing)return;
    if(_g.revision_testing && cr_value(_g,"revision_hide_hud",false))return;
    if(((_g.won && global.cr_win_ui.stage>=16) || (_g.dead && _g.ending.phase>=1)) && cr_ending_draw())return;
    if(_g.scene=="math"){bbcr_draw_math();return;}
    if(_g.scene=="nullpad" || _g.scene=="secretbook"){cr_game_ui_draw(global.cr_math_ui,true);return;}
    if(is_struct(_g.null_mode) && (_g.null_mode.phase=="intro" || _g.null_mode.phase=="boss")){if(_g.paused)cr_game_ui_draw(global.cr_pause_ui,true);return;}
    if(_g.testing && cr_value(_g,"sense_detention_fixture",false)){cr_detention_draw();return;}
    var _old=global.cr_ui;global.cr_ui=global.cr_hud;
    var _hud=cr_ui_node("MainHud").scripts.HudManager;
    var _event=_g.style=="demo" && is_struct(_g.demo) && _g.demo.event_text_time>0;
    cr_ui_active(_hud.eventBackground,_event);cr_ui_set_text(cr_ui_node(_hud.eventText),_event?_g.demo.event_text:"");
    var _target=cr_interaction_target().kind;cr_ui_node(_hud.reticle).image_override=(_target=="book" || _target=="item" || _target=="door" || _target=="demo_number" || _target=="demo_machine" || _target=="party_candle" || _target=="party_button")?_hud.retOn:_hud.retOff;
    cr_ui_set_text(cr_ui_node(_hud.textBox[0]),string(_g.notebooks)+(_g.mode=="endless"?"":"/"+string(_g.needed))+" "+global.cr_text.Hud_Notebooks);
    var _needle=cr_ui_node(_hud.staminaNeedle),_val=_g.stamina/100;
    var _pos=_val>1?round(_hud.staminaMaxPos+min((_hud.staminaOverPos-_hud.staminaMaxPos)*(_val-1),_hud.staminaOverPos)):round(lerp(_hud.staminaMinPos,_hud.staminaMaxPos,_val));
    _needle.rect[0]=_needle.base_rect[0]+_pos-_hud.staminaMaxPos;
    for(var _i=0;_i<array_length(_hud.itemBackgrounds);_i++){
        var _bg=cr_ui_node(_hud.itemBackgrounds[_i]);_bg.active=_i<3;
        if(_i<3){_bg.graphics[0].color=_i==_g.slot?[255,0,0,255]:[255,255,255,255];
            cr_ui_node(_hud.itemSprites[_i]).image_override=_g.inventory[_i]==""?"Transparent":global.cr_catalog.items[$ _g.inventory[_i]].small;}
    }
    var _item=_g.inventory[_g.slot];cr_ui_set_text(cr_ui_node(_hud.itemTitle),global.cr_text[$ (_item==""?"Itm_Nothing":global.cr_catalog.items[$ _item].name)]);
    var _b=cr_ui_node("MainHud/Baldi"),_anim=global.cr_ui_data.animations[$ (_g.indicator>0?_g.indicator_state:"Still")];
    var _at=_g.indicator>0?_anim.length-_g.indicator:(_g.time mod _anim.length);_b.image_override=cr_ui_animation_sprite(_anim,_at);
    _b.rect[1]=_b.base_rect[1];
    if(_g.indicator>0 && array_length(_anim.floats)>0)_b.rect[1]-=cr_curve(_anim.floats[0].curve.m_Curve,_at)+96;
    cr_ui_draw_nodes();global.cr_ui=_old;
    cr_boots_draw();
    cr_detention_draw();
    cr_rope_draw();
    if(_g.style=="demo")cr_demo_gui_draw();
    if(_g.paused){cr_game_ui_draw(global.cr_pause_ui,true);return;}
    if(global.cr_pause_ui.stage<16 && surface_exists(global.cr_pause_ui.previous))cr_game_transition_draw(global.cr_pause_ui,global.cr_pause_ui.previous,false);
    if(global.cr_math_ui.stage<16 && surface_exists(global.cr_math_ui.previous))cr_game_transition_draw(global.cr_math_ui,global.cr_math_ui.previous,false);
    if(_g.won)cr_ending_draw();
    draw_set_color(c_white);
}
