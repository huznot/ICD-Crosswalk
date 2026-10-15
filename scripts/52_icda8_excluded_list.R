source(if (file.exists("paths.R")) "paths.R" else "scripts/paths.R")
source("scripts/pipeline_lib.R")
suppressMessages({library(openxlsx); library(readxl)})

# the 52 icd-9-cm codes with no icda-8 match in the validation data

ORIG <- "data/original"
VAL  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/Validation_Data .xlsx")
LAB  <- file.path(ORIG, "ICD_Codes_Files_and_Validation_Data/ICD_Codes_Labels.xlsx")
OUT  <- out_path("52_codes_no_icda8.xlsx")

chk <- list(
  c("165", "no ICDA-8 match"),
  c("175", "no ICDA-8 match"),
  c("179", "no ICDA-8 match"),
  c("555", "no ICDA-8 match"),
  c("576", "no ICDA-8 match"),
  c("745", "no ICDA-8 match"),
  c("176", "no Kaposi sarcoma code in ICD-8, it entered ICD-9-CM later"),
  c("230", "ICD-8 230 to 239 is neoplasm of unspecified nature. There is no carcinoma in situ block in ICD-8"),
  c("231", "no carcinoma in situ block in ICD-8"),
  c("233", "no carcinoma in situ block in ICD-8"),
  c("234", "no carcinoma in situ block in ICD-8"),
  c("249", "ICD-8 has only 250 diabetes mellitus. Secondary diabetes is a later ICD-9-CM concept"),
  c("305", "ICD-8 has 304 drug dependence only. Nondependent abuse is a later concept"),
  c("315", "ICD-8 315 is unspecified mental retardation, a different concept"),
  c("327", "no sleep disorder code in ICD-8, organic sleep disorders entered ICD-9-CM in 2005"),
  c("338", "no pain NEC code in ICD-8, it entered ICD-9-CM in 2006"),
  c("495", "extrinsic allergic alveolitis has no ICD-8 code"),
  c("496", "chronic airway obstruction NEC is an ICD-9 concept")
)

excl <- read_excel(VAL, sheet = "Validation_ICD9_ICD8_Excld")
lab  <- read_excel(LAB, sheet = "CCS ICD-9-CM-3Level")
a8   <- read_excel(LAB, sheet = "ICDA-8-3Level")
a8lab <- setNames(as.character(a8$ICDA_8_LABEL), as.character(a8$ICDA_8))

m <- as.data.frame(do.call(rbind, chk), stringsAsFactors = FALSE)
names(m) <- c("code", "note")

d <- data.frame(`ICD-9-CM` = as.character(excl$`ICD-9-CM`), check.names = FALSE,
                stringsAsFactors = FALSE)
i <- match(d$`ICD-9-CM`, as.character(lab$ICD_9_CM))
d$`ICD-9-CM label` <- as.character(lab$ICD_9_CM_LABEL)[i]
j <- match(d$`ICD-9-CM`, m$code)
d$Notes <- ifelse(is.na(j), "", m$note[j])
d <- d[order(as.numeric(d$`ICD-9-CM`)), ]

## chapter the icd-9 code sits in, and the icda-8 codes it actually travels
## with in the co-occurrence data. both are here because the
## validation says no valid match but the data may still show a companion
CH9 <- c("1 infectious and parasitic", "2 neoplasms",
         "3 endocrine, nutritional, metabolic", "4 blood and blood-forming organs",
         "5 mental disorders", "6 nervous system and sense organs",
         "7 circulatory system", "8 respiratory system", "9 digestive system",
         "10 genitourinary system", "11 pregnancy and childbirth",
         "12 skin and subcutaneous tissue", "13 musculoskeletal and connective tissue",
         "14 congenital anomalies", "15 perinatal conditions",
         "16 symptoms, signs and ill-defined conditions", "17 injury and poisoning")

d$`ICD-9 chapter` <- CH9[vapply(d$`ICD-9-CM`, find_icd9cm_chapter, integer(1))]

co <- as.data.frame(load_cooccurrence_df(
  file.path(ORIG, "Co_occurrence/icd_8_9_co_occurrence_3d.xlsx")))
co$ICD_9_CM_Code <- as.character(co$ICD_9_CM_Code)
co$Co_Occurrence_Frequency <- as.numeric(co$Co_Occurrence_Frequency)

top3 <- function(k) {
  s <- co[co$ICD_9_CM_Code == k, ]
  if (!nrow(s)) return(c("none in the co-occurrence data", "", ""))
  s <- s[order(-s$Co_Occurrence_Frequency), ]
  out <- sprintf("%s %s (n=%d)", s$ICDA_8_Code, s$ICDA_8_LABEL, s$Co_Occurrence_Frequency)
  c(out, "", "", "")[1:3]
}
t3 <- t(vapply(d$`ICD-9-CM`, top3, character(3)))
d$`Top co-occurring ICDA-8`   <- t3[, 1]
d$`2nd co-occurring ICDA-8`   <- t3[, 2]
d$`3rd co-occurring ICDA-8`   <- t3[, 3]
d$`Co-occurrence rows` <- vapply(d$`ICD-9-CM`, function(k) sum(co$ICD_9_CM_Code == k), integer(1))

d <- d[, c("ICD-9-CM", "ICD-9-CM label", "ICD-9 chapter",
           "Top co-occurring ICDA-8", "2nd co-occurring ICDA-8",
           "3rd co-occurring ICDA-8", "Co-occurrence rows", "Notes")]

wb <- createWorkbook()
addWorksheet(wb, "no ICDA-8 match")
writeData(wb, 1, d, headerStyle = createStyle(textDecoration = "bold", valign = "bottom"))
addStyle(wb, 1, createStyle(valign = "top", wrapText = TRUE),
         rows = 2:(nrow(d) + 1), cols = 1:ncol(d), gridExpand = TRUE, stack = TRUE)
setColWidths(wb, 1, cols = 1:8, widths = c(10, 40, 30, 46, 46, 46, 12, 60))
freezePane(wb, 1, firstActiveRow = 2)

addWorksheet(wb, "chapters")
ch <- as.data.frame(table(d$`ICD-9 chapter`), stringsAsFactors = FALSE)
names(ch) <- c("ICD-9 chapter", "codes with no ICDA-8 match")
ch <- ch[order(-ch$`codes with no ICDA-8 match`), ]
writeData(wb, 2, ch, headerStyle = createStyle(textDecoration = "bold"))
setColWidths(wb, 2, cols = 1:2, widths = c(44, 28))
freezePane(wb, 2, firstActiveRow = 2)

## none of the 52 appear in the icd-9 to icda-8 co-occurrence file at all, and
## that is the whole reason the pipeline stays silent on them. worth putting
## beside the icd-10 track, where all 9 excluded codes do have co-occurrence
## data and all 9 get mapped
c10 <- as.character(read_excel(file.path(ORIG, "Co_occurrence/icd_10_9_co_occurrence_3c.xlsx"),
                               sheet = 1)$ICD_9_CM_Code3)
e10 <- as.character(read_excel(VAL, sheet = "Validation_ICD9_ICD10_Excld")$`ICD-9-CM`)
m10 <- unique(as.character(read_excel(VAL, sheet = "Validation_ICD9_ICD10")$`ICD-9-CM`))
m8  <- unique(as.character(read_excel(VAL, sheet = "Validaion_ICD9_ICD8")$`ICD-9-CM`))
c8  <- unique(co$ICD_9_CM_Code)

cov <- data.frame(
  Track = c("ICD-9-CM to ICD-10-CA", "ICD-9-CM to ICD-10-CA",
            "ICD-9-CM to ICDA-8", "ICD-9-CM to ICDA-8"),
  Group = c("no valid match in the validation data", "has a valid match",
            "no valid match in the validation data", "has a valid match"),
  Codes = c(length(e10), length(m10), nrow(d), length(m8)),
  `With co-occurrence data` = c(sum(e10 %in% c10), sum(m10 %in% c10),
                                sum(d$`ICD-9-CM` %in% c8), sum(m8 %in% c8)),
  check.names = FALSE)
cov$Share <- sprintf("%.0f%%", 100 * cov$`With co-occurrence data` / cov$Codes)

addWorksheet(wb, "co-occurrence coverage")
writeData(wb, 3, cov, headerStyle = createStyle(textDecoration = "bold"))
setColWidths(wb, 3, cols = 1:5, widths = c(26, 40, 10, 24, 10))
freezePane(wb, 3, firstActiveRow = 2)

saveWorkbook(wb, OUT, overwrite = TRUE)
cat("wrote", OUT, "\n\n")
print(cov, row.names = FALSE)
cat("\n")
cat("by chapter:\n"); print(ch, row.names = FALSE)
cat("\ncodes with no co-occurrence data at all:",
    sum(d$`Co-occurrence rows` == 0), "\n")
