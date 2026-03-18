




function openRadWindow(id, ControlRW, Page, ModifTitle, AddTitle) {
    var wnd = $find(ControlRW);
    var url = Page;

    if (id && id > 0) {
        url += "?Id=" + id;
        wnd.set_title(ModifTitle);
    } else {
        url += "?Id=0";
        wnd.set_title(AddTitle);
    }

    // ── Largeur dynamique ──────────────────────────
    var screenW = window.innerWidth;
    var maxW = 1100;   // plafond desktop
    var marge = 20;     // espace de chaque côté sur mobile

    var winW = Math.min(screenW - marge, maxW);
    wnd.set_width(winW);



    // ───────────────────────────────────────────────
    // Hauteur dynamique — plein écran sur mobile, fixe sur desktop
    var screenH = window.innerHeight;
    var maxH = 720;
    var winH = screenW < 768
        ? screenH - 20   // presque plein écran sur mobile
        : maxH;          // 720px fixe sur desktop

    wnd.set_width(winW);
    wnd.set_height(winH);


    wnd.setUrl(url);
    wnd.show();
}