using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace APIWebMngConsul.Security
{
    /// <summary>
    /// Valide le jeton de l'application mobile (émis par l'API 60SecAI, HS256) et
    /// en tire la compagnie. Cette API n'avait AUCUNE authentification : le dépôt
    /// de reçus était ouvert à tous et la compagnie était choisie par l'appelant.
    ///
    /// La section « Jwt » (Issuer, Audience, Key) doit être la même que celle de
    /// l'API 60SecAI. Sans clé, ou avec une clé de moins de 32 caractères, tout
    /// est refusé : on échoue fermé.
    /// </summary>
    public sealed class JwtGuard
    {
        public const string CompanyClaim = "companyGuid";
        private const int MinKeyLength = 32;

        private readonly string _issuer;
        private readonly string _audience;
        private readonly byte[] _key;

        public JwtGuard(IConfiguration configuration)
        {
            _issuer = configuration["Jwt:Issuer"] ?? string.Empty;
            _audience = configuration["Jwt:Audience"] ?? string.Empty;
            var key = configuration["Jwt:Key"] ?? string.Empty;
            _key = key.Length >= MinKeyLength ? Encoding.UTF8.GetBytes(key) : Array.Empty<byte>();
        }

        /// <summary>Vrai si l'en-tête Authorization porte un jeton valide ; la compagnie du jeton est renvoyée.</summary>
        public bool TryGetCompany(HttpRequest request, out Guid companyGuid)
        {
            companyGuid = Guid.Empty;
            if (_key.Length == 0 || _issuer.Length == 0 || _audience.Length == 0)
            {
                return false;
            }

            var header = request.Headers.Authorization.ToString();
            const string prefix = "Bearer ";
            if (!header.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            var parts = header[prefix.Length..].Trim().Split('.');
            if (parts.Length != 3)
            {
                return false;
            }

            try
            {
                // 1. L'algorithme annoncé doit être HS256 : jamais « none », jamais un autre.
                using (var head = JsonDocument.Parse(FromBase64Url(parts[0])))
                {
                    if (!head.RootElement.TryGetProperty("alg", out var alg) || alg.GetString() != "HS256")
                    {
                        return false;
                    }
                }

                // 2. La signature, comparée en temps constant.
                byte[] expected;
                using (var hmac = new HMACSHA256(_key))
                {
                    expected = hmac.ComputeHash(Encoding.ASCII.GetBytes(parts[0] + "." + parts[1]));
                }
                if (!CryptographicOperations.FixedTimeEquals(expected, FromBase64Url(parts[2])))
                {
                    return false;
                }

                // 3. Le contenu : émetteur, audience, expiration, compagnie.
                using var payload = JsonDocument.Parse(FromBase64Url(parts[1]));
                var root = payload.RootElement;

                if (!root.TryGetProperty("iss", out var iss) || iss.GetString() != _issuer)
                {
                    return false;
                }
                if (!root.TryGetProperty("aud", out var aud) || !AudienceMatches(aud))
                {
                    return false;
                }
                if (!root.TryGetProperty("exp", out var exp) || !exp.TryGetInt64(out var expSeconds)
                    || DateTimeOffset.FromUnixTimeSeconds(expSeconds) < DateTimeOffset.UtcNow.AddSeconds(-30))
                {
                    return false;
                }
                if (root.TryGetProperty("nbf", out var nbf) && nbf.TryGetInt64(out var nbfSeconds)
                    && DateTimeOffset.FromUnixTimeSeconds(nbfSeconds) > DateTimeOffset.UtcNow.AddSeconds(30))
                {
                    return false;
                }
                if (!root.TryGetProperty(CompanyClaim, out var company)
                    || !Guid.TryParse(company.GetString(), out companyGuid) || companyGuid == Guid.Empty)
                {
                    companyGuid = Guid.Empty;
                    return false;
                }

                return true;
            }
            catch
            {
                // Jeton mal formé : refusé.
                companyGuid = Guid.Empty;
                return false;
            }
        }

        private bool AudienceMatches(JsonElement aud)
        {
            if (aud.ValueKind == JsonValueKind.String)
            {
                return aud.GetString() == _audience;
            }
            if (aud.ValueKind == JsonValueKind.Array)
            {
                foreach (var a in aud.EnumerateArray())
                {
                    if (a.ValueKind == JsonValueKind.String && a.GetString() == _audience)
                    {
                        return true;
                    }
                }
            }
            return false;
        }

        private static byte[] FromBase64Url(string s)
        {
            var b = s.Replace('-', '+').Replace('_', '/');
            switch (b.Length % 4)
            {
                case 2: b += "=="; break;
                case 3: b += "="; break;
            }
            return Convert.FromBase64String(b);
        }
    }
}
