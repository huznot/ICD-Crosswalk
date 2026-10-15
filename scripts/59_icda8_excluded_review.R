# 59 review workbook for the 52 codes with no icda-8 match
# reads 52_codes_no_icda8.xlsx (52_) and 52_codes_accuracy_effect.csv (58_)
# writes review/52_codes_review.xlsx

source(if (file.exists("paths.R")) "paths.R" else "scripts/paths.R")
source("scripts/pipeline_lib.R")
suppressMessages(library(openxlsx))

ORIG <- "data/original"
GEN  <- "data/generated"
LAB  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/ICD_Codes_Labels.xlsx")
OUT  <- out_path("52_codes_review.xlsx")

MODELS <- c(ClinicalBERT = "cosine_similarity_matrices_8_9_clinicalbert_base_nocode.xlsx",
            SapBERT      = "cosine_similarity_matrices_8_9_sapbert_base_nocode.xlsx")

base <- read_excel(out_path("52_codes_no_icda8.xlsx"), sheet = "no ICDA-8 match")
base$`ICD-9-CM` <- as.character(base$`ICD-9-CM`)
stopifnot(nrow(base) == 52)

a8    <- read_excel(LAB, sheet = "ICDA-8-3Level")
a8lab <- setNames(as.character(a8$ICDA_8_LABEL), as.character(a8$ICDA_8))

top_by_model <- list()
for (m in names(MODELS)) {
  sheets <- load_similarity_sheets(file.path(GEN, MODELS[[m]]))
  cols <- lapply(sheets, names)
  tops <- character(nrow(base))
  for (i in seq_len(nrow(base))) {
    k <- base$`ICD-9-CM`[i]
    sh <- which(vapply(cols, function(cn) k %in% cn, logical(1)))
    if (!length(sh)) { tops[i] <- "not in the matrix"; next }
    df <- sheets[[sh[1]]]
    d <- data.frame(t = as.character(df[[names(df)[1]]]), s = df[[k]], stringsAsFactors = FALSE)
    d <- d[!is.na(d$s), ]; d <- d[order(-d$s), ]
    tops[i] <- sprintf("%s %s (%.3f)", d$t[1], a8lab[d$t[1]], d$s[1])
  }
  top_by_model[[m]] <- tops
  cat("read", m, "\n")
}

all52 <- data.frame(
  `ICD-9-CM` = base$`ICD-9-CM`,
  `ICD-9-CM label` = base$`ICD-9-CM label`,
  `ICD-9 chapter` = base$`ICD-9 chapter`,
  `ClinicalBERT top cosine` = top_by_model$ClinicalBERT,
  `SapBERT top cosine` = top_by_model$SapBERT,
  `In the co-occurrence data` = ifelse(base$`Co-occurrence rows` > 0, "yes", "no"),
  `Top co-occurring ICDA-8` = base$`Top co-occurring ICDA-8`,
  Notes = ifelse(is.na(base$Notes), "", base$Notes),
  check.names = FALSE)
all52 <- all52[order(as.numeric(all52$`ICD-9-CM`)), ]

ch <- as.data.frame(table(base$`ICD-9 chapter`), stringsAsFactors = FALSE)
names(ch) <- c("ICD-9 chapter", "Codes with no ICDA-8 match")
ch$Share <- sprintf("%.0f%%", 100 * ch$`Codes with no ICDA-8 match` / nrow(base))
ch <- ch[order(-ch$`Codes with no ICDA-8 match`), ]

eff <- read.csv(out_path("52_codes_accuracy_effect.csv"), stringsAsFactors = FALSE,
                check.names = FALSE)

hdr  <- createStyle(textDecoration = "bold", valign = "bottom", fgFill = "#D9D9D9",
                    border = "bottom", borderStyle = "medium", wrapText = TRUE)
body <- createStyle(valign = "top", wrapText = TRUE)
CB   <- createStyle(fgFill = "#EAF1FB")
SB   <- createStyle(fgFill = "#FDF1E4")
SEP  <- createStyle(border = "top", borderColour = "#808080", borderStyle = "thin")
BOLD <- createStyle(textDecoration = "bold")
GOOD_HIGH <- c("#F8696B", "#FFEB84", "#63BE7B")
GOOD_LOW  <- rev(GOOD_HIGH)

wb <- createWorkbook()
add <- function(name, df, widths, filter = FALSE, freeze_col = 1, wrap = TRUE) {
  addWorksheet(wb, name)
  writeData(wb, name, df, headerStyle = hdr, withFilter = filter)
  setColWidths(wb, name, cols = seq_along(widths), widths = widths)
  freezePane(wb, name, firstActiveRow = 2, firstActiveCol = freeze_col)
  if (wrap) addStyle(wb, name, body, rows = 2:(nrow(df) + 1), cols = seq_along(widths),
                     gridExpand = TRUE, stack = TRUE)
}

add("all 52", all52, c(10, 34, 28, 40, 40, 12, 40, 50), filter = TRUE, freeze_col = 2)
add("by chapter", ch, c(42, 16, 8))

tab <- "accuracy effect"
add(tab, eff, c(14, 8, 30, 11, 11, 11, 11, 12, 12, 10, 10, 10, 10, 10, 10, 10),
    filter = TRUE, freeze_col = 6, wrap = FALSE)
n <- nrow(eff)
for (p in list(list("ClinicalBERT", CB), list("SapBERT", SB))) {
  r <- which(eff$Model == p[[1]]) + 1
  addStyle(wb, tab, p[[2]], rows = r, cols = seq_along(eff), gridExpand = TRUE, stack = TRUE)
}
blk <- paste(eff$Model, eff$`Rule number`)
brk <- which(c(FALSE, blk[-1] != blk[-n])) + 1
addStyle(wb, tab, SEP, rows = brk, cols = seq_along(eff), gridExpand = TRUE, stack = TRUE)
addStyle(wb, tab, BOLD, rows = which(eff$`Best for this model and rule` == "yes") + 1,
         cols = seq_along(eff), gridExpand = TRUE, stack = TRUE)

shade <- function(cn, colours) {
  conditionalFormatting(wb, tab, cols = which(names(eff) == cn), rows = 2:(n + 1),
                        type = "colourScale", style = colours)
}
for (cn in c("True positives", "Precision", "Recall", "F1", "Accuracy")) shade(cn, GOOD_HIGH)
for (cn in c("False positives", "False negatives")) shade(cn, GOOD_LOW)

saveWorkbook(wb, OUT, overwrite = TRUE)
cat("wrote", OUT, "\n")
