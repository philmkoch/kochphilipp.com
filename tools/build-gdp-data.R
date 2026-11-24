# Build the static data files behind data/historical-gdp/index.qmd.
#
# Sources:
# - Dataset: historicalGDPs_augmented_dataset.xlsx (v3, April 2025) from
#   github.com/philmkoch/historicalGDPpc, pinned to a commit (see `dataset_url`).
# - Boundaries: the Shinylive bundle of the former explorer
#   (historicalGDPpc_app/docs/app.json), which embeds the shapefiles.
# Output: data/historical-gdp/
#   historical-gdppc.csv  tidy dataset, used for download and by the explorer
#   regions.geojson       simplified regional boundaries (NUTS, GADM, US/CA metro areas)
#   countries.geojson     simplified country boundaries, incl. historical special cases
#
# Run from the project root:
#   & 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' tools/build-gdp-data.R

suppressPackageStartupMessages({
  library(jsonlite)
  library(readxl)
  library(sf)
  library(dplyr)
})
sf_use_s2(FALSE)

bundle <- "historicalGDPpc_app/docs/app.json"
dataset_url <- paste0(
  "https://raw.githubusercontent.com/philmkoch/historicalGDPpc/",
  "4d536d4aa55bebeaea2fe9f5289ffc916c1ee8de/historicalGDPs_augmented_dataset.xlsx"
)
out_dir <- "data/historical-gdp"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# --- Unpack the bundle into a temporary folder ------------------------------
src <- file.path(tempdir(), "gdp-app")
dir.create(src, showWarnings = FALSE)
for (f in fromJSON(bundle, simplifyDataFrame = FALSE)) {
  p <- file.path(src, f$name)
  dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
  if (identical(f$type, "binary")) writeBin(base64_dec(f$content), p)
  else writeLines(f$content, p, useBytes = TRUE)
}

# --- Dataset ----------------------------------------------------------------
xlsx <- file.path(tempdir(), "historicalGDPs_augmented_dataset.xlsx")
download.file(dataset_url, xlsx, mode = "wb", quiet = TRUE)
gdp <- as.data.frame(read_excel(xlsx))
stopifnot(nrow(gdp) == 5700)

# Correct four source labels that are shifted by one row in v3. The values are
# right; only `flag` is misaligned. Checked against v1 of the dataset and the
# Maddison Project Database 2020 (NLD 2000 = 37,900; POL 2000 = 12,732):
# NLD/POL 2000 are Maddison source data, and NLD_2 1800 / POL_2 1850 are
# out-of-sample estimates (they carry confidence intervals).
flag_fix <- c(
  NLD_2000   = "source data (Maddison Project)",
  POL_2000   = "source data (Maddison Project)",
  NLD_2_1800 = "out-of-sample prediction",
  POL_2_1850 = "out-of-sample prediction"
)
i <- match(names(flag_fix), gdp$ID)
stopifnot(!anyNA(i),
          all(is.na(gdp$GDPpc_lower[i[1:2]])), all(!is.na(gdp$GDPpc_lower[i[3:4]])))
gdp$flag[i] <- flag_fix
# Consistency: every source observation lacks a CI, every estimate has one.
oos <- gdp$flag == "out-of-sample prediction"
stopifnot(all(is.na(gdp$GDPpc_lower[!oos])), all(!is.na(gdp$GDPpc_lower[oos])))

gdp$location_name[gdp$location == "UKI1"] <- "Inner London"
gdp$location_name[gdp$location == "UKI2"] <- "Outer London"

level <- ifelse(nchar(gdp$location) == 3 | grepl("^[A-Z]{3}_\\d$", gdp$location),
                "country", "region")
level[gdp$location %in% c("WAL", "SCO")] <- "country"
level[grepl("^(US|CN)\\d", gdp$location)] <- "region"

tidy <- data.frame(
  id        = gdp$location,
  name      = trimws(gdp$location_name),
  country   = gdp$country_0,
  level     = level,
  year      = as.integer(gdp$year),
  gdppc     = round(as.numeric(gdp$GDPpc), 0),
  lower     = round(as.numeric(gdp$GDPpc_lower), 0),
  upper     = round(as.numeric(gdp$GDPpc_upper), 0),
  estimated = gdp$flag == "out-of-sample prediction",
  source    = sub("^source data \\((.*)\\)$", "\\1", gdp$flag)
)
tidy$source[tidy$estimated] <- "Out-of-sample estimate"
tidy <- tidy[order(tidy$id, tidy$year), ]
write.csv(tidy, file.path(out_dir, "historical-gdppc.csv"), row.names = FALSE, na = "")

# --- Geometry helpers -------------------------------------------------------
shp <- function(x) st_read(file.path(src, "shp", x), quiet = TRUE)

# Drop islands and slivers too small to see at the map's zoom levels.
drop_specks <- function(x, min_area) {
  keys <- setdiff(names(x), attr(x, "sf_column"))
  parts <- suppressWarnings(st_cast(st_cast(x, "MULTIPOLYGON"), "POLYGON"))
  area <- as.numeric(st_area(parts))
  # Keep at least the largest part of every feature.
  biggest <- ave(area, do.call(paste, st_drop_geometry(parts)[keys]), FUN = max)
  parts[area >= min_area | area == biggest, ] |>
    group_by(across(all_of(keys))) |> summarise(.groups = "drop")
}

slim <- function(x, tol) {
  x |>
    st_make_valid() |>
    st_transform(3857) |>
    st_simplify(preserveTopology = TRUE, dTolerance = tol) |>
    drop_specks(min_area = (2 * tol)^2) |>
    st_transform(4326) |>
    st_make_valid() |>
    filter(!st_is_empty(geometry)) |>
    st_cast("MULTIPOLYGON", warn = FALSE)
}

write_geo <- function(x, file) {
  path <- file.path(out_dir, file)
  if (file.exists(path)) file.remove(path)
  st_write(x, path, driver = "GeoJSON", quiet = TRUE,
           layer_options = c("COORDINATE_PRECISION=3", "RFC7946=YES"))
}

ids <- unique(tidy$id)

# --- Regions ----------------------------------------------------------------
eu <- shp("continentalEurope.shp")
eu$NUTS_ID[eu$NUTS_ID %in% c("UKI3", "UKI4")] <- "UKI1"
eu$NUTS_ID[eu$NUTS_ID %in% c("UKI5", "UKI6", "UKI7")] <- "UKI2"
eu <- eu |> transmute(id = NUTS_ID)
us <- shp("US_MSAs.shp") |> transmute(id = paste0("US", GEOID))
# The dataset uses the 5-digit CMAPUID (province + CMA code), not the 3-digit CMAUID.
ca <- shp("CAN_MSAs.shp") |> transmute(id = paste0("CN", CMAPUID))

regions <- bind_rows(st_transform(eu, 4326), st_transform(us, 4326), st_transform(ca, 4326)) |>
  filter(id %in% ids) |>
  group_by(id) |> summarise(.groups = "drop") |>
  slim(tol = 2500)
write_geo(regions, "regions.geojson")

# --- Countries --------------------------------------------------------------
world <- shp("world-administrative-boundaries.shp") |>
  st_transform(4326) |>
  transmute(id = iso3, label = NA_character_, variant = "modern")

specials <- shp("specialcountries.shp") |> st_transform(4326)
krakow <- shp("continentalEurope.shp") |> filter(NUTS_ID == "PL21") |> st_transform(4326)
specials <- bind_rows(
  specials |> transmute(id = ID_0, label = COUNTRY),
  krakow |> transmute(id = "POL", label = "Poland (Krakow only)")
)
specials$id <- recode(specials$id, NLD_1 = "NLD", ENG = "GBR", N_ITA = "ITA")
specials$variant <- "historical"

countries <- bind_rows(world, specials) |>
  filter(id %in% ids) |>
  group_by(id, label, variant) |> summarise(.groups = "drop") |>
  slim(tol = 6000)
write_geo(countries, "countries.geojson")

# --- Report -----------------------------------------------------------------
missing <- setdiff(ids, c(regions$id, countries$id))
cat("Rows:", nrow(tidy), " Places:", length(ids),
    " Source:", sum(!tidy$estimated), " Estimates:", sum(tidy$estimated), "\n")
cat("Places without geometry:", if (length(missing)) paste(missing, collapse = ", ") else "none", "\n")
for (f in list.files(out_dir, pattern = "\\.(csv|geojson)$", full.names = TRUE))
  cat(sprintf("%-40s %6.0f KB\n", f, file.size(f) / 1024))
