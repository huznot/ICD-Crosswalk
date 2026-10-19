# tests for scripts/pipeline_lib.R and scripts/paths.R on small made up data
# run from the repo root: Rscript tests/test_pipeline.R
# exits with status 1 if anything fails

source("scripts/paths.R")
suppressMessages(source("scripts/pipeline_lib.R"))

fails <- 0
check <- function(what, ok) {
  if (isTRUE(ok)) cat("  ok   ", what, "\n")
  else { cat("  FAIL ", what, "\n"); fails <<- fails + 1 }
}
same_set <- function(a, b) setequal(as.character(a), as.character(b))

cat("chapters\n")
check("icd-9 250 is chapter 3", find_icd9cm_chapter("250") == 3)
check("icd-9 001 is chapter 1", find_icd9cm_chapter("001") == 1)
check("icd-9 handles decimals", find_icd9cm_chapter("250.01") == 3)
check("icd-10 E11 is chapter 4", find_icd10ca_chapter("E11") == 4)
check("icd-10 D48 vs D50 split", find_icd10ca_chapter("D48") == 2 && find_icd10ca_chapter("D50") == 3)
check("icda-8 315 is chapter 5", find_icda8_chapter("315") == 5)
check("vectorized lookup keeps order",
      identical(find_icd9cm_chapter(c("800", "001", "250")), c(17L, 1L, 3L)))

cat("chapter distance\n")
check("aligned chapters are 0", compute_chapter_distance(6, 8, chapter_alignment_10) == 0)
check("neighbours are 1", compute_chapter_distance(2, 3, chapter_alignment_10) == 1)
check("far apart is 2", compute_chapter_distance(1, 5, chapter_alignment_10) == 2)
check("missing chapter gives NA", is.na(compute_chapter_distance(NA, 3, chapter_alignment_10)))

cat("similarity cutoff\n")
sheet <- list(s1 = tibble(target = c("E11", "E10", "E13"), `250` = c(0.90, 0.85, 0.50)))
s95 <- get_similarity_scores_from_sheets(sheet, 0.95, "ICD_10_CA")
s90 <- get_similarity_scores_from_sheets(sheet, 0.90, "ICD_10_CA")
s1  <- get_similarity_scores_from_sheets(sheet, 1, "ICD_10_CA")
check("cutoff is relative to the code's best", same_set(s95$ICD_10_CA, "E11"))
check("lower threshold lets more in", same_set(s90$ICD_10_CA, c("E11", "E10")))
check("threshold 1 keeps only the top", same_set(s1$ICD_10_CA, "E11"))

cat("co-occurrence\n")
cooc_raw <- data.frame(ICD_9_CM_Code3 = "250", ICD_10_CA_Code3 = c("E11", "E13", "E14"),
                       Co_Occurrence_Frequency = c(5, 10, 2))
co2 <- get_cooccurrence_codes_from_df(cooc_raw, 2, "ICD_9_CM_Code3", "ICD_10_CA_Code3", "ICD_10_CA")
check("top n keeps the most frequent", same_set(co2$ICD_10_CA, c("E13", "E11")))

cat("merge and rules\n")
sim <- tibble(ICD_9_CM = "250", ICD_10_CA = c("E11", "E10", "K50"), Similarity = c(0.90, 0.80, 0.95))
co  <- tibble(ICD_9_CM = "250", ICD_10_CA = c("E11", "E13"), Co_Occurrence_Frequency = c(5, 10))
mg  <- merge_and_flag(sim, co, "ICD_10_CA", find_icd10ca_chapter, chapter_alignment_10)
check("chapter filter drops K50", !("K50" %in% mg$ICD_10_CA))
rule <- function(r) select_rows_by_flags(mg, r)$ICD_10_CA
check("rule 1 = top cosine or top cooc", same_set(rule(1), c("E11", "E13")))
check("rule 2 = top cosine or in both", same_set(rule(2), "E11"))
check("rule 3 = top cooc or in both", same_set(rule(3), c("E11", "E13")))
check("rule 4 = any of the three", same_set(rule(4), c("E11", "E13")))
check("bad rule number errors", inherits(try(select_rows_by_flags(mg, 5), silent = TRUE), "try-error"))

cat("scoring\n")
manual <- tibble(`ICD-9-CM` = c("250", "250"), `ICD-10-CA` = c("E11", "E10"))
auto   <- tibble(ICD_9_CM = c("250", "250", "338"), ICD_10_CA = c("E11", "E13", "R52"))
ccs    <- tibble(ICD_9_CM = c("250", "338"), CCS_ID = c(49, 259))
excl   <- tibble(`ICD-9-CM` = "338")
v  <- validate_mapping(manual, auto, ccs, excl, "ICD-10-CA", "ICD_10_CA")
vd <- validate_mapping(manual, auto, ccs, excl, "ICD-10-CA", "ICD_10_CA", drop_unmatched = TRUE)
tot <- function(d, col) sum(d[[col]], na.rm = TRUE)
check("tp / fp / fn counted", tot(v, "True Positive") == 1 && tot(v, "False Positive") == 2 &&
                              tot(v, "False Negative") == 1)
check("no-match code counts as fp by default", "338" %in% v$`ICD-9-CM`[v$`False Positive` == 1])
check("drop_unmatched takes it out", tot(vd, "False Positive") == 1)
ov <- calculate_performance_metrics(v)$overall
check("precision, recall, f1, accuracy",
      ov$overall_precision == 0.333 && ov$overall_recall == 0.5 &&
      ov$overall_f1_score == 0.4 && ov$overall_accuracy == 0.25)

cat("output folders\n")
check("tables split by topic", results_subdir("bootstrap_deltas.csv") == "tables/variability" &&
                               results_subdir("trend_x.csv") == "tables/descriptive")
check("category plots", results_subdir("plot_ccs_f1_distribution.png") == "figures/categories")
check("workbooks", results_subdir("1_threshold_frequencies.xlsx") == "workbooks")
check("review files", results_subdir("52_codes_review.xlsx") == "review")
check("unknown names go to tables", results_subdir("something_new.csv") == "tables")

cat(if (fails) sprintf("\n%d failed\n", fails) else "\nall passed\n")
if (fails) quit(status = 1)
