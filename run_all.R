# rebuilds everything from the committed data, in dependency order
# about 45 min on 8 cores. run from the repo root: Rscript run_all.R
# --quick skips the parameter searches
# embeddings aren't rebuilt here, see scripts/embeddings/run_all_embeddings.sh

source("scripts/paths.R")

QUICK <- "--quick" %in% commandArgs(trailingOnly = TRUE)

RSCRIPT <- file.path(R.home("bin"), "Rscript")

run <- function(script, args = character()) {
  cat(sprintf("\n===== %s %s =====\n", script, paste(args, collapse = " ")))
  t0 <- Sys.time()
  st <- system2(RSCRIPT, c(file.path("scripts", script), args))
  mins <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
  if (st != 0) stop(script, " failed with status ", st)
  cat(sprintf("----- %s done in %.1f min\n", script, mins))
}

run("../tests/test_pipeline.R")

# four step pipeline, full grid
if (!QUICK) {
  run("grid/full_grid.R")                    # slowest step, all 12 conditions
  run("grid/assemble_full_grid.R")
  run("analysis/error_analysis.R")
  run("analysis/candidate_generation.R")
}
run("grid/absolute_threshold_grid.R")        # lots of later scripts read this

# reranker
run("reranker/features.R")
run("reranker/cv_rerank.R", "10_9")
run("reranker/cv_rerank.R", "8_9")
run("reranker/merge_cv.R")
run("reranker/precision_coverage.R")
if (!QUICK) {
  # pass one track at a time
  for (tr in c("10_9", "8_9")) {
    run("reranker/ablation.R", tr)
    run("reranker/retrieval_sensitivity.R", tr)
    run("reranker/learning_curve.R", tr)
    run("reranker/category_holdout.R", tr)
  }
  run("reranker/portability.R")
}
run("reranker/top1_accuracy.R")
run("reranker/error_by_code_type.R")
run("reranker/target_blocks.R")

# one off analyses
run("analysis/variability.R")
run("analysis/category_breakdown.R")
if (!QUICK) run("analysis/code_prefix_test.R")
run("analysis/frequency_distributions.R")
run("analysis/stopword_choice.R")
run("analysis/stopwords_and_codes.R")
run("analysis/identical_labels.R")
run("analysis/descriptive_by_code.R")        # trend_tables.R reads this
run("analysis/trend_tables.R")

# codes with no reference match
# nine_codes_review.R skipped on purpose, it wipes hand formatting
run("no_match/unmatched_codes.R")
run("no_match/unmatched_descriptives.R")
run("no_match/unmatched_handout.R")
run("no_match/e13_d48_review.R")
run("no_match/icda8_52_list.R")
run("no_match/icda8_52_scores.R")
run("no_match/icda8_52_review.R")

# workbooks linked from the readme
run("workbooks/threshold_frequencies.R")
run("workbooks/icda8_code_in_label.R")
run("workbooks/similarity_gap.R")
run("workbooks/category_counts.R")
run("workbooks/clinicalbert_vs_sapbert.R")

run("show_results.R")

cat("\nall done. results/ is rebuilt.\n")
