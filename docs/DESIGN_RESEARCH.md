# Design basis for the academic website

Consulted 11 September 2026.

The layout directions use two complementary sources:

- Berkeley’s [guidance on personal academic webpages](https://townsendcenter.berkeley.edu/blog/personal-academic-webpages-how-tos-and-tips-better-site) recommends a concise biography and photograph, research, CV, and contact information; it also calls for a simple five- or six-item navigation, limited typefaces and accent colours, familiar page labels, and generous whitespace.
- The W3C Web Accessibility Initiative’s [guidance for designers](https://www.w3.org/WAI/tips/designing/) calls for sufficient contrast, links and controls that are not identified by colour alone, consistent navigation, visible focus states, a responsive viewport, and semantic headings.

## Decisions applied in every alternative

- The homepage names a research question before it presents credentials, then exposes three selected publication outcomes. This gives a first-time visitor a meaningful route into the work.
- The header uses a short set of primary destinations: publications or writing, policy, and CV or about. Contact remains visible in the footer or header.
- The selected Terracotta homepage carries only three project links and a dated news feed. This keeps ongoing updates visible without creating another destination or navigation choice.
- Each design uses a restrained system font pair: a serif for the research voice and a sans-serif for orientation. No external font request is required.
- Each palette has one dark reading colour, a calm light field, and one deliberate accent. The alternatives avoid gradients, stock-style imagery, decorative simulations, and repeated generic cards.
- Images have useful alternative text; all meaningful links include words as well as arrows; focus styling and mobile layouts are included in the CSS.

## What differs between the options

| Option | Visual character | Palette | Project presentation |
|---|---|---|---|
| Terracotta | Centred, warm, and editorial | ivory, plum, fired clay | three compact links |
| Cobalt | Precise and data-oriented | paper white, cobalt, marigold | single-line research index |
| Moss | Quiet and field-oriented | parchment, moss, violet | inline research paths |

The simplified alternatives also take visual inspiration from [Starcatcher](https://starcatcher.eu/): a pale field, compact navigation, one main proposition, and a small set of quiet routes into the work. Terracotta is the selected direction; its dated news feed lives directly on the homepage. The other pages remain local references while the chosen direction is refined.

## Benchmark pass: academic and data-science sites

Consulted 17 September 2026.

- [Raj Chetty](https://rajchetty.com/) uses a direct nameplate, a short role-and-research statement, an immediate Bio/CV route, and a few clear paths into papers, data, and lectures.
- [Dani Rodrik](https://drodrik.scholars.harvard.edu/) puts his academic title and research focus first, then distinguishes current items from the full publication record.
- [Yann LeCun](https://yann.lecun.com/) shows the value of a plainly written affiliation and a compact index of maintained research resources.
- [Andrew Ng](https://www.andrewng.org/) keeps the opening hierarchy legible: name, short identity statement, and a small, familiar navigation before deeper material.

The revised Terracotta homepage adopts the useful common elements while preserving its sparse character: a one-line academic role beneath the research statement, a named **About** route next to the CV, a compact dated feed, and selected outcomes at the beginning of Publications. It intentionally does not add institutional logos, impact counters, large project cards, or a second update page.

## Sandor Juhász reference

[Sándor Juhász’s homepage](https://sandorjuhasz.com/) is a useful model for compact academic communication: a plain biographical introduction, one unadorned portrait, a dated news list, and selected publications in a continuous reading flow. The Terracotta homepage now follows that lighter sequence. It retains the centred research statement and tall right-hand portrait slot, removes the redundant selected-research strip, and gives the dated feed a direct **News** heading. Selected outcomes remain at the top of Publications.

## Benchmark pass 2: publications, data projects, and explorers

Consulted 23 November 2026. Page text was checked with automated fetches, so visual details are only partly confirmed.

### Personal sites

- [Andrew Heiss](https://www.andrewheiss.com/research/) (Quarto): research list filterable by tag, with DOI, preprint, code and data links on each entry. Each paper has its own page with an abstract, key figures and BibTeX. This is the strongest model for Publications.
- [John Paul Helveston](https://www.jhelvy.com/research) (Quarto): a uniform button row on every entry (View / PDF / Code & Data / Cite). Cheaper to maintain than one page per paper.
- [Emily Riederer](https://www.emilyriederer.com/) (Quarto): Quarto listings with thumbnails. The homepage shows the latest few items, each with an "All…" link.
- [Gabriel Zucman](https://gabriel-zucman.eu/): bracketed links on each entry ([Data] [Slides] [Data and code]). Large datasets get their own front door ([missingprofits.world](https://missingprofits.world/), [realtimeinequality.org](https://realtimeinequality.org/)).
- [Nathan Lane](https://nathanlane.info/): a status label and a one-paragraph summary per paper, with clean typography and a light/dark toggle.
- [Max Roser](https://maxroser.com/) and [César Hidalgo](https://cesarhidalgo.com/): open data projects or "platforms" listed as a category of output in their own right.

### Dataset and explorer pages

- [Post45 Data Collective](https://data.post45.org/) (Quarto + Observable): closest to our case. Order: DOI and authors, abstract, interactive table, download of the full or filtered data, licence, charts, methods, data dictionary, BibTeX.
- [OWID grapher](https://ourworldindata.org/grapher/gdp-per-capita-maddison-project-database): gold standard for metadata around a chart. It includes "How to cite", the licence, a ZIP with CSV + metadata, and stable CSV URLs with R/Python/Stata snippets.
- [Maddison Project Database](https://www.rug.nl/ggdc/historicaldevelopment/maddison/): coverage line, DOI-archived files, CC BY, and explicit citation rules. It has no explorer, which is the gap our page fills.
- [Global Data Lab SHDI](https://globaldatalab.org/shdi/): map / chart / table views for subnational data. Its compulsory registration before download is the thing to avoid.
- [Clio Infra](https://clio-infra.eu/): states its boundary convention up front. Our page should do the same for regions.

### Implications

- Data projects get their own top-level **Data** tab. The historical GDP per capita page follows this order: summary, explorer, download, how to cite, methods in brief, data dictionary, boundaries and version.
- ML-imputed values are visually distinct from observed values.
- The explorer is built from pre-computed static JSON/TopoJSON, using Quarto OJS with Observable Plot and a lightweight map. The current Shinylive (webR) app loads R, `sf`, `leaflet`, `plotly` and an 8 MB bundle in the browser on every visit, which is why it is slow on any host.
- Publications should move into a structured data file and be rendered as a Quarto listing with a uniform link row.
