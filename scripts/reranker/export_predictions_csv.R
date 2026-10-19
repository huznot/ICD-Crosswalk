# exports the out of fold predictions as csv, to check without r
# the rds files stay, the scripts load those

source("scripts/paths.R")

OUT <- "results/rerank/csv_export"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)

files <- c(out_path("cv_rerank_predictions.rds"),
           out_path("heldout_counts_10_9.rds"),
           out_path("heldout_counts_8_9.rds"))

for (f in files) {
  if (!file.exists(f)) {
    cat(sprintf("  [missing %s, skipped]\n", f))
    next
  }
  d <- readRDS(f)
  p <- file.path(OUT, sub("\\.rds$", ".csv", basename(f)))
  write.csv(d, p, row.names = FALSE)
  cat(sprintf("  wrote %s (%d rows, %d cols)\n", p, nrow(d), ncol(d)))
}

cat("\nDone.\n")
