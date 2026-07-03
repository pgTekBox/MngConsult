/** @type {import('tailwindcss').Config} */
// Config de build pour la LandingPage.
// Scanne le markup (.aspx) ET le code-behind (.vb) car RenderPlanCard
// génère des classes utilitaires côté serveur (cartes de forfaits).
// Régénérer le CSS après toute modif de classes :
//   tailwindcss -c tailwind.config.js -i css/landingpage.src.css -o css/landingpage.css --minify
module.exports = {
  content: [
    './LandingPage.aspx',
    './LandingPage.aspx.vb',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
