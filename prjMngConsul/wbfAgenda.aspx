<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    MaintainScrollPositionOnPostback="true" CodeBehind="wbfAgenda.aspx.vb"
    Inherits="MngConsul.wbfAgenda" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Agenda — 60Sec-AI
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        /* =========================================================
           AGENDA  — Layout
           ========================================================= */
        .ag-wrap {
            display: flex;
            flex-direction: column;
            min-height: 600px;
        }

        /* ---- Toolbar ---- */
        .ag-toolbar {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 12px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            flex-wrap: wrap;
            background: rgba(255,255,255,.75);
        }

        .ag-toolbar .ag-nav {
            display: flex;
            gap: 6px;
            align-items: center;
        }

        .ag-toolbar .ag-title {
            font-weight: 800;
            font-size: 18px;
            text-transform: capitalize;
            min-width: 220px;
        }

        .ag-toolbar .ag-spacer {
            flex: 1;
        }

        .ag-views {
            display: flex;
            border: 1px solid var(--mc-stroke);
            border-radius: 12px;
            overflow: hidden;
            background: #fff;
        }

        .ag-views button {
            border: none;
            background: transparent;
            padding: 8px 14px;
            cursor: pointer;
            font-weight: 700;
            color: #475569;
        }

        .ag-views button.active {
            background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10));
            color: #0f172a;
        }

        .ag-iconbtn {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            border: 1px solid var(--mc-stroke);
            background: #fff;
            cursor: pointer;
            font-weight: 700;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }

        .ag-iconbtn:hover { background: #f8fafc; }

        .ag-btn-add {
            background: linear-gradient(135deg, #2563eb, #06b6d4);
            color: #fff;
            border: none;
            padding: 10px 14px;
            border-radius: 12px;
            cursor: pointer;
            font-weight: 800;
        }

        /* ---- Filtres ressources ---- */
        .ag-resources {
            display: flex;
            gap: 8px;
            padding: 10px 16px;
            border-bottom: 1px solid var(--mc-stroke);
            flex-wrap: wrap;
            background: #fbfcfe;
        }

        .ag-res-pill {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 999px;
            border: 1px solid var(--mc-stroke);
            background: #fff;
            font-size: 12px;
            font-weight: 700;
            cursor: pointer;
            user-select: none;
        }

        .ag-res-pill .dot {
            width: 10px;
            height: 10px;
            border-radius: 999px;
            display: inline-block;
        }

        .ag-res-pill.off {
            opacity: .35;
        }

        /* =========================================================
           VUE MOIS
           ========================================================= */
        .ag-month {
            display: grid;
            grid-template-rows: auto 1fr;
        }

        .ag-month-head {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
        }

        .ag-month-head div {
            padding: 8px;
            text-align: center;
            font-weight: 800;
            font-size: 12px;
            color: #475569;
            text-transform: uppercase;
        }

        .ag-month-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            grid-auto-rows: minmax(110px, 1fr);
        }

        .ag-day {
            border-right: 1px solid #eef2f7;
            border-bottom: 1px solid #eef2f7;
            padding: 6px;
            display: flex;
            flex-direction: column;
            gap: 4px;
            position: relative;
            background: #fff;
            min-height: 110px;
        }

        .ag-day.other {
            background: #fafbfc;
            color: #94a3b8;
        }

        .ag-day.today .ag-day-num {
            background: #2563eb;
            color: #fff;
        }

        .ag-day-num {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            font-weight: 700;
            min-width: 24px;
            height: 24px;
            padding: 0 6px;
            border-radius: 999px;
            align-self: flex-start;
        }

        .ag-event {
            font-size: 11px;
            padding: 3px 6px;
            border-radius: 6px;
            color: #fff;
            font-weight: 700;
            cursor: pointer;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            border-left: 3px solid rgba(0,0,0,.2);
        }

        .ag-event.dragging { opacity: .4; }

        .ag-day.drop-target { background: #eff6ff; }

        .ag-event-more {
            font-size: 11px;
            color: #2563eb;
            cursor: pointer;
            font-weight: 700;
        }

        /* =========================================================
           VUE SEMAINE / JOUR
           ========================================================= */
        .ag-week-wrap {
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .ag-week-allday {
            display: grid;
            border-bottom: 1px solid var(--mc-stroke);
            background: #f8fafc;
            font-size: 11px;
        }

        .ag-week-allday .lbl {
            padding: 6px 8px;
            font-weight: 700;
            color: #64748b;
            border-right: 1px solid #eef2f7;
            text-align: right;
        }

        .ag-week-allday .cell {
            padding: 4px;
            border-right: 1px solid #eef2f7;
            display: flex;
            flex-direction: column;
            gap: 2px;
            min-height: 28px;
        }

        .ag-week-head {
            display: grid;
            background: #f8fafc;
            border-bottom: 1px solid var(--mc-stroke);
            font-size: 12px;
        }

        .ag-week-head .col {
            padding: 8px;
            text-align: center;
            font-weight: 800;
            border-right: 1px solid #eef2f7;
        }

        .ag-week-head .col.today {
            color: #2563eb;
        }

        .ag-week-head .col .num {
            font-size: 18px;
            display: block;
        }

        .ag-week-body {
            display: grid;
            position: relative;
            overflow-y: auto;
            max-height: 600px;
        }

        .ag-time-col {
            border-right: 1px solid #eef2f7;
            background: #fafbfc;
        }

        .ag-time-slot {
            height: 40px;
            padding: 2px 6px;
            font-size: 11px;
            color: #64748b;
            text-align: right;
            border-bottom: 1px solid #f1f5f9;
        }

        .ag-day-col {
            border-right: 1px solid #eef2f7;
            position: relative;
            min-height: 100%;
        }

        .ag-day-col .ag-slot {
            height: 40px;
            border-bottom: 1px solid #f1f5f9;
        }

        .ag-day-col .ag-slot.half {
            border-bottom: 1px dashed #f1f5f9;
        }

        .ag-day-col.drop-target {
            background: #eff6ff;
        }

        .ag-week-event {
            position: absolute;
            left: 4px;
            right: 4px;
            border-radius: 6px;
            padding: 4px 6px;
            color: #fff;
            font-size: 11px;
            font-weight: 700;
            cursor: grab;
            overflow: hidden;
            border-left: 3px solid rgba(0,0,0,.25);
            box-shadow: 0 2px 6px rgba(0,0,0,.12);
        }

        .ag-week-event:active { cursor: grabbing; }

        .ag-week-event .ev-title {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .ag-week-event .ev-time {
            font-size: 10px;
            opacity: .9;
        }

        .ag-week-event.dragging { opacity: .5; }

        /* "Ligne du temps" actuelle */
        .ag-now-line {
            position: absolute;
            left: 0;
            right: 0;
            height: 2px;
            background: #ef4444;
            z-index: 5;
            pointer-events: none;
        }

        .ag-now-line::before {
            content: '';
            position: absolute;
            left: -5px;
            top: -4px;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #ef4444;
        }

        /* =========================================================
           Notifications / toasts
           ========================================================= */
        .ag-toast-host {
            position: fixed;
            top: 20px;
            right: 20px;
            display: flex;
            flex-direction: column;
            gap: 8px;
            z-index: 9999;
        }

        .ag-toast {
            background: #fff;
            border: 1px solid var(--mc-stroke);
            border-left: 4px solid #2563eb;
            border-radius: 10px;
            padding: 10px 14px;
            box-shadow: 0 8px 24px rgba(2,6,23,.15);
            min-width: 280px;
            max-width: 360px;
            animation: slideIn .25s ease-out;
        }

        .ag-toast .t-title {
            font-weight: 800;
            font-size: 14px;
            margin-bottom: 2px;
        }

        .ag-toast .t-body {
            font-size: 12px;
            color: #475569;
        }

        @keyframes slideIn {
            from { transform: translateX(120%); opacity: 0; }
            to   { transform: translateX(0); opacity: 1; }
        }

        /* =========================================================
           Mobile
           ========================================================= */
        @media (max-width: 768px) {
            .ag-toolbar { gap: 6px; }
            .ag-toolbar .ag-title { font-size: 14px; min-width: auto; }
            .ag-views button { padding: 6px 10px; font-size: 12px; }
            .ag-day { min-height: 70px; }
            .ag-event { font-size: 10px; padding: 2px 4px; }
        }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" Skin="Metro"></telerik:RadAjaxLoadingPanel>
    <telerik:RadWindowManager ID="rwmAgenda" runat="server" EnableShadow="true">
        <Windows>
            <telerik:RadWindow ID="rwAppointment" runat="server"
                ClientIDMode="Static"
                Modal="true"
                VisibleOnPageLoad="false"
                Behaviors="Close,Move,Resize"
                DestroyOnClose="true"
                Width="1300px"
                Height="700px"
                MinWidth="320"
                MinHeight="500"
                Title="Rendez-vous"
                OnClientClose="agOnApptClose">
            </telerik:RadWindow>
        </Windows>
    </telerik:RadWindowManager>

    <%-- ===== AJAX MANAGER : rafraîchit la zone agenda après ajout/modif/suppression ===== --%>
   
    <%-- Panel ne contenant QUE les hidden fields (pas de blocs <%= %> à l'intérieur) --%>
        <telerik:RadAjaxPanel ID="RAP1" runat="server" LoadingPanelID="RadAjaxLoadingPanel1" ClientIDMode="Static">
        <asp:HiddenField ID="hfEvents"        runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="hfEmployees"     runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="hfTypes"         runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="hfViewMode"      runat="server" ClientIDMode="Static" Value="month" />
        <asp:HiddenField ID="hfCurrentDate"   runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="hfEmployeeFilter" runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="hfMoveData"      runat="server" ClientIDMode="Static" />
      </telerik:RadAjaxPanel>
    <div class="ag-wrap">

        <!-- TOOLBAR -->
        <div class="ag-toolbar">
            <div class="ag-nav">
                <button type="button" class="ag-iconbtn" onclick="agNav(-1); return false;" title="Précédent">‹</button>
                <button type="button" class="ag-iconbtn" onclick="agNav(1); return false;"  title="Suivant">›</button>
                <button type="button" class="ag-iconbtn" onclick="agNavToday(); return false;" title="Aujourd'hui">●</button>
            </div>

            <div class="ag-title" id="agTitle">—</div>

            <div class="ag-spacer"></div>

            <div class="ag-views" role="tablist">
                <button type="button" id="vMonth" class="active" onclick="agSetView('month'); return false;">Mois</button>
                <button type="button" id="vWeek"  onclick="agSetView('week');  return false;">Semaine</button>
                <button type="button" id="vDay"   onclick="agSetView('day');   return false;">Jour</button>
            </div>

            <button type="button" class="ag-btn-add" onclick="agNewAppointment(); return false;">+ Rendez-vous</button>
        </div>

        <!-- FILTRES RESSOURCES -->
        <div class="ag-resources" id="agResources">
            <span style="font-size:12px; font-weight:700; color:#64748b; align-self:center;">Ressources :</span>
            <%-- généré par JS --%>
        </div>

        <!-- VUE MOIS -->
        <div class="ag-month" id="agMonthView">
            <div class="ag-month-head">
                <div>Lun</div><div>Mar</div><div>Mer</div><div>Jeu</div><div>Ven</div><div>Sam</div><div>Dim</div>
            </div>
            <div class="ag-month-grid" id="agMonthGrid"></div>
        </div>

        <!-- VUE SEMAINE / JOUR -->
        <div class="ag-week-wrap" id="agWeekView" style="display:none">
            <div class="ag-week-allday" id="agAllDay"></div>
            <div class="ag-week-head"   id="agWeekHead"></div>
            <div class="ag-week-body"   id="agWeekBody"></div>
        </div>

    </div>

    <!-- Hôte des toasts/rappels -->
    <div class="ag-toast-host" id="agToastHost"></div>

    <script>
        // ============================================================
        // ÉTAT GLOBAL (côté client)
        // ============================================================
        var AG = {
            view: document.getElementById('hfViewMode').value || 'month',
            currentDate: parseISODate(document.getElementById('hfCurrentDate').value) || new Date(),
            events: JSON.parse(document.getElementById('hfEvents').value || '[]'),
            employees: JSON.parse(document.getElementById('hfEmployees').value || '[]'),
            types: JSON.parse(document.getElementById('hfTypes').value || '[]'),
            empFilter: (document.getElementById('hfEmployeeFilter').value || '').split(',').filter(Boolean).map(Number),
            startHour: 7,
            endHour: 20,
            slotMinutes: 30
        };

        function parseISODate(s) {
            if (!s) return null;
            var d = new Date(s);
            return isNaN(d) ? null : d;
        }

        function fmtIso(d) {
            // YYYY-MM-DD HH:mm:ss
            var z = function (n) { return n < 10 ? '0' + n : n; };
            return d.getFullYear() + '-' + z(d.getMonth() + 1) + '-' + z(d.getDate()) + ' ' + z(d.getHours()) + ':' + z(d.getMinutes()) + ':00';
        }

        function fmtTime(d) {
            var z = function (n) { return n < 10 ? '0' + n : n; };
            return z(d.getHours()) + ':' + z(d.getMinutes());
        }

        function startOfWeek(d) {
            var x = new Date(d);
            var day = (x.getDay() + 6) % 7; // lundi = 0
            x.setDate(x.getDate() - day);
            x.setHours(0, 0, 0, 0);
            return x;
        }

        function startOfMonth(d) {
            return new Date(d.getFullYear(), d.getMonth(), 1);
        }

        function addDays(d, n) {
            var x = new Date(d);
            x.setDate(x.getDate() + n);
            return x;
        }

        function sameDay(a, b) {
            return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
        }

        function monthLabel(d) {
            return d.toLocaleDateString('fr-CA', { year: 'numeric', month: 'long' });
        }

        function dayLabel(d) {
            return d.toLocaleDateString('fr-CA', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
        }

        // ============================================================
        // RENDU TOOLBAR + RESSOURCES
        // ============================================================
        function agRenderTitle() {
            var el = document.getElementById('agTitle');
            if (AG.view === 'month') {
                el.textContent = monthLabel(AG.currentDate);
            } else if (AG.view === 'week') {
                var s = startOfWeek(AG.currentDate);
                var e = addDays(s, 6);
                el.textContent = s.toLocaleDateString('fr-CA', { day: 'numeric', month: 'short' }) + ' – ' +
                    e.toLocaleDateString('fr-CA', { day: 'numeric', month: 'short', year: 'numeric' });
            } else {
                el.textContent = dayLabel(AG.currentDate);
            }
        }

        function agRenderResources() {
            var host = document.getElementById('agResources');
            // garde le label
            host.innerHTML = '<span style="font-size:12px; font-weight:700; color:#64748b; align-self:center;">Ressources :</span>';
            AG.employees.forEach(function (emp) {
                var on = AG.empFilter.length === 0 || AG.empFilter.indexOf(emp.Id) !== -1;
                var pill = document.createElement('span');
                pill.className = 'ag-res-pill' + (on ? '' : ' off');
                pill.innerHTML = '<span class="dot" style="background:' + (emp.ColorHex || '#06b6d4') + '"></span>' + emp.FullName;
                pill.onclick = function () {
                    var idx = AG.empFilter.indexOf(emp.Id);
                    if (AG.empFilter.length === 0) {
                        // partir de "tous", ne garder que celui-ci
                        AG.empFilter = AG.employees.map(function (e) { return e.Id }).filter(function (id) { return id !== emp.Id });
                    } else if (idx === -1) {
                        AG.empFilter.push(emp.Id);
                    } else {
                        AG.empFilter.splice(idx, 1);
                    }
                    if (AG.empFilter.length === AG.employees.length) AG.empFilter = [];
                    document.getElementById('hfEmployeeFilter').value = AG.empFilter.join(',');
                    agRender();
                };
                host.appendChild(pill);
            });
        }

        // ============================================================
        // FILTRAGE
        // ============================================================
        function agFilteredEvents() {
            if (!AG.empFilter || AG.empFilter.length === 0) return AG.events;
            return AG.events.filter(function (ev) {
                if (!ev.EmployeeId) return true;
                return AG.empFilter.indexOf(ev.EmployeeId) !== -1;
            });
        }

        // ============================================================
        // VUE MOIS
        // ============================================================
        function agRenderMonth() {
            document.getElementById('agMonthView').style.display = '';
            document.getElementById('agWeekView').style.display = 'none';

            var grid = document.getElementById('agMonthGrid');
            grid.innerHTML = '';

            var first = startOfMonth(AG.currentDate);
            var firstDow = (first.getDay() + 6) % 7;
            var start = addDays(first, -firstDow);

            var today = new Date();
            today.setHours(0, 0, 0, 0);

            var events = agFilteredEvents();

            for (var i = 0; i < 42; i++) {
                var d = addDays(start, i);
                var dayEl = document.createElement('div');
                dayEl.className = 'ag-day';
                if (d.getMonth() !== AG.currentDate.getMonth()) dayEl.classList.add('other');
                if (sameDay(d, today)) dayEl.classList.add('today');

                var num = document.createElement('div');
                num.className = 'ag-day-num';
                num.textContent = d.getDate();
                dayEl.appendChild(num);

                // Drag&drop : accepter le drop
                (function (date, el) {
                    el.addEventListener('dragover', function (e) {
                        e.preventDefault();
                        el.classList.add('drop-target');
                    });
                    el.addEventListener('dragleave', function () {
                        el.classList.remove('drop-target');
                    });
                    el.addEventListener('drop', function (e) {
                        e.preventDefault();
                        el.classList.remove('drop-target');
                        var id = e.dataTransfer.getData('text/plain');
                        if (id) agMoveEvent(parseInt(id, 10), date, null);
                    });
                    el.addEventListener('dblclick', function () {
                        agNewAppointmentAt(date, null);
                    });
                })(new Date(d), dayEl);

                // Événements du jour
                var dayEvents = events.filter(function (ev) {
                    var s = new Date(ev.Start), e = new Date(ev.End);
                    return s <= addDays(d, 1) && e >= d;
                });

                var max = 3;
                dayEvents.slice(0, max).forEach(function (ev) {
                    var box = document.createElement('div');
                    box.className = 'ag-event';
                    box.style.background = ev.Color || '#2563eb';
                    box.draggable = true;
                    box.title = ev.Title + (ev.CustomerName ? ' — ' + ev.CustomerName : '');
                    var s = new Date(ev.Start);
                    box.textContent = (ev.IsAllDay ? '' : fmtTime(s) + ' ') + ev.Title;
                    box.addEventListener('click', function (e) {
                        e.stopPropagation();
                        agEditAppointment(ev.Id);
                    });
                    box.addEventListener('dragstart', function (e) {
                        e.dataTransfer.setData('text/plain', ev.Id);
                        box.classList.add('dragging');
                    });
                    box.addEventListener('dragend', function () { box.classList.remove('dragging'); });
                    dayEl.appendChild(box);
                });

                if (dayEvents.length > max) {
                    var more = document.createElement('div');
                    more.className = 'ag-event-more';
                    more.textContent = '+' + (dayEvents.length - max) + ' de plus';
                    more.onclick = function () {
                        AG.view = 'day';
                        AG.currentDate = new Date(d);
                        document.getElementById('hfViewMode').value = 'day';
                        document.getElementById('hfCurrentDate').value = fmtIso(AG.currentDate);
                        agRender();
                    };
                    dayEl.appendChild(more);
                }

                grid.appendChild(dayEl);
            }
        }

        // ============================================================
        // VUE SEMAINE / JOUR
        // ============================================================
        function agRenderWeek() {
            document.getElementById('agMonthView').style.display = 'none';
            document.getElementById('agWeekView').style.display = '';

            var isDay = (AG.view === 'day');
            var dayCount = isDay ? 1 : 7;
            var start = isDay ? new Date(AG.currentDate.getFullYear(), AG.currentDate.getMonth(), AG.currentDate.getDate()) : startOfWeek(AG.currentDate);
            start.setHours(0, 0, 0, 0);

            // Grilles
            var allday = document.getElementById('agAllDay');
            var head = document.getElementById('agWeekHead');
            var body = document.getElementById('agWeekBody');

            var cols = 'minmax(60px, 80px) repeat(' + dayCount + ', 1fr)';
            allday.style.gridTemplateColumns = cols;
            head.style.gridTemplateColumns = cols;
            body.style.gridTemplateColumns = cols;

            // Header
            var today = new Date(); today.setHours(0, 0, 0, 0);
            head.innerHTML = '<div class="col" style="background:#fafbfc;"></div>';
            allday.innerHTML = '<div class="lbl">Toute la journée</div>';

            for (var i = 0; i < dayCount; i++) {
                var d = addDays(start, i);
                var col = document.createElement('div');
                col.className = 'col' + (sameDay(d, today) ? ' today' : '');
                col.innerHTML = '<span>' + d.toLocaleDateString('fr-CA', { weekday: 'short' }) + '</span><span class="num">' + d.getDate() + '</span>';
                head.appendChild(col);

                var ad = document.createElement('div');
                ad.className = 'cell';
                allday.appendChild(ad);
            }

            // Body : col temps + colonnes jours
            body.innerHTML = '';
            var totalSlots = (AG.endHour - AG.startHour) * 2; // 30 min

            // colonne heures
            var timeCol = document.createElement('div');
            timeCol.className = 'ag-time-col';
            for (var h = AG.startHour; h < AG.endHour; h++) {
                var s1 = document.createElement('div'); s1.className = 'ag-time-slot';
                s1.textContent = (h < 10 ? '0' + h : h) + ':00';
                timeCol.appendChild(s1);
                var s2 = document.createElement('div'); s2.className = 'ag-time-slot';
                s2.textContent = '';
                timeCol.appendChild(s2);
            }
            body.appendChild(timeCol);

            var slotHeightPx = 40; // doit matcher le CSS .ag-time-slot

            var events = agFilteredEvents();
            var dayCols = [];

            for (var i = 0; i < dayCount; i++) {
                var d = addDays(start, i);
                var col = document.createElement('div');
                col.className = 'ag-day-col';
                col.style.position = 'relative';
                col.style.height = (totalSlots * slotHeightPx) + 'px';

                // slots vides + double-click pour créer
                for (var s = 0; s < totalSlots; s++) {
                    var slot = document.createElement('div');
                    slot.className = 'ag-slot' + (s % 2 ? ' half' : '');
                    (function (date, slotIdx, slotEl) {
                        slotEl.addEventListener('dblclick', function () {
                            var when = new Date(date);
                            when.setHours(AG.startHour + Math.floor(slotIdx / 2), (slotIdx % 2) * 30, 0, 0);
                            agNewAppointmentAt(when, when);
                        });
                    })(new Date(d), s, slot);
                    col.appendChild(slot);
                }

                // drop target
                (function (colEl, date) {
                    colEl.addEventListener('dragover', function (e) {
                        e.preventDefault();
                        colEl.classList.add('drop-target');
                    });
                    colEl.addEventListener('dragleave', function () {
                        colEl.classList.remove('drop-target');
                    });
                    colEl.addEventListener('drop', function (e) {
                        e.preventDefault();
                        colEl.classList.remove('drop-target');
                        var id = e.dataTransfer.getData('text/plain');
                        if (!id) return;
                        // calc position
                        var rect = colEl.getBoundingClientRect();
                        var y = e.clientY - rect.top;
                        var slotIdx = Math.max(0, Math.floor(y / slotHeightPx));
                        var newDate = new Date(date);
                        newDate.setHours(AG.startHour + Math.floor(slotIdx / 2), (slotIdx % 2) * 30, 0, 0);
                        agMoveEvent(parseInt(id, 10), newDate, newDate);
                    });
                })(col, new Date(d));

                body.appendChild(col);
                dayCols.push({ el: col, date: new Date(d) });

                // ligne "maintenant"
                if (sameDay(d, today)) {
                    var now = new Date();
                    var minSinceStart = (now.getHours() - AG.startHour) * 60 + now.getMinutes();
                    if (minSinceStart > 0 && minSinceStart < (AG.endHour - AG.startHour) * 60) {
                        var line = document.createElement('div');
                        line.className = 'ag-now-line';
                        line.style.top = (minSinceStart / 30 * slotHeightPx) + 'px';
                        col.appendChild(line);
                    }
                }
            }

            // Placement events
            events.forEach(function (ev) {
                var s = new Date(ev.Start), e = new Date(ev.End);

                // Toute la journée
                if (ev.IsAllDay) {
                    for (var i = 0; i < dayCount; i++) {
                        var d = addDays(start, i);
                        if (s <= addDays(d, 1) && e >= d) {
                            var cell = allday.children[i + 1]; // +1 pour le label
                            var pill = document.createElement('div');
                            pill.className = 'ag-event';
                            pill.style.background = ev.Color || '#2563eb';
                            pill.textContent = ev.Title;
                            pill.title = ev.Title;
                            pill.addEventListener('click', function () { agEditAppointment(ev.Id); });
                            cell.appendChild(pill);
                        }
                    }
                    return;
                }

                // Pour chaque jour visible où l'événement chevauche
                for (var i = 0; i < dayCount; i++) {
                    var col = dayCols[i];
                    var dayStart = new Date(col.date); dayStart.setHours(AG.startHour, 0, 0, 0);
                    var dayEnd = new Date(col.date); dayEnd.setHours(AG.endHour, 0, 0, 0);

                    if (e <= dayStart || s >= dayEnd) continue;

                    var evStart = s < dayStart ? dayStart : s;
                    var evEnd = e > dayEnd ? dayEnd : e;

                    var topMin = (evStart.getHours() - AG.startHour) * 60 + evStart.getMinutes();
                    var dur = Math.max(15, (evEnd - evStart) / 60000);

                    var box = document.createElement('div');
                    box.className = 'ag-week-event';
                    box.style.top = (topMin / 30 * slotHeightPx) + 'px';
                    box.style.height = (dur / 30 * slotHeightPx - 2) + 'px';
                    box.style.background = ev.Color || '#2563eb';
                    box.draggable = true;
                    box.innerHTML = '<div class="ev-time">' + fmtTime(s) + ' – ' + fmtTime(e) + '</div>' +
                        '<div class="ev-title">' + ev.Title + (ev.CustomerName ? ' · ' + ev.CustomerName : '') + '</div>';
                    box.addEventListener('click', function () { agEditAppointment(ev.Id); });
                    box.addEventListener('dragstart', function (eDrag) {
                        eDrag.dataTransfer.setData('text/plain', ev.Id);
                        box.classList.add('dragging');
                    });
                    box.addEventListener('dragend', function () { box.classList.remove('dragging'); });

                    col.el.appendChild(box);
                }
            });
        }

        // ============================================================
        // RENDU PRINCIPAL
        // ============================================================
        function agRender() {
            agRenderTitle();
            agRenderResources();
            // boutons vues
            ['Month', 'Week', 'Day'].forEach(function (v) {
                var b = document.getElementById('v' + v);
                if (b) b.classList.toggle('active', AG.view === v.toLowerCase());
            });
            if (AG.view === 'month') agRenderMonth();
            else agRenderWeek();
        }

        // ============================================================
        // NAVIGATION
        // ============================================================
        function agNav(dir) {
            if (AG.view === 'month') {
                AG.currentDate = new Date(AG.currentDate.getFullYear(), AG.currentDate.getMonth() + dir, 1);
            } else if (AG.view === 'week') {
                AG.currentDate = addDays(AG.currentDate, 7 * dir);
            } else {
                AG.currentDate = addDays(AG.currentDate, dir);
            }
            document.getElementById('hfCurrentDate').value = fmtIso(AG.currentDate);
            agReload();
        }

        function agNavToday() {
            AG.currentDate = new Date();
            document.getElementById('hfCurrentDate').value = fmtIso(AG.currentDate);
            agReload();
        }

        function agSetView(v) {
            AG.view = v;
            document.getElementById('hfViewMode').value = v;
            agReload();
        }

        function agReload() {
            // Déclenche un AjaxRequest sur le RadAjaxManager → recharge le panneau pnlAgenda
            
            var mgr = $find("RAP1");
            console.log('Reloading agenda with view='  );
            console.log(mgr);
            if (mgr) {
                
                mgr.ajaxRequest('refresh');
            }
        }

        // ============================================================
        // CRÉATION / ÉDITION
        // ============================================================
        function agNewAppointment() {
            var d = new Date(AG.currentDate);
            d.setHours(9, 0, 0, 0);
            agNewAppointmentAt(d, null);
        }

        // Largeur cible 1300, sinon la largeur de la fenêtre (mobile / petit écran)
        function agComputeWindowSize() {
            var targetW = 1300;
            var targetH = 700;
            var maxW = Math.floor(window.innerWidth * 0.98);
            var maxH = Math.floor(window.innerHeight * 0.95);
            return {
                w: Math.min(targetW, maxW),
                h: Math.min(targetH, maxH)
            };
        }

        function agOpenApptWindow(url) {
            // Régler la taille de la fenêtre AVANT de l'ouvrir
            var sz = agComputeWindowSize();

            // radopen ouvre la fenêtre identifiée par son ID dans le RadWindowManager
            var win = window.radopen(url, 'rwAppointment');
            if (!win) return;

            win.setSize(sz.w, sz.h);
            win.center();
            win.setActive(true);
        }

        function agNewAppointmentAt(date, withTime) {
            var d = new Date(date);
            if (!withTime) { d.setHours(9, 0, 0, 0); }
            agOpenApptWindow('wbfAppointmentEdit.aspx?id=0&start=' + encodeURIComponent(fmtIso(d)));
        }

        function agEditAppointment(id) {
            agOpenApptWindow('wbfAppointmentEdit.aspx?id=' + id);
        }

        function agOnApptClose(sender, args) {
            // Recharger après fermeture du popup
            // setTimeout pour laisser la fenêtre finir sa fermeture
            // avant de déclencher le postback
            setTimeout(function () {
                agReload();
            }, 50);
        }

        // ============================================================
        // DRAG & DROP : déplacement
        // ============================================================
        function agMoveEvent(id, newDate, newDateTime) {
            // Trouver l'event original pour préserver la durée
            var ev = AG.events.find(function (e) { return e.Id === id; });
            if (!ev) return;

            var oldStart = new Date(ev.Start);
            var oldEnd = new Date(ev.End);
            var duration = oldEnd - oldStart;

            var newStart;
            if (newDateTime) {
                newStart = new Date(newDateTime);
            } else {
                // garder l'heure originale, changer la date
                newStart = new Date(newDate);
                newStart.setHours(oldStart.getHours(), oldStart.getMinutes(), 0, 0);
            }
            var newEnd = new Date(newStart.getTime() + duration);

            // Envoi au serveur
            document.getElementById('hfMoveData').value =
                id + '|' + fmtIso(newStart) + '|' + fmtIso(newEnd);
            var mgr = $find('RAP1');
            if (mgr) {
                mgr.ajaxRequest('move');
            }
        }

        // ============================================================
        // RAPPELS / NOTIFICATIONS (côté client)
        // ============================================================
        function agCheckReminders() {
            var now = new Date();
            AG.events.forEach(function (ev) {
                if (!ev.ReminderMinutes) return;
                if (ev._reminded) return;
                var s = new Date(ev.Start);
                var triggerAt = new Date(s.getTime() - ev.ReminderMinutes * 60000);
                if (now >= triggerAt && now < s) {
                    agShowToast(ev.Title, 'À ' + fmtTime(s) + (ev.CustomerName ? ' — ' + ev.CustomerName : ''));
                    ev._reminded = true;
                }
            });
        }

        function agShowToast(title, body) {
            var host = document.getElementById('agToastHost');
            var t = document.createElement('div');
            t.className = 'ag-toast';
            t.innerHTML = '<div class="t-title">🔔 ' + title + '</div><div class="t-body">' + body + '</div>';
            host.appendChild(t);
            setTimeout(function () {
                t.style.transition = 'opacity .4s';
                t.style.opacity = '0';
                setTimeout(function () { host.removeChild(t); }, 400);
            }, 8000);
        }

        // Démarrage initial
        document.addEventListener('DOMContentLoaded', function () {
            agRender();
            agCheckReminders();
            setInterval(agCheckReminders, 60000); // chaque minute
        });

        // ============================================================
        // Re-rendu après chaque AjaxRequest du RadAjaxManager
        // (ajout/modif/suppression de RDV, drag&drop, navigation, etc.)
        // ============================================================
        function agReloadFromHiddenFields() {
            try {
                AG.events = JSON.parse(document.getElementById('hfEvents').value || '[]');
                AG.employees = JSON.parse(document.getElementById('hfEmployees').value || '[]');
                AG.types = JSON.parse(document.getElementById('hfTypes').value || '[]');
                AG.view = document.getElementById('hfViewMode').value || 'month';
                var dateStr = document.getElementById('hfCurrentDate').value;
                if (dateStr) {
                    var d = new Date(dateStr.replace(' ', 'T'));
                    if (!isNaN(d)) AG.currentDate = d;
                }
            } catch (e) {
                console.error('Erreur de rechargement agenda:', e);
            }
        }

        if (typeof Sys !== 'undefined' && Sys.WebForms) {
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function (sender, args) {
                if (args && args.get_error()) return;
                agReloadFromHiddenFields();
                agRender();
            });
        }
    </script>
</asp:Content>
