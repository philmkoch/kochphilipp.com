# kochphilipp.com

The source for the next version of [kochphilipp.com](https://www.kochphilipp.com), built with Quarto and intended for GitHub Pages.

## What is here now

- `archive/` contains a reproducible snapshot of the current public Squarespace site: source pages, directly linked PDFs, homepage images, checksums, and a complete link inventory.
- `docs/VISUAL_LAYOUT.md` is the agreed design brief and page-level wireframe.
- `docs/DESIGN_RESEARCH.md` records the online academic-web and accessibility guidance used for the design decisions.
- `docs/MIGRATION_NOTES.md` records URL, domain, publishing, and launch constraints.
- The whole site uses the Terracotta design: `assets/styles.scss` sets the shared palette, type, navbar, and buttons; `assets/designs/terracotta.css` (plus `minimal-override.css`) styles the homepage hero, selected work, and news. `designs/` retains Terracotta, Cobalt, and Moss as local design references (not rendered).
- The local first draft provides Home, Projects, Publications, Policy, and About, including the current nine publication entries, thirteen policy reports, preserved first-party downloads, and a short News feed on the homepage.
- `.github/workflows/publish.yml` is ready to publish once this folder has been pushed to a GitHub repository and GitHub Pages has been enabled for Actions.

## Data tab

`data.qmd` lists open datasets; `data/historical-gdp/index.qmd` hosts the historical GDP per capita explorer (Leaflet map + Observable Plot chart in `assets/gdp-explorer.js`). It replaces the former Shinylive app, which loaded R in the browser and was slow on any host. The CSV and simplified GeoJSON boundaries in `data/historical-gdp/` are built with the command below. The dataset is v3 from the `philmkoch/historicalGDPpc` repository (pinned commit, with four source labels corrected); the boundaries come from the old app's bundle (`historicalGDPpc_app/docs/app.json`, not tracked).

```powershell
Rscript tools/build-gdp-data.R
```

## Local preview

To render the site locally, run:

```powershell
.\tools\render-site.ps1
```

Quarto renders the site into `_site/`, which is deliberately not tracked by Git.

To keep a live local preview open, use:

```powershell
& 'C:\Program Files\Quarto\bin\quarto.exe' preview
```

## Content workflow

The first draft is ready for local review. Before publishing, the remaining substantive work is to confirm exact wording and authorship details, add research-derived figures where they improve individual publication entries, and move publication metadata into a single structured source. Add future updates at the top of the News feed in `index.qmd`; each should be dated and link to the relevant work when useful.

Do not cancel the current Squarespace site until the new domain connection, all retained URLs, downloads, email records, and Google Search Console coverage have been verified.
