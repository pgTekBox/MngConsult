using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Playwright;
using Microsoft.Playwright.NUnit;
using NUnit.Framework;

namespace MngConsul.E2E.Tests;

// =====================================================================
//  Smoke test — vérifie que chaque écran du menu se charge sans erreur.
//
//  Avant de lancer :
//    1) Le site doit tourner (Visual Studio / IIS Express) à l'URL ci-dessous.
//    2) Définir les variables d'environnement :
//         MNG_BASEURL   (déf. http://localhost:53024)
//         MNG_EMAIL     (courriel d'un compte de test actif)
//         MNG_PASSWORD  (mot de passe de ce compte)
//
//  Lancer :   dotnet test
// =====================================================================

internal static class SmokeConfig
{
    public static string BaseUrl =>
        Environment.GetEnvironmentVariable("MNG_BASEURL") ?? "http://localhost:53024";

    public static string Email =>
        Environment.GetEnvironmentVariable("MNG_EMAIL") ?? "b@b.com";

    public static string Password =>
        Environment.GetEnvironmentVariable("MNG_PASSWORD") ?? "11111111";

    // État de session partagé (cookies) écrit après le login, relu par chaque test.
    public static string StorageStatePath =>
        Path.Combine(Path.GetTempPath(), "mng_smoke_state.json");
}

// Se connecte UNE fois avant tous les tests et sauvegarde la session.
[SetUpFixture]
public class LoginFixture
{
    public static bool Skipped { get; private set; }
    public static string SkipReason { get; private set; } = "";

    [OneTimeSetUp]
    public async Task GlobalLogin()
    {
        if (string.IsNullOrWhiteSpace(SmokeConfig.Email) || string.IsNullOrWhiteSpace(SmokeConfig.Password))
        {
            Skipped = true;
            SkipReason = "Définir MNG_EMAIL et MNG_PASSWORD (et MNG_BASEURL si différent) pour lancer le smoke test.";
            if (File.Exists(SmokeConfig.StorageStatePath)) File.Delete(SmokeConfig.StorageStatePath);
            return;
        }

        // Auto-réparation : installe le navigateur s'il manque (VS, antivirus, 1re exécution...).
        var exit = Microsoft.Playwright.Program.Main(new[] { "install", "chromium", "chromium-headless-shell" });
        if (exit != 0)
        {
            Skipped = true;
            SkipReason = $"Échec de l'installation du navigateur Playwright (code {exit}). " +
                         "Lance manuellement : pwsh bin/Debug/net9.0/playwright.ps1 install chromium chromium-headless-shell";
            return;
        }

        using var pw = await Playwright.CreateAsync();
        await using var browser = await pw.Chromium.LaunchAsync();
        var ctx = await browser.NewContextAsync(new BrowserNewContextOptions
        {
            BaseURL = SmokeConfig.BaseUrl,
            IgnoreHTTPSErrors = true
        });
        var page = await ctx.NewPageAsync();

        try
        {
            await page.GotoAsync("/wbfLogin.aspx", new PageGotoOptions { Timeout = 30000 });
            await page.FillAsync("#tbEmail", SmokeConfig.Email);
            await page.FillAsync("#tbPassword", SmokeConfig.Password);
            await page.ClickAsync("#btnLogin");
            await page.WaitForLoadStateAsync(LoadState.NetworkIdle);
        }
        catch (PlaywrightException ex)
        {
            Skipped = true;
            SkipReason = $"Site injoignable à {SmokeConfig.BaseUrl}. Démarre prjMngConsul dans " +
                         $"Visual Studio (Ctrl+F5) avant de lancer les tests. Détail : {ex.Message}";
            await ctx.CloseAsync();
            return;
        }

        if (page.Url.Contains("wbfLogin", StringComparison.OrdinalIgnoreCase))
        {
            Skipped = true;
            SkipReason = "Login échoué : encore sur wbfLogin.aspx. Vérifie MNG_EMAIL/MNG_PASSWORD " +
                         "(et que le compte est actif, abonnement + profil complétés).";
            await ctx.CloseAsync();
            return;
        }

        await ctx.StorageStateAsync(new BrowserContextStorageStateOptions
        {
            Path = SmokeConfig.StorageStatePath
        });
        await ctx.CloseAsync();
    }
}

[TestFixture]
public class ScreenSmokeTests : PageTest
{
    // Chaque écran navigable du menu (on exclut Déconnexion et les écrans « à enlever »).
    private static readonly string[] Screens =
    {
        "/wbfWelcome.aspx",
        "/Default.aspx",
        "/wbfAgenda.aspx",
        // Ventes
        "/wbfCustomers.aspx",
        "/wbfCustomersInvoices.aspx",
        "/wbfReceiptEdit.aspx",
        // Achats
        "/wbfSuppliers.aspx",
        "/wbfSuppliersInvoices.aspx",
        // Comptabilité
        "/wbfJournal.aspx",
        "/wbfTemplate.aspx",
        "/PlaidAccounts.aspx",
        "/wbfReleve.aspx",
        "/wbfRapportTaxe.aspx",
        "/wbfFermetureAnnee.aspx",
        "/wbfPlanComptable.aspx",
        "/wbfProductCategory.aspx",
        "/wbfProducts.aspx",
        // Jobs
        "/wbfJobs.aspx",
        "/wbfJobSchedule.aspx",
        "/wbfJobMonitoring.aspx",
        "/wbfJobExecution.aspx",
        "/wbfJobDashboard.aspx",
        // Rapports
        "/wbfRapportPlanComptable.aspx",
        "/wbfEtatResultats.aspx",
        "/wbfBilan.aspx",
        "/wbfFluxTresorerie.aspx",
        "/wbfBeneficesNonRepartis.aspx",
        "/wbfBalanceVerification.aspx",
        "/wbfAIPaiement.aspx",
        "/wbfAISale.aspx",
        // Importation
        "/wbfImport.aspx",
        // Paramètres & sécurité
        "/wbfUsers.aspx",
        "/wbfsetting.aspx",
        "/wbfSettingsOpenAiPrompts.aspx",
        "/wbfStripeWebhookDiagnostic.aspx",
        "/wbfAutoPayAuthorizations.aspx",
    };

    // Marqueurs typiques d'une page d'erreur ASP.NET.
    private static readonly string[] ErrorMarkers =
    {
        "Server Error in",
        "Exception Details:",
        "Runtime Error",
        "An unhandled exception",
        "Stack Trace:",
    };

    public override BrowserNewContextOptions ContextOptions()
    {
        var opts = new BrowserNewContextOptions
        {
            BaseURL = SmokeConfig.BaseUrl,
            IgnoreHTTPSErrors = true
        };
        if (File.Exists(SmokeConfig.StorageStatePath))
            opts.StorageStatePath = SmokeConfig.StorageStatePath;
        return opts;
    }

    [SetUp]
    public void Guard()
    {
        if (LoginFixture.Skipped)
            Assert.Ignore(LoginFixture.SkipReason);
    }

    [TestCaseSource(nameof(Screens))]
    public async Task Screen_Loads_Without_Error(string path)
    {
        // DOMContentLoaded : on veut que le serveur réponde avec le HTML, pas attendre
        // toutes les ressources (scripts/images), ce qui ferait expirer des pages valides.
        // 60 s pour absorber la compilation ASP.NET au 1er accès (IIS Express à froid).
        var resp = await Page.GotoAsync(path, new PageGotoOptions
        {
            WaitUntil = WaitUntilState.DOMContentLoaded,
            Timeout = 60000
        });

        Assert.That(resp, Is.Not.Null, $"Aucune réponse HTTP pour {path}");
        Assert.That(resp!.Status, Is.LessThan(400), $"Statut HTTP {resp.Status} sur {path}");
        Assert.That(Page.Url, Does.Not.Contain("wbfLogin").IgnoreCase,
            $"Redirigé vers le login en ouvrant {path} (session/auth perdue).");

        var html = await Page.ContentAsync();
        foreach (var marker in ErrorMarkers)
            Assert.That(html, Does.Not.Contain(marker),
                $"Erreur ASP.NET détectée sur {path} (marqueur « {marker} »).");
    }
}
