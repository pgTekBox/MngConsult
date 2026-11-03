<%@ Page Title="Ma journée — Portail comptable" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master"
    CodeBehind="wbfCabJournee.aspx.vb" Inherits="MngConsul.wbfCabJournee" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Ma journée — Portail comptable
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;600;700;800&display=swap">
<style>
/* ---- « Ma journée » (maquette v2) : tout est confiné sous #mj pour ne pas
      déteindre sur le reste du portail (Site.Master). ---- */
#mj{
  --encre:#0E1F3D; --encre2:#44536E; --encre3:#6A7891;
  --fond:#F2F5F9; --filet:#E3E9F1; --bord:#D5DDE8; --champ:#F7F9FC; --pastille:#E8EDF5;
  --choisi:#E3EBF7; --marine:#1B4F9C; --marine-fonce:#143A73; --nuit:#0E1F3D; --or:#D9A03C;
  --rouge:#B3261E; --rouge-pale:#FDECEC; --ambre:#9A5B00; --ambre-pale:#FFF4DF; --vert:#1E6B3A; --vert-pale:#E6F4EA;
  color:var(--encre);font-size:15px;
  font-family:Nunito,system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif;
}
#mj *{box-sizing:border-box}
#mj button,#mj select,#mj textarea,#mj input{font:inherit;color:inherit}
#mj a{color:inherit}
#mj h1{font-size:30px;font-weight:800;margin:0}
#mj .chapeau{color:var(--encre2);font-size:16px;margin:6px 0 18px}
#mj .btn{background:var(--marine);color:#fff;border:0;border-radius:999px;height:44px;padding:0 20px;font-weight:800;cursor:pointer;white-space:nowrap}
#mj .btn:hover{background:var(--marine-fonce)}
#mj .btn-ghost{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:7px 12px;font-weight:700;cursor:pointer}
#mj .btn-ghost:hover{border-color:var(--marine)}
#mj .lien{background:none;border:0;color:var(--encre2);font-weight:800;font-size:14px;cursor:pointer;padding:4px 6px;border-radius:8px}
#mj .lien:hover{background:var(--fond);color:var(--encre)}

#mj .mj-demo{display:flex;gap:8px;align-items:center;background:var(--ambre-pale);color:var(--ambre);border-radius:12px;padding:10px 14px;font-weight:700;font-size:13.5px;margin-bottom:14px}
#mj .mj-demo svg{width:18px;height:18px;flex:none}

#mj .mj-tete{display:flex;align-items:flex-end;gap:16px;flex-wrap:wrap;margin-bottom:14px}
#mj .mj-tete .chapeau{margin:4px 0 0}
#mj .mj-vue{margin-left:auto;display:flex;align-items:center;gap:10px;font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3);text-transform:uppercase}
#mj .mj-vue select{border:1px solid var(--bord);background:#fff;border-radius:12px;height:42px;padding:0 12px;font-weight:800;font-size:15px;color:var(--encre);letter-spacing:0;text-transform:none;min-width:230px}
#mj .mj-vue em{font-style:normal;background:var(--pastille);color:var(--encre2);border-radius:999px;padding:1px 7px;font-size:11px;letter-spacing:.04em}

#mj .mj-tuiles{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:16px}
#mj .mj-tuile{display:block;text-align:left;text-decoration:none;background:#fff;border:1px solid var(--filet);border-radius:18px;padding:14px 16px;cursor:pointer;color:var(--encre)}
#mj .mj-tuile:hover{border-color:var(--marine)}
#mj .mj-tuile[aria-pressed=true]{outline:3px solid var(--marine);outline-offset:-1px}
#mj .mj-tuile small{display:block;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3);text-transform:uppercase}
#mj .mj-tuile b{display:block;font-size:30px;font-weight:800;line-height:1.1;margin-top:2px}
#mj .mj-tuile span{color:var(--encre2);font-size:13.5px}
#mj .mj-tuile.rouge{border-left:6px solid var(--rouge)}#mj .mj-tuile.rouge b{color:var(--rouge)}
#mj .mj-tuile.ambre{border-left:6px solid var(--or)}#mj .mj-tuile.ambre b{color:var(--ambre)}
#mj .mj-tuile.nuit{background:var(--nuit);border-color:var(--nuit);color:#fff}
#mj .mj-tuile.nuit small{color:var(--or)}#mj .mj-tuile.nuit span{color:#C9D3E3}

#mj .mj-grille{display:grid;grid-template-columns:1fr;gap:16px;align-items:start}
#mj .mj-file{background:#fff;border:1px solid var(--filet);border-radius:20px;overflow:hidden}
#mj .mj-file-tete{display:flex;align-items:center;gap:10px 14px;flex-wrap:wrap;padding:16px 18px 6px}
#mj .mj-file-tete h2,#mj .mj-carte h2,#mj .mj-sec-tete h2{margin:0;font-size:18px;font-weight:800}
#mj .mj-puces{display:flex;gap:6px;flex-wrap:wrap;margin-left:auto}
#mj .mj-puce{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:5px 11px;font-weight:800;font-size:13px;cursor:pointer}
#mj .mj-puce i{font-style:normal;color:var(--encre3);margin-left:4px}
#mj .mj-puce[aria-pressed=true]{background:var(--nuit);border-color:var(--nuit);color:#fff}
#mj .mj-puce[aria-pressed=true] i{color:#C9D3E3}
#mj .mj-regle{margin:0;padding:0 18px 10px;color:var(--encre3);font-size:13px}
#mj .mj-filtre-actif{margin:0 18px 10px;background:var(--choisi);color:var(--marine-fonce);border-radius:10px;padding:7px 12px;font-weight:800;font-size:13.5px;display:flex;justify-content:space-between;align-items:center;gap:10px}
#mj .mj-filtre-actif[hidden]{display:none}
#mj .mj-filtre-actif button{background:none;border:0;color:var(--marine-fonce);font-weight:800;cursor:pointer;text-decoration:underline}

#mj .rang{padding:6px 16px;background:var(--champ);border-top:1px solid var(--filet);border-bottom:1px solid var(--filet);font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3);text-transform:uppercase;display:flex;gap:8px;align-items:center}
#mj .rang .n{background:var(--nuit);color:#fff;border-radius:999px;min-width:20px;height:20px;display:grid;place-items:center;font-size:11px;letter-spacing:0}
#mj .ech{display:inline-block;border-radius:999px;padding:3px 10px;font-size:12.5px;font-weight:800;white-space:nowrap}
#mj .ech.rouge{background:var(--rouge-pale);color:var(--rouge)}#mj .ech.jaune{background:var(--ambre-pale);color:var(--ambre)}#mj .ech.vert{background:var(--vert-pale);color:var(--vert)}
#mj .btn-p{background:var(--marine);color:#fff;border:0;border-radius:999px;height:38px;padding:0 16px;font-weight:800;cursor:pointer;white-space:nowrap}
#mj .btn-p:hover{background:var(--marine-fonce)}
#mj .btn-lot{background:#DCE7F6;color:var(--marine-fonce);border:0;border-radius:999px;height:38px;padding:0 14px;font-weight:800;cursor:pointer;white-space:nowrap}
#mj .vide-file{padding:30px 18px;text-align:center;color:var(--encre2)}
#mj .vide-file b{display:block;font-size:18px;color:var(--encre);margin-bottom:4px}

#mj .mj-cote{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:16px;align-items:stretch}
#mj .mj-carte{background:#fff;border:1px solid var(--filet);border-radius:20px;padding:16px 18px}
#mj .mj-carte h2{display:inline-block;margin-right:10px;margin-bottom:10px}
#mj #equipe{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:8px}
#mj .pers{width:100%;display:grid;grid-template-columns:36px minmax(0,1fr);gap:6px 10px;align-items:center;border:1px solid var(--filet);background:none;text-align:left;padding:10px;border-radius:14px;cursor:pointer;color:inherit;align-content:start}
#mj .pers:hover{background:var(--fond)}
#mj .pers[aria-pressed=true]{background:var(--choisi);border-color:var(--marine)}
#mj .pers .ini{width:36px;height:36px;border-radius:50%;background:#F2D9A6;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:13px}
#mj .pers .ini.patron{background:var(--nuit);color:var(--or)}
#mj .pers b{font-size:14.5px;line-height:1.2}
#mj .pers .nb{grid-column:1 / -1;font-weight:800;font-size:13px;color:var(--encre2);white-space:nowrap}
#mj .pers .nb.trop{color:var(--rouge)}
#mj .pers .jauge{grid-column:1 / -1;height:8px;border-radius:999px;background:var(--pastille);overflow:hidden;display:flex}
#mj .pers .jauge i{display:block;height:100%}
#mj .pers .jauge .j1{background:var(--rouge)}#mj .pers .jauge .j2{background:var(--or)}#mj .pers .jauge .j3{background:#AEBBCD}
#mj .pers .abs{grid-column:1 / -1;font-size:12.5px;font-weight:800;color:var(--ambre)}
#mj .mj-aide{display:inline;margin:8px 0 0;font-size:12.5px;color:var(--encre3)}
#mj .mj-60{background:var(--nuit);border-color:var(--nuit);color:#fff}
#mj .mj-60-t{display:flex;align-items:center;gap:10px;margin-bottom:6px}
#mj .mj-60-t h2{margin:0;color:#fff}
#mj .mj-60 p{margin:0 0 8px;color:#C9D3E3;font-size:14px;line-height:1.45}
#mj .mj-60 p b{color:var(--or);font-size:18px}
#mj .lien-fl{color:var(--or);font-weight:800;text-decoration:none;font-size:14px}

#mj .ava60{display:inline-block;width:34px;height:34px;flex:none}
#mj .ava60.grand{width:56px;height:56px}
#mj .ava60.petit{width:26px;height:26px;margin-top:1px}
#mj .ava60 svg{width:100%;height:100%;display:block}

#mj .mj-ech{margin-top:18px;background:#fff;border:1px solid var(--filet);border-radius:20px;padding:16px 18px}
#mj .mj-sec-tete{display:flex;align-items:baseline;gap:10px;flex-wrap:wrap;margin-bottom:12px}
#mj .mj-sous{color:var(--encre3);font-weight:700;font-size:13.5px}
#mj .mj-sec-tete .lien{margin-left:auto;color:var(--marine-fonce)}
#mj .mj-bande{display:grid;grid-template-columns:repeat(5,1fr);gap:8px}
#mj .sem{background:var(--champ);border-radius:14px;padding:10px;min-height:110px}
#mj .sem h3{margin:0 0 8px;font-size:12px;letter-spacing:.06em;font-weight:800;color:var(--encre3);text-transform:uppercase}
#mj .sem.charge{background:var(--ambre-pale)}
#mj .sem.charge h3::after{content:" · semaine chargée";color:var(--ambre)}
#mj .jalon{display:flex;align-items:center;gap:8px;background:#fff;border:1px solid var(--filet);border-radius:10px;padding:6px 8px;margin-bottom:6px;font-size:13px}
#mj .jalon .d{font-weight:800;min-width:42px;color:var(--encre2)}
#mj .jalon .t{flex:1;font-weight:700;line-height:1.25}
#mj .jalon .c{background:var(--nuit);color:#fff;border-radius:999px;min-width:24px;height:22px;padding:0 6px;display:grid;place-items:center;font-weight:800;font-size:12px}

/* Ligne d'activité */
#mj .ligne-a{display:grid;grid-template-columns:118px minmax(0,1fr) 112px 170px 150px;gap:4px 14px;align-items:center;padding:9px 16px 9px 14px;border-bottom:1px solid var(--filet);border-left:5px solid transparent}
#mj .ligne-a:last-child{border-bottom:0}
#mj .ligne-a:hover{background:#F7FAFE}
#mj .ligne-a.rouge{border-left-color:var(--rouge)}#mj .ligne-a.jaune{border-left-color:var(--or)}#mj .ligne-a.vert{border-left-color:#3E9B62}
#mj .ld-ech{display:flex;align-items:center;gap:7px;font-weight:800;font-size:13.5px;white-space:nowrap}
#mj .ld-ech .pt{width:9px;height:9px;border-radius:50%;flex:none}
#mj .ligne-a.rouge .ld-ech{color:var(--rouge)}#mj .ligne-a.rouge .pt{background:var(--rouge)}
#mj .ligne-a.jaune .ld-ech{color:var(--ambre)}#mj .ligne-a.jaune .pt{background:var(--or)}
#mj .ligne-a.vert .ld-ech{color:var(--vert)}#mj .ligne-a.vert .pt{background:#3E9B62}
#mj .ld-quoi{min-width:0;display:flex;flex-direction:column;gap:1px}
#mj .ld-quoi .l1{font-weight:800;font-size:15px;display:flex;align-items:center;gap:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#mj .ld-quoi .l2{font-size:13.5px;color:var(--encre2);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
#mj .ld-quoi .l2 b{color:var(--encre)}
#mj .s60{flex:none;width:20px;height:20px;border-radius:50%;background:#111;color:var(--or);font-size:9.5px;font-weight:800;display:inline-grid;place-items:center}
#mj .ld-voir{border:0;background:none;color:var(--marine-fonce);font-weight:800;font-size:13px;cursor:pointer;text-decoration:underline;padding:0 2px}
#mj .ld-mt{text-align:right;font-weight:800;font-variant-numeric:tabular-nums;font-size:14.5px}
#mj .rs{display:flex;align-items:center;gap:6px;min-width:0}
#mj .ini2{width:26px;height:26px;border-radius:50%;background:#F2D9A6;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:10.5px;flex:none}
#mj .ini2+.ini2{margin-left:-12px;box-shadow:0 0 0 2px #fff}
#mj .rs-n{font-size:13.5px;font-weight:700;color:var(--encre2);white-space:nowrap}
#mj .rs select{border:1px solid transparent;background:transparent;border-radius:8px;height:32px;padding:0 4px;font-weight:700;font-size:13.5px;color:var(--encre);min-width:0;flex:1;cursor:pointer}
#mj .rs select:hover,#mj .rs select:focus{border-color:var(--bord);background:#fff}
#mj .ld-act{display:flex;justify-content:flex-end}
#mj .ld-act .btn-p,#mj .ld-act .btn-lot{height:34px;padding:0 14px;font-size:14px;width:100%}
#mj .ld-clients{grid-column:2 / -1;display:flex;flex-wrap:wrap;gap:6px;padding:2px 0 4px}
#mj .ld-clients button{border:1px solid var(--bord);background:#fff;border-radius:999px;padding:4px 10px;font-size:13px;cursor:pointer;color:var(--encre2)}
#mj .ld-clients button b{color:var(--encre)}
#mj .ld-clients button:hover{border-color:var(--marine)}

/* Fenêtre de détail d'une activité */
#mj #d60{border:0;border-radius:22px;padding:0;color:var(--encre);width:min(900px,calc(100% - 24px));max-height:calc(100vh - 32px);box-shadow:0 24px 70px rgba(14,31,61,.38)}
#mj #d60::backdrop{background:rgba(14,31,61,.5)}
#mj #d60[open]{display:flex;flex-direction:column}
#mj .dt-tete{display:flex;gap:14px;align-items:flex-start;padding:18px 22px 14px;border-bottom:1px solid var(--filet)}
#mj .dt-id{flex:1;min-width:0}
#mj .dt-id small{font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3);text-transform:uppercase}
#mj .dt-id h2{margin:2px 0 8px;font-size:21px;line-height:1.25}
#mj .dt-meta{display:flex;gap:8px;flex-wrap:wrap;align-items:center}
#mj .dt-meta .ch{background:var(--fond);border-radius:999px;padding:4px 10px;font-size:13.5px;color:var(--encre2)}
#mj .dt-meta .ch b{color:var(--encre)}
#mj .d60-fermer{border:0;background:var(--fond);width:38px;height:38px;border-radius:50%;cursor:pointer;display:grid;place-items:center;flex:none}
#mj .d60-fermer svg{width:17px;height:17px}
#mj .dt-corps{padding:16px 22px;overflow:auto}
#mj .dt-pq{display:flex;gap:10px;align-items:baseline;flex-wrap:wrap;border-radius:12px;padding:10px 14px;font-size:14.5px;margin-bottom:12px}
#mj .dt-pq b{font-size:12px;letter-spacing:.06em;text-transform:uppercase}
#mj .dt-pq.rouge{background:var(--rouge-pale);color:#7A1A14}#mj .dt-pq.rouge b{color:var(--rouge)}
#mj .dt-pq.jaune{background:var(--ambre-pale);color:#5E3A00}#mj .dt-pq.jaune b{color:var(--ambre)}
#mj .dt-pq.vert{background:var(--vert-pale);color:#174F2C}#mj .dt-pq.vert b{color:var(--vert)}
#mj .dt-dit{display:flex;gap:10px;align-items:flex-start;margin:0 0 16px;font-weight:700;line-height:1.45}
#mj .dt-grille{display:grid;grid-template-columns:1.15fr 1fr;gap:20px}
#mj .dt-corps h3{margin:0 0 8px;font-size:12px;letter-spacing:.08em;font-weight:800;color:var(--encre3);text-transform:uppercase}
#mj .dt-corps .h3b{margin-top:16px}
#mj .dt-et{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:6px}
#mj .dt-et li{display:flex;align-items:center;gap:10px;border:1px solid var(--filet);border-radius:12px;padding:8px 10px;font-size:14.5px}
#mj .dt-et li.fait{background:var(--champ);color:var(--encre2)}
#mj .dt-et li.fait .tx{text-decoration:line-through;text-decoration-color:#AEBBCD}
#mj .dt-et li.ici{border:2px solid var(--marine);background:#F3F7FD;font-weight:800}
#mj .dt-et .tx{flex:1}
#mj .dt-et em{display:block;font-style:normal;font-size:12px;color:var(--marine);font-weight:800}
#mj .dt-et .q{min-width:54px;text-align:center;border-radius:999px;padding:3px 8px;font-size:12px;font-weight:800;color:#fff}
#mj .dt-et .q60{background:#111;color:var(--or)}#mj .dt-et .qcab{background:#C0632A}#mj .dt-et .qcli{background:#1E6B3A}
#mj .dt-et li.fait .q::after{content:" ✓"}
#mj .dt-don{display:grid;grid-template-columns:auto 1fr;gap:6px 14px;margin:0 0 14px;font-size:14.5px;background:var(--champ);border-radius:12px;padding:12px 14px}
#mj .dt-don dt{color:var(--encre3);font-weight:700}#mj .dt-don dd{margin:0;font-weight:800}
#mj .dt-pcs{list-style:none;margin:0 0 14px;padding:0;display:flex;flex-direction:column;gap:6px}
#mj .dt-pcs li{display:flex;align-items:center;gap:8px;border:1px solid var(--filet);border-radius:10px;padding:7px 10px;font-weight:700;font-size:14px;color:var(--marine-fonce)}
#mj .dt-pcs svg{width:16px;height:16px;flex:none}
#mj .dt-droit{border-left:4px solid #C0632A;background:#FBF1EA;border-radius:0 10px 10px 0;padding:8px 12px;font-size:14px;line-height:1.4}
#mj .dt-droit b{display:block;font-size:12px;letter-spacing:.06em;text-transform:uppercase;color:#C0632A}
#mj .dt-lot{width:100%;border-collapse:collapse;font-size:14px}
#mj .dt-lot th{font-size:11.5px;letter-spacing:.06em;color:var(--encre3);text-align:left;padding:6px 8px;border-bottom:1px solid var(--filet);text-transform:uppercase}
#mj .dt-lot td{padding:8px;border-bottom:1px solid var(--filet);vertical-align:middle}
#mj .dt-lot td b{display:block}#mj .dt-lot td small{color:var(--encre3)}
#mj .dt-lot .r{text-align:right;font-weight:800;white-space:nowrap}
#mj .dt-lot input{width:20px;height:20px;accent-color:var(--marine)}
#mj .dt-lot tr.exclu td{opacity:.45}#mj .dt-lot tr.exclu b{text-decoration:line-through}
#mj .d60-auto{display:flex;gap:10px;align-items:flex-start;background:#FFF8EA;border:1px solid #F1D9A6;border-radius:14px;padding:10px 12px;cursor:pointer;font-size:14px;line-height:1.4;margin-top:16px}
#mj .d60-auto input{width:20px;height:20px;accent-color:var(--marine);margin-top:1px;flex:none}
#mj .d60-auto b{display:block;color:var(--ambre);font-size:12px;letter-spacing:.06em;text-transform:uppercase}
#mj .d60-pied{display:flex;justify-content:flex-end;align-items:center;gap:10px;padding:12px 20px;border-top:1px solid var(--filet);background:var(--champ)}
#mj .dt-total{margin-right:auto;color:var(--encre2);font-size:14px}
#mj .dt-total b{color:var(--encre)}
#mj #d60-ok[disabled]{background:#AEBBCD;cursor:not-allowed}

#mj .toast{position:fixed;left:50%;bottom:24px;transform:translateX(-50%);background:var(--nuit);color:#fff;border-radius:999px;padding:12px 18px;font-weight:800;display:flex;gap:14px;align-items:center;box-shadow:0 8px 24px rgba(14,31,61,.25);z-index:60}
#mj .toast[hidden]{display:none}
#mj .toast button{background:none;border:0;color:var(--or);font-weight:800;cursor:pointer}

#mj button:focus-visible,#mj select:focus-visible,#mj a:focus-visible{outline:2px solid var(--marine);outline-offset:2px}

/* Vue d'une seule personne : on retire ce qui est de trop */
#mj.vue-perso .mj-equipe,#mj.vue-perso .mj-ech,#mj.vue-perso .mj-tuile.nuit,#mj.vue-perso .rs,#mj.vue-perso .mj-regle{display:none!important}
#mj.vue-perso .mj-tuiles{grid-template-columns:repeat(3,1fr)}
#mj.vue-perso .ligne-a{grid-template-columns:118px minmax(0,1fr) 112px 150px}
#mj .mj-perso{display:flex;flex-direction:column;gap:12px;justify-content:center}
#mj .mj-perso[hidden]{display:none}
#mj .pv-t{display:flex;align-items:center;gap:12px}
#mj .pv-t .ini{width:44px;height:44px;border-radius:50%;background:#F2D9A6;color:var(--nuit);display:grid;place-items:center;font-weight:800;font-size:15px;flex:none}
#mj .pv-t .ini.patron{background:var(--nuit);color:var(--or)}
#mj .pv-t h2{margin:0!important;font-size:18px}
#mj .pv-t small{display:block;color:var(--encre3);font-weight:700}
#mj .pv-retour{margin-left:auto;color:var(--marine-fonce)}
#mj .pv-note{margin:0;background:var(--choisi);color:var(--marine-fonce);border-radius:10px;padding:8px 12px;font-weight:800;font-size:13.5px}
#mj .pv-note.abs{background:var(--ambre-pale);color:var(--ambre)}
#mj .pv-note.trop{background:var(--rouge-pale);color:var(--rouge)}

@media (max-width:1180px){#mj .mj-cote{grid-template-columns:1fr}#mj #equipe{grid-template-columns:repeat(3,minmax(0,1fr))}#mj .mj-bande{grid-template-columns:repeat(3,1fr)}}
@media (max-width:1100px){
  #mj .ligne-a{grid-template-columns:104px minmax(0,1fr) 150px 140px}#mj .ld-mt{display:none}
  #mj.vue-perso .ligne-a{grid-template-columns:104px minmax(0,1fr) 140px}
}
@media (max-width:860px){
  #mj .mj-tuiles{grid-template-columns:1fr 1fr}
  #mj #equipe{grid-template-columns:1fr 1fr}
  #mj .mj-bande{grid-template-columns:repeat(auto-fit,minmax(150px,1fr))}
  #mj .sem{min-width:0}
  #mj .mj-vue{margin-left:0;width:100%}#mj .mj-vue select{flex:1;min-width:0}
  #mj .mj-puces{margin-left:0}
}
@media (max-width:760px){
  #mj .ligne-a{grid-template-columns:minmax(0,1fr) auto;gap:4px 10px}
  #mj .ld-ech{grid-column:1;grid-row:1}
  #mj .ld-quoi{grid-column:1 / -1;grid-row:2}
  #mj .ld-quoi .l1,#mj .ld-quoi .l2{white-space:normal}
  #mj .ld-mt{display:block;grid-column:2;grid-row:1}
  #mj .rs{grid-column:1;grid-row:3}
  #mj .ld-act{grid-column:2;grid-row:3}
  #mj .ld-act .btn-p,#mj .ld-act .btn-lot{width:auto}
  #mj .ld-clients{grid-column:1 / -1}
  #mj.vue-perso .ligne-a{grid-template-columns:minmax(0,1fr) auto}#mj.vue-perso .mj-tuiles{grid-template-columns:1fr 1fr}
  #mj .dt-grille{grid-template-columns:1fr}#mj .dt-tete,#mj .dt-corps{padding-left:16px;padding-right:16px}#mj .d60-pied{flex-wrap:wrap}#mj .dt-total{flex-basis:100%}
}
@media (max-width:520px){#mj #equipe{grid-template-columns:1fr}}
</style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
<div id="mj">
  <div class="mj-demo">
    <svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 8v5M12 16h.01"/></svg>
    Données de démonstration — « Ma journée » n'est pas encore branchée sur vos vraies tâches.
  </div>

  <div class="mj-tete">
    <div>
      <h1>Ma journée</h1>
      <p class="chapeau" id="mj-date"></p>
    </div>
    <label class="mj-vue">Connecté comme <em>démo</em>
      <select id="f-qui" aria-label="Personne connectée (démo)"></select>
    </label>
  </div>

  <div class="mj-tuiles" role="group" aria-label="Filtres rapides">
    <button type="button" class="mj-tuile rouge" data-filtre="urgent"><small>Urgent</small><b id="k-urg">0</b><span>échéance dans 2 jours ou moins</span></button>
    <button type="button" class="mj-tuile ambre" data-filtre="semaine"><small>Cette semaine</small><b id="k-sem">0</b><span>de 3 à 7 jours</span></button>
    <button type="button" class="mj-tuile" data-filtre="s60"><small>Préparé par 60</small><b id="k-60">0</b><span>attend votre validation</span></button>
    <a class="mj-tuile nuit" href="wbfCabDemandes.aspx"><small>Clients non associés</small><b>3</b><span>attendent votre réponse</span></a>
  </div>

  <div class="mj-grille">
    <aside class="mj-cote" aria-label="L'équipe et 60">
      <section class="mj-carte mj-perso" id="perso" hidden></section>
      <section class="mj-carte mj-equipe">
        <h2>Charge de l'équipe</h2>
        <div id="equipe"></div>
        <p class="mj-aide">Changez la personne d'une ligne dans la liste pour réattribuer.</p>
      </section>
      <section class="mj-carte mj-60">
        <div class="mj-60-t"><span class="ava60" data-c="violet" aria-hidden="true"></span><h2>60 a fait aujourd'hui</h2></div>
        <p><b id="n60fait">0</b> activités faites seul pour vos clients : relevés importés, dépenses classées, relances envoyées.</p>
        <a href="wbfCabAvatar60.aspx" class="lien-fl">Voir les Activités de l'Avatar 60 ›</a>
      </section>
    </aside>

    <section class="mj-file" aria-labelledby="h-file">
      <div class="mj-file-tete">
        <h2 id="h-file">À faire, dans l'ordre</h2>
        <div class="mj-puces" id="f-bloc" role="group" aria-label="Filtrer par bloc"></div>
      </div>
      <p class="mj-regle">Ordre : échéances gouvernementales proches, puis l'argent qui attend, puis le client qui attend une réponse, puis ce que 60 signale.</p>
      <div id="mj-filtre-actif" class="mj-filtre-actif" hidden></div>
      <div id="file"></div>
    </section>
  </div>

  <section class="mj-ech" aria-labelledby="h-ech">
    <div class="mj-sec-tete"><h2 id="h-ech">Échéances des 30 prochains jours</h2><span class="mj-sous">Nombre de clients touchés</span></div>
    <div class="mj-bande" id="echeances"></div>
  </section>

  <dialog id="d60" aria-labelledby="d60-titre">
    <div class="dt-tete">
      <span class="ava60 grand" id="d60-ava" aria-hidden="true"></span>
      <div class="dt-id">
        <small id="d60-bloc"></small>
        <h2 id="d60-titre"></h2>
        <div class="dt-meta" id="d60-meta"></div>
      </div>
      <button type="button" class="d60-fermer" id="d60-fermer" aria-label="Fermer"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><path d="M6 6l12 12M18 6L6 18"/></svg></button>
    </div>
    <div class="dt-corps">
      <div class="dt-pq" id="d60-pq"><b>Pourquoi maintenant</b><span id="d60-pq-t"></span></div>
      <p class="dt-dit"><span class="ava60 petit" id="d60-ava2" aria-hidden="true"></span><span id="d60-dit"></span></p>
      <div class="dt-grille">
        <section>
          <h3 id="d60-g-t">Les étapes</h3>
          <div id="d60-gauche"></div>
        </section>
        <section>
          <h3>Ce que 60 a préparé</h3>
          <dl class="dt-don" id="d60-prep"></dl>
          <div id="d60-pcs-z"><h3>Pièces</h3><ul class="dt-pcs" id="d60-pcs"></ul></div>
          <div class="dt-droit"><b>Autorisation</b><span id="d60-droit"></span></div>
        </section>
      </div>
      <label class="d60-auto"><input type="checkbox" id="d60-auto"><span><b>Proposition de 60</b><span id="d60-auto-t"></span></span></label>
    </div>
    <div class="d60-pied">
      <span class="dt-total" id="d60-total"></span>
      <button type="button" class="btn-ghost" id="d60-tard">Plus tard</button>
      <button type="button" class="btn" id="d60-ok"></button>
    </div>
  </dialog>

  <div class="toast" id="toast" role="status" hidden><span id="toast-tx"></span><button type="button" id="toast-annuler">Annuler</button></div>
</div>

<script type="text/javascript">
(function(){
const MJ=document.getElementById('mj');
// Données réelles injectées par le serveur (tâches/membres du cabinet), ou null.
var SRV = <asp:Literal ID="litData" runat="server" />;
const REEL = !!(SRV && SRV.reel);
let AUJ=new Date(2026,10,2); // démo
let PERS=[
  {id:'lb',nom:'Louise Bérubé',role:'Associée',patron:true,cap:6},
  {id:'lg',nom:'Léa Gagné',role:'Technicienne comptable',cap:8},
  {id:'lu',nom:'Luc Charbonneau',role:'Technicien comptable',cap:8},
  {id:'mt',nom:'Marie Tremblay',role:'Technicienne comptable',cap:8,abs:"Absente jusqu'au 4 novembre · Luc la remplace",remp:'lu'},
  {id:'sg',nom:'Sophie Gagnon',role:'Adjointe',cap:8}];
let CLI=[
 ['Marc Allard','électricien','lg'],['Annie Roy','photographe','sg'],['Luc Gendron','consultant TI','lb'],['Julie Fortin','designer','sg'],
 ['Pierre Ménard','menuisier','lu'],['Nathalie Bisson','nutritionniste','sg'],['Garage Lapointe','mécanique','lg'],['Boulangerie Côté','boulangerie','lu'],
 ['Sylvie Dion','massothérapeute','sg'],['Excavation Brodeur','excavation','lg'],['Clinique vétérinaire Sutton','vétérinaire','lb'],['Café du Mont','restaurant','mt'],
 ['Jean Ouellet','plombier','lu'],['Atelier Vachon','ébénisterie','mt'],['Karine Lefebvre','coiffeuse','sg'],['Toitures Gagnon','couvreur','lg'],
 ['Studio Lumen','vidéo','mt'],['Paysagement Roy','paysagiste','lu'],['Éric Fortier','traducteur','sg'],['Ferme Bélanger','agriculture','lb'],
 ['Gîte des Pins','hébergement','mt'],['Dre Caroline Morin','dentiste','lb'],['Transport Lussier','camionnage','lg'],['Martin Paquette','programmeur','sg'],
 ['Épicerie Tanguay','épicerie','lu'],['Isabelle Roy','physiothérapeute','sg'],['Rénovations Pelletier','rénovation','lg'],['Chocolaterie Brome','chocolaterie','mt'],
 ['Simon Lavoie','architecte','lb'],['Yoga Sutton','studio de yoga','sg']].map(([nom,metier,p],i)=>({i,nom,metier,p}));
let A={
 das:{t:'Déclencher la remise des retenues à la source',bloc:'Paiements',type:'gouv',verbe:'Déclencher',s60:1,lot:1,
   dit:c=>`J'ai calculé les retenues d'octobre de ${c}. Le solde bancaire couvre la remise.`,prep:(c,m)=>[['Période','Octobre 2026'],['À remettre',m],['Destinataires','Revenu Québec et ARC']],
   auto:"Déclencher automatiquement les prochaines remises de ce client, dans ses plafonds."},
 tps:{t:'Réviser et produire la déclaration TPS/TVQ',bloc:'Taxes de vente',type:'gouv',verbe:'Produire',s60:1,lot:1,
   dit:c=>`La déclaration de ${c} est prête. L'écart avec la période précédente est normal.`,prep:(c,m)=>[['Période','Juillet à septembre 2026'],['À remettre',m],['Transactions','214']],
   auto:"Vous avertir seulement si l'écart dépasse 15 % avec la période précédente."},
 paie:{t:'Valider la paie',bloc:'Paie',type:'argent',verbe:'Valider',s60:1,lot:1,
   dit:c=>`La paie de ${c} est calculée. Les heures viennent de l'application des employés.`,prep:(c,m)=>[['Employés','3'],['Net à verser',m],['Dépôt prévu','Jeudi']],
   auto:"Valider automatiquement quand rien ne change par rapport à la dernière paie."},
 fact:{t:'Approuver les factures fournisseurs',bloc:'Paiements',type:'argent',verbe:'Approuver',s60:1,lot:1,
   dit:c=>`J'ai lu et classé les factures de ${c}. Les montants respectent ses plafonds.`,prep:(c,m)=>[['Factures','4'],['Total',m],['Plus proche échéance','Jeudi']],
   auto:"Approuver automatiquement les factures récurrentes de moins de 500 $."},
 question:{t:'Répondre à la question du client',bloc:'Échanges',type:'attend',verbe:'Répondre',
   dit:c=>`${c} attend une réponse. J'ai préparé un brouillon à partir de son dossier.`,prep:(c,m,x)=>[['Question',x||'Une dépense peut-elle être déduite ?'],['Brouillon','Prêt, à réviser']],
   auto:"Répondre moi-même aux questions semblables, avec votre validation."},
 docs:{t:'Relancer pour les documents manquants',bloc:'Fin de mois',type:'attend',verbe:'Relancer',lot:1,
   dit:c=>`Il manque des documents à ${c} pour fermer septembre.`,prep:(c,m,x)=>[['Document',x||'Relevé de carte de crédit'],['Relances faites','1']],
   auto:"Relancer automatiquement chaque semaine jusqu'à réception."},
 liquid:{t:'Manque de liquidités prévu',bloc:'Signalé par 60',type:'signal',verbe:'Voir',
   dit:c=>`D'après mes prévisions, le compte de ${c} passera sous zéro. Le client est avisé.`,prep:(c,m,x)=>[['Point bas',x||'−640 $ le 12 novembre'],['Cause','Acompte et loyer la même semaine']],
   auto:"Proposer au client de reporter un paiement non urgent."},
 seuil:{t:'Seuil des taxes en vue : inscrire le client',bloc:'Taxes de vente',type:'signal',verbe:'Inscrire',
   dit:c=>`Les ventes de ${c} atteignent 91 % du seuil de 30 000 $ sur 4 trimestres.`,prep:()=>[['Ventes 4 trimestres','27 400 $'],['Dépassement prévu','Janvier 2027']],
   auto:"Préparer l'inscription pour que le client la signe en un geste."},
 concil:{t:"Approuver la conciliation bancaire d'octobre",bloc:'Fin de mois',type:'autre',verbe:'Approuver',s60:1,lot:1,
   dit:c=>`La banque de ${c} est conciliée. Il ne reste aucun écart.`,prep:()=>[['Mois','Octobre 2026'],['Écart','0,00 $']],
   auto:"Approuver automatiquement quand l'écart est nul."},
 classer:{t:"Régler les transactions que 60 n'a pas su classer",bloc:'Fin de mois',type:'autre',verbe:'Régler',s60:1,lot:1,
   dit:c=>`J'ai classé presque tout pour ${c}. Il reste quelques transactions incertaines.`,prep:()=>[['Incertaines','3'],['Total','501,95 $']],
   auto:"Apprendre de vos choix et ne plus vous demander ces cas."},
 t2:{t:'Vérifier et transmettre la T2 et la CO-17',bloc:"Fin d'année",type:'gouv',verbe:'Transmettre',s60:1,lot:1,
   dit:c=>`J'ai produit les déclarations de société de ${c} avec les livres fermés.`,prep:()=>[['Exercice','Clos le 31 juillet 2026'],['Impôt à payer','2 140,00 $']],
   auto:"Vous rappeler 30 jours avant chaque échéance de société."}};
const DET={
 das:{pq:'Une remise en retard entraîne une pénalité de 3 % à 10 % du montant.',pcs:['Sommaire des retenues d’octobre.pdf'],
   droit:'Le client vous autorise à déclencher ses remises, jusqu’à 10 000 $ par mois.',
   et:[['60','Retenues d’octobre calculées',1],['60','Solde bancaire vérifié : suffisant',1],['cab','Vérifier le montant et déclencher la remise',0],['60','Confirmer au client et inscrire au journal',0]]},
 tps:{pq:'Après l’échéance, des intérêts et une pénalité s’ajoutent au solde dû.',pcs:['Brouillon TPS-TVQ.pdf','Détail des taxes par mois.xlsx'],
   droit:'Vous révisez et produisez la déclaration ; le client la voit dans son application.',
   et:[['60','Taxes calculées sur 214 transactions',1],['60','Comparaison avec la période précédente : +6 %',1],['cab','Réviser et produire la déclaration',0],['cli','Voir la déclaration produite',0]]},
 paie:{pq:'Les employés doivent être payés jeudi ; le dépôt prend un jour ouvrable.',pcs:['Registre de paie.pdf'],
   droit:'60 calcule, vous validez ; le client déclenche la paie ou vous y autorise.',
   et:[['60','Heures reçues de l’application des employés',1],['60','Paie et retenues calculées',1],['cab','Valider la paie, employé par employé',0],['cli','Déclencher la paie, ou vous y autoriser',0]]},
 fact:{pq:'Payer à temps évite les frais de retard ; deux factures offrent un escompte de 2 %.',pcs:['Factures fournisseurs (4).pdf'],
   droit:'Le client approuve avec vous, dans ses plafonds : 2 500 $ par paiement, 10 000 $ par mois.',
   et:[['60','Factures lues, classées et taxes extraites',1],['60','Plafonds du client vérifiés',1],['cab','Approuver les factures',0],['cli','Déclencher les paiements, ou vous y autoriser',0]]},
 question:{pq:'Le client attend une réponse ; une réponse rapide garde sa confiance.',pcs:[],
   droit:'Échanges entre le client et votre cabinet, rattachés à son dossier.',
   et:[['cli','Question posée dans son application',1],['60','Brouillon de réponse préparé à partir du dossier',1],['cab','Réviser et envoyer la réponse',0]]},
 docs:{pq:'Sans ces documents, septembre ne peut pas être fermé.',pcs:[],
   droit:'Demandes de documents faites au nom de votre cabinet.',
   et:[['60','Document manquant repéré',1],['60','Première relance envoyée',1],['cab','Relancer le client',0],['cli','Déposer le document',0]]},
 liquid:{pq:'Agir avant la date du point bas évite un découvert et des frais.',pcs:['Prévision de trésorerie, 30 jours.pdf'],
   droit:'60 avertit ; le conseil revient à votre cabinet.',
   et:[['60','Prévision de trésorerie sur 30 jours',1],['60','Client avisé',1],['cab','Conseiller le client : reporter, financer ou ajuster',0]]},
 seuil:{pq:'Au-delà de 30 000 $, le client doit percevoir les taxes dès la vente suivante.',pcs:[],
   droit:'60 avertit ; l’inscription se fait par le client ou par votre cabinet.',
   et:[['60','Ventes des 4 derniers trimestres calculées',1],['cab','Préparer l’inscription aux taxes',0],['cli','Signer l’inscription',0]]},
 concil:{pq:'La conciliation approuvée permet de fermer octobre.',pcs:['Conciliation bancaire d’octobre.pdf'],
   droit:'Votre signature sur la fin de mois.',
   et:[['60','Banque importée et appariée',1],['60','Écart vérifié : 0,00 $',1],['cab','Approuver la conciliation',0]]},
 classer:{pq:'Ces transactions empêchent de fermer le mois.',pcs:[],
   droit:'Votre cabinet tranche ; 60 retient la règle.',
   et:[['60','Transactions classées, sauf 3',1],['cab','Choisir le bon compte pour les 3 transactions',0],['60','Retenir la règle pour la prochaine fois',0]]},
 t2:{pq:'Les déclarations de société doivent être produites 6 mois après la fin d’exercice.',pcs:['T2 2026.pdf','CO-17 2026.pdf','États financiers 2026.pdf'],
   droit:'La fiscalité reste chez vous ; la transmission se fait au choix du client.',
   et:[['60','Livres fermés et déclarations produites',1],['cab','Vérifier la T2 et la CO-17',0],['cli','Signer l’autorisation de transmission',0],['cab','Transmettre aux gouvernements',0]]}};
Object.keys(DET).forEach(k=>Object.assign(A[k],DET[k]));
const QUI={'60':['60','q60'],cab:['Vous','qcab'],cli:['Client','qcli']};
let AMT=['das','paie','fact','tps'];
const RANGS=['','Échéance gouvernementale proche',"L'argent attend",'Le client attend une réponse','60 signale','Le reste, par échéance'];
let N=0; let T=[];
const add=(c,a,j,x)=>T.push({id:++N,c,a,j,x,resp:CLI[c].p==='mt'?'lu':CLI[c].p,fait:false});
[0,6,9,22].forEach(c=>add(c,'das',1)); add(2,'tps',2); add(21,'tps',2);
add(7,'paie',1); add(24,'paie',1); add(11,'paie',2); add(26,'paie',4);
add(9,'fact',3); add(15,'fact',3); add(4,'fact',5);
add(1,'question',0,'Peut-elle déduire son nouvel objectif photo ?'); add(18,'question',1,'Doit-il facturer la TPS à un client en France ?'); add(29,'question',2,'Comment payer ses professeurs à contrat ?');
add(3,'docs',4,'Relevé Visa de septembre'); add(16,'docs',6,'Factures de sous-traitants'); add(13,'docs',6,'Relevé de marge de crédit');
add(5,'liquid',10,'−640 $ le 12 novembre'); add(20,'liquid',6,'−1 280 $ le 8 novembre');
add(3,'seuil',14);
[12,17,19,25,28].forEach(c=>add(c,'concil',6)); add(7,'classer',5); add(27,'classer',5);
add(19,'t2',27);
const montant=t=>{const v=((t.id*7919)%4800+350)+((t.id*37)%100)/100;return v.toLocaleString('fr-CA',{minimumFractionDigits:2,maximumFractionDigits:2})+' $'};

// Bascule sur les données réelles (tâches/membres du cabinet) si présentes.
if(REEL){
  AUJ=new Date(SRV.auj[0],SRV.auj[1],SRV.auj[2]);
  PERS=SRV.pers.map(p=>({id:p.id,nom:p.nom,role:p.role||'',patron:!!p.patron,cap:p.cap||8}));
  CLI=SRV.cli.map(c=>({i:c.i,nom:c.nom,metier:c.metier||'',p:c.p}));
  A=SRV.a; AMT=[];
  T=SRV.t.map(x=>({id:x.id,taskId:x.taskId,c:x.c,a:x.a,j:x.j,resp:x.resp,x:x.x,fait:false}));
  // Pas de bandeau ni de commutateur « connecté comme » en mode réel.
  const _d=MJ.querySelector('.mj-demo'); if(_d) _d.style.display='none';
  const _v=MJ.querySelector('.mj-vue'); if(_v) _v.style.display='none';
  const _dn=MJ.querySelector('.mj-tuile.nuit b'); if(_dn) _dn.textContent=(SRV.demandes!=null?SRV.demandes:0);
}

const rang=t=>{const a=A[t.a];return a.type==='gouv'&&t.j<=2?1:a.type==='argent'?2:a.type==='attend'?3:a.type==='signal'?4:5};
const coul=j=>j<=2?'rouge':j<=7?'jaune':'vert';
const echLib=j=>j<=0?"Aujourd'hui":j===1?'Demain':`Dans ${j} jours`;
const ini=n=>n.replace(/^Dre? /,'').split(/\s+/).map(x=>x[0]).slice(0,2).join('').toUpperCase();
const P=id=>PERS.find(p=>p.id===id);
const esc=s=>String(s).replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const $=s=>MJ.querySelector(s),$$=s=>[...MJ.querySelectorAll(s)];
// Avatar 60 : même visuel que l'assistant mauve (bas de page) — visage à traits
// blancs, sans anneau doré. La couleur du disque indique la priorité (rouge =
// urgent, jaune = cette semaine, vert = à jour) ; violet = neutre (identique à
// l'assistant). Cf. le SVG de #iaBouton dans Site.Master.
const AVC={rouge:'#E35D55',jaune:'#F2C14E',vert:'#6CC28A',violet:'#5E35C9',blanc:'#FFFFFF'};
const ava=c=>`<svg viewBox="0 0 256 256"><circle cx="128" cy="128" r="104" fill="${AVC[c]||AVC.violet}"/><circle cx="96" cy="120" r="16" fill="none" stroke="#FFFFFF" stroke-width="12"/><path d="M80 120 C78 93 90 77 113 78" fill="none" stroke="#FFFFFF" stroke-width="12" stroke-linecap="round"/><ellipse cx="162" cy="106" rx="15" ry="25" fill="none" stroke="#FFFFFF" stroke-width="12" transform="rotate(12 160 110)"/><path d="M148 68 q16 -9 30 0" fill="none" stroke="#FFFFFF" stroke-width="9" stroke-linecap="round"/><path d="M108 170 q20 6 40 -6" fill="none" stroke="#FFFFFF" stroke-width="10" stroke-linecap="round"/></svg>`;

let U=REEL?SRV.me:'lb'; const F={qui:(REEL&&!SRV.patron)?(SRV.me):'tous',tuile:'',bloc:'tous'};
let ouverts={}, courant=null, dernier=null;

function visibles(sansBloc){return T.filter(t=>!t.fait&&(F.qui==='tous'||t.resp===F.qui)&&
  (F.tuile===''||(F.tuile==='urgent'&&t.j<=2)||(F.tuile==='semaine'&&t.j>2&&t.j<=7)||(F.tuile==='s60'&&A[t.a].s60))&&
  (sansBloc||F.bloc==='tous'||A[t.a].bloc===F.bloc))}

function rendre(){
  const base=T.filter(t=>!t.fait&&(F.qui==='tous'||t.resp===F.qui));
  const clientsOuverts=new Set(base.map(t=>t.c)).size;
  const _dj=AUJ.toLocaleDateString('fr-CA',{weekday:'long',day:'numeric',month:'long'});
  const _djc=_dj.charAt(0).toUpperCase()+_dj.slice(1);
  $('#mj-date').textContent=`${_djc} · ${base.length} actions ouvertes pour ${clientsOuverts} clients${F.qui!=='tous'&&P(U)&&P(U).patron&&P(F.qui)?' · '+P(F.qui).nom:''}`;
  $('#f-qui').innerHTML=PERS.map(p=>`<option value="${p.id}" ${U===p.id?'selected':''}>${p.nom} · ${p.patron?'associée':'employé'}${p.abs?' (absente)':''}</option>`).join('');
  const moi=P(U)||{patron:false}, patron=!!moi.patron;
  $('#k-urg').textContent=base.filter(t=>t.j<=2).length;
  $('#k-sem').textContent=base.filter(t=>t.j>2&&t.j<=7).length;
  $('#k-60').textContent=base.filter(t=>A[t.a].s60).length;
  $$('[data-filtre]').forEach(b=>b.setAttribute('aria-pressed',String(F.tuile===b.dataset.filtre)));
  const fa=$('#mj-filtre-actif');
  fa.hidden=!F.tuile; if(F.tuile) fa.innerHTML=`<span>Filtre : ${({urgent:'urgent',semaine:'cette semaine',s60:'préparé par 60'})[F.tuile]}</span><button type="button" data-raz>Tout voir</button>`;

  const sb=visibles(true), blocs=[...new Set(sb.map(t=>A[t.a].bloc))];
  if(F.bloc!=='tous'&&!blocs.includes(F.bloc)) F.bloc='tous';
  $('#f-bloc').innerHTML=[['tous','Tous',sb.length]].concat(blocs.map(b=>[b,b,sb.filter(t=>A[t.a].bloc===b).length])).map(([k,l,n])=>`<button type="button" class="mj-puce" data-bloc="${esc(k)}" aria-pressed="${F.bloc===k}">${esc(l)}<i>${n}</i></button>`).join('');

  const L=visibles(false);
  let h='';
  for(let r=1;r<=5;r++){
    const lr=L.filter(t=>rang(t)===r).sort((x,y)=>x.j-y.j); if(!lr.length) continue;
    h+=`<div class="rang"><span class="n">${r}</span>${RANGS[r]}</div>`;
    const vus=new Set();
    lr.forEach(t=>{
      if(vus.has(t.id)) return;
      const g=A[t.a].lot?lr.filter(x=>x.a===t.a):[t];
      g.forEach(x=>vus.add(x.id));
      const a=A[t.a], j=Math.min(...g.map(x=>x.j)), c=coul(j), lot=g.length>1;
      const tot=AMT.includes(t.a)?g.reduce((s,x)=>s+parseFloat(montant(x).replace(/\s/g,'').replace(',','.')),0):0;
      const mt=tot?tot.toLocaleString('fr-CA',{minimumFractionDigits:2,maximumFractionDigits:2})+' $':'';
      const noms=g.map(x=>CLI[x.c].nom);
      const qui=lot?`<b>${noms.length} clients</b> · ${esc(noms.slice(0,2).join(', '))}${noms.length>2?` et ${noms.length-2} autre${noms.length>3?'s':''}`:''}`
                   :`<b>${esc(CLI[t.c].nom)}</b> · ${esc(CLI[t.c].metier)}`;
      const gens=[...new Set(g.map(x=>x.resp))];
      const nomCourt=id=>{const pp=P(id);return pp?pp.nom.split(' ')[0]:'—';};
      const resp=lot?`<span class="rs">${gens.map(id=>`<span class="ini2" title="${P(id)?P(id).nom:''}">${P(id)?ini(P(id).nom):'?'}</span>`).join('')}<span class="rs-n">${gens.length>1?gens.length+' personnes':nomCourt(gens[0])}</span></span>`
                    :(REEL?`<span class="rs"><span class="ini2">${P(t.resp)?ini(P(t.resp).nom):'?'}</span><span class="rs-n">${nomCourt(t.resp)}</span></span>`
                          :`<span class="rs"><span class="ini2">${ini(P(t.resp).nom)}</span><select data-resp="${t.id}" aria-label="Personne responsable">${PERS.map(p=>`<option value="${p.id}" ${t.resp===p.id?'selected':''}>${p.nom.split(' ')[0]}${p.abs?' (absente)':''}</option>`).join('')}</select></span>`);
      const key=t.a+'-'+r;
      h+=`<div class="ligne-a ${c}">
        <span class="ld-ech"><span class="pt"></span>${echLib(j)}</span>
        <span class="ld-quoi">
          <span class="l1">${esc(a.t)}${a.s60?'<span class="s60" title="Préparé par 60">60</span>':''}</span>
          <span class="l2">${qui}${lot?` <button type="button" class="ld-voir" data-voir="${key}" aria-expanded="${!!ouverts[key]}">${ouverts[key]?'masquer':'voir'}</button>`:''}</span>
        </span>
        <span class="ld-mt">${mt}</span>
        ${resp}
        <span class="ld-act">${lot?`<button type="button" class="btn-lot" data-lot="${g.map(x=>x.id).join(',')}">Faire en lot (${g.length})</button>`:`<button type="button" class="btn-p" data-ouvrir="${t.id}">${a.verbe}</button>`}</span>
        ${lot&&ouverts[key]?`<div class="ld-clients">${g.map(x=>`<button type="button" data-ouvrir="${x.id}"><b>${esc(CLI[x.c].nom)}</b>${AMT.includes(x.a)?` · ${montant(x)}`:''} · ${P(x.resp).nom.split(' ')[0]}</button>`).join('')}</div>`:''}
      </div>`;
    });
  }
  $('#file').innerHTML=h||`<div class="vide-file"><b>Rien à faire ici</b>Changez le filtre ou la personne.</div>`;

  const ouv=T.filter(t=>!t.fait);
  $('#equipe').innerHTML=PERS.map(p=>{
    const m=ouv.filter(t=>t.resp===p.id), a=m.filter(t=>t.j<=2).length, s=m.filter(t=>t.j>2&&t.j<=7).length, l=m.length-a-s, trop=a+s>p.cap, w=n=>Math.min(100,n/12*100);
    return `<button type="button" class="pers" data-pers="${p.id}" aria-pressed="${F.qui===p.id}">
      <span class="ini ${p.patron?'patron':''}">${ini(p.nom)}</span>
      <span><b>${p.nom}</b></span><span class="nb ${trop?'trop':''}">${a} urgentes · ${a+s} sem.</span>
      <span class="jauge" title="${a} urgentes, ${s} cette semaine, ${l} plus tard"><i class="j1" style="width:${w(a)}%"></i><i class="j2" style="width:${w(s)}%"></i><i class="j3" style="width:${w(l)}%"></i></span>
      ${p.abs?`<span class="abs">${p.abs}</span>`:trop?`<span class="abs" style="color:var(--rouge)">Semaine trop chargée : réattribuez une action</span>`:''}
    </button>`}).join('');

  const J=[['3 nov','Remises (remetteurs accélérés)',4,0],['6 nov','Paies de la semaine',9,0],['13 nov','Paies de la semaine',9,1],['15 nov','Remises des retenues à la source',14,1],['20 nov','Paies de la semaine',9,2],['27 nov','Paies de la semaine',9,3],['30 nov',"TPS/TVQ mensuelles d'octobre",7,4],['1er déc','Fermeture de novembre',30,4]];
  const S=['2 au 8 nov.','9 au 15 nov.','16 au 22 nov.','23 au 29 nov.','30 nov. au 1er déc.'];
  $('#echeances').innerHTML=S.map((s,i)=>{const js=J.filter(x=>x[3]===i),tot=js.reduce((a,x)=>a+x[2],0);
    return `<div class="sem ${tot>=20&&i<4?'charge':''}"><h3>${s}</h3>${js.map(x=>`<div class="jalon"><span class="d">${x[0]}</span><span class="t">${x[1]}</span><span class="c">${x[2]}</span></div>`).join('')}</div>`}).join('');

  const perso=F.qui!=='tous';
  MJ.classList.toggle('vue-perso',perso);
  if(perso){
    const pp=P(F.qui), m=ouv.filter(t=>t.resp===pp.id), u=m.filter(t=>t.j<=2).length, sm=m.filter(t=>t.j>2&&t.j<=7).length;
    const remp=PERS.find(x=>x.remp===pp.id);
    const note=pp.abs?`<p class="pv-note abs">Absente jusqu'au 4 novembre. Ses actions sont dans la journée de ${P(pp.remp).nom}, qui la remplace.</p>`
      :remp?`<p class="pv-note">${patron?`${pp.nom.split(' ')[0]} remplace`:'Vous remplacez'} ${remp.nom} jusqu'au 4 novembre : ses actions sont incluses ici.</p>`
      :(u+sm>pp.cap?`<p class="pv-note trop">${patron?`La semaine de ${pp.nom.split(' ')[0]} est trop chargée : réattribuez une action.`:'Votre semaine est chargée : parlez-en à votre responsable.'}</p>`:'');
    $('#perso').innerHTML=`<div class="pv-t"><span class="ini ${pp.patron?'patron':''}">${ini(pp.nom)}</span><div><h2>${patron?`Journée de ${pp.nom}`:`Bonjour ${pp.nom.split(' ')[0]}`}</h2><small>${pp.role}</small></div>${patron?`<button type="button" class="lien pv-retour" data-pers="${pp.id}">← Tout le cabinet</button>`:''}</div>${note}`;
  }
  $('#perso').hidden=!perso;
}

let exclus=new Set();
function etapesHtml(a){
  const premier=a.et.findIndex(e=>!e[2]);
  return `<ol class="dt-et">${a.et.map((e,i)=>`<li class="${e[2]?'fait':i===premier?'ici':''}"><span class="q ${QUI[e[0]][1]}">${QUI[e[0]][0]}</span><span class="tx">${esc(e[1])}${i===premier?'<em>À faire maintenant</em>':''}</span></li>`).join('')}</ol>`;
}
function majTotal(g,a){
  const inc=g.filter(x=>!exclus.has(x.id));
  if(g.length>1){
    const tot=AMT.includes(a.k)?inc.reduce((s,x)=>s+parseFloat(montant(x).replace(/\s/g,'').replace(',','.')),0):0;
    $('#d60-total').innerHTML=`<b>${inc.length}</b> sur ${g.length} inclus${tot?` · <b>${tot.toLocaleString('fr-CA',{minimumFractionDigits:2,maximumFractionDigits:2})} $</b>`:''}`;
    $('#d60-ok').textContent=`${a.verbe} pour ${inc.length>1?'les '+inc.length:inc.length===1?'1 client':'0'}`;
    $('#d60-ok').disabled=!inc.length;
  } else { $('#d60-total').textContent=''; $('#d60-ok').disabled=false; }
}
function ouvrir(ids){
  const g=ids.map(id=>T.find(t=>t.id===id)), t=g[0], a=A[t.a], j=Math.min(...g.map(x=>x.j)), c=coul(j);
  a.k=t.a; courant=ids; exclus=new Set();
  $('#d60-ava').innerHTML=ava(c); $('#d60-ava2').innerHTML=ava(c);
  $('#d60-bloc').textContent=a.bloc+(a.s60?' · préparé par 60':'');
  $('#d60-pq').className='dt-pq '+c; $('#d60-pq-t').textContent=a.pq||''; $('#d60-pq').style.display=a.pq?'':'none';
  $('#d60-pcs').innerHTML=(a.pcs||[]).map(n=>`<li><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2h9l5 5v15H6zM14 2v6h6"/></svg>${esc(n)}</li>`).join('');
  $('#d60-pcs-z').hidden=!(a.pcs&&a.pcs.length);
  $('#d60-droit').textContent=a.droit||''; var _dr=$('.dt-droit'); if(_dr)_dr.style.display=a.droit?'':'none';
  if(g.length===1){
    const cn=CLI[t.c].nom;
    $('#d60-titre').textContent=a.t;
    $('#d60-meta').innerHTML=`<span class="ch"><b>${esc(cn)}</b>${CLI[t.c].metier?', '+esc(CLI[t.c].metier):''}</span><span class="ech ${c}">${echLib(t.j)}</span><span class="ch">Responsable : <b>${P(t.resp)?P(t.resp).nom:'—'}</b></span>`;
    const ditTxt=(typeof a.dit==='function')?a.dit(cn):(a.dit||t.x||''); $('#d60-dit').textContent=ditTxt; var _dd=$('.dt-dit'); if(_dd)_dd.style.display=ditTxt?'':'none';
    let prepA=(typeof a.prep==='function')?a.prep(cn,montant(t),t.x):(a.prep||[]);
    if(!prepA.length) prepA=[['Dossier',cn],['Échéance',echLib(t.j)],['Responsable',P(t.resp)?P(t.resp).nom:'—']];
    $('#d60-prep').innerHTML=prepA.map(([k,v])=>`<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join('');
    if(a.et&&a.et.length){$('#d60-g-t').textContent='Les étapes';$('#d60-gauche').innerHTML=etapesHtml(a);}
    else{$('#d60-g-t').textContent="Ce qu'il faut faire";$('#d60-gauche').innerHTML=`<p style="color:var(--encre2);line-height:1.5;margin:0">${esc(t.x||a.t)}</p>`;}
    $('#d60-ok').textContent=a.verbe==='Voir'?'Je m’en occupe':`${a.verbe} maintenant`;
  } else {
    $('#d60-titre').textContent=`${a.t} : ${g.length} clients`;
    $('#d60-meta').innerHTML=`<span class="ech ${c}">${echLib(j)}</span><span class="ch">Traitement en lot</span><span class="ch">Responsables : <b>${[...new Set(g.map(x=>P(x.resp)?P(x.resp).nom.split(' ')[0]:'—'))].join(', ')}</b></span>`;
    $('#d60-dit').textContent=`J'ai tout préparé pour les ${g.length} clients. Chaque action sera faite au nom de son client, avec ses propres chiffres, et inscrite à son journal. Décochez un client pour le garder pour plus tard.`; var _dd2=$('.dt-dit'); if(_dd2)_dd2.style.display='';
    $('#d60-g-t').textContent='Les clients du lot';
    $('#d60-gauche').innerHTML=`<table class="dt-lot"><thead><tr><th></th><th>Client</th>${AMT.includes(t.a)?'<th class="r">Montant</th>':''}<th>Échéance</th></tr></thead><tbody>${g.map(x=>`<tr data-tr="${x.id}"><td><input type="checkbox" checked data-inc="${x.id}" aria-label="Inclure ${esc(CLI[x.c].nom)}"></td><td><b>${esc(CLI[x.c].nom)}</b><small>${P(x.resp)?esc(P(x.resp).nom):''}</small></td>${AMT.includes(t.a)?`<td class="r">${montant(x)}</td>`:''}<td><span class="ech ${coul(x.j)}">${echLib(x.j)}</span></td></tr>`).join('')}</tbody></table>${a.et&&a.et.length?`<h3 class="h3b">Les étapes, pour chaque client</h3>${etapesHtml(a)}`:''}`;
    const prepL=(typeof a.prep==='function')?a.prep(CLI[t.c].nom,montant(t),t.x).filter(([k])=>!/montant|à remettre|net|total/i.test(k)):[];
    $('#d60-prep').innerHTML=prepL.map(([k,v])=>`<dt>${esc(k)}</dt><dd>${esc(v)}</dd>`).join('')||'<dt>Lot</dt><dd>Prêt</dd>';
  }
  majTotal(g,a);
  var _au=$('.d60-auto'); if(_au)_au.style.display=a.auto?'':'none';
  $('#d60-auto').checked=false; $('#d60-auto-t').textContent=a.auto?(g.length>1?a.auto.replace('de ce client','de ces clients').replace('ce client','ces clients').replace('ses plafonds','leurs plafonds'):a.auto):'';
  $('#d60').showModal();
}
$('#d60').addEventListener('change',e=>{const id=e.target.dataset.inc;if(!id)return;const n=+id;e.target.checked?exclus.delete(n):exclus.add(n);e.target.closest('tr').classList.toggle('exclu',!e.target.checked);const g=courant.map(x=>T.find(t=>t.id===x));majTotal(g,A[g[0].a])});
function toast(tx,annulable){$('#toast-tx').textContent=tx;$('#toast-annuler').hidden=!annulable;$('#toast').hidden=false;clearTimeout(toast.t);toast.t=setTimeout(()=>{$('#toast').hidden=true;dernier=null},10000)}
function poster(op,ids){if(!REEL||!ids||!ids.length)return;try{fetch(location.pathname,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:'op='+op+'&ids='+encodeURIComponent(ids.filter(Boolean).join(','))}).catch(()=>{});}catch(e){}}
$('#d60-ok').addEventListener('click',()=>{
  const g=courant.filter(id=>!exclus.has(id)).map(id=>T.find(t=>t.id===id)); if(!g.length) return;
  poster('done',g.map(x=>x.taskId));
  g.forEach(t=>t.fait=true); dernier=g.map(t=>t.id);
  const auto=$('#d60-auto').checked; $('#d60').close(); rendre();
  toast(`${g.length>1?g.length+' actions faites':'Fait'} et ${g.length>1?'inscrites au journal de chaque client':'inscrit au journal du client'}.${auto?' 60 s’en chargera la prochaine fois.':''}`,true);
});
$('#d60-tard').addEventListener('click',()=>$('#d60').close());
$('#d60-fermer').addEventListener('click',()=>$('#d60').close());
$('#d60').addEventListener('click',e=>{if(e.target===$('#d60'))$('#d60').close()});
$('#toast-annuler').addEventListener('click',()=>{if(dernier){poster('undo',dernier.map(id=>{const tt=T.find(t=>t.id===id);return tt&&tt.taskId;}));dernier.forEach(id=>{const tt=T.find(t=>t.id===id);if(tt)tt.fait=false;});dernier=null;$('#toast').hidden=true;rendre()}});

MJ.addEventListener('click',e=>{
  const b=e.target.closest('button'); if(!b||b.closest('#d60')) return;
  if(b.dataset.filtre){F.tuile=F.tuile===b.dataset.filtre?'':b.dataset.filtre;rendre()}
  else if(b.dataset.raz!==undefined){F.tuile='';rendre()}
  else if(b.dataset.bloc){F.bloc=b.dataset.bloc;rendre()}
  else if(b.dataset.pers&&P(U)&&P(U).patron){F.qui=F.qui===b.dataset.pers?'tous':b.dataset.pers;rendre()}
  else if(b.dataset.voir){ouverts[b.dataset.voir]=!ouverts[b.dataset.voir];rendre()}
  else if(b.dataset.lot){ouvrir(b.dataset.lot.split(',').map(Number))}
  else if(b.dataset.ouvrir){ouvrir([+b.dataset.ouvrir])}
});
MJ.addEventListener('change',e=>{
  if(e.target.id==='f-qui'){U=e.target.value;F.qui=P(U).patron?'tous':U;F.tuile='';F.bloc='tous';rendre()}
  else if(e.target.dataset.resp){const t=T.find(x=>x.id==e.target.dataset.resp);t.resp=e.target.value;rendre();toast(`${A[t.a].t} : confiée à ${P(t.resp).nom}.`);dernier=null}
});
$('.ava60[data-c]').innerHTML=ava($('.ava60[data-c]').dataset.c||'violet');
$('#n60fait').textContent=REEL?(SRV.n60!=null?SRV.n60:0):47;
rendre();
})();
</script>
</asp:Content>
