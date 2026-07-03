/** @type {import('tailwindcss').Config} */
// Config de build pour la LandingPage.
// Le contenu des pages/sections est en BD (T024LandingSectionContent), donc PAS
// dans le .aspx : on scanne aussi tailwind-content.html (dump du contenu BD) pour
// que Tailwind trouve toutes les classes utilisées par les sections/sous-pages.
// Régénérer tailwind-content.html après un ajout de NOUVELLES classes en BD, puis :
//   tailwindcss -c tailwind.config.js -i css/landingpage.src.css -o css/landingpage.css --minify
module.exports = {
  content: [
    './LandingPage.aspx',
    './LandingPage.aspx.vb',
    './tailwind-content.html',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
