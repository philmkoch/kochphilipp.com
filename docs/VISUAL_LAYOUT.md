# Visual layout plan

## Selected direction

**Terracotta reading room.** The homepage is a warm, sparse academic front door: one concise research proposition, a tall personal portrait, and a compact chronological feed. Selected outcomes live at the beginning of Publications. It uses space and typographic hierarchy rather than images, cards, or decorative visualisations.

The intended order of attention is: research question, current update, then selected outcomes and the full scholarly record on Publications. A narrow 3:5 portrait slot sits to the right of the centred homepage statement, with a larger 4:5 slot in the About introduction. Both are reserved for user-supplied photography.

## Navigation

`Philipp Koch | Publications | Policy | About | CV`

- **Publications** is the complete academic record and starts with three selected research outcomes, including public data and explorer links where available.
- **Policy** keeps reports for the policy audience in one place.
- **About** gives the visitor a short biography, affiliations, and the larger portrait slot.
- **CV** is a direct download.

Email, GitHub, and LinkedIn remain quiet footer links. There is no separate news destination: updates are a feed on the homepage.

## Homepage wireframe

```text
┌─────────────────────────────────────────────────────────────┐
│ Philipp Koch               Publications  Policy  About  CV   │
├─────────────────────────────────────────────────────────────┤
│ ECONOMIST · DATA SCIENTIST · VIENNA                          │
│                                                             │
│ How economies develop, connect, and change.                 │
│ Short research sentence                         portrait    │
│ Academic role and affiliation                              │
├─────────────────────────────────────────────────────────────┤
│ News                                                        │
│ date        short update title                              │
│             one or two sentences                            │
├─────────────────────────────────────────────────────────────┤
│ email   GitHub   LinkedIn                                   │
└─────────────────────────────────────────────────────────────┘
```

Add future updates above the existing article in `index.qmd`. Keep each entry to a date, a short title, and at most two sentences. Link to a project, publication, or policy note only when it helps the reader continue.

## Style system

- **Background:** warm paper `#fbf3e8`.
- **Ink:** deep plum `#302730`.
- **Accent:** fired clay `#b8583b`, used for small labels, rules, and focus.
- **Type:** an editorial serif for headings and system sans-serif for navigation and body text.
- **Layout:** thin rules, centred hero, and generous whitespace. No gradients, stock imagery, generic cards, or decorative diagrams.
- **Motion:** subtle hover and focus only.

## Responsive and accessibility rules

- On narrow screens, the navigation wraps, research paths become a vertical list, and each news item stacks the date above its text.
- Links name their destination; the arrows are supplementary.
- Keyboard focus remains visible and text/control contrast must meet WCAG requirements.
- Any future figure receives useful alternative text and a caption that names the variable, period, and uncertainty where applicable.
