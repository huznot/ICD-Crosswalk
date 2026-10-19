# merges the per track reranker/cv_rerank.R outputs after a parallel run
#   Rscript scripts/reranker/cv_rerank.R 10_9 &  Rscript scripts/reranker/cv_rerank.R 8_9 &
#   Rscript scripts/reranker/merge_cv.R
# not needed if reranker/cv_rerank.R ran with no arguments

source("scripts/paths.R")

suppressMessages(library(dplyr))
OUT_DIR <- "results"

parts <- list.files(OUT_DIR, pattern = "^cv_rerank_part_.*\\.rds$", full.names = TRUE)
if (!length(parts)) stop("no cv_rerank_part_*.rds found in ", OUT_DIR)
cat(sprintf("Merging %d track part(s): %s\n", length(parts),
            paste(basename(parts), collapse = ", ")))

p <- lapply(parts, readRDS)
results <- bind_rows(lapply(p, `[[`, "results"))
folds   <- bind_rows(lapply(p, `[[`, "folds"))
imp     <- bind_rows(lapply(p, `[[`, "imp"))
preds   <- bind_rows(lapply(p, `[[`, "preds"))

write.csv(results, out_path("cv_rerank_results.csv"), row.names = FALSE)
write.csv(folds,   out_path("cv_rerank_folds.csv"),   row.names = FALSE)
saveRDS(preds, out_path("cv_rerank_predictions.rds"))

importance <- imp %>% group_by(track, Feature) %>%
  summarise(gain = mean(Gain), .groups = "drop") %>% arrange(track, desc(gain))
write.csv(importance, out_path("cv_rerank_importance.csv"), row.names = FALSE)

cat(sprintf("Merged: %d result rows, %d fold rows, %d prediction rows, tracks: %s\n",
            nrow(results), nrow(folds), nrow(preds),
            paste(unique(results$track), collapse = ", ")))
