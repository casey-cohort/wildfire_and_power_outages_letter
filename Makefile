# Makefile for the wildfire & power outages analysis pipeline.
#
# Pipeline:
#   analysis/0_data/<name>.sh          -> download raw data into data/raw/<name>/
#   analysis/1_preprocessing/<name>.R  -> read raw data, write data/processed/<name>.parquet
#   analysis/2_figures/<name>.R        -> read merged.parquet, write figures/<name>/*.png
#
# All scripts use paths relative to the project root, so always run make from
# the project root (that is where this file lives).

R           := Rscript
DATA        := analysis/0_data
PREP        := analysis/1_preprocessing
FIG         := analysis/2_figures

# Set NO_DOWNLOAD=1 to reuse whatever raw data is already on disk instead of
# (re)downloading it. Handy after editing a download script or when you only
# want to re-run preprocessing:
#
#   make NO_DOWNLOAD=1              # rebuild processed data, never download
#   make wfbz NO_DOWNLOAD=1         # rebuild one target without downloading
#
# `download` wraps each download recipe: with NO_DOWNLOAD set it skips the
# command and reuses the existing file, erroring only if it is actually missing.
NO_DOWNLOAD ?=
download = $(if $(NO_DOWNLOAD),@test -e $@ && echo "  NO_DOWNLOAD: reusing $@" || { echo "  NO_DOWNLOAD set but $@ is missing" >&2; exit 1; },$1)

PROCESSED := \
	data/processed/eagle-i.parquet \
	data/processed/wfbz.parquet \
	data/processed/wfsmoke.parquet

# merge.R joins the individual processed datasets into one merged table, so its
# output depends on all of the above.
MERGED := merged.parquet

# Each figures/*.R script writes several PNGs at once into its own
# figures/<name>/ directory, so — like eagle-i's and county's downloads — we
# track a .stamp file rather than the individual PNGs.
FIGURES := \
	figures/by_state/.stamp \
	figures/time_series/.stamp

.PHONY: all data figures clean clean-processed clean-raw clean-figures help
.DELETE_ON_ERROR:

all: $(MERGED) $(FIGURES)                ## Build every processed dataset and figure (default)

data: data/raw/eagle-i/.stamp \
      data/raw/wfbz/wfbz.geojson \
      data/raw/wfsmoke/wfsmoke.rds \
      data/raw/county/.stamp             ## Download all raw data

figures: $(FIGURES)                      ## Generate all figures

# ---------------------------------------------------------------------------
# 0. Download raw data
# ---------------------------------------------------------------------------

# eagle-i.sh pulls many files from figshare via figshare_sync.sh, so we track a
# stamp rather than a single output file.
data/raw/eagle-i/.stamp: $(DATA)/eagle-i.sh $(DATA)/figshare_sync.sh
	$(call download,$(DATA)/eagle-i.sh)
	@touch $@

data/raw/wfbz/wfbz.geojson: $(DATA)/wfbz.sh
	$(call download,$(DATA)/wfbz.sh)

data/raw/wfsmoke/wfsmoke.rds: $(DATA)/wfsmoke.sh
	$(call download,$(DATA)/wfsmoke.sh)

# counties.R downloads one county shapefile per year (2018-2025), so we track a
# stamp rather than a single output file.
data/raw/county/.stamp: $(DATA)/counties.R
	$(call download,$(R) $(DATA)/counties.R)
	@touch $@

# ---------------------------------------------------------------------------
# 1. Preprocess raw -> processed
# ---------------------------------------------------------------------------

data/processed/eagle-i.parquet: $(PREP)/eagle-i.R data/raw/eagle-i/.stamp data/raw/county/.stamp
	$(R) $<

data/processed/wfbz.parquet: $(PREP)/wfbz.R data/raw/wfbz/wfbz.geojson data/raw/county/.stamp
	$(R) $<

data/processed/wfsmoke.parquet: $(PREP)/wfsmoke.R data/raw/wfsmoke/wfsmoke.rds
	$(R) $<

# merge depends on every individual processed dataset; re-run it whenever any of
# them (or merge.R itself) changes.
$(MERGED): $(PREP)/merge.R $(PROCESSED)
	$(R) $<

# ---------------------------------------------------------------------------
# 2. Generate figures
# ---------------------------------------------------------------------------

# A directory can't be the target itself: its mtime only changes when a file
# is added or removed inside it, not when an existing PNG is rewritten, so
# make would fail to notice regions.R had changed and needed to re-run. A
# .stamp file, touched after the script succeeds, gives make something with a
# real mtime to key off instead.

figures/by_state/.stamp: $(FIG)/regions.R $(MERGED)
	@mkdir -p $(@D)
	$(R) $<
	@touch $@

figures/time_series/.stamp: $(FIG)/time_series.R $(MERGED)
	@mkdir -p $(@D)
	$(R) $<
	@touch $@

# ---------------------------------------------------------------------------
# Housekeeping
# ---------------------------------------------------------------------------

clean-processed:                         ## Remove processed parquet files
	rm -f $(PROCESSED) $(MERGED)

clean-raw:                               ## Remove downloaded raw data
	rm -rf data/raw/eagle-i data/raw/wfbz data/raw/wfsmoke data/raw/county

clean-figures:                           ## Remove generated figures
	rm -rf figures/by_state figures/time_series

clean: clean-processed clean-raw clean-figures  ## Remove all generated data

help:                                    ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'