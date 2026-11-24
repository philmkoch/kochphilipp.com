# Current-site archive

Run `tools/archive-current-site.ps1` to make a dated snapshot of the three currently public Squarespace pages:

- `https://www.kochphilipp.com/`
- `https://www.kochphilipp.com/publications`
- `https://www.kochphilipp.com/policy`

Each snapshot contains:

- raw source HTML;
- `link-inventory.csv` and `link-inventory.json`, recording every public link and image source on those pages;
- all directly linked PDF files;
- directly used homepage images and image files linked from the public pages;
- a download manifest with original URLs, local paths, content types, byte sizes, checksums, and any download errors.

The script does **not** crawl external landing pages or attempt to download publisher-hosted documents that are not directly linked as files on the current site. Those source URLs are preserved in the link inventory.

Downloaded files are ignored by Git to avoid inflating the public source repository. The manifests and this documentation remain trackable.
