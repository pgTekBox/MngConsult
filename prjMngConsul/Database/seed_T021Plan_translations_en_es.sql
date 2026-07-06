-- =============================================================
-- Traductions EN/ES des forfaits affichés sur la landing (cartes).
-- Remplit les colonnes _en/_es utilisées par RenderPlanCard :
-- Name, Tagline, EmployeeRange, BadgeText, Description, Features.
-- (DescriptionLong n'est pas rendu par les cartes → non traduit.)
-- Réexécutable : réécrit simplement les mêmes valeurs.
-- =============================================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
DECLARE @nl NCHAR(2) = NCHAR(13) + NCHAR(10);

-- ---------- solo : Travailleur Autonome ----------
UPDATE dbo.T021Plan SET
    Name_en          = N'Self-Employed',
    Name_es          = N'Trabajador Autónomo',
    Tagline_en       = N'Not incorporated',
    Tagline_es       = N'Sin incorporación',
    EmployeeRange_en = N'0 employees',
    EmployeeRange_es = N'0 empleados',
    Description_en   = N'Ideal for the self-employed, non-incorporated worker who wants to manage their finances simply.',
    Description_es   = N'Ideal para el trabajador autónomo no incorporado que quiere gestionar sus finanzas de forma sencilla.',
    Features_en      = N'Client management with calendar' + @nl + N'Client invoicing' + @nl + N'Supplier management' + @nl + N'Full chart of accounts' + @nl + N'Real-time financial statements' + @nl + N'Government remittances' + @nl + N'AI assistant' + @nl + N'Point of sale (POS)',
    Features_es      = N'Gestión de clientes con calendario' + @nl + N'Facturación de clientes' + @nl + N'Gestión de proveedores' + @nl + N'Plan contable completo' + @nl + N'Estados financieros en tiempo real' + @nl + N'Remesas gubernamentales' + @nl + N'Asistente de IA' + @nl + N'Punto de venta (TPV)'
WHERE Code = 'solo';

-- ---------- comsolo : Compagnie Solo ----------
UPDATE dbo.T021Plan SET
    Name_en          = N'Solo Corporation',
    Name_es          = N'Empresa Individual',
    Tagline_en       = N'Incorporated',
    Tagline_es       = N'Con incorporación',
    EmployeeRange_en = N'0 employees',
    EmployeeRange_es = N'0 empleados',
    BadgeText_en     = N'Most popular',
    BadgeText_es     = N'El más popular',
    Description_en   = N'For the incorporated entrepreneur who chooses not to pay themselves a salary.',
    Description_es   = N'Para el empresario incorporado que decide no pagarse un salario.',
    Features_en      = N'Everything in the Self-Employed plan' + @nl + N'Incorporated business accounting' + @nl + N'Dividends & mixed compensation' + @nl + N'Year-end close & opening' + @nl + N'Bank account connection' + @nl + N'Automated financial reconciliation',
    Features_es      = N'Todo del plan Trabajador Autónomo' + @nl + N'Contabilidad de empresa incorporada' + @nl + N'Dividendos y remuneración mixta' + @nl + N'Cierre y apertura de año' + @nl + N'Conexión de cuenta bancaria' + @nl + N'Conciliación financiera automatizada'
WHERE Code = 'comsolo';

-- ---------- com119 : Compagnie 1–19 ----------
UPDATE dbo.T021Plan SET
    Name_en          = N'Company 1–19',
    Name_es          = N'Empresa 1–19',
    Tagline_en       = N'1 to 9 employees',
    Tagline_es       = N'1 a 9 empleados',
    EmployeeRange_en = N'1–19 employees',
    EmployeeRange_es = N'1–19 empleados',
    Description_en   = N'Designed for growing SMBs with a team of full-time employees.',
    Description_es   = N'Diseñado para pymes en crecimiento con un equipo de empleados a tiempo completo.',
    Features_en      = N'Everything in the Solo Corporation plan' + @nl + N'Payroll for up to 19 employees' + @nl + N'Employee portal & pay stubs' + @nl + N'Leave & sick-day management' + @nl + N'Contracts & T4A' + @nl + N'HR compliance alerts',
    Features_es      = N'Todo del plan Empresa Individual' + @nl + N'Nómina para hasta 19 empleados' + @nl + N'Portal del empleado y recibos de pago' + @nl + N'Gestión de vacaciones y bajas' + @nl + N'Contratos y T4A' + @nl + N'Alertas de cumplimiento de RR. HH.'
WHERE Code = 'com119';
GO
