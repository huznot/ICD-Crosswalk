# finds the repo root and picks the results/ subfolder for each output
# every script sources this first

local({
  d <- getwd()
  while (!file.exists(file.path(d, "icd_crosswalk.Rproj")) && dirname(d) != d) d <- dirname(d)
  if (!file.exists(file.path(d, "icd_crosswalk.Rproj"))) stop("cant find the repo root above ", getwd())
  setwd(d)
})

# subfolder picked from the file name
results_subdir <- function(name) {
  n <- basename(name)
  if (grepl("^plot_ccs_", n))                                        return("figures/categories")
  if (grepl("^plot_unmatched_", n))                                  return("figures/unmatched")
  if (grepl("^plot_", n))                                            return("figures")
  if (grepl("^full_grid", n))                                        return("grid")
  if (grepl("^unmatched|^validation_pairs", n))                      return("unmatched")
  if (grepl("^(cv_rerank|rerank_features|base_emit|heldout_counts|precision_coverage|candidate_generation|chapter_filter)", n))
                                                                     return("rerank")
  # numbered workbooks for the readme
  if (grepl("^[1-4]_(threshold_frequencies|icda8_code_in_label|similarity_gap_by_model|counts_by_ccs_category)", n))
                                                                     return("workbooks")
  if (grepl("^clinicalbert_vs_sapbert", n))                          return("head_to_head")
  if (grepl("^([0-9]+_codes|e13_d48|cutoff_|absolute_threshold|identical_labels)", n))
                                                                     return("review")
  if (grepl("[.](png|pdf)$", n))                                     return("figures")
  if (grepl("^(grid_results|best_by_model|ccs_breakdown|regression_summary|bidirectional|code_prefix)", n))
                                                                     return("tables/comparison")
  if (grepl("^error_analysis", n))                                   return("tables/errors")
  if (grepl("^(ablation|retrieval_sensitivity|learning_curve|category_holdout|top1_accuracy|portability)", n))
                                                                     return("tables/reranker")
  if (grepl("^(bootstrap|cv_fold_variability)", n))                  return("tables/variability")
  if (grepl("^ccs_", n))                                             return("tables/categories")
  if (grepl("^(freq_dist|similarity_matrix_example|per_code_rank|trend_)", n))
                                                                     return("tables/descriptive")
  "tables"
}

# out_path("x.csv") -> results/tables/x.csv
out_path <- function(...) {
  name <- file.path(...)
  name <- sub("^results[/\\]", "", name)
  p <- if (dirname(name) != ".") file.path("results", name)
       else file.path("results", results_subdir(name), name)
  dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE)
  p
}
