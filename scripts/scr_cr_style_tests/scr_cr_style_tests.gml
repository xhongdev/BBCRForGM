function cr_style_allowed_item(_item,_weighted) {
    for(var _i=0;_i<array_length(_weighted);_i++)if(_weighted[_i].item==_item)return true;
    return false;
}
function cr_style_facility_front(_facility) {
    var _g=global.bbcr,_m=global.cr_map;
    for(var _i=0;_i<array_length(_m.colliders);_i++){
        var _b=_m.colliders[_i];if(!variable_struct_exists(_b,"facility") || _b.facility!=_facility)continue;
        for(var _distance=3;_distance<=10;_distance+=.5)for(var _angle=0;_angle<360;_angle+=15){
            _g.px=_b.center[0]+lengthdir_x(_distance,_angle);_g.pz=_b.center[2]+lengthdir_y(_distance,_angle);
            _g.yaw=arctan2(_b.center[0]-_g.px,_b.center[2]-_g.pz);var _target=cr_interaction_target();
            if(!cr_blocked(_g.px,_g.pz,global.cr_catalog.movement.radius) && _target.kind=="facility" && _target.index==_facility)return true;
        }
    }
    return false;
}
function cr_style_party_test() {
    var _g=global.bbcr,_m=global.cr_map,_data=_g.party.data;
    cr_assert(_g.style=="party" && _m.manager=="ClassicPartyManager" && array_length(_g.books)==7 && _g.needed==7,"Party school requires all seven source activities after ending pre-generation is balanced");
    cr_assert(array_length(_data.balloon_rooms)==8 && array_length(_data.school_balloons)==4,"Party imports eight BalloonRoomFunction rooms and four source balloon prefabs");
    cr_assert(array_length(_g.balloons)>=32 && array_length(_g.balloons)<=56,"Party creates source Random.Range(4,8) balloons in every balloon room");
    var _room_counts=array_create(23,0);
    for(var _i=0;_i<array_length(_g.balloons);_i++){
        var _tile=cr_tile(_g.balloons[_i].px,_g.balloons[_i].pz);if(!is_undefined(_tile))_room_counts[_tile.room]++;
    }
    for(var _i=0;_i<array_length(_data.balloon_rooms);_i++){var _room=_data.balloon_rooms[_i].room;cr_assert(_room_counts[_room]>=4 && _room_counts[_room]<=7,"Party balloon count follows source room range "+string(_room));}
    var _gift_count=0;for(var _i=0;_i<array_length(_g.items);_i++)if(cr_value(_g.items[_i],"sprite_override","")==_data.present_sprite)_gift_count++;
    cr_assert(_gift_count==array_length(_g.items) && _data.present_sprite=="PresentIcon_Large","all initial Party pickups use the source present sprite");
    var _machines=[];for(var _i=0;_i<array_length(_m.facilities);_i++)if(string_pos("CrazyVendingMachine",_m.facilities[_i].name)==1)array_push(_machines,_i);
    cr_assert(array_length(_machines)==3,"Party imports all three Crazy vending machines as interactive facilities");
    for(var _mi=0;_mi<array_length(_machines);_mi++){
        var _index=_machines[_mi],_f=_m.facilities[_index];cr_assert(_f.uses==10 && array_length(_f.potential)>0,"Crazy vending source stock and weighted item table "+string(_mi+1));
        cr_assert(cr_style_facility_front(_index),"Crazy vending has an accessible source collider face "+string(_mi+1));
        repeat(10){_g.inventory=["Quarter","",""];_g.slot=0;var _before=_f.uses;cr_use_item();cr_assert(_f.uses==_before-1 && cr_style_allowed_item(_g.inventory[0],_f.potential),"Crazy vending purchase returns a weighted source item");}
        _g.inventory=["Quarter","",""];cr_use_item();cr_assert(_f.uses==0 && _g.inventory[0]=="Quarter","Crazy vending refuses an eleventh purchase after source stock ten");
    }
    cr_assert(array_length(_data.elevator.batches)>0 && array_length(_data.covers.batches)==1 && array_length(_data.covers.batches[0].vertices)==60,"Party imports the elevator and both SecretCovers wall quads");
}
function cr_style_party_final_test() {
    var _g=global.bbcr,_count=array_length(_g.exits);_g.notebooks=_g.needed;_g.exits_closed=_count-1;_g.progress.party_won=false;_g.unlock_notice="";
    for(var _i=0;_i<_count;_i++){_g.exits[_i].used=_i!=0;_g.exits[_i].prepared=false;}
    var _box=_g.exits[0].inside[0];_g.px=_box.center[0];_g.pz=_box.center[2];cr_exits_trigger();
    cr_assert(_g.party.phase=="elevator_ready" && !_g.won && _g.scene=="game","Party final elevator starts its source flow instead of returning to menu");
    cr_assert(_g.party.elevator_y==-30 && _g.progress.party_won && _g.unlock_notice==global.cr_text.Men_UnlockNotif+global.cr_text.But_LightsOut,"Party final exit lowers the elevator and records the Lights Out notice");
    var _trigger=_g.party.data.elevator_trigger;_g.px=_trigger.center[0];_g.pz=_trigger.center[2];cr_party_step(.01);
    cr_assert(_g.party.phase=="lift" && _g.items_disabled,"entering the source manager trigger locks items and starts the lift");
    repeat(300)cr_party_step(.01);
    cr_assert(_g.party.phase=="candle" && abs(_g.party.lift_height-35)<.001 && abs(_g.jump_height-30)<.001,"Party lift rises from source height 5 to 35 at ten units per second");
    var _c=_g.party.data.candle.box;_g.yaw=arctan2(_c.center[0]-_g.px,_c.center[2]-_g.pz);
    cr_assert(cr_interaction_target().kind=="party_candle","source candle is clickable from the raised Party elevator");cr_interact();
    cr_assert(global.cr_map.manager=="ClassicPartyEnding" && _g.party.phase=="ending" && !_g.won && _g.scene=="game","candle swaps to the 439-tile Party ending environment without a menu return");
    var _sum=0;for(var _i=0;_i<4;_i++)_sum+=_g.party.values[_i];
    cr_assert(_sum>=10 && array_length(_g.balloons)==_sum,"Party ending generates four source balloon-color counts whose total is at least ten");
    var _end=_g.party.data.ending_trigger;_g.px=_end.center[0];_g.pz=_end.center[2];cr_party_step(.01);
    cr_assert(_g.party.phase=="corrupt" && !_g.won,"Party ending trigger begins the source corruption countdown rather than quitting");
    show_debug_message("BBCR_STYLE_PARTY: "+json_stringify({school_balloon_rooms:array_length(_g.party.data.balloon_rooms),ending_balloons:_sum,phase:_g.party.phase,level:global.cr_map.manager}));
}
function cr_style_machine_front(_index) {
    var _g=global.bbcr;
    for(var _i=0;_i<array_length(global.cr_map.colliders);_i++){
        var _b=global.cr_map.colliders[_i];if(!variable_struct_exists(_b,"activity") || _b.activity!=_index)continue;
        for(var _sign=-1;_sign<=1;_sign+=2){
            _g.px=_b.center[0]+_b.axes[2][0]*8*_sign;_g.pz=_b.center[2]+_b.axes[2][2]*8*_sign;_g.yaw=arctan2(-_b.axes[2][0]*_sign,-_b.axes[2][2]*_sign);
            if(!cr_blocked(_g.px,_g.pz,global.cr_catalog.movement.radius) && cr_interaction_target().kind=="demo_machine")return true;
        }
    }return false;
}
function cr_style_book_front(_index) {
    var _g=global.bbcr,_b=_g.books[_index];
    for(var _a=0;_a<360;_a+=90){
        _g.px=_b.book_x+lengthdir_x(7,_a);_g.pz=_b.book_z+lengthdir_y(7,_a);_g.yaw=arctan2(_b.book_x-_g.px,_b.book_z-_g.pz);
        if(!cr_blocked(_g.px,_g.pz,global.cr_catalog.movement.radius) && cr_interaction_target().kind=="book")return true;
    }return false;
}
function cr_style_demo_test() {
    var _g=global.bbcr;cr_assert(global.cr_map.manager=="ClassicDemoManager" && array_length(_g.books)==7,"Demo starts seven imported MathMachine activities");
    var _numbers=0,_batches=0;for(var _i=0;_i<7;_i++){var _b=_g.books[_i];_numbers+=array_length(_b.numbers);_batches+=array_length(_b.machine.batches);cr_assert(!_b.book_ready && _b.state=="active","Demo notebook remains hidden until its MathMachine completes");}
    cr_assert(_numbers==70 && _batches>0,"Demo imports ten source floating numbers and machine meshes for all seven rooms");
    cr_assert(array_length(_g.books[0].machine.text)==4,"Demo imports all four source world-space TMP fields");
    cr_assert(_g.books[0].machine.text[0].font=="COMIC_24_Pro","Demo MathMachine uses the source COMIC_24_Pro bitmap font");
    var _book=_g.books[0],_answer=_book.answer,_number=_book.numbers[_answer];
    var _tile=global.cr_map.tiles[global.cr_map.bully_candidates[0]];_g.px=_tile.x*10+5;_g.pz=_tile.z*10+5;_g.yaw=0;_number.px=_g.px;_number.pz=_g.pz+7;
    cr_assert(cr_interaction_target().kind=="demo_number","Demo floating answer is selected through the source-distance reticle ray");cr_interact();
    cr_assert(_g.demo.held_machine==0 && _g.demo.held_number==_answer && _number.held,"clicked Demo number follows the player until machine submission");
    cr_assert(cr_style_machine_front(0),"Demo MathMachine has an accessible clickable source collider");cr_assert(cr_interaction_target().kind=="demo_machine","held number does not occlude the machine click layer");cr_interact();
    cr_assert(_book.book_ready && _book.state=="correct" && _g.scene=="game" && _g.demo.problems==1,"correct Demo submission reveals its notebook without opening YCTP");
    var _corrupted=0;for(var _i=1;_i<7;_i++)_corrupted+=_g.books[_i].corrupted;
    cr_assert(_corrupted==6,"first Demo activity corrupts every unfinished MathMachine");
    cr_assert(cr_style_book_front(0),"revealed Demo notebook is reachable at source notebookDistance");cr_interact();
    cr_assert(_g.notebooks==1 && _g.scene=="game" && _book.done,"collecting the Demo machine notebook stays in world gameplay");
    var _second=_g.books[1],_wrong=(_second.answer+1) mod 10;cr_demo_hold_number(10+_wrong);cr_demo_submit_machine(1);
    var _remaining=0;for(var _i=2;_i<7;_i++)_remaining+=_g.books[_i].corrupted;
    cr_assert(_second.state=="wrong" && _g.spoop && _remaining==0,"second Demo completion clears corruption and a wrong answer starts spoop mode");
    show_debug_message("BBCR_STYLE_DEMO: "+json_stringify({machines:7,numbers:_numbers,scene:_g.scene,problems:_g.demo.problems,notebooks:_g.notebooks}));
}
function cr_style_unlock_test() {
    var _g=global.bbcr;_g.unlock_notice=global.cr_text.Men_UnlockNotif+global.cr_text.But_LightsOut;
    cr_ui_dispose(global.cr_ui);global.cr_ui=cr_ui_context("MainMenu");cr_ui_scene("MainMenu");
    cr_assert(cr_ui_node("LoadingScreen").active && global.cr_ui.unlock_time==7,"Party unlock reuses the source LoadingScreen for seven seconds");
    cr_assert(cr_ui_node("LoadingScreen/Text/Text1").graphics[0].layout.text==_g.unlock_notice && audio_is_playing(global.cr_ui.sound) && global.cr_ui.music<0,"Party unlock shows localized text and plays BAL_Wow before title music");
    repeat(419)bbcr_menu_step(1/60);cr_assert(cr_ui_node("LoadingScreen").active,"unlock screen remains visible immediately before seven seconds");
    bbcr_menu_step(1/60);cr_assert(!cr_ui_node("LoadingScreen").active && global.cr_ui.stage==0 && _g.unlock_notice=="" && audio_is_playing(global.cr_ui.music),"unlock screen starts the source dither removal and title music at seven seconds");
    _g.progress.demo_won=false;cr_progress_complete_style("demo");cr_assert(_g.unlock_notice==global.cr_text.Men_UnlockNotif+global.cr_text.But_HardMode,"Demo completion queues the original Hard Mode unlock message");
    show_debug_message("BBCR_STYLE_UNLOCK: "+json_stringify({hold:7,interval:.0666666,screen:"LoadingScreen",sound:"BAL_Wow"}));
}
function cr_style_test_step() {
    var _g=global.bbcr,_stage=cr_value(_g,"style_test_stage",0);
    switch(_stage){
        case 0:
            global.cr_checks=0;global.cr_failures=0;global.cr_cheat_hint_visible=false;cr_style_party_test();
            var _b=_g.balloons[0],_tile=global.cr_map.tiles[global.cr_map.bully_candidates[0]];_g.px=_tile.x*10+5;_g.pz=_tile.z*10+5;_g.yaw=0;_b.px=_g.px;_b.pz=_g.pz+8;_g.capture_scene="style_party_balloon";_g.style_test_stage=1;break;
        case 1:
            _g.px=135;_g.pz=325;_g.yaw=0;_g.capture_scene="style_party_cafeteria";_g.style_test_stage=2;break;
        case 2:
            cr_style_party_final_test();var _b=_g.balloons[0];_g.px=_b.px;_g.pz=_b.pz-8;_g.yaw=0;_g.capture_scene="style_party_ending";_g.style_test_stage=3;break;
        case 3:
            _g.style="demo";bbcr_start_game("story");var _m=_g.books[0].machine,_yaw=degtorad(_m.direction*90);_g.px=_m.x-sin(_yaw)*9;_g.pz=_m.z-cos(_yaw)*9;_g.yaw=_yaw;_g.capture_scene="style_demo_machine";_g.style_test_stage=4;break;
        case 4:
            var _b=_g.books[0];show_debug_message("BBCR_STYLE_DEMO_FRAME: "+json_stringify({a:_b.a,op:_b.op,b:_b.b,answer:_b.answer,x:_b.machine.x,z:_b.machine.z,direction:_b.machine.direction}));
            _g.style_demo_text=_b.machine.text;_b.machine.text=[];_g.capture_scene="style_demo_machine_base";_g.style_test_stage=5;break;
        case 5:
            _g.books[0].machine.text=_g.style_demo_text;_g.capture_scene="style_demo_machine_text";_g.style_test_stage=6;break;
        case 6:
            cr_style_demo_test();cr_style_unlock_test();show_debug_message("BBCR_STYLE_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();break;
    }
}
