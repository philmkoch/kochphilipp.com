# Migration notes

## Chosen stack

- **Authoring:** Quarto with Markdown/`.qmd` source files.
- **Version control:** Git, pushed to a GitHub repository.
- **Publishing:** GitHub Pages through the included GitHub Actions workflow.
- **Canonical public address:** `https://www.kochphilipp.com` initially, matching the existing canonical URLs.

This gives the site durable source files, an inspectable publication history, and a deployment path that does not depend on Squarespace.

## Domain and cutover

Keeping `kochphilipp.com` does not require keeping Squarespace website hosting. Domain registration, DNS, and hosting are separate.

Before cutover:

1. Identify the domain registrar and current DNS provider; neither can be inferred safely from the public site.
2. Record every DNS entry, especially MX, SPF, DKIM, DMARC, and Search Console verification records.
3. Create the GitHub repository and enable Pages with GitHub Actions as the source.
4. Add `www.kochphilipp.com` as the custom GitHub Pages domain, then choose the GitHub-provided DNS records in the domain provider.
5. Verify HTTPS and both the bare and `www` domain before changing the canonical choice or ending Squarespace hosting.

## URL preservation

Retain these current URLs at launch:

- `/`
- `/publications`
- `/policy`
- `/s/CV_PK-8.pdf`
- all current `/s/…pdf` and `/s/20230608_Poster.png` assets recorded in the archive manifest

GitHub Pages can serve retained static paths. It cannot create server-side redirects in the way a dedicated host can, so prefer retaining a URL outright. If a redirect becomes necessary, use a static HTML redirect page and keep it indefinitely.

## Search and handover

- Keep the current site live until the new pages, PDFs, HTTPS, mail, and custom domain all work.
- Add a sitemap and verify the new site in Google Search Console.
- Submit the sitemap, monitor indexing and 404s, and retain the old URL map.
- Do not rely on a Squarespace XML export alone: it does not preserve every page type, style setting, or linked file.

## Content still to decide

- Which precise figure and caption will represent each launch project.
- Whether the current portrait becomes the small hero image.
- Public scope for teaching material.
- Citation export format and whether individual paper pages should be created at the first public release or directly after it.
