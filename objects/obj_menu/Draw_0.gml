bbcr_draw_menu();
if(global.bbcr.captionevent_testing)exit;
if(global.bbcr.policy_testing)exit;
if(global.bbcr.revision_testing)exit;
if (global.bbcr.testing && !global.bbcr.current_testing && !global.bbcr.window_testing && !global.bbcr.style_feedback_testing) {
    surface_save(application_surface,"bbcr_"+global.bbcr.page+".png");
    surface_save(global.cr_ui.surface,"bbcr_native_"+global.bbcr.page+".png");
    if(global.bbcr.page=="dither8")surface_save(global.cr_ui.previous,"bbcr_native_dither_previous.png");
}
