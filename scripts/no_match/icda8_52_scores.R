# icd-9 to icda-8 scores with all 52 no-match codes kept in
# every cutoff x top n x rule, both models
# writes 52_codes_accuracy_effect.csv, no_match/icda8_52_review.R reads it

source("scripts/paths.R")
source("scripts/pipeline_lib.R")

ORIG <- "data/original"
GEN  <- "data/generated"
VAL  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/Validation_Data .xlsx")
LAB  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/ICD_Codes_Labels.xlsx")
OUT  <- out_path("52_codes_accuracy_effect.csv")

MODELS <- c(ClinicalBERT = "cosine_similarity_matrices_8_9_clinicalbert_base_nocode.xlsx",
            SapBERT      = "cosine_similarity_matrices_8_9_sapbert_base_nocode.xlsx")
THRESHOLDS <- c(0.95, 0.99, 0.995, 0.999, 1)
TOP_NS     <- seq(5, 30, by = 5)
RULES      <- 1:4
RULE_TEXT  <- c("1" = "top cosine or top co-occurrence",
                "2" = "top cosine or in both lists",
                "3" = "top co-occurrence or in both lists",
                "4" = "any of the three")

man  <- read_excel(VAL, sheet = "Validaion_ICD9_ICD8")
excl <- read_excel(VAL, sheet = "Validation_ICD9_ICD8_Excld")
ccs  <- read_excel(LAB, sheet = "CCS ICD-9-CM-3Level") %>% select(ICD_9_CM, CCS_ID)
cooc <- load_cooccurrence_df(file.path(ORIG, "Co_occurrence/icd_8_9_co_occurrence_3d.xlsx"))

e52 <- as.character(excl$`ICD-9-CM`)
stopifnot(length(e52) == 52)

co_by_n <- setNames(lapply(TOP_NS, function(tn)
  get_cooccurrence_codes_from_df(cooc, tn, "ICD_9_CM_Code", "ICDA_8_Code", "ICDA_8")),
  as.character(TOP_NS))

rows <- list()
for (m in names(MODELS)) {
  sheets <- load_similarity_sheets(file.path(GEN, MODELS[[m]]))
  for (thr in THRESHOLDS) {
    sim <- get_similarity_scores_from_sheets(sheets, thr, "ICDA_8")
    for (tn in TOP_NS) {
      mg <- merge_and_flag(sim, co_by_n[[as.character(tn)]], "ICDA_8",
                           find_icda8_chapter, chapter_alignment_8)
      for (rl in RULES) {
        au  <- select_rows_by_flags(mg, rl)
        fin <- validate_mapping(man, au, ccs, excl, "ICDA-8", "ICDA_8")
        tp <- sum(fin$`True Positive`, na.rm = TRUE)
        fp <- sum(fin$`False Positive`, na.rm = TRUE)
        fn <- sum(fin$`False Negative`, na.rm = TRUE)
        rows[[length(rows) + 1]] <- data.frame(
          Model = m, `Rule number` = rl, Rule = unname(RULE_TEXT[as.character(rl)]),
          `Similarity threshold` = thr, `Top N co-occurring` = tn,
          `Mappings produced` = nrow(au),
          `False positives from the 52 codes` = sum(as.character(au$ICD_9_CM) %in% e52),
          `Correct pairs to find` = tp + fn,
          `True positives` = tp, `False positives` = fp, `False negatives` = fn,
          Precision = round(tp / (tp + fp), 3),
          Recall    = round(tp / (tp + fn), 3),
          F1        = round(2 * tp / (2 * tp + fp + fn), 3),
          Accuracy  = round(tp / (tp + fp + fn), 3),   # no true negatives to use
          check.names = FALSE)
      }
    }
  }
  cat("done", m, "\n")
}
eff <- do.call(rbind, rows)
eff <- eff[order(eff$Model, eff$`Rule number`, eff$`Similarity threshold`,
                 eff$`Top N co-occurring`), ]

# ties go to lower cutoff/top n
best <- unlist(lapply(split(seq_len(nrow(eff)), paste(eff$Model, eff$`Rule number`)),
                      function(i) i[order(-eff$F1[i], eff$`Similarity threshold`[i],
                                          eff$`Top N co-occurring`[i])][1]))
eff$`Best for this model and rule` <- ifelse(seq_len(nrow(eff)) %in% best, "yes", "")
eff <- eff[, c(1:5, ncol(eff), 6:(ncol(eff) - 1))]

print(eff[eff$`Best for this model and rule` == "yes",
          c("Model", "Rule number", "Similarity threshold", "Top N co-occurring",
            "Precision", "Recall", "F1")], row.names = FALSE)

write.csv(eff, OUT, row.names = FALSE)
cat("\nwrote", OUT, "\n")
