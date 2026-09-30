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

## Deploy

The site is published by one script, with no GitHub Actions:

```bash
bash scripts/publish.sh
```

GitHub Pages serves the `gh-pages` branch (Settings > Pages: deploy from a branch, `gh-pages`,
`/`). The script:

1. refuses if the working tree has uncommitted or untracked changes;
2. refuses unless the running Node's major version matches `.nvmrc`;
3. exports the committed tree (`git archive HEAD`) to a temporary directory and runs `npm ci`
   and `npm run build` there, so gitignored files in your working copy never reach the site;
4. adds an empty `.nojekyll`, so Pages serves the files as built instead of running Jekyll;
5. commits the build on top of `gh-pages` as a normal commit (never a force push) and pushes it;
6. confirms the remote branch points at the new commit and prints it.

Pushing to `main` does not deploy anything. Publish after the change you want live is committed
(and, so its source is on the remote too, pushed). A build identical to what is already on
`gh-pages` publishes nothing. Each `gh-pages` commit message names the source commit it was built
from; the Pages build for it shows as "pages build and deployment" in the repository's Actions
tab, which GitHub runs itself for branch-based Pages.

## License

All rights reserved.
