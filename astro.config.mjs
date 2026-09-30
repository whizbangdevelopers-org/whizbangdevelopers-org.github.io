import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://whizbangdevelopers-org.github.io',
  integrations: [sitemap()],
  // Tailwind CSS v4 runs as a Vite plugin; its entry point is src/styles/global.css.
  vite: {
    plugins: [tailwindcss()],
  },
});
