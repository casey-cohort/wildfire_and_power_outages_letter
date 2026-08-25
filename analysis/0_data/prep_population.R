options(scipen = 999)
if (!require("pacman", quietly = TRUE)) {
  install.packages("pacman")
}
pacman::p_load(glue, fs, here)

# ── GHS Population rasters ────────────────────────────────────────────────────
# Defaults: up to one hour total
unzip_url <- function(url, dst, timeout = 60 * 60) {

  if (!dir.exists(dst)) {
    dir.create(dst, recursive = TRUE)
  }

  temp_zip <- tempfile(fileext = ".zip")
  on.exit(unlink(temp_zip, force = TRUE), add = TRUE)

  cat("Starting streaming download of", basename(url), "...\n")

  # Stream download (for very large files)
  tryCatch({
    response <- httr::GET(
      url,
      httr::write_disk(temp_zip, overwrite = TRUE),
      httr::progress(),
      httr::timeout(timeout)
    )

    httr::stop_for_status(response)

    if (!file.exists(temp_zip) || file.size(temp_zip) == 0) {
      stop("Streaming download failed or file is empty")
    }

  }, error = function(e) {
    stop("Streaming download failed: ", e$message)
  })

  cat("Extracting files...\n")

  tryCatch({
    extracted_files <- unzip(temp_zip, exdir = dst, overwrite = TRUE)
    cat("Successfully extracted", length(extracted_files), "files to", dst, "\n")

  }, error = function(e) {
    stop("Extraction failed: ", e$message)
  })

  return(dst)
}

download_spatial_ghs_pop <- function(yr, dst) {
  outfile <- file.path(
    dst,
    glue('GHS_POP_E{yr}_GLOBE_R2023A_54009_100_V1_0.tif')
  )
  if (!fs::file_exists(outfile)) {
    unzip_url(
      glue(
        'https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_POP_GLOBE_R2023A/GHS_POP_E{yr}_GLOBE_R2023A_54009_100/V1-0/GHS_POP_E{yr}_GLOBE_R2023A_54009_100_V1_0.zip'
      ),
      dir_create(dst)
    )
  }
  outfile
}

popfile['2020'] <- download_spatial_ghs_pop(
  2020,
  here('data/raw/')
)
