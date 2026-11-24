// Historical GDP per capita explorer.
// Static replacement for the former Shinylive app: the data and simplified
// boundaries are pre-built by tools/build-gdp-data.R and loaded as plain files.
import * as Plot from "https://cdn.jsdelivr.net/npm/@observablehq/plot@0.6.16/+esm";
import { csvParse, csvFormat } from "https://cdn.jsdelivr.net/npm/d3-dsv@3.0.1/+esm";

const BASE = new URL("../data/historical-gdp/", import.meta.url);
const DEFAULT_PLACES = ["ITA", "NLD", "GBR", "ESP"];
const VIEWS = {
  europe: { center: [52, 14], zoom: 4 },
  america: { center: [42, -95], zoom: 4 },
};
// Sequential ramp from paper through the site's clay to deep plum.
const RAMP = ["#f7e9d6", "#ebbf97", "#cf7d52", "#94402c", "#3f1f30"];

const $ = (sel) => document.querySelector(sel);
const fmt = new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 });
const dollars = (v) => "$" + fmt.format(v);

const state = {
  year: 1750,
  level: "region",
  places: [...DEFAULT_PLACES],
};

// ---------------------------------------------------------------------------
// Historical country boundaries: which modern countries are replaced by which
// historical units in a given year (mirrors the logic of the original app).
function countryBoundaries(year) {
  if (year <= 1700) return { hide: ["GBR", "NLD", "POL", "ITA"], show: ["GBR", "WAL", "SCO", "NLD", "NLD_2", "POL", "POL_2", "ITA", "S_ITA"] };
  if (year <= 1800) return { hide: ["NLD", "POL", "ITA"], show: ["NLD", "NLD_2", "POL", "POL_2", "ITA", "S_ITA"] };
  if (year === 1850) return { hide: ["POL", "ITA", "CZE", "SVK"], show: ["POL", "POL_2", "ITA", "S_ITA", "CSK"] };
  if (year <= 1950) return { hide: ["CZE", "SVK"], show: ["CSK"] };
  return { hide: [], show: [] };
}

function countryVisible(f, year) {
  const { hide, show } = countryBoundaries(year);
  const { id, variant } = f.properties;
  return variant === "historical" ? show.includes(id) : !hide.includes(id);
}

// ---------------------------------------------------------------------------
function colourScale(values) {
  const lo = Math.log10(Math.min(...values));
  const hi = Math.log10(Math.max(...values));
  const span = hi - lo || 1;
  const hex = (h) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16));
  const stops = RAMP.map(hex);
  const colour = (v) => {
    const t = Math.min(1, Math.max(0, (Math.log10(v) - lo) / span)) * (stops.length - 1);
    const i = Math.min(stops.length - 2, Math.floor(t));
    const k = t - i;
    const c = stops[i].map((a, j) => Math.round(a + (stops[i + 1][j] - a) * k));
    return `rgb(${c.join(",")})`;
  };
  colour.domain = [10 ** lo, 10 ** hi];
  return colour;
}

function renderLegend(scale) {
  const [lo, hi] = scale.domain;
  const ticks = [0, 0.25, 0.5, 0.75, 1].map((t) => 10 ** (Math.log10(lo) + t * Math.log10(hi / lo)));
  const round = (v) => (v > 10000 ? Math.round(v / 1000) * 1000 : Math.round(v / 100) * 100);
  $("#gdp-legend").innerHTML = `
    <div class="gdp-legend-title">GDP per capita, ${state.year}</div>
    <div class="gdp-legend-bar" style="background:linear-gradient(to right, ${RAMP.join(",")})"></div>
    <div class="gdp-legend-ticks">${ticks.map((v) => `<span>${dollars(round(v))}</span>`).join("")}</div>`;
}

// ---------------------------------------------------------------------------
async function load() {
  const [csv, regions, countries] = await Promise.all([
    fetch(new URL("historical-gdppc.csv", BASE)).then((r) => r.text()),
    fetch(new URL("regions.geojson", BASE)).then((r) => r.json()),
    fetch(new URL("countries.geojson", BASE)).then((r) => r.json()),
  ]);
  const rows = csvParse(csv, (d) => ({
    ...d,
    year: +d.year,
    gdppc: +d.gdppc,
    lower: d.lower === "" ? null : +d.lower,
    upper: d.upper === "" ? null : +d.upper,
    estimated: d.estimated === "TRUE",
  }));
  return { rows, regions, countries };
}

function readUrl() {
  const p = new URLSearchParams(location.search);
  const year = +p.get("year");
  if (year >= 1300 && year <= 2000 && year % 50 === 0) state.year = year;
  if (["region", "country"].includes(p.get("level"))) state.level = p.get("level");
  if (p.get("places") !== null) state.places = p.get("places").split(",").filter(Boolean);
}

function writeUrl() {
  const p = new URLSearchParams({ year: state.year, level: state.level, places: state.places.join(",") });
  history.replaceState(null, "", `${location.pathname}?${p}${location.hash}`);
}

// ---------------------------------------------------------------------------
async function main() {
  readUrl();
  let data;
  try {
    data = await load();
  } catch (err) {
    $("#gdp-status").textContent = "The data could not be loaded. Please download the CSV instead.";
    console.error(err);
    return;
  }
  const { rows, regions, countries } = data;

  // Lookups
  const byKey = new Map(rows.map((d) => [`${d.id}|${d.year}`, d]));
  const places = new Map();
  for (const d of rows) if (!places.has(d.id)) places.set(d.id, { id: d.id, name: d.name, country: d.country, level: d.level });
  const nameCount = new Map();
  for (const p of places.values()) nameCount.set(p.name, (nameCount.get(p.name) || 0) + 1);
  for (const p of places.values()) p.label = nameCount.get(p.name) > 1 ? `${p.name} (${p.id})` : p.name;
  state.places = state.places.filter((id) => places.has(id));

  // Place picker
  const labelToId = new Map();
  const options = [...places.values()].sort((a, b) => a.label.localeCompare(b.label));
  $("#gdp-places").innerHTML = options
    .map((p) => {
      const text = `${p.label} · ${p.level === "country" ? "country" : p.country}`;
      labelToId.set(text, p.id);
      return `<option value="${text.replace(/"/g, "&quot;")}"></option>`;
    })
    .join("");

  // Map
  const map = L.map("gdp-map", { preferCanvas: true, zoomSnap: 0.5, scrollWheelZoom: false, worldCopyJump: true })
    .setView(VIEWS.europe.center, VIEWS.europe.zoom);
  L.tileLayer("https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}", {
    attribution: "Basemap &copy; Esri, HERE, Garmin, &copy; OpenStreetMap contributors",
    maxZoom: 10,
  }).addTo(map);
  map.on("click", () => map.scrollWheelZoom.enable());
  let layer = null;

  function tooltip(f, d) {
    const p = places.get(d.id);
    const label = f.properties.label || p.label;
    const series = f.properties.label && f.properties.label !== p.name ? `<div class="gdp-tip-note">Series: ${p.name}</div>` : "";
    const detail = d.estimated
      ? `Estimate · 90% CI ${dollars(d.lower)}–${dollars(d.upper)}`
      : `Source: ${d.source}`;
    return `<strong>${label}</strong>${series}<div>${d.year}: <b>${dollars(d.gdppc)}</b></div><div class="gdp-tip-note">${detail}</div>`;
  }

  function drawMap() {
    const source = state.level === "region" ? regions : countries;
    const features = source.features.filter(
      (f) => byKey.has(`${f.properties.id}|${state.year}`) && (state.level === "region" || countryVisible(f, state.year))
    );
    if (layer) layer.remove();
    if (!features.length) {
      $("#gdp-legend").innerHTML = `<div class="gdp-legend-title">No ${state.level} data for ${state.year}</div>`;
      return;
    }
    const scale = colourScale(features.map((f) => byKey.get(`${f.properties.id}|${state.year}`).gdppc));
    layer = L.geoJSON(
      { type: "FeatureCollection", features },
      {
        style: (f) => ({
          fillColor: scale(byKey.get(`${f.properties.id}|${state.year}`).gdppc),
          fillOpacity: 0.92,
          color: "#6b5960",
          weight: 0.5,
        }),
        onEachFeature: (f, lyr) => {
          const d = byKey.get(`${f.properties.id}|${state.year}`);
          lyr.bindTooltip(tooltip(f, d), { sticky: true, className: "gdp-tip" });
          lyr.on("mouseover", () => lyr.setStyle({ weight: 2, color: "#302730" }));
          lyr.on("mouseout", () => lyr.setStyle({ weight: 0.5, color: "#6b5960" }));
          lyr.on("click", () => addPlace(d.id));
        },
      }
    ).addTo(map);
    renderLegend(scale);
  }

  // Chart
  function drawChart() {
    const el = $("#gdp-chart");
    const selected = rows.filter((d) => state.places.includes(d.id)).map((d) => ({ ...d, label: places.get(d.id).label }));
    el.replaceChildren();
    if (!selected.length) {
      el.innerHTML = `<p class="gdp-empty">Pick a country or region above, or click a place on the map.</p>`;
      return;
    }
    const order = state.places.map((id) => places.get(id).label);
    const band = selected.map((d) => ({ ...d, lo: d.lower ?? d.gdppc, hi: d.upper ?? d.gdppc }));
    const width = el.clientWidth || 700;
    el.append(
      Plot.plot({
        width,
        height: Math.max(300, Math.min(440, width * 0.55)),
        marginLeft: 56,
        style: { fontFamily: "inherit", fontSize: "12px", background: "transparent" },
        x: { label: null, tickFormat: (d) => String(d), domain: [1300, 2000], ticks: 8 },
        y: { type: "log", label: "GDP per capita (2011 int. $)", grid: true, tickFormat: "~s" },
        color: { domain: order, scheme: "tableau10", legend: true },
        marks: [
          Plot.areaY(band, { x: "year", y1: "lo", y2: "hi", z: "label", fill: "label", fillOpacity: 0.13, curve: "monotone-x" }),
          Plot.lineY(selected, { x: "year", y: "gdppc", z: "label", stroke: "label", strokeWidth: 1.8, curve: "monotone-x" }),
          Plot.dot(selected.filter((d) => !d.estimated), { x: "year", y: "gdppc", fill: "label", r: 3.2 }),
          Plot.dot(selected.filter((d) => d.estimated), { x: "year", y: "gdppc", stroke: "label", fill: "white", r: 3.2, strokeWidth: 1.5 }),
          Plot.tip(
            selected,
            Plot.pointer({
              x: "year",
              y: "gdppc",
              stroke: "label",
              title: (d) =>
                `${d.label}, ${d.year}\n${dollars(d.gdppc)}\n` +
                (d.estimated ? `Estimate (90% CI ${dollars(d.lower)}–${dollars(d.upper)})` : `Source: ${d.source}`),
            })
          ),
        ],
      })
    );
  }

  function drawChips() {
    $("#gdp-chips").innerHTML = state.places
      .map(
        (id) =>
          `<span class="gdp-chip">${places.get(id).label}<button type="button" data-remove="${id}" aria-label="Remove ${places.get(id).label}">×</button></span>`
      )
      .join("");
  }

  function addPlace(id) {
    if (!places.has(id) || state.places.includes(id)) return;
    state.places.push(id);
    refreshSelection();
  }

  function refreshSelection() {
    drawChips();
    drawChart();
    writeUrl();
  }

  function setYear(y) {
    state.year = y;
    $("#gdp-year").value = y;
    $("#gdp-year-value").textContent = y;
    drawMap();
    writeUrl();
  }

  function setLevel(level) {
    state.level = level;
    document.querySelectorAll("[data-level]").forEach((b) => b.setAttribute("aria-pressed", String(b.dataset.level === level)));
    drawMap();
    writeUrl();
  }

  // Events
  $("#gdp-year").addEventListener("input", (e) => setYear(+e.target.value));
  document.querySelectorAll("[data-level]").forEach((b) => b.addEventListener("click", () => setLevel(b.dataset.level)));
  document.querySelectorAll("[data-zoom]").forEach((b) =>
    b.addEventListener("click", () => map.flyTo(VIEWS[b.dataset.zoom].center, VIEWS[b.dataset.zoom].zoom, { duration: 0.6 }))
  );
  $("#gdp-search").addEventListener("change", (e) => {
    const id = labelToId.get(e.target.value);
    if (id) addPlace(id);
    e.target.value = "";
  });
  $("#gdp-chips").addEventListener("click", (e) => {
    const id = e.target.dataset.remove;
    if (!id) return;
    state.places = state.places.filter((p) => p !== id);
    refreshSelection();
  });
  $("#gdp-download-selection").addEventListener("click", () => {
    const sel = rows.filter((d) => state.places.includes(d.id));
    if (!sel.length) return;
    const blob = new Blob([csvFormat(sel)], { type: "text/csv" });
    const a = Object.assign(document.createElement("a"), { href: URL.createObjectURL(blob), download: "historical-gdppc-selection.csv" });
    a.click();
    URL.revokeObjectURL(a.href);
  });
  $("#gdp-copy-link").addEventListener("click", async (e) => {
    const btn = e.currentTarget;
    try {
      await navigator.clipboard.writeText(location.href);
      btn.lastChild.textContent = " Link copied";
    } catch {
      btn.lastChild.textContent = " Copy the address bar";
    }
    setTimeout(() => (btn.lastChild.textContent = " Copy link to this view"), 2000);
  });
  let lastWidth = 0;
  new ResizeObserver(([entry]) => {
    const w = Math.round(entry.contentRect.width);
    if (Math.abs(w - lastWidth) > 20) {
      lastWidth = w;
      drawChart();
    }
  }).observe($("#gdp-chart"));

  $("#gdp-status").remove();
  setLevel(state.level);
  setYear(state.year);
  refreshSelection();
}

main();
