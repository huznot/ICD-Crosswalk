# how much the f1 scores would move on a different set of codes
# both tracks: icd-9 to icd-10-ca and icd-9 to icda-8
# bootstrap that resamples whole icd-9 codes
# writes bootstrap_*.csv

source("scripts/paths.R")
source("scripts/pipeline_lib.R")
set.seed(42)

ORIG_BASE    <- "data/original"
SAPBERT_BASE <- "data/sapbert"
GEN_BASE     <- "data/generated"
OUT_DIR      <- "results"
B <- 2000

gen <- function(tag) file.path(GEN_BASE, sprintf("cosine_similarity_matrices_%%s_%s.xlsx", tag))

CONDITIONS <- list(
  `ClinicalBERT-original`         = file.path(ORIG_BASE, "Cosine_Similarity_Matrices/cosine_similarity_matrices_%s_ClinicalBERT.xlsx"),
  `ClinicalBERT-base`             = gen("clinicalbert_base"),
  `ClinicalBERT-base-nocode`      = gen("clinicalbert_base_nocode"),
  `ClinicalBERT-stopwords`        = gen("clinicalbert_stopwords"),
  `ClinicalBERT-stopwords-nocode` = gen("clinicalbert_stopwords_nocode"),
  `ClinicalBERT-stopwords-raw`    = gen("clinicalbert_stopwords_raw"),
  `ClinicalBERT-stripped`         = gen("clinicalbert_stripped"),
  `SapBERT-base`                  = file.path(SAPBERT_BASE, "cosine_similarity_matrices_%s_SapBERT.xlsx"),
  `SapBERT-stripped`              = gen("sapbert_stripped"),
  `mpnet-base`                    = gen("mpnet_base"),
  `mpnet-stripped`                = gen("mpnet_stripped")
)

# deltas inside each draw, so paired
COMPARISONS <- list(
  c("ClinicalBERT-base", "ClinicalBERT-original"),
  c("SapBERT-base", "ClinicalBERT-original"),
  c("mpnet-base", "ClinicalBERT-original"),
  c("mpnet-base", "SapBERT-base"),
  c("ClinicalBERT-base-nocode", "ClinicalBERT-base"),
  c("ClinicalBERT-stopwords", "ClinicalBERT-base"),
  c("ClinicalBERT-stopwords-nocode", "ClinicalBERT-base"),
  c("ClinicalBERT-stopwords-nocode", "ClinicalBERT-base-nocode"),
  c("ClinicalBERT-stopwords-raw", "ClinicalBERT-stopwords"),
  c("SapBERT-stripped", "SapBERT-base"),
  c("mpnet-stripped", "mpnet-base")
)

TOP1_ARMS <- list(
  `ClinicalBERT, code and label` = gen("clinicalbert_base"),
  `ClinicalBERT, label only`     = gen("clinicalbert_base_nocode"),
  `SapBERT, code and label`      = file.path(SAPBERT_BASE, "cosine_similarity_matrices_%s_SapBERT.xlsx"),
  `SapBERT, label only`          = gen("sapbert_base_nocode"),
  `mpnet, code and label`        = gen("mpnet_base"),
  `mpnet, label only`            = gen("mpnet_base_nocode")
)
TOP1_COMPARISONS <- list(
  c("ClinicalBERT, label only", "ClinicalBERT, code and label"),
  c("SapBERT, label only", "SapBERT, code and label"),
  c("mpnet, label only", "mpnet, code and label")
)

TRACKS <- list(
  `10_9` = list(target_col_name = "ICD_10_CA", icd9_col = "ICD_9_CM_Code3", target_col = "ICD_10_CA_Code3",
                find_target_chapter_fn = find_icd10ca_chapter, chapter_alignment = chapter_alignment_10,
                manual_target_col = "ICD-10-CA",
                manual_sheet = "Validation_ICD9_ICD10", excl_sheet = "Validation_ICD9_ICD10_Excld",
                cooc_file = "Co_occurrence/icd_10_9_co_occurrence_3c.xlsx"),
  `8_9`  = list(target_col_name = "ICDA_8", icd9_col = "ICD_9_CM_Code", target_col = "ICDA_8_Code",
                find_target_chapter_fn = find_icda8_chapter, chapter_alignment = chapter_alignment_8,
                manual_target_col = "ICDA-8",
                manual_sheet = "Validaion_ICD9_ICD8", excl_sheet = "Validation_ICD9_ICD8_Excld",
                cooc_file = "Co_occurrence/icd_8_9_co_occurrence_3d.xlsx")
)

VAL_XLSX <- file.path(ORIG_BASE, "ICD_Codes_Files_and_Validation_Data/Validation_Data .xlsx")
ccs_df <- read_excel(file.path(ORIG_BASE, "ICD_Codes_Files_and_Validation_Data/ICD_Codes_Labels.xlsx"),
                     sheet = "CCS ICD-9-CM-3Level") %>% select(ICD_9_CM, CCS_ID)
for (tr in names(TRACKS)) {
  TRACKS[[tr]]$manual <- read_excel(VAL_XLSX, sheet = TRACKS[[tr]]$manual_sheet)
  TRACKS[[tr]]$excl   <- read_excel(VAL_XLSX, sheet = TRACKS[[tr]]$excl_sheet)
  TRACKS[[tr]]$cooc   <- load_cooccurrence_df(file.path(ORIG_BASE, TRACKS[[tr]]$cooc_file))
}

best <- read.csv(out_path("full_grid_best.csv"), stringsAsFactors = FALSE)

# per code counts, all the bootstrap needs
per_code_counts <- function(track_name, sheets, thr, tn, fc) {
  tk  <- TRACKS[[track_name]]
  tcn <- tk$target_col_name
  similarity_df   <- get_similarity_scores_from_sheets(sheets, thr, tcn)
  cooccurrence_df <- get_cooccurrence_codes_from_df(tk$cooc, tn, tk$icd9_col, tk$target_col, tcn)
  merged_df <- merge_and_flag(similarity_df, cooccurrence_df, tcn,
                              tk$find_target_chapter_fn, tk$chapter_alignment)
  auto_df   <- select_rows_by_flags(merged_df, fc)
  final_valid_df <- validate_mapping(tk$manual, auto_df, ccs_df, tk$excl,
                                     manual_target_col = tk$manual_target_col,
                                     target_col_name = tcn)
  final_valid_df %>%
    group_by(code = `ICD-9-CM`) %>%
    summarise(TP = sum(`True Positive`, na.rm = TRUE),
              FP = sum(`False Positive`, na.rm = TRUE),
              FN = sum(`False Negative`, na.rm = TRUE), .groups = "drop")
}

metrics_from_totals <- function(tp, fp, fn) {
  p <- ifelse(tp + fp > 0, tp / (tp + fp), 0)
  r <- ifelse(tp + fn > 0, tp / (tp + fn), 0)
  list(precision = p, recall = r,
       f1 = ifelse(p + r > 0, 2 * p * r / (p + r), 0),
       accuracy = ifelse(tp + fp + fn > 0, tp / (tp + fp + fn), 0))
}

resample_matrix <- function(n_codes, B) {
  matrix(sample.int(n_codes, n_codes * B, replace = TRUE), nrow = n_codes, ncol = B)
}

boot_metrics <- function(counts, idx) {
  tp <- colSums(matrix(counts$TP[idx], nrow = nrow(idx)))
  fp <- colSums(matrix(counts$FP[idx], nrow = nrow(idx)))
  fn <- colSums(matrix(counts$FN[idx], nrow = nrow(idx)))
  as.data.frame(metrics_from_totals(tp, fp, fn))
}

boot_summary <- function(point, boot) {
  tibble(estimate = round(point, 4), sd = round(sd(boot), 4),
         ci_low = round(quantile(boot, 0.025, names = FALSE), 4),
         ci_high = round(quantile(boot, 0.975, names = FALSE), 4))
}

align_codes <- function(counts_list) {
  all_codes <- sort(unique(unlist(lapply(counts_list, function(x) x$code))))
  lapply(counts_list, function(x) {
    tibble(code = all_codes) %>%
      left_join(x, by = "code") %>%
      mutate(across(c(TP, FP, FN), ~ tidyr::replace_na(.x, 0L)))
  })
}

# part 1: best grid point f1

var_rows   <- list()
delta_rows <- list()

for (track_name in names(TRACKS)) {
  cat(sprintf("\n=== f1, track %s ===\n", track_name))

  counts_by_model <- list()
  for (model in names(CONDITIONS)) {
    row <- best %>% filter(track == track_name, model == !!model)
    if (nrow(row) != 1) stop("no unique best row for ", model, " on ", track_name)
    path <- sprintf(CONDITIONS[[model]], track_name)
    if (!file.exists(path)) stop("missing similarity matrix: ", path)
    cat(sprintf("  %-30s thr=%.3f top_n=%2d flags=%d\n", model,
                row$similarity_threshold, row$top_n, row$flag_combination))
    counts_by_model[[model]] <- per_code_counts(track_name, load_similarity_sheets(path),
                                                row$similarity_threshold, row$top_n,
                                                row$flag_combination)
  }

  # same resamples everywhere so deltas pair
  counts_by_model <- align_codes(counts_by_model)
  n_codes <- nrow(counts_by_model[[1]])
  idx <- resample_matrix(n_codes, B)
  cat(sprintf("  %d codes, %d bootstrap replicates\n", n_codes, B))

  point_by_model <- list()
  boot_by_model  <- list()
  for (model in names(CONDITIONS)) {
    cnt <- counts_by_model[[model]]
    point_by_model[[model]] <- metrics_from_totals(sum(cnt$TP), sum(cnt$FP), sum(cnt$FN))
    boot_by_model[[model]]  <- boot_metrics(cnt, idx)
    for (m in names(point_by_model[[model]]))
      var_rows[[length(var_rows) + 1]] <- tibble(track = track_name, model = model, metric = m) %>%
        bind_cols(boot_summary(point_by_model[[model]][[m]], boot_by_model[[model]][[m]]))
  }

  for (cmp in COMPARISONS) {
    a <- cmp[1]; b <- cmp[2]
    for (m in c("precision", "recall", "f1", "accuracy")) {
      d_boot <- boot_by_model[[a]][[m]] - boot_by_model[[b]][[m]]
      delta_rows[[length(delta_rows) + 1]] <- tibble(
        track = track_name, model = a, reference = b, metric = m,
        delta = round(point_by_model[[a]][[m]] - point_by_model[[b]][[m]], 4),
        sd = round(sd(d_boot), 4),
        ci_low = round(quantile(d_boot, 0.025, names = FALSE), 4),
        ci_high = round(quantile(d_boot, 0.975, names = FALSE), 4),
        prop_favouring_model = round(mean(d_boot > 0), 4),
        crosses_zero = quantile(d_boot, 0.025, names = FALSE) < 0 &
                       quantile(d_boot, 0.975, names = FALSE) > 0)
    }
  }
}

variability <- bind_rows(var_rows)
deltas      <- bind_rows(delta_rows)
write.csv(variability, out_path("bootstrap_variability.csv"), row.names = FALSE)
write.csv(deltas, out_path("bootstrap_deltas.csv"), row.names = FALSE)

cat("\n=== f1 with bootstrap standard deviation ===\n")
print(as.data.frame(variability %>% filter(metric == "f1") %>% select(-metric)))
cat("\n=== every claimed difference in f1 ===\n")
print(as.data.frame(deltas %>% filter(metric == "f1") %>% select(-metric)))

# part 2: top-1 retrieval

top1_hits <- function(path, truth) {
  sheets <- load_similarity_sheets(path)
  bestsofar <- NULL
  for (df in sheets) {
    id  <- names(df)[1]
    tgt <- as.character(df[[id]])
    cols <- setdiff(names(df), id)
    m <- as.matrix(df[, cols, drop = FALSE])
    m[is.na(m)] <- -Inf
    wi <- max.col(t(m), ties.method = "first")
    this <- tibble(ICD_9_CM = as.character(cols),
                   target = tgt[wi],
                   sim = m[cbind(wi, seq_along(cols))])
    bestsofar <- if (is.null(bestsofar)) this else
      bind_rows(bestsofar, this) %>% group_by(ICD_9_CM) %>%
        slice_max(sim, n = 1, with_ties = FALSE) %>% ungroup()
  }
  bestsofar %>%
    filter(ICD_9_CM %in% truth$ICD_9_CM) %>%
    mutate(hit = as.integer(paste(ICD_9_CM, target) %in% paste(truth$ICD_9_CM, truth$target))) %>%
    select(code = ICD_9_CM, hit) %>%
    arrange(code)
}

t1_rows <- list()
t1_delta_rows <- list()

for (track_name in names(TRACKS)) {
  tk <- TRACKS[[track_name]]
  excl <- as.character(tk$excl$`ICD-9-CM`)
  truth <- tk$manual %>%
    transmute(ICD_9_CM = as.character(`ICD-9-CM`),
              target = as.character(.data[[tk$manual_target_col]])) %>%
    filter(!(ICD_9_CM %in% excl)) %>% distinct()

  cat(sprintf("\n=== top-1, track %s ===\n", track_name))
  hits_by_arm <- list()
  for (arm in names(TOP1_ARMS)) {
    path <- sprintf(TOP1_ARMS[[arm]], track_name)
    if (!file.exists(path)) { cat(sprintf("  SKIP %s, missing %s\n", arm, path)); next }
    hits_by_arm[[arm]] <- top1_hits(path, truth)
    cat(sprintf("  %-30s %.4f\n", arm, mean(hits_by_arm[[arm]]$hit)))
  }

  all_codes <- sort(unique(unlist(lapply(hits_by_arm, function(x) x$code))))
  hits_by_arm <- lapply(hits_by_arm, function(x)
    tibble(code = all_codes) %>% left_join(x, by = "code") %>%
      mutate(hit = tidyr::replace_na(hit, 0L)))
  idx <- resample_matrix(length(all_codes), B)

  boot_by_arm <- list()
  for (arm in names(hits_by_arm)) {
    h <- hits_by_arm[[arm]]$hit
    bt <- colMeans(matrix(h[idx], nrow = nrow(idx)))
    boot_by_arm[[arm]] <- bt
    t1_rows[[length(t1_rows) + 1]] <- tibble(track = track_name, arm = arm) %>%
      bind_cols(boot_summary(mean(h), bt))
  }

  for (cmp in TOP1_COMPARISONS) {
    if (is.null(boot_by_arm[[cmp[1]]]) || is.null(boot_by_arm[[cmp[2]]])) next
    d_boot <- boot_by_arm[[cmp[1]]] - boot_by_arm[[cmp[2]]]
    d_point <- mean(hits_by_arm[[cmp[1]]]$hit) - mean(hits_by_arm[[cmp[2]]]$hit)
    t1_delta_rows[[length(t1_delta_rows) + 1]] <- tibble(
      track = track_name, arm = cmp[1], reference = cmp[2],
      delta = round(d_point, 4), sd = round(sd(d_boot), 4),
      ci_low = round(quantile(d_boot, 0.025, names = FALSE), 4),
      ci_high = round(quantile(d_boot, 0.975, names = FALSE), 4),
      crosses_zero = quantile(d_boot, 0.025, names = FALSE) < 0 &
                     quantile(d_boot, 0.975, names = FALSE) > 0)
  }
}

top1_var <- bind_rows(t1_rows)
top1_delta <- bind_rows(t1_delta_rows)
write.csv(top1_var, out_path("bootstrap_top1.csv"), row.names = FALSE)
write.csv(top1_delta, out_path("bootstrap_top1_deltas.csv"), row.names = FALSE)

cat("\n=== top-1 retrieval with bootstrap standard deviation ===\n")
print(as.data.frame(top1_var))
cat("\n=== effect of removing the code number on top-1 ===\n")
print(as.data.frame(top1_delta))

cat("\nDone. Wrote bootstrap_variability.csv, bootstrap_deltas.csv,",
    "bootstrap_top1.csv, bootstrap_top1_deltas.csv\n")
