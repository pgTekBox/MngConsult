SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================================
-- T120PlanComptable_Classe : descriptions de classes multilingues (fr/en/es).
-- DescriptionFr = Description existante. DescriptionEn/Es = traductions.
-- Mapping par CODE (clé ASCII stable, identique entre compagnies).
-- Idempotent : colonnes ajoutées si absentes, puis (re)peuplées.
-- =============================================================

IF COL_LENGTH('dbo.T120PlanComptable_Classe', 'DescriptionFr') IS NULL
    ALTER TABLE dbo.T120PlanComptable_Classe ADD DescriptionFr varchar(200) NULL;
GO
IF COL_LENGTH('dbo.T120PlanComptable_Classe', 'DescriptionEn') IS NULL
    ALTER TABLE dbo.T120PlanComptable_Classe ADD DescriptionEn varchar(200) NULL;
GO
IF COL_LENGTH('dbo.T120PlanComptable_Classe', 'DescriptionEs') IS NULL
    ALTER TABLE dbo.T120PlanComptable_Classe ADD DescriptionEs varchar(200) NULL;
GO

UPDATE dbo.T120PlanComptable_Classe
   SET DescriptionFr = [Description],
       DescriptionEn = [Description],
       DescriptionEs = [Description];
GO

UPDATE c
   SET DescriptionEn = t.en,
       DescriptionEs = t.es
FROM dbo.T120PlanComptable_Classe c
INNER JOIN (VALUES
    ('ACT-CT',  N'Current assets', N'Activo circulante'),
    ('ACT-LT',  N'Long-term assets', N'Activo no circulante'),
    ('PAS-CT',  N'Current liabilities', N'Pasivo circulante'),
    ('PAS-LT',  N'Long-term liabilities', N'Pasivo no circulante'),
    ('CP',      N'Equity', N'Capital contable'),
    ('REV',     N'Revenue', N'Ingresos'),
    ('CDV',     N'Cost of sales', N'Costo de ventas'),
    ('CHG-EXP', N'Operating expenses', N'Gastos de operación'),
    ('IMP-EXT', N'Taxes and extraordinary items', N'Impuestos y partidas extraordinarias'),
    ('ACT-BNQ', N'Cash / Bank', N'Efectivo / Banco'),
    ('ACT-CLI', N'Accounts receivable', N'Cuentas por cobrar'),
    ('ACT-ERC', N'Short-term notes receivable', N'Documentos por cobrar CP'),
    ('ACT-STK', N'Inventory', N'Inventarios'),
    ('ACT-FPA', N'Prepaid expenses', N'Gastos pagados por adelantado'),
    ('ACT-PLC', N'Short-term investments', N'Inversiones CP'),
    ('ACT-TAX', N'GST/QST receivable', N'GST/QST por cobrar'),
    ('ACT-IMC', N'Property, plant and equipment', N'Propiedad, planta y equipo'),
    ('ACT-AMC', N'Accumulated depreciation', N'Depreciación acumulada'),
    ('ACT-IMI', N'Intangible assets', N'Activos intangibles'),
    ('ACT-PLT', N'Long-term investments', N'Inversiones LP'),
    ('ACT-ERL', N'Long-term notes receivable', N'Documentos por cobrar LP'),
    ('PAS-FRN', N'Accounts payable', N'Cuentas por pagar'),
    ('PAS-CC',  N'Credit cards', N'Tarjetas de crédito'),
    ('PAS-CAP', N'Accrued liabilities', N'Gastos por pagar'),
    ('PAS-TAX', N'Taxes payable', N'Impuestos por pagar'),
    ('PAS-RET', N'Payroll deductions', N'Retenciones salariales'),
    ('PAS-RVR', N'Deferred revenue', N'Ingresos diferidos'),
    ('PAS-PCL', N'Current portion of long-term debt', N'Porción corriente de deuda LP'),
    ('PAS-HYP', N'Mortgage loans', N'Préstamos hipotecarios'),
    ('PAS-EBL', N'Long-term bank loans', N'Préstamos bancarios LP'),
    ('PAS-OBL', N'Bonds and debentures', N'Bonos y obligaciones'),
    ('PAS-IDF', N'Deferred taxes', N'Impuestos diferidos'),
    ('PAS-ADL', N'Other long-term debt', N'Otras deudas LP'),
    ('CP-ACT',  N'Share capital', N'Capital social'),
    ('CP-APP',  N'Owners'' contributions', N'Aportaciones de los propietarios'),
    ('CP-RET',  N'Withdrawals / Dividends', N'Retiros / Dividendos'),
    ('CP-BNR',  N'Retained earnings', N'Utilidades retenidas'),
    ('CP-BNE',  N'Net income for the year', N'Utilidad neta del ejercicio'),
    ('CP-SUR',  N'Contributed surplus', N'Superávit aportado'),
    ('REV-VTE', N'Sales revenue', N'Ingresos por ventas'),
    ('REV-SVC', N'Service revenue', N'Ingresos por servicios'),
    ('REV-INT', N'Interest income', N'Ingresos por intereses'),
    ('REV-LOC', N'Rental income', N'Ingresos por alquiler'),
    ('REV-AUT', N'Other income', N'Otros ingresos'),
    ('CDV-ACH', N'Merchandise purchases', N'Compras de mercancías'),
    ('CDV-MOD', N'Direct labour', N'Mano de obra directa'),
    ('CDV-STR', N'Subcontracting', N'Subcontratación'),
    ('CDV-TRN', N'Freight-in', N'Fletes sobre compras'),
    ('CDV-VAR', N'Change in inventory', N'Variación de inventarios'),
    ('CHG-SAL', N'Salaries and benefits', N'Sueldos y prestaciones'),
    ('CHG-LOY', N'Rent and occupancy', N'Alquiler y ocupación'),
    ('CHG-FRB', N'Supplies and office', N'Suministros y oficina'),
    ('CHG-TEL', N'Telecommunications', N'Telecomunicaciones'),
    ('CHG-PUB', N'Advertising and marketing', N'Publicidad y marketing'),
    ('CHG-DEP', N'Travel expenses', N'Gastos de viaje'),
    ('CHG-HON', N'Professional fees', N'Honorarios profesionales'),
    ('CHG-ASS', N'Insurance', N'Seguros'),
    ('CHG-AMO', N'Depreciation', N'Depreciación'),
    ('CHG-IFB', N'Interest and bank charges', N'Intereses y gastos bancarios'),
    ('CHG-CRD', N'Bad debts', N'Cuentas incobrables'),
    ('IMP-REV', N'Income taxes', N'Impuestos sobre la renta'),
    ('IMP-DIF', N'Deferred taxes (expense)', N'Impuestos diferidos (gasto)'),
    ('EXT-GAN', N'Extraordinary gains', N'Ganancias extraordinarias'),
    ('EXT-PER', N'Extraordinary losses', N'Pérdidas extraordinarias'),
    ('EXT-INH', N'Unusual items', N'Partidas inusuales')
) AS t(code, en, es)
    ON LTRIM(RTRIM(c.Code)) = t.code;
GO
