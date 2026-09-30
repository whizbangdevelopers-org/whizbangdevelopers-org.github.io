# whizBANG Developers

Marketing website for whizBANG Developers organization.

**Live site:** https://whizbangdevelopers-org.github.io

## Tech Stack

- [Astro](https://astro.build/) 7 - Static site framework
- [Tailwind CSS](https://tailwindcss.com/) 4, through its Vite plugin - Styling
- [Web3Forms](https://web3forms.com/) - Contact form

Tailwind's theme lives in `src/styles/global.css`: the brand `primary` palette, plus the
Tailwind 3 font stack and palette the site kept when it moved to Tailwind 4.

## Development

Requires Node 22.12 or later; `.nvmrc` pins the major version the site is built and published
with.

```bash
npm ci
npm run dev
```

## Build

```bash
npm run build     # astro check, then astro build into dist/
npm run preview   # serve dist/ locally
```

## License

All rights reserved.
