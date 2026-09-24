<%@ Page Title="" Language="vb" AutoEventWireup="false" MasterPageFile="~/Site.Master" ValidateRequest="false"
    CodeBehind="wbfPaieAnneeEdit.aspx.vb" Inherits="prjSec60Admin.wbfPaieAnneeEdit" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Paie — Taux de l'année — Sec60Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <style>
        .pe-wrap { padding: 4px 0 30px; }
        .pe-top { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; flex-wrap: wrap; margin-bottom: 14px; }
        .pe-title { font-size: 22px; font-weight: 900; }
        .pe-sub { font-size: 13px; color: #64748b; margin-top: 4px; line-height: 1.5; }
        .pe-bar { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
        .pe-btn { cursor: pointer; border: 1px solid #e2e8f0; border-radius: 12px !important; padding: 10px 12px; font-weight: 800; font-family: inherit;
                  background: linear-gradient(135deg, rgba(37,99,235,.14), rgba(6,182,212,.10)); color: #0f172a; text-decoration: none; display: inline-block; }
        .pe-btn.primary { border-color: rgba(37,99,235,.4); background: rgba(37,99,235,.08); color: #1d4ed8; }
        .pe-btn.ok { border-color: rgba(22,163,74,.4); background: rgba(22,163,74,.08); color: #15803d; }
        .pe-btn.danger { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: #dc2626; }
        .pe-msg { padding: 10px 12px; border-radius: 12px; font-weight: 700; font-size: 13px; border: 1px solid #e2e8f0; background: #fff; margin-bottom: 12px; white-space: pre-line; }
        .pe-msg.bad { border-color: rgba(220,38,38,.35); background: rgba(220,38,38,.08); color: #dc2626; }
        .pe-msg.ok { border-color: rgba(22,163,74,.35); background: rgba(22,163,74,.08); color: #16a34a; }
        .pe-badge { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 800; vertical-align: middle; margin-left: 8px; }
        .pe-badge.V { background: rgba(22,163,74,.12); color: #15803d; }
        .pe-badge.B { background: rgba(245,158,11,.14); color: #b45309; }
        .pe-card { background: #fff; border: 1px solid rgba(226,232,240,.9); border-radius: 16px; box-shadow: 0 12px 28px rgba(15,23,42,.08); overflow: hidden; margin-bottom: 14px; }
        .pe-head { padding: 12px 16px; border-bottom: 1px solid #e2e8f0; display: flex; justify-content: space-between; align-items: center; gap: 10px; flex-wrap: wrap; }
        .pe-head .h { font-weight: 900; }
        .pe-head .s { font-size: 12px; color: #64748b; }
        .pe-body { padding: 14px 16px; }
        .pe-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
        .pe-grid.g2 { grid-template-columns: 1fr 1fr; }
        @media (max-width: 1100px) { .pe-grid { grid-template-columns: repeat(2, 1fr); } }
        @media (max-width: 600px) { .pe-grid, .pe-grid.g2 { grid-template-columns: 1fr; } }
        .f label { display: block; font-size: 12px; color: #334155; margin-bottom: 5px; font-weight: 700; }
        .f .inp, .f .ta { width: 100%; box-sizing: border-box; padding: 9px 11px; border: 1px solid #e2e8f0; border-radius: 12px; outline: none; background: #fff; font-family: inherit; color: #0f172a; font-size: 14px; }
        .f .inp:focus, .f .ta:focus { border-color: rgba(37,99,235,.5); box-shadow: 0 0 0 4px rgba(37,99,235,.12); }
        .f .ta { min-height: 64px; resize: vertical; }
        .f .hint { font-size: 11px; color: #64748b; margin-top: 4px; }
        table.tr { border-collapse: collapse; width: 100%; max-width: 640px; }
        table.tr th, table.tr td { padding: 4px 6px; text-align: left; font-size: 13px; }
        table.tr th { color: #334155; font-weight: 700; }
        table.tr .inp { width: 100%; box-sizing: border-box; padding: 7px 10px; border: 1px solid #e2e8f0; border-radius: 10px; font-family: inherit; }
        .pe-verif { display: grid; grid-template-columns: 1fr 1fr auto; gap: 12px; align-items: end; max-width: 620px; }
        table.res { border-collapse: collapse; margin-top: 12px; font-size: 13.5px; }
        table.res th, table.res td { border: 1px solid #e2e8f0; padding: 6px 12px; text-align: right; }
        table.res th:first-child, table.res td:first-child { text-align: left; }
        table.res th { background: #f8fafc; }
        .pe-warn { background: rgba(245,158,11,.10); border: 1px solid rgba(245,158,11,.35); color: #92400e; border-radius: 12px; padding: 10px 12px; font-size: 13px; margin-bottom: 12px; }
    </style>
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">
    <div class="pe-wrap">
        <div class="pe-top">
            <div>
                <div class="pe-title">Taux de l'année <asp:Literal ID="litAnnee" runat="server" /><asp:Literal ID="litBadge" runat="server" /></div>
                <div class="pe-sub"><asp:Literal ID="litEtat" runat="server" /></div>
            </div>
            <div class="pe-bar">
                <a class="pe-btn" href="wbfPaieAnnees.aspx">← Liste des années</a>
                <asp:Button ID="btnSupprimer" runat="server" CssClass="pe-btn danger" Text="Supprimer ce brouillon" Visible="false"
                    OnClientClick="return confirm('Supprimer ce brouillon ? Les valeurs saisies seront perdues.');" />
                <asp:Button ID="btnDevalider" runat="server" CssClass="pe-btn" Text="Retirer la validation" Visible="false"
                    OnClientClick="return confirm('Retirer la validation ? 60secPaie refusera les paies de cette année jusqu\'à une nouvelle validation.');" />
                <asp:Button ID="btnSave" runat="server" CssClass="pe-btn primary" Text="Enregistrer" />
                <asp:Button ID="btnValider" runat="server" CssClass="pe-btn ok" Text="Enregistrer et valider" Visible="false"
                    OnClientClick="return confirm('Valider cette année ? 60secPaie l\'utilisera pour toutes les paies datées de cette année, dans les cinq minutes.');" />
            </div>
        </div>

        <asp:Panel ID="pnlMsg" runat="server" Visible="false">
            <p id="pMsg" runat="server" class="pe-msg"></p>
        </asp:Panel>
        <asp:Panel ID="pnlValidee" runat="server" Visible="false" CssClass="pe-warn">
            Cette année est <b>validée</b> : elle sert aux paies. Modifiez-la seulement pour une édition de mi-année des guides
            (les paies déjà confirmées ne changent pas) ; enregistrez ensuite, la validation est conservée.
        </asp:Panel>

        <!-- Source -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Source</div><div class="s">D'où viennent ces valeurs, pour qui les relira.</div></div>
            <div class="pe-body">
                <div class="pe-grid g2">
                    <div class="f"><label>Guides utilisés</label><asp:TextBox ID="txtSource" runat="server" CssClass="inp" MaxLength="300" />
                        <div class="hint">ex. : T4127 (124e édition, janvier 2027, ARC) ; TP-1015.F (2027-01, Revenu Québec)</div></div>
                    <div class="f"><label>Note</label><asp:TextBox ID="txtNote" runat="server" CssClass="ta" TextMode="MultiLine" /></div>
                </div>
            </div>
        </div>

        <!-- Impôt fédéral -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Impôt fédéral — T4127, employé du Québec</div><div class="s">Taux en fraction : 0.14 pour 14 %.</div></div>
            <div class="pe-body">
                <table class="tr">
                    <tr><th>Tranche</th><th>Revenu imposable annuel jusqu'à</th><th>Taux (R)</th><th>Constante (K)</th></tr>
                    <tr><td>1</td><td><asp:TextBox ID="txtFedS1" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedT1" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedC1" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>2</td><td><asp:TextBox ID="txtFedS2" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedT2" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedC2" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>3</td><td><asp:TextBox ID="txtFedS3" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedT3" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedC3" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>4</td><td><asp:TextBox ID="txtFedS4" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedT4" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedC4" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>5</td><td><asp:TextBox ID="txtFedS5" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedT5" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedC5" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>6</td><td><asp:TextBox ID="txtFedS6" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedT6" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtFedC6" runat="server" CssClass="inp" /></td></tr>
                </table>
                <div class="f"><div class="hint">La dernière tranche utilisée porte « * » comme seuil (sans plafond). Laissez vides les lignes inutiles.</div></div>
                <div class="pe-grid" style="margin-top:12px">
                    <div class="f"><label>Montant personnel de base (TC par défaut)</label><asp:TextBox ID="txtFedMontantPersonnelBase" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux des crédits (taux le plus bas)</label><asp:TextBox ID="txtFedTauxCredits" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Montant canadien pour emploi (CEA)</label><asp:TextBox ID="txtFedMontantEmploi" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Abattement du Québec</label><asp:TextBox ID="txtFedAbattementQuebec" runat="server" CssClass="inp" /><div class="hint">0.165 = 16,5 %</div></div>
                    <div class="f"><label>Crédit fonds de travailleurs — taux (LCF)</label><asp:TextBox ID="txtFedCreditFondsTravailleursTaux" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Crédit fonds de travailleurs — maximum</label><asp:TextBox ID="txtFedCreditFondsTravailleursMax" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Forfaitaire — seuil du taux fixe</label><asp:TextBox ID="txtFedSeuilForfaitaireTauxFixe" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Forfaitaire — taux fixe (Québec)</label><asp:TextBox ID="txtFedTauxFixeForfaitaireQuebec" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- Assurance-emploi -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Assurance-emploi — taux du Québec</div><div class="s">T4127, chapitre AE.</div></div>
            <div class="pe-body">
                <div class="pe-grid">
                    <div class="f"><label>Maximum de la rémunération assurable</label><asp:TextBox ID="txtAEMaxAssurable" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux de l'employé</label><asp:TextBox ID="txtAETaux" runat="server" CssClass="inp" /><div class="hint">0.013 = 1,30 %</div></div>
                    <div class="f"><label>Cotisation maximale de l'employé</label><asp:TextBox ID="txtAEMaxEmploye" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- Impôt du Québec -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Impôt du Québec — TP-1015.F</div><div class="s">Taux en fraction.</div></div>
            <div class="pe-body">
                <table class="tr">
                    <tr><th>Tranche</th><th>Revenu imposable annuel jusqu'à</th><th>Taux (T)</th><th>Constante (K)</th></tr>
                    <tr><td>1</td><td><asp:TextBox ID="txtQcS1" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcT1" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcC1" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>2</td><td><asp:TextBox ID="txtQcS2" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcT2" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcC2" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>3</td><td><asp:TextBox ID="txtQcS3" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcT3" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcC3" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>4</td><td><asp:TextBox ID="txtQcS4" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcT4" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcC4" runat="server" CssClass="inp" /></td></tr>
                    <tr><td>5</td><td><asp:TextBox ID="txtQcS5" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcT5" runat="server" CssClass="inp" /></td><td><asp:TextBox ID="txtQcC5" runat="server" CssClass="inp" /></td></tr>
                </table>
                <div class="pe-grid" style="margin-top:12px">
                    <div class="f"><label>Montant personnel de base (ligne 10 par défaut)</label><asp:TextBox ID="txtQcMontantPersonnelBase" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux des crédits</label><asp:TextBox ID="txtQcTauxCredits" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Déduction pour travailleur — taux (H)</label><asp:TextBox ID="txtQcDeductionTravailleurTaux" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Déduction pour travailleur — maximum annuel</label><asp:TextBox ID="txtQcDeductionTravailleurMax" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Crédit fonds de travailleurs — taux</label><asp:TextBox ID="txtQcCreditFondsTravailleursTaux" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Fonds de travailleurs — maximum annuel</label><asp:TextBox ID="txtQcFondsTravailleursMaxAnnuel" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Forfaitaire — seuil du taux fixe</label><asp:TextBox ID="txtQcSeuilForfaitaireTauxFixe" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Forfaitaire — taux fixe</label><asp:TextBox ID="txtQcTauxFixeForfaitaire" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- RRQ -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Régime de rentes du Québec</div><div class="s">TP-1015.F et Retraite Québec.</div></div>
            <div class="pe-body">
                <div class="pe-grid">
                    <div class="f"><label>Maximum des gains admissibles (MGA)</label><asp:TextBox ID="txtRRQMaxGainsAdmissibles" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Exemption générale</label><asp:TextBox ID="txtRRQExemption" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux total (base + 1re supplémentaire)</label><asp:TextBox ID="txtRRQTaux" runat="server" CssClass="inp" /><div class="hint">0.063 = 6,3 %</div></div>
                    <div class="f"><label>Taux de base</label><asp:TextBox ID="txtRRQTauxBase" runat="server" CssClass="inp" /><div class="hint">0.053 = 5,3 % ; sert au crédit K2Q</div></div>
                    <div class="f"><label>Cotisation maximale de l'employé</label><asp:TextBox ID="txtRRQMaxEmploye" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Cotisation maximale — partie de base</label><asp:TextBox ID="txtRRQMaxBaseEmploye" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Maximum supplémentaire (MSGA, 2e cotisation)</label><asp:TextBox ID="txtRRQ2MaxSupplementaire" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>2e cotisation supplémentaire — taux</label><asp:TextBox ID="txtRRQ2Taux" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>2e cotisation supplémentaire — maximum</label><asp:TextBox ID="txtRRQ2MaxEmploye" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- RQAP -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Régime québécois d'assurance parentale</div><div class="s">TP-1015.F.</div></div>
            <div class="pe-body">
                <div class="pe-grid">
                    <div class="f"><label>Maximum de la rémunération assurable</label><asp:TextBox ID="txtRQAPMaxAssurable" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux de l'employé</label><asp:TextBox ID="txtRQAPTauxEmploye" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Cotisation maximale de l'employé</label><asp:TextBox ID="txtRQAPMaxEmploye" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux de l'employeur</label><asp:TextBox ID="txtRQAPTauxEmployeur" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Cotisation maximale de l'employeur</label><asp:TextBox ID="txtRQAPMaxEmployeur" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- FSS -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Fonds des services de santé</div><div class="s">TP-1015.F, partie 5. Taux en pourcentage (4.26 = 4,26 %). Formule : constante + coefficient × masse en millions.</div></div>
            <div class="pe-body">
                <div class="pe-grid">
                    <div class="f"><label>Taux du secteur public</label><asp:TextBox ID="txtFSSTauxSecteurPublic" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Masse salariale — plancher</label><asp:TextBox ID="txtFSSMassePlancher" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Masse salariale — plafond</label><asp:TextBox ID="txtFSSMassePlafond" runat="server" CssClass="inp" /></div>
                    <div class="f"></div>
                    <div class="f"><label>Secteur général — constante</label><asp:TextBox ID="txtFSSGeneralConstante" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Secteur général — coefficient</label><asp:TextBox ID="txtFSSGeneralCoefficient" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Primaire et manufacturier — constante</label><asp:TextBox ID="txtFSSPrimaireConstante" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Primaire et manufacturier — coefficient</label><asp:TextBox ID="txtFSSPrimaireCoefficient" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- CNESST / CNT -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">CNESST et normes du travail</div><div class="s">Décision de la CNESST ; Revenu Québec pour la CNT.</div></div>
            <div class="pe-body">
                <div class="pe-grid">
                    <div class="f"><label>Salaire maximum assurable (CNESST)</label><asp:TextBox ID="txtCNESSTMaxAssurable" runat="server" CssClass="inp" /></div>
                    <div class="f"><label>Taux de la cotisation aux normes du travail (CNT)</label><asp:TextBox ID="txtCNTTaux" runat="server" CssClass="inp" /><div class="hint">0.0006 = 0,06 %</div></div>
                    <div class="f"><label>Salaire maximum assujetti à la CNT</label><asp:TextBox ID="txtCNTMaxAssujetti" runat="server" CssClass="inp" /></div>
                </div>
            </div>
        </div>

        <!-- Vérification -->
        <div class="pe-card">
            <div class="pe-head"><div class="h">Vérifier avec un exemple</div><div class="s">Calcule avec les valeurs saisies ci-dessus, sans les enregistrer. Comparez avec l'exemple des guides ou le calculateur en ligne.</div></div>
            <div class="pe-body">
                <div class="pe-verif">
                    <div class="f"><label>Salaire brut annuel</label><asp:TextBox ID="txtVBrut" runat="server" CssClass="inp" Text="60000" /></div>
                    <div class="f"><label>Périodes de paie par année</label><asp:TextBox ID="txtVPeriodes" runat="server" CssClass="inp" Text="26" /></div>
                    <div><asp:Button ID="btnVerifier" runat="server" CssClass="pe-btn" Text="Calculer" /></div>
                </div>
                <asp:Literal ID="litVerif" runat="server" />
            </div>
        </div>
    </div>
</asp:Content>
