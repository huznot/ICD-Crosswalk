source(if (file.exists("paths.R")) "paths.R" else "scripts/paths.R")
source("scripts/pipeline_lib.R")
suppressMessages(library(openxlsx))

# the 52 icd-9 codes with no icda-8 match were reviewed in
# 52_icda8_excluded_list.R, where six look wrong. the icda-8 estimates account
# for them the same way the icd-9 to icd-10-ca ones do.
#
# nothing in the repo ever dropped them: validate_mapping defaults to
# drop_unmatched = FALSE and no script overrides it. so they are already in
# every reported number. this quantifies what that is worth, and what the six
# corrections would change, by running three scenarios side by side:
#
#   codes dropped        the old behaviour, scored only on codes with a match
#   codes included       what the repo already does
#   six corrections      the six from the review treated as real matches

ORIG <- "data/original"
GEN  <- "data/generated"
VAL  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/Validation_Data .xlsx")
LAB  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/ICD_Codes_Labels.xlsx")
OUT  <- out_path("52_codes_accuracy_effect.csv")   # 59_ reads this into the review workbook

MODELS <- c(ClinicalBERT = "cosine_similarity_matrices_8_9_clinicalbert_base_nocode.xlsx",
            SapBERT      = "cosine_similarity_matrices_8_9_sapbert_base_nocode.xlsx")
# every cutoff crossed with every top n, so the effect of each step can be read
# off directly. the cutoffs and top n values are the ones in table 2 of the
# methods paper for this track (0.990 to 1.0, top 5 to 30 in steps of 5), plus
# 0.95 which the earlier version of this table used
THRESHOLDS <- c(0.95, 0.99, 0.995, 0.999, 1)   # the 8_9 track still uses the relative rule
TOP_NS     <- seq(5, 30, by = 5)
RULES      <- 1:4
RULE_TEXT  <- c("1" = "top cosine or top co-occurrence",
                "2" = "top cosine or in both lists",
                "3" = "top co-occurrence or in both lists",
                "4" = "any of the three")

# the six the review marked as validation data wrong, where the icda-8 code is
# unambiguous and nothing competes. same six as 52_icda8_excluded_list.R
CORRECTIONS <- data.frame(
  icd9  = c("165", "175", "179", "555", "576", "745"),
  icda8 = c("163", "174", "182", "563", "576", "746"),
  note  = c("ICD-8 stops at 163, no other home for ill-defined respiratory sites",
            "ICD-8 did not split breast cancer by sex, 174 covers both",
            "uterus part unspecified has only one home, 182 other",
            "563 is the only chronic inflammatory bowel code in ICD-8",
            "the same thing under the same number",
            "746 is the only heart code, the numbers do not line up"),
  stringsAsFactors = FALSE)

man  <- read_excel(VAL, sheet = "Validaion_ICD9_ICD8")
excl <- read_excel(VAL, sheet = "Validation_ICD9_ICD8_Excld")
ccs  <- read_excel(LAB, sheet = "CCS ICD-9-CM-3Level") %>% select(ICD_9_CM, CCS_ID)
cooc <- load_cooccurrence_df(file.path(ORIG, "Co_occurrence/icd_8_9_co_occurrence_3d.xlsx"))
a8   <- read_excel(LAB, sheet = "ICDA-8-3Level")
lab9 <- read_excel(LAB, sheet = "CCS ICD-9-CM-3Level")

e52 <- as.character(excl$`ICD-9-CM`)
stopifnot(length(e52) == 52, all(CORRECTIONS$icd9 %in% e52))

# scenario 3: the six move out of the excluded list and into the validated pairs
man_fix <- rbind(
  data.frame(`ICD-9-CM` = as.character(man$`ICD-9-CM`),
             `ICDA-8` = as.character(man$`ICDA-8`), check.names = FALSE),
  data.frame(`ICD-9-CM` = CORRECTIONS$icd9, `ICDA-8` = CORRECTIONS$icda8, check.names = FALSE))
excl_fix <- excl[!(as.character(excl$`ICD-9-CM`) %in% CORRECTIONS$icd9), ]

SCEN <- list(
  list(name = "codes dropped",   man = man,     excl = excl,     drop = TRUE),
  list(name = "codes included",  man = man,     excl = excl,     drop = FALSE),
  list(name = "six corrections", man = man_fix, excl = excl_fix, drop = FALSE))

cat(sprintf("%d validated pairs over %d icd-9 codes, %d codes with no match\n",
            nrow(man), length(unique(as.character(man$`ICD-9-CM`))), length(e52)))
cat(sprintf("with the six corrections: %d pairs, %d codes with no match\n\n",
            nrow(man_fix), nrow(excl_fix)))

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
        au <- select_rows_by_flags(mg, rl)
        n52 <- sum(as.character(au$ICD_9_CM) %in% e52)
        for (sc in SCEN) {
          fin <- validate_mapping(sc$man, au, ccs, sc$excl, "ICDA-8", "ICDA_8",
                                  drop_unmatched = sc$drop)
          tp <- sum(fin$`True Positive`, na.rm = TRUE)
          fp <- sum(fin$`False Positive`, na.rm = TRUE)
          fn <- sum(fin$`False Negative`, na.rm = TRUE)
          rows[[length(rows) + 1]] <- data.frame(
            Model = m, Scenario = sc$name,
            `Similarity threshold` = thr, `Top N co-occurring` = tn,
            `Rule number` = rl, Rule = unname(RULE_TEXT[as.character(rl)]),
            `Mappings produced` = nrow(au),
            `Mappings for the 52 excluded codes` = n52,
            `Correct pairs to find` = tp + fn,
            `True positives` = tp, `False positives` = fp, `False negatives` = fn,
            Precision = round(ifelse(tp + fp > 0, tp / (tp + fp), NA), 3),
            Recall    = round(ifelse(tp + fn > 0, tp / (tp + fn), NA), 3),
            F1        = round(ifelse(2 * tp + fp + fn > 0, 2 * tp / (2 * tp + fp + fn), NA), 3),
            check.names = FALSE)
        }
      }
    }
  }
  cat("done", m, "\n")
}
res <- do.call(rbind, rows)
res <- res[order(res$Model, res$`Rule number`, res$`Similarity threshold`,
                 res$`Top N co-occurring`, match(res$Scenario, vapply(SCEN, `[[`, "", "name"))), ]

## one row per setting, the scenario that is actually reported, with f1 for the
## other two alongside. sorted so top n climbs within each cutoff, and the f1
## change from the step before is its own column
g <- function(sc) res[res$Scenario == sc, ]
eff <- g("codes included")
key <- function(d) paste(d$Model, d$`Rule number`, d$`Similarity threshold`, d$`Top N co-occurring`)
eff$`F1 if the 52 are dropped` <- g("codes dropped")$F1[match(key(eff), key(g("codes dropped")))]
eff$`F1 with the six fixes`    <- g("six corrections")$F1[match(key(eff), key(g("six corrections")))]
eff$`F1 change from including` <- round(eff$F1 - eff$`F1 if the 52 are dropped`, 3)
# accuracy here is tp / (tp + fp + fn), the measure the rest of the repo uses.
# there is no true negative count to work with
eff$Accuracy <- round(eff$`True positives` /
                      (eff$`True positives` + eff$`False positives` + eff$`False negatives`), 3)
eff <- eff[order(eff$Model, eff$`Rule number`, eff$`Similarity threshold`,
                 eff$`Top N co-occurring`), ]

grp <- paste(eff$Model, eff$`Rule number`, eff$`Similarity threshold`)
prev <- function(x) ave(x, grp, FUN = function(v) c(NA, head(v, -1)))
eff$`Top N before` <- prev(eff$`Top N co-occurring`)
eff$`F1 change from the top N before` <- round(eff$F1 - prev(eff$F1), 3)
eff$`Precision change from the top N before` <- round(eff$Precision - prev(eff$Precision), 3)
eff$`Recall change from the top N before` <- round(eff$Recall - prev(eff$Recall), 3)

# the setting with the best f1 for each model and rule, which is what this table
# used to show on its own. ties go to the smaller cutoff and top n
best <- unlist(lapply(split(seq_len(nrow(eff)), paste(eff$Model, eff$`Rule number`)),
                      function(i) i[order(-eff$F1[i], eff$`Similarity threshold`[i],
                                          eff$`Top N co-occurring`[i])][1]))
eff$`Best for this model and rule` <- ifelse(seq_len(nrow(eff)) %in% best, "yes", "")

eff <- eff[, c("Model", "Rule number", "Rule", "Similarity threshold",
               "Top N co-occurring", "Best for this model and rule",
               "Mappings produced", "Mappings for the 52 excluded codes",
               "Correct pairs to find", "True positives", "False positives",
               "False negatives", "Precision", "Recall", "F1", "Accuracy",
               "Top N before", "Precision change from the top N before",
               "Recall change from the top N before", "F1 change from the top N before",
               "F1 if the 52 are dropped", "F1 with the six fixes",
               "F1 change from including")]

cat("\nbest setting for each model and rule\n")
print(eff[eff$`Best for this model and rule` == "yes",
          c("Model", "Rule number", "Similarity threshold", "Top N co-occurring",
            "Precision", "Recall", "F1", "F1 change from including")], row.names = FALSE)

cat("\nhow far f1 moves for one step up in top n\n")
for (m in names(MODELS)) for (rl in RULES) {
  d <- abs(eff$`F1 change from the top N before`[eff$Model == m & eff$`Rule number` == rl])
  cat(sprintf("  %-12s rule %d  median %.3f  largest %.3f\n", m, rl,
              median(d, na.rm = TRUE), max(d, na.rm = TRUE)))
}

write.csv(eff, OUT, row.names = FALSE)
cat("\nwrote", OUT, "\n")
