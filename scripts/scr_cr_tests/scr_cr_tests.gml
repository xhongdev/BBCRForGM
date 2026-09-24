function cr_assert(_ok,_message) {
    global.cr_checks++;if(!_ok){global.cr_failures++;show_debug_message("BBCR_TEST_FAIL: "+_message);}
}
function cr_menu_test_step(_frame) {
    var _u=global.cr_ui;
    switch(_frame){
        case 1:global.cr_checks=0;global.cr_failures=0;
            // Source-frame comparisons exclude the optional test-menu overlay.
            // Its visible/hidden states are covered by the separate cheat suite.
            global.cr_cheat_hint_visible=false;
            cr_assert(_u.scene=="ClassicLauncher","source startup begins at ClassicLauncher");
            var _btn=cr_ui_node("Canvas/Launcher/PlayButton");
            cr_assert(cr_ui_hit(52,361)==_btn.id,"Launcher Play hit reaches source button");
            cr_assert(_btn.graphics[0].reference_ppu==1,"Launcher nine-slice uses its own reference PPU");
            _u.held=_btn.id;global.bbcr.page="launcher_held";break;
        case 2:_u.held="";global.bbcr.page="launcher";break;
        case 3:cr_ui_scene("Logo");break;
        case 5:cr_ui_scene("Warnings");break;
        case 7:
            cr_assert(audio_is_playing(_u.music),"warning source ErrorScreen loop plays");
            cr_ui_scene("MainMenu");_u.stage=16;
            cr_assert(audio_is_playing(_u.music),"source title MIDI render plays at title entry");break;
        case 9:
            var _bg=cr_ui_node("Title/Image"),_play=cr_ui_node("Title/StartButton"),_exit=cr_ui_node("Title/Exit");
            cr_assert(_bg.rect[0]==0 && _bg.rect[1]==0 && _bg.rect[2]==480 && _bg.rect[3]==360,"title source image fills original 480x360 canvas");
            cr_assert(abs(_play.rect[0]-277.66667)<.001 && abs(_play.rect[1]-256.333336)<.001,"Play RectTransform preserves source fractional coordinates");
            cr_assert(_exit.rect[0]==0 && _exit.rect[1]==296 && _exit.rect[2]==64,"Exit uses source lower-left rectangle");
            cr_assert(_play.button.normal=="PlayButtons_0" && _play.button.hover=="PlayButtons_1","Play source normal and highlighted sprites");
            cr_assert(cr_ui_hit(341,288)==_play.id,"source Play rectangle receives pointer input");
            cr_assert(cr_ui_hit(220,180)=="","title background does not act as Play");
            cr_ui_hover(_play.id);global.bbcr.page="title_hover";break;
        case 11:
            cr_ui_press(cr_ui_node("Title/StartButton"));
            cr_assert(cr_ui_node("Menu").active && !cr_ui_node("Title").active,"title Play opens separate blackboard menu");
            cr_assert(_u.stage==0,"source button starts 16-stage dither transition");
            cr_assert(abs(_u.interval-.03333333)<=.000001,"source dither interval matches serialized value");
            _u.stage=16;_u.held="";break;
        case 13:
            var _play=cr_ui_node("Menu/Play");cr_ui_hover(_play.id);global.bbcr.page="menu_hover";
            var _text=cr_ui_node("Menu/Play/Text (TMP)").graphics[0];
            cr_assert(_text.font=="COMIC_24_Pro" && _text.size==24 && _text.layout.text=="Play!","blackboard text uses original TMP font and localized label");break;
        case 15:cr_ui_press(cr_ui_node("Menu/Play"));_u.stage=16;_u.held="";
            cr_assert(cr_ui_node("StyleSelect").active,"blackboard Play opens style doors");break;
        case 17:cr_ui_hover(cr_ui_node("StyleSelect/ClassicStyle").id);global.bbcr.page="styles_hover";break;
        case 19:cr_ui_press(cr_ui_node("StyleSelect/ClassicStyle"));_u.stage=16;_u.held="";
            cr_assert(global.bbcr.style=="classic" && cr_ui_node("ModeSelect").active,"source style events select Classic and open mode screen");break;
        case 21:cr_ui_press(cr_ui_node("ModeSelect/Back"));_u.stage=16;_u.held="";
            cr_assert(cr_ui_node("StyleSelect").active && !cr_ui_node("ModeSelect").active,"mode Back restores source style page");
            for(var _i=0;_i<3;_i++){
                var _style=["ClassicStyle","PartyStyle","DemoStyle"][_i];cr_ui_press(cr_ui_node("StyleSelect/"+_style));_u.stage=16;
                var _overview=cr_ui_node("ModeSelect").scripts.EndlessMapOverview,_title=cr_ui_node(_overview.levelName).graphics[0].layout.text;
                cr_assert(string_pos(["Classic","Party","Demo"][_i],_title)==1,"mode blackboard uses selected "+_style+" title");
                cr_ui_press(cr_ui_node("ModeSelect/Back"));_u.stage=16;
            }global.bbcr.style="classic";break;
        case 23:cr_ui_press(cr_ui_node("StyleSelect/Back"));_u.stage=16;_u.held="";break;
        case 25:cr_ui_press(cr_ui_node("Menu/Back"));_u.stage=16;_u.held="";
            cr_assert(cr_ui_node("Title").active && !cr_ui_node("Title/StartButton").high,"return to title clears old hover state");
            cr_ui_hover(cr_ui_node("Title/Exit").id);global.bbcr.page="exit_hover";break;
        case 27:cr_ui_hover("");cr_ui_press(cr_ui_node("Title/StartButton"));_u.stage=8;global.bbcr.page="dither8";break;
        case 29:
            _u.stage=16;cr_ui_scene("Logo");repeat(299)bbcr_menu_step(1/60);
            cr_assert(_u.scene=="Logo","Logo stays visible before five seconds");
            repeat(2)bbcr_menu_step(1/60);cr_assert(_u.scene=="Warnings","Logo timer advances automatically to Warnings");
            cr_ui_warning_advance();
            cr_assert(_u.wait=="warning" && _u.stage==0,"warning advance starts source dither and audio fade");
            repeat(61)bbcr_menu_step(1/60);
            cr_assert(_u.scene=="MainMenu" && _u.intro_time>1.4,"warning fade reaches title with delayed intro");
            repeat(85)bbcr_menu_step(1/60);cr_assert(_u.intro_time>0,"intro voice waits 1.5 seconds");
            repeat(6)bbcr_menu_step(1/60);cr_assert(_u.intro_time<0 && _u.intro_sound>=0,"intro voice starts after source delay");
            _u.stage=16;break;
        case 31:window_set_size(1280,720);global.bbcr.page="resize_wide";break;
        case 34:
            cr_assert(window_get_width()==1280 && window_get_height()==720,"window accepts widescreen resize");
            var _vp=cr_ui_viewport();cr_assert(_vp[0]==160 && _vp[1]==0 && _vp[2]==2,"widescreen centers 4:3 source canvas");
            var _p=cr_ui_pointer(842,576);cr_assert(cr_ui_hit(_p[0],_p[1])==cr_ui_node("Title/StartButton").id,"window-space mouse maps to Play after widescreen resize");
            cr_assert(!window_mouse_get_locked(),"menu cursor leaves window border reachable for resizing");
            window_set_size(600,800);global.bbcr.page="resize_tall";break;
        case 37:
            var _vp=cr_ui_viewport();cr_assert(_vp[0]==0 && _vp[1]==175 && _vp[2]==1.25,"portrait window preserves source aspect ratio");
            window_set_size(480,360);global.bbcr.page="resize_native";break;
        case 40:window_set_size(777,555);global.bbcr.page="resize_fractional";break;
        case 43:window_set_size(960,720);global.bbcr.page="title";break;
        case 46:
            cr_ui_active("Title",false);cr_ui_active("Options",true);_u.stage=16;global.bbcr.page="options_general";
            var _o=cr_ui_node("Options").scripts.OptionsMenu;
            var _bars=cr_ui_node(_o.sensitivityAdj[0]);
            cr_assert(_bars.bar_value>0 && cr_ui_node(_bars.scripts.AdjustmentBars.bars[0]).image_override=="MenuBarSheet_0","General sensitivity bars receive source lit sprites");break;
        case 48:
            var _o=cr_ui_node("Options").scripts.OptionsMenu;
            cr_ui_active(_o.categories[0],false);cr_ui_active(_o.categories[1],true);global.bbcr.page="options_audio";
            cr_assert(string_pos("Audio",cr_ui_node(_o.categories[1]).path)>0,"source Options second category is Audio");
            for(var _i=0;_i<3;_i++){
                var _bar=cr_ui_node(_o.soundAdj[_i]),_before=cr_ui_bar_value(_bar);cr_ui_bar_adjust(_bar,-1);
                cr_assert(abs(global.bbcr.volumes[_i]-(_before-.1))<.001,"audio slider updates its own persisted channel "+string(_i));
                cr_assert(cr_ui_node(_bar.scripts.AdjustmentBars.bars[_bar.bar_value]).image_override=="MenuBarSheet_1","audio slider clears exact unlit bar "+string(_i));
                cr_ui_bar_adjust(_bar,1);
            }break;
        case 50:
            cr_ui_active("Options",false);cr_ui_active("HowToPlay",true);global.bbcr.page="howto";
            var _text=cr_ui_node("HowToPlay/Text/Text3"),_q=_text.graphics[0].layout.quads,_bottom=0;
            for(var _i=0;_i<array_length(_q);_i++)_bottom=max(_bottom,_text.rect[1]+_q[_i][5]+_q[_i][7]);
            cr_assert(_bottom<360,"How To Play final paragraph fits original canvas without clipping");break;
        case 52:
            cr_ui_active("HowToPlay",false);cr_ui_active("LoadingScreen",true);_u.stage=16;
            cr_ui_loading_tick(1/60);global.bbcr.page="loading_first";break;
        case 54:
            repeat(90)cr_ui_loading_tick(1/60);global.bbcr.page="loading_moved";
            var _node=cr_ui_node("LoadingScreen"),_anchor=cr_ui_node(_node.scripts.ClassicLoadScreen.faceAnchor);
            cr_assert(_anchor.rect[0]!=_anchor.base_rect[0] && _anchor.rect[1]!=_anchor.base_rect[1],"loading animation follows source X and sine Y motion");break;
        case 56:
            show_debug_message("BBCR_MENU_TEST_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");
            if(global.bbcr.menu_testing)game_end();else{bbcr_start_game("story");room_goto(rm_game);}break;
    }
}
function cr_run_tests() {
    global.cr_checks=0;global.cr_failures=0;var _g=global.bbcr,_m=global.cr_map;
    cr_assert(array_length(_m.books)==7 && _g.needed==7,"source has seven notebook activities");
    cr_assert(array_length(_m.tiles)==766,"exit tile groups imported");
    cr_assert(array_length(_m.doors)==27,"fifteen standard and twelve swing doors");
    cr_assert(_g.px==175 && _g.pz==25,"spawn from north exit prefab");
    cr_assert(!cr_blocked(_g.px,_g.pz,1.5),"player spawn is collision free");
    var _path=path_add();
    for(var _i=0;_i<7;_i++){
        var _b=_m.books[_i],_target=cr_nav_point(_b.x,_b.z),_reachable=false;
        for(var _a=0;_a<360 && !_reachable;_a+=15){
            var _p=cr_nav_point(_b.x+lengthdir_x(8,_a),_b.z+lengthdir_y(8,_a));
            if(point_distance(_p[0],_p[1],_b.x,_b.z)<=10)_reachable=mp_grid_path(global.cr_nav,_path,_g.px,_g.pz,_p[0],_p[1],false);
        }
        cr_assert(_reachable,"path to interaction range of notebook "+string(_i+1));
    }path_delete(_path);
    cr_assert(_m.books[0].x==132.5 && _m.books[0].z==60,"notebook uses activity position, not item");
    var _d=_g.doors[0];cr_assert(cr_blocked(_d.cx,_d.cz,1.5),"closed standard door blocks movement");
    cr_door_open(_d,false);cr_assert(!cr_blocked(_d.cx,_d.cz,1.5),"open standard door is traversable");
    _d.open=0;_d.lock=10;cr_assert(!cr_door_open(_d,false),"locked door rejects open");_d.lock=0;
    cr_collect_book(0);cr_assert(_g.scene=="math" && _g.notebooks==1,"collect counts immediately and opens YCTP");
    repeat(16)cr_transition_tick(global.cr_math_ui,.017);cr_math_start_ready();
    cr_assert(array_length(_g.voice_queue)==10 && _g.voice_queue[0]=="BAL_Math_Intro1" && _g.voice_queue[4]=="BAL_YCTP_Info2","first notebook queues all five source introduction clips before problem");
    cr_assert(string_pos(global.cr_text.YCTP_Solve1,_g.problem_text)==1,"YCTP problem uses original localized prefix and line breaks");
    cr_assert(_g.npcs[0].name=="Baldi" && _g.npcs[1].name=="Principal","Classic-prefixed source NPCs normalized for state machines");
    var _party=cr_json("bbcr/PartyMain.json"),_demo=cr_json("bbcr/ClassicDemo.json");
    cr_assert(array_length(_party.books)==7 && _party.manager=="ClassicPartyManager","Party style level imports independently");
    cr_assert(array_length(_demo.books)==7 && _demo.manager=="ClassicDemoManager","Demo style level imports independently");
    _g.a=0;_g.b=8;_g.op="-";_g.answer=-8;_g.input="-8";bbcr_submit_math();
    cr_assert(_g.marks[0]==1 && !_g.spoop,"negative answer accepted without anger");
    _g.input="999";bbcr_submit_math();cr_assert(_g.spoop && _g.extra_anger==1,"wrong early problem activates extra anger");
    _g.input="999";bbcr_submit_math();cr_assert(_g.math_done && _g.anger>1,"third wrong problem adds permanent anger");
    cr_assert(cr_curve(_g.npcs[0].params.slapCurve,10)==.706,"Baldi curve source keyframe");
    _g.scene="game";_g.math_done=false;_g.paused=false;_g.dead=false;
    cr_assert(cr_sprite("Title_Remastered")>=0 && cr_sprite("Slap_Sheet_0")>=0,"source title and character graphics load");
    var _snd=cr_sound("BAL_Slap");cr_assert(_snd>=0,"source WAV plays through stream API");
    repeat(16)cr_transition_tick(global.cr_math_ui,.017);
    var _before=_g.time;cr_pause(true);cr_assert(_g.paused && _g.time==_before,"pause does not advance world");cr_pause(false);
    _g.style="party";bbcr_start_game("story");
    cr_assert(global.cr_map.manager=="ClassicPartyManager" && global.bbcr.needed==7,"Party style builds as a playable world");
    cr_world_step(.01);cr_assert(variable_struct_exists(global.cr_map.happy.states,"BAL_Wave") && _g.npcs[0].name=="Baldi","Party Animator overrides and character AI dispatch remain active");
    cr_assert(!cr_blocked(global.bbcr.px,global.bbcr.pz,1.5),"Party style spawn is collision free");
    _g.style="demo";bbcr_start_game("story");
    cr_world_step(.01);
    cr_assert(global.cr_map.manager=="ClassicDemoManager" && global.bbcr.needed==7,"Demo style builds as a playable world");
    cr_assert(!cr_blocked(global.bbcr.px,global.bbcr.pz,1.5),"Demo style spawn is collision free");
    _g.style="classic";bbcr_start_game("story");
    cr_assert(global.cr_map.manager=="ClassicGameManager","Classic world restores after style changes");
    var _right=matrix_transform_vertex(cr_camera_view(0,0,0),1,5,10),_left=matrix_transform_vertex(cr_camera_view(0,0,0),-1,5,10);
    cr_assert(_right[0]>_left[0],"world +X projects to screen right when facing source North");
    var _front=matrix_transform_vertex(cr_camera_view(0,0,.1),0,5,10);
    cr_assert(_front[0]<0,"positive mouse yaw turns right and moves old target left");
    var _cam=global.cr_catalog.camera,_proj=matrix_build_projection_perspective_fov(_cam.vertical_fov,4/3,_cam.near,_cam.far);
    cr_assert(abs(abs(_proj[5])-sqrt(3))<.0001 && abs(abs(_proj[0])-sqrt(3)*.75)<.0001,"projection preserves source 60-degree vertical field of view at 4:3");
    cr_assert(global.cr_map.spawn[1]==5 && _cam.near==.3,"source player eye height and near plane use Unity world units");
    cr_world_parity_tests();
    var _missing=0;for(var _i=0;_i<array_length(global.cr_batches);_i++)if(cr_sprite(global.cr_batches[_i].texture)<0){_missing++;show_debug_message("BBCR_TEST_MISSING_TEXTURE: "+global.cr_batches[_i].texture);}
    cr_assert(_missing==0,"every world batch has a loadable source texture");
    cr_assert(!cr_ui_node("LoadingScreen").active && global.cr_ui.wait=="","entering game clears loading UI and its wait state");
    _g.notebooks=1;cr_collect_book(0);
    repeat(16)cr_transition_tick(global.cr_math_ui,.017);cr_math_start_ready();
    repeat(2){_g.input=string(_g.answer);bbcr_submit_math();}
    var _buzz=0;for(var _i=0;_i<array_length(_g.voice_queue);_i++)if(_g.voice_queue[_i]==global.cr_ui_data.yctp.audGlitch)_buzz++;
    cr_assert(_g.corrupt && _buzz==3,"second notebook third problem queues original three glitch clips");
    var _ui=global.cr_ui;global.cr_ui=global.cr_math_ui;
    cr_ui_set_text(cr_ui_node(global.cr_ui_data.yctp.problemTxt),_g.problem_text);
    cr_assert(cr_ui_node("YCTP/YCTP_Canvas/Text/Overflow1").graphics[0].layout.text!="","corrupted math flows into source linked overflow text fields");
    global.cr_ui=_ui;bbcr_start_game("story");
    show_debug_message("BBCR_TEST_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");
}
function cr_world_parity_tests() {
    var _g=global.bbcr,_x=_g.px,_z=_g.pz,_yaw=_g.yaw,_movement=global.cr_catalog.movement;
    cr_assert(_movement.radius==2 && _movement.height==8,"player capsule matches source radius 2 and height 8");
    var _buffers=0;for(var _i=0;_i<array_length(global.cr_map.colliders);_i++)if(global.cr_map.colliders[_i].layer==12)_buffers++;
    cr_assert(_buffers==0,"placement ObjectBuffer colliders cannot block the player");
    var _b=global.cr_catalog.sprites[$ global.cr_catalog.pickups.Notebook.sprites[0]];
    cr_assert(_b.width==101 && _b.height==128 && _b.ppu==100,"notebook uses original 1.01 by 1.28 world-unit sprite");
    var _d=_g.doors[0],_nx=sin(degtorad(_d.dir*90)),_nz=cos(degtorad(_d.dir*90));
    _g.px=_d.cx-_nx*4;_g.pz=_d.cz-_nz*4;_g.yaw=degtorad(_d.dir*90);
    var _target=cr_interaction_target();cr_assert(_target.kind=="door" && _target.index==0,"blue door ray hits source trigger on first attempt");
    cr_interact();cr_assert(_d.open==3,"blue door opens from the same target used by hand reticle");_d.open=0;
    _g.yaw+=pi/2;cr_assert(cr_interaction_target().kind!="door","looking alongside a door does not target it");
    for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].swing){
        var _s=_g.doors[_i],_sx=sin(degtorad(_s.dir*90)),_sz=cos(degtorad(_s.dir*90));
        cr_assert(!cr_box_overlap(_s.trigger,_s.cx-_sx*6,_s.cz-_sz*6,2),"yellow door does not trigger six units from its plane");
        cr_assert(cr_box_overlap(_s.trigger,_s.cx-_sx*2,_s.cz-_sz*2,2),"yellow door trigger contacts source player capsule near its plane");break;
    }
    _g.px=_x;_g.pz=_z;_g.yaw=_yaw;_g.inventory[0]="Zesty";_g.slot=0;
    var _sound_count=array_length(_g.sound_instances);cr_use_item();
    cr_assert(_g.stamina==200 && _g.inventory[0]=="" && array_length(_g.sound_instances)==_sound_count,"ZestyBar restores double stamina without invented voice playback");_g.stamina=100;
}
function cr_roundtrip_menu_test() {
    var _u=global.cr_ui;
    if(_u.wait==""){
        _u.stage=16;cr_ui_press(cr_ui_node("Title/StartButton"));_u.stage=16;
        cr_ui_press(cr_ui_node("Menu/Play"));_u.stage=16;
        cr_ui_press(cr_ui_node("StyleSelect/ClassicStyle"));_u.stage=16;
        // Use the serialized StartGame event, as a real click on Story does.
        for(var _i=0;_i<array_length(_u.nodes);_i++){
            var _n=_u.nodes[_i];if(is_undefined(_n.button) || !cr_ui_visible(_n))continue;
            for(var _j=0;_j<array_length(_n.button.press);_j++)if(_n.button.press[_j].method=="StartGame" && _n.button.press[_j].int==0){cr_ui_press(_n);_u.stage=16;break;}
            if(_u.wait=="game")break;
        }
        cr_assert(_u.wait=="game","roundtrip uses original Story button callbacks");
    }
    bbcr_menu_step(.1);if(global.bbcr.scene=="game")room_goto(rm_game);
}
function cr_window_test_step() {
    var _g=global.bbcr;
    if(!variable_struct_exists(_g,"window_test_next"))_g.window_test_next=0;
    if(current_time<_g.window_test_next)return;
    switch(_g.window_test_frame){
        case 0:cr_ui_scene("MainMenu");global.cr_ui.stage=16;break;
        case 1:show_debug_message("BBCR_WINDOW_ACTION: maximize menu");break;
        case 2:screen_save("bbcr_maximize_menu.png");show_debug_message("BBCR_WINDOW_SIZE: menu "+string(window_get_width())+" "+string(window_get_height())+" "+string(surface_get_width(application_surface))+" "+string(surface_get_height(application_surface)));show_debug_message("BBCR_WINDOW_ACTION: restore menu");break;
        case 3:bbcr_start_game("story");break;
        case 4:_g.projection_fixture=true;_g.yaw=0;break;
        case 5:cr_window_projection_capture("normal");show_debug_message("BBCR_WINDOW_ACTION: maximize game");break;
        case 6:cr_window_projection_capture("maximized");_g.projection_fixture=false;break;
        case 7:screen_save("bbcr_maximize_game.png");show_debug_message("BBCR_WINDOW_SIZE: game "+string(window_get_width())+" "+string(window_get_height())+" "+string(surface_get_width(application_surface))+" "+string(surface_get_height(application_surface)));show_debug_message("BBCR_WINDOW_ACTION: restore game");_g.projection_fixture=true;break;
        case 8:cr_window_projection_capture("restored");window_set_size(1280,720);break;
        case 9:cr_window_projection_capture("wide");window_set_size(600,800);break;
        case 10:cr_window_projection_capture("portrait");window_set_size(777,555);break;
        case 11:cr_window_projection_capture("fractional");show_debug_message("BBCR_WINDOW_RESULT: complete");game_end();break;
    }
    _g.window_test_frame++;_g.window_test_next=current_time+1200;
}
function cr_window_projection_capture(_label) {
    screen_save("bbcr_window_projection_"+_label+".png");
    surface_save(application_surface,"bbcr_window_surface_"+_label+".png");
    if(surface_exists(global.cr_world_surface))surface_save(global.cr_world_surface,"bbcr_window_world_"+_label+".png");
    show_debug_message("BBCR_WINDOW_PROJECTION: "+_label+" "+string(window_get_width())+" "+string(window_get_height())+" viewport "+string(view_xport[0])+","+string(view_yport[0])+","+string(view_wport[0])+","+string(view_hport[0]));
}
function cr_test_item_type(_type) {
    var _keys=variable_struct_get_names(global.cr_catalog.items);
    for(var _i=0;_i<array_length(_keys);_i++)if(global.cr_catalog.items[$ _keys[_i]].type==_type)return _keys[_i];return "";
}
function cr_gameplay_feedback_tests() {
    var _g=global.bbcr,_m=global.cr_map,_h=_m.happy;
    cr_assert(is_struct(_h) && _h.offset[0]==-2 && _h.offset[1]==-1,"HappyBaldi retains source left/down child offset");
    cr_assert(cr_actor_animation(_h,"BAL_Wave",0)!=cr_actor_animation(_h,"BAL_Wave",1),"greeting samples actual Animator sprite keys");
    _g.happy_time=0;_g.happy_spoke=false;cr_world_step(.8);cr_assert(!_g.happy_spoke,"Oh Hi waits for source wave animation event at half speed");
    cr_world_step(.1);cr_assert(_g.happy_spoke,"Oh Hi triggers when wave crosses the source animation event");
    for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].need_sound!=""){
        var _d=_g.doors[_i],_dx=sin(degtorad(_d.dir*90)),_dz=cos(degtorad(_d.dir*90));
        _g.px=_d.cx-_dx*2;_g.pz=_d.cz-_dz*2;cr_world_step(.01);var _voice=_d.need_voice;
        cr_assert(_voice>=0 && audio_is_playing(_voice),"locked yellow door plays original two-notebook reminder on contact");
        cr_world_step(.01);cr_assert(_d.need_voice==_voice,"staying in yellow-door trigger does not restart reminder each frame");break;
    }
    var _d=_g.doors[0];_g.px=_d.cx-sin(degtorad(_d.dir*90))*4;_g.pz=_d.cz-cos(degtorad(_d.dir*90))*4;_g.yaw=degtorad(_d.dir*90);
    _g.inventory=[cr_test_item_type(8),"",""];_g.slot=0;var _sounds=array_length(_g.sound_instances);cr_use_item();
    cr_assert(_g.inventory[0]=="" && _d.silent==4 && array_length(_g.sound_instances)==_sounds+1,"NoSquee applies to aimed door and plays source use sound");
    _g.inventory=[cr_test_item_type(18),"",""];cr_use_item();
    cr_assert(_g.boots==15 && array_length(_g.boot_effects)==1,"boots create source timed effect and animation instance");
    _g.px=_m.spawn[0];_g.pz=_m.spawn[2];cr_world_step(15.1);
    cr_assert(_g.boots==0 && array_length(_g.boot_effects)==1,"boots expiry removes immunity while retaining Up animation");cr_world_step(2);
    cr_assert(array_length(_g.boot_effects)==0,"boots effect releases after source two-second outro lifetime");
    var _n=undefined;
    for(var _i=0;_i<array_length(_g.npcs);_i++)if(_g.npcs[_i].name=="FirstPrize")_n=json_parse(json_stringify(_g.npcs[_i]));
    _n.px=175;_n.pz=55;_n.yaw=pi/2;_g.px=175;_g.pz=65;
    cr_first_prize_step(_n,.1,true);
    cr_assert(_n.speed==0 && _n.px==175 && _n.pz==55,"First Prize stops movement while turning more than source five-degree tolerance");
    cr_assert(abs(radtodeg(_n.yaw)-88.5)<.001,"First Prize turns at source 15 degrees per second");
    _n.yaw=0;cr_first_prize_step(_n,.1,true);
    cr_assert(abs(_n.speed-1.5)<.001 && point_distance(_n.gx,_n.gz,_g.px,_g.pz)>1,"First Prize accelerates toward corridor end rather than player's coordinates");
    _n.speed=20;var _gx=_n.gx,_gz=_n.gz;_g.px=155;_g.pz=55;cr_first_prize_step(_n,.1,true);
    cr_assert(_n.gx==_gx && _n.gz==_gz && !is_undefined(_n.pending_target),"First Prize defers retargeting while moving above wander speed");
    cr_first_prize_step(_n,.5,false);cr_assert(_n.unseen>0,"First Prize preserves one-second sight-loss grace period");
    cr_first_prize_step(_n,.6,false);cr_assert(_n.unseen==0 && !_n.pushing,"First Prize leaves pursuit after losing sight");
    _n.cooldown=30;var _yaw=_n.yaw;cr_first_prize_step(_n,.1,false);
    cr_assert(_n.speed==0 && abs(radtodeg(_n.yaw-_yaw)-15)<.001,"cut First Prize wires stop propulsion and spin at source turn speed times ten");
    _g.px=_m.spawn[0];_g.pz=_m.spawn[2];_g.yaw=0;_g.notebooks=1;cr_collect_book(0);
    cr_assert(global.cr_math_ui.stage==0 && global.cr_math_ui.reveal,"notebook click starts source dither fade-in");
    repeat(16)cr_transition_tick(global.cr_math_ui,.017);cr_math_start_ready();
    repeat(2){_g.input=string(_g.answer);bbcr_submit_math();}_g.input="0";bbcr_submit_math();
    var _closed=0;for(var _i=0;_i<array_length(_g.exits);_i++)_closed+=(_g.exits[_i].state==1);
    cr_assert(_closed==4,"corrupt second notebook activates all four source exit walls");
    var _e=_g.exits[0],_w=_e.barrier;cr_assert(cr_blocked((_w[0]+_w[2])/2,(_w[1]+_w[3])/2,2),"source closed exit wall blocks physical passage");
    _g.notebooks=6;cr_collect_book(2);_closed=0;for(var _i=0;_i<array_length(_g.exits);_i++)_closed+=_g.exits[_i].state;
    cr_assert(_closed==0,"all notebooks reopen the four exits for the final escape");
    _g.mode="free";_g.spoop=false;for(var _i=0;_i<array_length(_g.exits);_i++)_g.exits[_i].state=0;
    cr_collect_book(1);_closed=0;for(var _i=0;_i<array_length(_g.exits);_i++)_closed+=_g.exits[_i].state;
    cr_assert(_closed==0,"Free Run notebooks keep exits open");
    bbcr_start_game("story");
}
function cr_feedback_capture_step(_frame) {
    var _g=global.bbcr;
    switch(_frame){
        case 28:cr_gameplay_feedback_tests();_g.capture_scene="greeting_first";break;
        case 29:_g.happy_time=1;_g.capture_scene="greeting_wave";break;
        case 30:_g.happy_time=4;_g.capture_scene="greeting_done";break;
        case 31:
            for(var _i=0;_i<array_length(_g.doors);_i++)if(!_g.doors[_i].swing && global.cr_map.rooms[_g.doors[_i].a_room].category==4){
                var _d=_g.doors[_i];_g.px=_d.cx+sin(degtorad(_d.dir*90))*8;_g.pz=_d.cz+cos(degtorad(_d.dir*90))*8;_g.yaw=degtorad(_d.dir*90)+pi;_g.capture_door=_i;break;
            }_g.capture_scene="faculty_outside";break;
        case 32:
            var _d=_g.doors[_g.capture_door];_g.px=_d.cx-sin(degtorad(_d.dir*90))*8;_g.pz=_d.cz-cos(degtorad(_d.dir*90))*8;_g.yaw=degtorad(_d.dir*90);_g.capture_scene="faculty_inside";break;
        case 33:
            var _found=false;
            for(var _i=0;_i<array_length(global.cr_map.colliders);_i++){
                var _b=global.cr_map.colliders[_i];if(!variable_struct_exists(_b,"facility"))continue;
                for(var _side=-1;_side<=1;_side+=2){
                    _g.px=_b.center[0]+_b.axes[2][0]*7*_side;_g.pz=_b.center[2]+_b.axes[2][2]*7*_side;_g.yaw=arctan2(-_b.axes[2][0]*_side,-_b.axes[2][2]*_side);
                    var _target=cr_interaction_target();if(!cr_blocked(_g.px,_g.pz,2) && _target.kind=="facility" && _target.index==_b.facility){_g.capture_facility=_b.facility;_found=true;break;}
                }if(_found)break;
            }cr_assert(_found,"vending test approaches accessible machine face");_g.inventory=["Quarter","",""];_g.slot=0;_g.capture_scene="machine_stock";break;
        case 34:
            var _f=global.cr_map.facilities[_g.capture_facility];cr_use_item();cr_assert(_f.uses==0 && _g.inventory[0]==_f.item,"aimed vending machine delivers one product and exhausts stock");_g.capture_scene="machine_sold";break;
        case 35:
            _g.inventory=["Quarter","",""];cr_use_item();cr_assert(_g.inventory[0]=="Quarter","sold-out machine refuses a second coin");
            _g.px=175;_g.pz=25;_g.yaw=0;_g.inventory=[cr_test_item_type(18),"",""];cr_use_item();_g.boot_effects[0].time=.5;_g.capture_scene="boots_down";break;
        case 36:_g.boot_effects[0].time=1.2;_g.capture_scene="boots_hidden";break;
        case 37:_g.boot_effects[0].time=15.5;_g.capture_scene="boots_up";break;
        case 38:_g.boot_effects=[];_g.capture_scene="math_before";break;
        case 39:cr_collect_book(0);repeat(8)cr_transition_tick(global.cr_math_ui,.017);_g.capture_scene="math_enter_half";break;
        case 40:repeat(8)cr_transition_tick(global.cr_math_ui,.017);_g.capture_scene="math_enter_full";break;
        case 41:cr_math_close();cr_assert(global.cr_math_ui.stage==0 && !global.cr_math_ui.reveal,"YCTP exit captures final UI and starts source fade-out");repeat(8)cr_transition_tick(global.cr_math_ui,.017);_g.capture_scene="math_exit_half";break;
        case 42:repeat(8)cr_transition_tick(global.cr_math_ui,.017);_g.capture_scene="math_exit_full";break;
        case 43:
            var _e=_g.exits[0],_w=_e.barrier,_cx=(_w[0]+_w[2])/2,_cz=(_w[1]+_w[3])/2,_yaw=degtorad(_e.dir*90);
            _g.px=_cx+sin(_yaw)*12;_g.pz=_cz+cos(_yaw)*12;_g.yaw=_yaw+pi;_g.capture_scene="exit_open";break;
        case 44:cr_spoop();_g.capture_scene="exit_closed";break;
        case 45:for(var _i=0;_i<array_length(_g.exits);_i++)_g.exits[_i].state=0;_g.capture_scene="exit_reopened";break;
    }
}
function cr_npc_feedback_tests() {
    var _g=global.bbcr,_p=_g.npcs[0].params,_values=[.1,1.1,2.1,3.1,4.1,5.1,6.1,10,15,25,60];
    for(var _i=0;_i<array_length(_values);_i++)show_debug_message("BBCR_CURVE_CHECK: "+json_stringify([_values[_i],cr_curve(_p.slapCurve,_values[_i]),cr_curve(_p.speedCurve,_values[_i])+_p.baseSpeed]));
    cr_assert(abs(cr_curve(_p.slapCurve,1.1)-2.3761014)<.0002 && abs(cr_curve(_p.slapCurve,6.1)-1.18400745)<.0002,"weighted slap curve preserves early and late notebook cooldowns");
    var _n=json_parse(json_stringify(_g.npcs[0]));_n.path=path_add();_n.px=175;_n.pz=45;_n.gx=175;_n.gz=95;_n.priority=100;_n.route_timer=0;
    _g.px=55;_g.pz=395;_g.anger=1.1;_g.extra_anger=0;_n.slap_timer=cr_curve(_p.slapCurve,_g.anger);_n.slap_count=0;
    repeat(200)cr_npc_step(_n,.01);
    cr_assert(_n.slap_count==0 && _n.pz==45,"Baldi waits through source initial slap interval before moving");
    repeat(80)cr_npc_step(_n,.01);var _rest=_n.pz;
    cr_assert(_n.slap_count==1 && _n.slap_left<.0001 && _rest>60 && _rest<62,"first slap moves only its accumulated distance budget");
    repeat(100)cr_npc_step(_n,.01);
    cr_assert(_n.slap_count==1 && abs(_n.pz-_rest)<.0001,"Baldi remains still during the rest of the slap cooldown");path_delete(_n.path);
    var _principal=json_parse(json_stringify(_g.npcs[1]));_principal.path=path_add();_principal.px=175;_principal.pz=45;_principal.gx=175;_principal.gz=95;_principal.route_timer=0;_principal.speed=0;
    repeat(60)cr_npc_step(_principal,1/60);
    cr_assert(abs(_principal.speed-20)<.001 && abs(_principal.pz-55.1666667)<.03,"Principal accelerates at source 20 units per second squared with actual displacement");
    repeat(30)cr_npc_step(_principal,1/60);
    cr_assert(abs(_principal.speed-22)<.001 && _principal.pz>65,"Principal reaches source 22-unit movement speed");path_delete(_principal.path);
    var _route=json_parse(json_stringify(_g.npcs[1]));_route.path=path_add();_route.px=175;_route.pz=55.7;_route.gx=175;_route.gz=95;_route.route_timer=0;
    cr_npc_move(_route,20,.05);cr_assert(abs(_route.pz-56.7)<.001,"retargeting does not spend movement walking back to a grid cell center");path_delete(_route.path);
    for(var _i=0;_i<array_length(_g.npcs);_i++){
        var _n=json_parse(json_stringify(_g.npcs[_i]));_n.path=path_add();_n.px=177;_n.pz=45;_n.gx=177;_n.gz=85;_n.route_timer=0;
        repeat(30)cr_npc_move(_n,20,.05);
        cr_assert(abs(_n.px-175)<.001 && _n.pz>65,"hall route stays centered for "+_n.name);
        _n.px=177;_n.pz=55;repeat(20)cr_npc_push(_n,.3,1.5);
        cr_assert(abs(_n.px-175)<.001 && _n.pz>75 && !cr_blocked(_n.px,_n.pz,_n.params.collision_radius),"BSODA centers and advances "+_n.name+" without sliding into furniture");path_delete(_n.path);
    }
    _g.spoop=true;_g.notebooks=2;for(var _i=0;_i<array_length(_g.npcs);_i++){_g.npcs[_i].hidden=true;_g.npcs[_i].cooldown=1000;}
    for(var _i=0;_i<array_length(_g.doors);_i++)if(_g.doors[_i].swing){
        var _d=_g.doors[_i];_d.open=0;_d.locked=false;_d.lock=0;_g.npcs[0].priority=0;_g.indicator=0;
        _g.px=_d.cx-sin(degtorad(_d.dir*90))*2;_g.pz=_d.cz-cos(degtorad(_d.dir*90))*2;cr_world_step(.01);
        cr_assert(_d.open>0 && _g.npcs[0].priority==_d.noise && _g.npcs[0].gx==_d.cx && _g.indicator>0 && _g.indicator_state=="Baldicator_Look","player yellow-door trigger attracts Baldi and displays coming indicator");
        _d.open=0;_g.npcs[0].priority=127;_g.npcs[0].current_sound=127;_g.indicator=0;cr_world_step(.01);
        cr_assert(_g.npcs[0].priority==127 && _g.indicator>0 && _g.indicator_state=="Baldicator_Think","lower-priority yellow-door sound still displays source thinking indicator");
        _d.open=0;_g.indicator=0;cr_door_open(_d,false);cr_assert(_g.indicator==0,"NPC opening yellow door does not announce a player noise");break;
    }
    _g.px=175;_g.pz=25;var _anger=_g.anger;cr_world_step(10);
    cr_assert(_g.anger==_anger,"Story anger does not accumulate from elapsed play time");
    _g.mode="endless";_g.anger_tick=1;_g.anger_rate=.01;cr_world_step(.5);
    cr_assert(_g.anger==_anger,"Endless waits for its one-second source anger tick");cr_world_step(.5);
    cr_assert(abs(_g.anger-_anger-.01)<=.000001 && abs(_g.anger_rate-.01025)<=.000001,"Endless increments anger and next rate once per source tick");
    bbcr_start_game("story");
}
function cr_vending_capture(_name,_sold,_label) {
    var _g=global.bbcr,_m=global.cr_map;
    for(var _i=0;_i<array_length(_m.colliders);_i++){
        var _b=_m.colliders[_i];if(!variable_struct_exists(_b,"facility"))continue;
        var _f=_m.facilities[_b.facility];if(_f.name!=_name)continue;
        _g.px=_b.center[0]-_b.axes[2][0]*6;_g.pz=_b.center[2]-_b.axes[2][2]*6;_g.yaw=arctan2(_b.axes[2][0],_b.axes[2][2]);
        if(cr_blocked(_g.px,_g.pz,2))continue;
        _f.uses=_sold?0:1;_g.capture_scene=_label;
        show_debug_message("BBCR_VENDING_CAPTURE: "+json_stringify({label:_label,facility:_b.facility,sold:_sold,x:_g.px,z:_g.pz,yaw:_g.yaw}));return;
    }cr_assert(false,"accessible front capture of "+_name);
}
function cr_npc_feedback_capture(_frame) {
    var _g=global.bbcr;
    switch(_frame){
        case 46:cr_npc_feedback_tests();cr_vending_capture("SodaMachine",false,"soda_front");_g.input_deadline=current_time+3000;show_debug_message("BBCR_INPUT_ACTION: space_down");break;
        case 47:
            _g.inventory=["Bsoda","",""];_g.slot=0;cr_use_item();var _s=_g.projectiles[array_length(_g.projectiles)-1];
            cr_assert(abs(_s.dx+sin(_g.yaw))<.0001 && abs(_s.dz+cos(_g.yaw))<.0001,"held look-back fires BSODA in camera direction");show_debug_message("BBCR_INPUT_ACTION: space_up");_g.input_deadline=current_time+3000;_g.projectiles=[];
            _g.capture_scene="";break;
        case 48:
            _g.inventory=["Bsoda","",""];cr_use_item();var _s=_g.projectiles[array_length(_g.projectiles)-1];
            cr_assert(abs(_s.dx-sin(_g.yaw))<.0001 && abs(_s.dz-cos(_g.yaw))<.0001,"releasing look-back restores forward BSODA direction");_g.projectiles=[];
            cr_vending_capture("SodaMachine",true,"soda_sold_front");break;
        case 49:cr_vending_capture("ZestyMachine",false,"zesty_front");break;
        case 50:cr_vending_capture("ZestyMachine",true,"zesty_sold_front");break;
        case 51:
            for(var _i=0;_i<array_length(global.cr_ui.nodes);_i++)if(global.cr_ui.nodes[_i].parent=="")global.cr_ui.nodes[_i].active=false;
            cr_ui_active("LoadingScreen",true);global.cr_ui.wait="game";global.cr_ui.stage=16;cr_ui_loading_tick(.5);
            bbcr_draw_menu();surface_save(global.cr_ui.surface,"bbcr_loading_last.png");_g.capture_scene="";break;
        case 52:
            bbcr_start_game("story");cr_assert(global.cr_load_transition.stage==0 && surface_exists(global.cr_load_transition.previous),"entering game keeps final loading frame for source dither transition");_g.capture_scene="loading_exit_start";break;
        case 53: repeat(8)cr_loading_exit_tick(.017);_g.capture_scene="loading_exit_half";break;
        case 54: repeat(8)cr_loading_exit_tick(.017);_g.capture_scene="loading_exit_done";cr_assert(global.cr_load_transition.stage==16 && !surface_exists(global.cr_load_transition.previous),"loading outro completes all sixteen stages and releases its snapshot");break;
        case 55:
            global.cr_load_transition.previous=surface_create(480,360);global.cr_load_transition.stage=4;
            cr_world_cleanup();cr_assert(!surface_exists(global.cr_load_transition.previous),"unfinished loading snapshot releases on world cleanup");bbcr_start_game("story");break;
    }
}
