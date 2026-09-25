// Aide en ligne de 60Sec-AI : choix de la langue, sommaire, recherche dans la page, impression.
// La page porte trois <article class="langue" lang="fr|en|es"> ; on n'affiche que celui de la langue
// demandée par ?lang=xx (sinon la langue mémorisée dans ce navigateur, sinon le français).
(function () {
    var langues = ['fr', 'en', 'es'];
    var libelles = {
        sommaire: { fr: 'Dans cette section', en: 'In this section', es: 'En esta sección' },
        retour: { fr: 'Sommaire de l’aide', en: 'Help contents', es: 'Índice de la ayuda' },
        imprimer: { fr: 'Imprimer', en: 'Print', es: 'Imprimir' },
        rechercher: { fr: 'Rechercher dans la page…', en: 'Search this page…', es: 'Buscar en la página…' },
        aucun: { fr: 'Aucun résultat', en: 'No match', es: 'Sin resultados' },
        pied: { fr: 'Aide de 60Sec-AI — les libellés cités sont ceux des écrans.', en: '60Sec-AI help — quoted labels are those of the screens.', es: 'Ayuda de 60Sec-AI — las etiquetas citadas son las de las pantallas.' }
    };

    function langueDemandee() {
        var q = (new URLSearchParams(location.search).get('lang') || '').toLowerCase();
        if (langues.indexOf(q) >= 0) return q;
        try { var m = localStorage.getItem('aideLang'); if (langues.indexOf(m) >= 0) return m; } catch (e) { }
        return 'fr';
    }

    var courante = langueDemandee();
    var articles = document.querySelectorAll('article.langue');
    var sommaire = document.getElementById('aideSommaire');
    var recherche = document.getElementById('aideRecherche');

    function texte(cle) { return (libelles[cle] || {})[courante] || ''; }

    function construireSommaire(article) {
        if (!sommaire) return;
        sommaire.innerHTML = '';
        var t = document.createElement('div'); t.className = 'titre'; t.textContent = texte('sommaire'); sommaire.appendChild(t);
        article.querySelectorAll('h2, h3').forEach(function (h, i) {
            if (!h.id) h.id = courante + '-t' + i;
            var a = document.createElement('a'); a.href = '#' + h.id; a.textContent = h.textContent;
            if (h.tagName === 'H3') a.className = 'n3';
            sommaire.appendChild(a);
        });
    }

    function appliquer(langue) {
        courante = langue;
        try { localStorage.setItem('aideLang', langue); } catch (e) { }
        document.documentElement.lang = langue;
        var visible = null;
        articles.forEach(function (a) {
            var ok = a.getAttribute('lang') === langue;
            a.classList.toggle('visible', ok);
            if (ok) visible = a;
        });
        if (!visible && articles.length) { visible = articles[0]; visible.classList.add('visible'); }
        document.querySelectorAll('.aide-langues button').forEach(function (b) { b.classList.toggle('actif', b.getAttribute('data-lang') === langue); });
        document.querySelectorAll('[data-fr]').forEach(function (el) { var v = el.getAttribute('data-' + langue) || el.getAttribute('data-fr'); if (el.tagName === 'INPUT') el.placeholder = v; else el.textContent = v; });
        var pied = document.querySelector('.aide-pied'); if (pied) pied.textContent = texte('pied');
        if (recherche) recherche.placeholder = texte('rechercher');
        if (visible) { construireSommaire(visible); var h1 = visible.querySelector('h1'); if (h1) document.title = h1.textContent + ' — 60Sec-AI'; }
        if (recherche && recherche.value) filtrer(recherche.value);
    }

    // Recherche : on masque les sections (h2) qui ne contiennent pas le texte, et on surligne le reste.
    function nettoyer(article) {
        article.querySelectorAll('mark.aide-hit').forEach(function (m) { m.replaceWith(document.createTextNode(m.textContent)); });
        article.normalize();
        article.querySelectorAll('section.masque').forEach(function (s) { s.classList.remove('masque'); });
    }
    function surligner(el, q) {
        var w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT, null), n, noeuds = [];
        while ((n = w.nextNode())) noeuds.push(n);
        var re = new RegExp(q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'ig');
        noeuds.forEach(function (t) {
            if (!re.test(t.nodeValue)) return;
            re.lastIndex = 0;
            var frag = document.createDocumentFragment(), reste = t.nodeValue, m;
            while ((m = re.exec(reste)) !== null) {
                frag.appendChild(document.createTextNode(reste.slice(0, m.index)));
                var mk = document.createElement('mark'); mk.className = 'aide-hit'; mk.textContent = m[0]; frag.appendChild(mk);
                reste = reste.slice(m.index + m[0].length); re.lastIndex = 0;
            }
            frag.appendChild(document.createTextNode(reste));
            t.parentNode.replaceChild(frag, t);
        });
    }
    function filtrer(q) {
        var article = document.querySelector('article.langue.visible'); if (!article) return;
        nettoyer(article);
        q = (q || '').trim();
        var sections = article.querySelectorAll(':scope > section');
        if (q.length < 2) { sections.forEach(function (s) { s.classList.remove('masque'); }); construireSommaire(article); return; }
        var trouve = 0;
        sections.forEach(function (s) {
            var ok = s.textContent.toLowerCase().indexOf(q.toLowerCase()) >= 0;
            s.classList.toggle('masque', !ok);
            if (ok) { trouve++; surligner(s, q); }
        });
        construireSommaire(article);
        if (sommaire) sommaire.querySelectorAll('a').forEach(function (a) { var h = document.getElementById(a.hash.slice(1)); if (h && h.closest('section.masque')) a.classList.add('masque'); });
        if (trouve === 0 && sommaire) { var d = document.createElement('div'); d.className = 'msg'; d.textContent = texte('aucun'); sommaire.appendChild(d); }
    }

    document.querySelectorAll('.aide-langues button').forEach(function (b) {
        b.addEventListener('click', function () {
            appliquer(b.getAttribute('data-lang'));
            var u = new URL(location.href); u.searchParams.set('lang', courante); history.replaceState(null, '', u);
        });
    });
    var imprimer = document.getElementById('aideImprimer'); if (imprimer) imprimer.addEventListener('click', function () { window.print(); });
    if (recherche) recherche.addEventListener('input', function () { filtrer(recherche.value); });

    // Les liens vers les autres sections gardent la langue courante.
    document.addEventListener('click', function (e) {
        var a = e.target.closest('a[href$=".html"], a[href*=".html#"], a[href*=".html?"]');
        if (!a || /^https?:/i.test(a.getAttribute('href'))) return;
        var u = new URL(a.getAttribute('href'), location.href); u.searchParams.set('lang', courante); a.href = u.toString();
    });

    // Surligne l'entrée du sommaire de la partie visible à l'écran.
    if ('IntersectionObserver' in window && sommaire) {
        var obs = new IntersectionObserver(function (entries) {
            entries.forEach(function (en) {
                if (!en.isIntersecting) return;
                sommaire.querySelectorAll('a').forEach(function (a) { a.classList.toggle('courant', a.hash === '#' + en.target.id); });
            });
        }, { rootMargin: '-10% 0px -80% 0px' });
        document.querySelectorAll('article.langue h2, article.langue h3').forEach(function (h) { obs.observe(h); });
    }

    appliquer(courante);
    if (location.hash) { var cible = document.getElementById(location.hash.slice(1)); if (cible) setTimeout(function () { cible.scrollIntoView(); }, 50); }
})();
