![Logos](results/figures/logos.png)

# icd crosswalk

exploring automation of ICD code crosswalking

two migrations:

- icd-9-cm to icd-10-ca, the current canadian standard
- icd-9-cm to icda-8, going backwards

## results

| | |
|---|---|
| [clinicalbert vs sapbert](results/head_to_head/clinicalbert_vs_sapbert.xlsx) | both models on the same settings, overall and by category |
| [counts at each cutoff](results/workbooks/1_threshold_frequencies.xlsx) | how many pairs each cutoff keeps, with true and false positives |
| [code number in the label](results/workbooks/2_icda8_code_in_label.xlsx) | whether embedding the code number with the label matters |
| [why sapbert scores lower](results/workbooks/3_similarity_gap_by_model.xlsx) | correct pairs against everything else, per model |
| [all 130 ccs categories](results/workbooks/4_counts_by_ccs_category.xlsx) | counts per category |
| [the 52 with no icda-8 match](results/review/52_codes_review.xlsx) | the review of those codes, and every cutoff crossed with every top n from 5 to 30 |

[docs/tables.md](docs/tables.md) lists every other table and the script that
makes it.

## running it

needs r. all the data is in the repo, so nothing has to be downloaded. run
everything from the repo root, or open `icd_crosswalk.Rproj` in rstudio.

```bash
Rscript tests/test_pipeline.R    # quick check the pipeline functions work
Rscript tests/sanity_check.R     # reproduces the original pipeline's numbers
Rscript scripts/show_results.R   # every headline number, about a second
Rscript run_all.R                # rebuild everything
Rscript run_all.R --quick        # skips the full grid search
```

each script says at the top what it does, what it reads and what it writes.

r packages: `dplyr`, `tidyr`, `readxl`, `stringr`, `purrr`, `ggplot2`,
`stopwords`, `openxlsx`.

python is only needed to rebuild the embeddings:

```bash
python scripts/embeddings/generate_embeddings.py --model sapbert --clean base
```

## layout

```
data/                labels, co-occurrence tables, manual crosswalks, matrices
scripts/
  pipeline_lib.R     the four step pipeline, shared by everything
  paths.R            repo root and where each output goes
  show_results.R     prints the headline numbers
  grid/              parameter searches over cutoff, top n and rule
  workbooks/         the workbooks linked above
  no_match/          the codes with no reference match, incl. the 52
  analysis/          one off analyses
  embeddings/        python that builds the similarity matrices
tests/               test_pipeline.R and sanity_check.R
docs/                tables.md, a list of every output
results/             everything the scripts produce
run_all.R            rebuilds it all in dependency order
```

scripts call `out_path("name.csv")` and `scripts/paths.R` works out which
results folder it belongs in from the file name, so the layout and the code
cannot drift apart.
