# reproduces the original pipeline's numbers on the original matrices
# the original dropped the no-match codes before scoring, so this does too
# run from the repo root: Rscript tests/sanity_check.R, takes about a minute
# exits with status 1 if a number is off

source("scripts/paths.R")
suppressMessages(source("scripts/pipeline_lib.R"))

ORIG <- "data/original"
VAL  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/Validation_Data .xlsx")
LAB  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/ICD_Codes_Labels.xlsx")
ccs  <- read_excel(LAB, sheet = "CCS ICD-9-CM-3Level") %>% select(ICD_9_CM, CCS_ID)

fails <- 0
compare <- function(name, got, want) {
  g <- unlist(got)[c("overall_precision", "overall_recall", "overall_f1_score", "overall_accuracy")]
  ok <- all(abs(g - want) <= 0.0015)
  cat(sprintf("%-22s want %s\n%-22s got  %s  %s\n", name, paste(want, collapse = " "),
              "", paste(g, collapse = " "), if (ok) "ok" else "FAIL"))
  if (!ok) fails <<- fails + 1
}

r10 <- run_pipeline_10_9_cached(
  load_similarity_sheets(file.path(ORIG, "Cosine_Similarity_Matrices/cosine_similarity_matrices_10_9_ClinicalBERT.xlsx")),
  load_cooccurrence_df(file.path(ORIG, "Co_occurrence/icd_10_9_co_occurrence_3c.xlsx")),
  read_excel(VAL, sheet = "Validation_ICD9_ICD10"), ccs,
  read_excel(VAL, sheet = "Validation_ICD9_ICD10_Excld"),
  similarity_threshold = 0.995, top_n = 10, flag_combination = 3, drop_unmatched = TRUE)
compare("icd-9 to icd-10-ca", r10$overall, c(0.686, 0.277, 0.395, 0.246))

r8 <- run_pipeline_8_9_cached(
  load_similarity_sheets(file.path(ORIG, "Cosine_Similarity_Matrices/cosine_similarity_matrices_8_9_ClinicalBERT.xlsx")),
  load_cooccurrence_df(file.path(ORIG, "Co_occurrence/icd_8_9_co_occurrence_3d.xlsx")),
  read_excel(VAL, sheet = "Validaion_ICD9_ICD8"), ccs,
  read_excel(VAL, sheet = "Validation_ICD9_ICD8_Excld"),
  similarity_threshold = 0.995, top_n = 5, flag_combination = 3, drop_unmatched = TRUE)
compare("icd-9 to icda-8", r8$overall, c(0.753, 0.680, 0.714, 0.556))

cat(if (fails) "\nnumbers don't match the original\n" else "\nmatches the original\n")
if (fails) quit(status = 1)
