/// Isolated save tests; the real bbcr.sav and legacy bbcr.ini are never opened.
function cr_crypto_test_assert(_condition,_label) {
    global.cr_checks++;
    if(!_condition){global.cr_failures++;show_debug_message("BBCR_TEST_FAIL: "+_label);}
}
function cr_crypto_test_hash() {
    var _b=buffer_load("bbcr_crypto_test.sav"),_hash=buffer_sha1(_b,0,buffer_get_size(_b));buffer_delete(_b);return _hash;
}
function cr_crypto_test_step() {
    var _g=global.bbcr;
    global.cr_checks=0;global.cr_failures=0;
    var _reopen=false,_reject=false,_fresh=false;
    for(var _i=0;_i<=parameter_count();_i++){
        if(parameter_string(_i)=="--crypto-reopen")_reopen=true;
        if(parameter_string(_i)=="--crypto-reject")_reject=true;
        if(parameter_string(_i)=="--crypto-fresh")_fresh=true;
    }
    if(_fresh){
        cr_crypto_test_assert(_g.crypto.ready && !_g.crypto.corrupt && _g.high_score==0,"first launch without save loads defaults");
        cr_crypto_test_assert(cr_save() && file_exists("bbcr_crypto_test.sav"),"first save creates encrypted file");
        cr_crypto_test_assert(!file_exists("bbcr_crypto_test.ini"),"fresh launch never creates plaintext INI");
    }else if(_reject){
        var _hash=cr_crypto_test_hash();
        cr_crypto_test_assert(_g.crypto.corrupt && !_g.crypto.ready,"separate-process corrupted startup is read-only");
        cr_crypto_test_assert(!cr_save() && cr_crypto_test_hash()==_hash,"startup defaults cannot replace corrupted save");
        cr_crypto_test_assert(file_exists("bbcr_crypto_test.ini"),"corrupt sealed file does not silently fall back to plaintext");
    }else if(_reopen){
        cr_crypto_test_assert(_g.high_score==456 && _g.subtitles && _g.progress.flags[4],"second process startup restores encrypted score options and progress");
        cr_crypto_test_assert(_g.games_since_error==12 && _g.reduce_flashing && !_g.rumble,"second process restores events and general options");
        cr_crypto_test_assert(!file_exists("bbcr_crypto_test.ini") && !file_exists("bbcr_crypto_test.runtime.ini"),"restart has no plaintext save");
    }else{
        cr_crypto_test_assert(string_pos("AES-256-GCM",bbcr_save_crypto_version())>0,"native extension loaded in Runner");
        cr_crypto_test_assert(_g.crypto.converted && _g.high_score==321 && _g.subtitles && _g.progress.flags[2],"real startup migrates legacy options score and progress");
        cr_crypto_test_assert(!file_exists("bbcr_crypto_test.ini") && file_exists("bbcr_crypto_test.sav"),"legacy removed only after encrypted commit");
        cr_crypto_test_assert(!file_exists("bbcr_crypto_test.runtime.ini"),"startup leaves no decrypted disk copy");
        _g.high_score=400;_g.games_since_error=9;_g.progress.flags[3]=true;
        cr_crypto_test_assert(cr_save(),"normal save uses native authenticated commit");
        var _first=cr_crypto_test_hash();
        cr_crypto_test_assert(cr_save() && cr_crypto_test_hash()!=_first,"repeated saves use fresh keys and nonces");
        _g.progress.party_won=true;
        cr_crypto_test_assert(cr_progress_save(),"progress-only save also encrypts");
        var _plain=bbcr_save_crypto_read(cr_crypto_path(_g.crypto.sealed));ini_open_from_string(_plain);
        cr_crypto_test_assert(ini_read_real("scores","classic",0)==400 && ini_read_real("progress","party_won",0)==1,"progress save preserves score");
        cr_crypto_test_assert(ini_read_string("custom","sentinel","")=="preserve-me","unknown legacy sections survive ordinary saves");ini_close();
        cr_cheat_mark_used();_g.high_score=999;_g.progress.flags[4]=true;_g.games_since_error=99;_g.subtitles=false;
        cr_crypto_test_assert(cr_save(),"cheat session can save ordinary options");
        _plain=bbcr_save_crypto_read(cr_crypto_path(_g.crypto.sealed));ini_open_from_string(_plain);
        cr_crypto_test_assert(CR_CHEATS_CAN_RECORD_PROGRESS || (ini_read_real("scores","classic",0)==400 && ini_read_real("progress","flag_4",0)==0 && ini_read_real("events","games_since_error",0)==9),"encrypted save honors no-score/no-unlock cheat policy");
        cr_crypto_test_assert(ini_read_real("options","subtitles",1)==0,"ordinary option persists independently of cheat policy");ini_close();
        global.cr_cheat.used=false;global.cr_cheat.record_baseline=undefined;
        var _b=buffer_load("bbcr_crypto_test.sav"),_n=buffer_get_size(_b);
        buffer_poke(_b,_n-1,buffer_u8,buffer_peek(_b,_n-1,buffer_u8)^^1);buffer_save(_b,"bbcr_crypto_test.sav");buffer_delete(_b);
        var _damaged=cr_crypto_test_hash();
        cr_crypto_test_assert(!cr_save() && _g.crypto.write_failed,"save refuses a file modified while game is running");
        cr_crypto_test_assert(cr_crypto_test_hash()==_damaged,"failed commit leaves damaged evidence unchanged");
        cr_crypto_test_assert(!cr_crypto_prepare("bbcr_crypto_test.sav","bbcr_crypto_test.ini") && _g.crypto.corrupt,"tampered startup fails authentication");
        cr_crypto_test_assert(!cr_save() && cr_crypto_test_hash()==_damaged,"corrupt startup does not overwrite with defaults");
        cr_crypto_test_assert(cr_user_data_reset(),"explicit user reset can replace rejected save");
        cr_crypto_test_assert(cr_crypto_prepare("bbcr_crypto_test.sav","bbcr_crypto_test.ini"),"reset creates readable encrypted defaults");
        _g.high_score=456;_g.subtitles=true;_g.progress.flags[4]=true;_g.games_since_error=12;_g.reduce_flashing=true;_g.rumble=false;
        cr_crypto_test_assert(cr_save(),"final fixture for separate-process reopen");
        var _snapshot=_g.crypto;
        cr_crypto_test_assert(!cr_crypto_prepare("bbcr_crypto_missing_dir/out.sav","bbcr_crypto_fail.ini"),"failed legacy migration reports failure");
        cr_crypto_test_assert(file_exists("bbcr_crypto_fail.ini"),"failed migration retains original plaintext");
        _g.crypto=_snapshot;
    }
    show_debug_message("BBCR_CRYPTO_RESULT: "+string(global.cr_checks)+" checks, "+string(global.cr_failures)+" failures");game_end();
}
