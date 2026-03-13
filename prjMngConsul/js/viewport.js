






function adjustGridHeight() {
    var pageHead = document.querySelector('.page-head');
    var fullGrid = document.querySelector('.full-grid');
    var footer = document.querySelector('.app-footer');  // ← ton sélecteur

    if (!pageHead || !fullGrid) return;

    var pageHeadBottom = pageHead.getBoundingClientRect().bottom;
    var footerHeight = footer ? footer.offsetHeight : 0;
    var windowHeight = window.innerHeight;
    var padding = 16;

    fullGrid.style.height = (windowHeight - pageHeadBottom - footerHeight - padding) + 'px';
}

// Au chargement
window.addEventListener('load', adjustGridHeight);

// Au redimensionnement
window.addEventListener('resize', adjustGridHeight);

// Après chaque postback AJAX Telerik
function pageLoad() {
    adjustGridHeight();
}
