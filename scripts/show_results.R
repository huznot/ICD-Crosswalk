# prints the headline numbers from saved results, about a second

source("scripts/paths.R")

suppressMessages({library(dplyr)})

get <- function(f) {
  p <- out_path(f)
  if (!file.exists(p)) { cat(sprintf("  [missing %s, rerun the script that makes it]\n", f)); return(NULL) }
  read.csv(p, stringsAsFactors = FALSE)
}
hdr <- function(n, s) cat(sprintf("\n\n=========== %s. %s ===========\n", n, s))
tname <- function(x) ifelse(x == "10_9", "ICD-9 to ICD-10-CA", "ICD-9 to ICDA-8")

hdr(1, "embedding model comparison, best f1 over the full grid")
d <- get("full_grid_best.csv")
if (!is.null(d)) {
  for (tr in c("10_9", "8_9")) {
    cat(sprintf("\n%s\n", tname(tr)))
    x <- d[d$track == tr, ] %>% arrange(desc(f1))
    for (i in seq_len(nrow(x)))
      cat(sprintf("  %-38s f1 %.3f\n", x$model[i], x$f1[i]))
  }
}

hdr(2, "where correct pairs are lost in the four step pipeline")
d <- get("error_analysis_summary.csv")
if (!is.null(d)) {
  x <- d[d$model == "SapBERT", ]
  cat("\n  share of correct pairs in the manual crosswalk that survive each step,\n")
  cat("  sapbert at its best setting:\n\n")
  cat(sprintf("  %-36s %10s %10s\n", "", "ICD-10-CA", "ICDA-8"))
  # pct_in_universe is always 100, just a check
  rows <- list(
    c("survives the similarity cutoff",  "pct_pass_threshold"),
    c("in the co-occurrence list",       "pct_in_cooc"),
    c("kept after the chapter filter",   "pct_in_pool"),
    c("output by the rule",              "pct_emitted"))
  for (r in rows)
    cat(sprintf("  %-36s %9.1f%% %9.1f%%\n", r[1],
                x[x$track == "10_9", r[2]], x[x$track == "8_9", r[2]]))
  cat(sprintf("\n  %-36s %10.3f %10.3f\n", "best f1 possible from what survives",
              x[x$track == "10_9", "oracle_f1"], x[x$track == "8_9", "oracle_f1"]))
}

hdr(3, "how much the numbers move on a different set of codes")
d <- get("bootstrap_variability.csv")
if (!is.null(d)) {
  d <- d[d$metric == "f1", ]
  for (tr in c("10_9", "8_9")) {
    x <- d[d$track == tr, ]
    cat(sprintf("\n%s\n", tname(tr)))
    for (i in seq_len(nrow(x)))
      cat(sprintf("  %-22s f1 %.3f  (sd %.3f, 95%% %.3f to %.3f)\n",
                  x$model[i], x$estimate[i], x$sd[i], x$ci_low[i], x$ci_high[i]))
  }
  cat("\n  2000 bootstrap draws, resampling whole icd-9 codes\n")
}

hdr(4, "spread across the 130 ccs categories")
d <- get("ccs_category_summary.csv")
if (!is.null(d)) {
  for (tr in c("10_9", "8_9")) {
    x <- d[d$track == tr, ]
    cat(sprintf("\n%s\n", tname(tr)))
    for (i in seq_len(nrow(x)))
      cat(sprintf("  %-22s mean %.3f  sd %.3f  median %.3f  perfect %d  zero %d\n",
                  x$model[i], x$mean_f1[i], x$sd_f1[i], x$median_f1[i],
                  x$n_perfect[i], x$n_zero[i]))
  }
  cat("\n  59 of 130 categories hold a single code, so their f1 is noisy\n")
}

cat("\nthe workbooks linked in the readme have the head to head and cutoff results\n")
