# terms

what the words in the scripts, file names and workbooks mean.

## the two tracks

every result is for one of two mappings. both start from icd-9-cm codes.

| track | what it maps | tag in file names |
|---|---|---|
| icd-9 to icd-10-ca | icd-9-cm codes to the current canadian standard | `10_9` |
| icd-9 to icda-8 | icd-9-cm codes back to the older icda-8 | `8_9` |

so `cosine_similarity_matrices_10_9_sapbert_base.xlsx` is sapbert on the
icd-9 to icd-10-ca track, and `8_9` anywhere means icd-9 to icda-8.

each script says at the top which track it covers.

## the four step pipeline

for every icd-9 code:

1. **cosine cutoff.** compare the icd-9 label with every target label using an
   embedding model and keep the targets that score high enough.
2. **top n co-occurring.** keep the n target codes that show up most often
   alongside the icd-9 code in the manitoba records (pairs seen fewer than 6
   times were removed before we got the data).
3. **chapter filter.** drop any target from a chapter that doesn't line up
   with the icd-9 code's chapter.
4. **rule.** pick the final mappings from what's left (see rules below).

## cutoffs

there are two kinds and they look similar, so check which one a file uses.

- **relative cutoff** (0.95, 0.99, 0.995, 0.999, 1.0): keeps targets scoring at
  least that share of the code's best score. 0.99 means "within 1% of the
  best". the best target always gets through. this is what the original
  pipeline used, and what the full grid and everything on the icd-9 to icda-8
  track use.
- **fixed cutoff** (e.g. 0.90 for clinicalbert, 0.60 for sapbert): keeps
  targets scoring above that number, full stop. used in the newer icd-9 to
  icd-10-ca work (the head to head and workbooks 1, 3 and 4).
  clinicalbert and sapbert get different values because their scores sit in
  different ranges.

## rules

each target that survives steps 1 to 3 gets three yes/no flags:

- top cosine: the highest similarity score for that icd-9 code
- top co-occurrence: the most frequent co-occurring code for that icd-9 code
- in both lists: it passed the cutoff and is in the top n

| rule | keeps |
|---|---|
| 1 | top cosine or top co-occurrence |
| 2 | top cosine or in both lists |
| 3 | top co-occurrence or in both lists |
| 4 | any of the three |

## the 9 and the 52

the validation data (the manual crosswalk) marks some icd-9 codes as having
no correct code in the target system:

- **the 9**: icd-9 codes with no icd-10-ca code (icd-9 to icd-10-ca track)
- **the 52**: icd-9 codes with no icda-8 code (icd-9 to icda-8 track)

six of the 52 first looked like they might have an icda-8 code. they were
checked and the validation data is right, so all 52 stay as no match.

**included vs dropped.** these codes can't have a correct mapping, so any
mapping the pipeline makes for one of them is a false positive.

- **included** (what the repo does now): they stay in the scoring, so mistakes
  on them count against precision.
- **dropped** (what the original pipeline did): they're removed before scoring,
  so mistakes on them cost nothing.

`tests/sanity_check.R` drops them, because it reproduces the original
pipeline's numbers.

## scores

- **true positive (tp)**: a mapping that's in the manual crosswalk
- **false positive (fp)**: a mapping that isn't
- **false negative (fn)**: a crosswalk pair the pipeline missed
- **precision** = tp / (tp + fp), how many of its mappings are right
- **recall** = tp / (tp + fn), how much of the crosswalk it found
- **f1**: the balance of precision and recall
- **accuracy** = tp / (tp + fp + fn). there are no true negatives to count, so
  this is not the usual accuracy

## model and text names in the grid

| name | meaning |
|---|---|
| ClinicalBERT-original | the matrices from the original pipeline |
| -base | label text lowercased and cleaned, with the code number in front ("250 diabetes mellitus") |
| -nocode | label text without the code number ("diabetes mellitus") |
| -stripped | filler words removed (and, or, of, nos, nec, ...) |
| -stopwords | common english words removed, keeping single letters and no/not/nor |
| -stopwords-raw | the full stopword list, as published |

putting the code number in front turned out to hurt, see
`results/review/identical_labels.png`. the newer work uses `-nocode`.

## other terms

- **ccs category**: the clinical classifications software groups. 130 groups of
  icd-9 codes, used to break results down by clinical area. many hold only one
  code, so per category scores can be noisy.
- **chapter**: the top level grouping in each coding system (e.g. icd-9
  chapter 2 is neoplasms).
- **similarity matrix**: an xlsx in `data/` with the cosine score for every icd-9
  code against every target code, one sheet per ccs group.
