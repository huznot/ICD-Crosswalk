# tables

every file in results/, what it is, and the script that makes it. `10_9` in a
file name means icd-9 to icd-10-ca and `8_9` means icd-9 to icda-8. see
[terms.md](terms.md) for what the words mean.

## workbooks

| file | what it is | script |
|---|---|---|
| head_to_head/clinicalbert_vs_sapbert.xlsx | icd-9 to icd-10-ca. both models on the same top n and rule, overall and by ccs category | workbooks/clinicalbert_vs_sapbert.R |
| workbooks/1_threshold_frequencies.xlsx | icd-9 to icd-10-ca. how many pairs each cutoff keeps, with tp, fp and fn | workbooks/threshold_frequencies.R |
| workbooks/2_icda8_code_in_label.xlsx | icd-9 to icda-8. code number in the label or not | workbooks/icda8_code_in_label.R |
| workbooks/3_similarity_gap_by_model.xlsx | icd-9 to icd-10-ca. similarity of correct pairs against everything else, per model | workbooks/similarity_gap.R |
| workbooks/4_counts_by_ccs_category.xlsx | icd-9 to icd-10-ca. counts for all 130 ccs categories at the fixed cutoffs | workbooks/category_counts.R |
| review/52_codes_review.xlsx | icd-9 to icda-8. the 52 icd-9 codes with no icda-8 code, by chapter, and the scores with them included at every cutoff and top n | no_match/icda8_52_review.R |
| review/52_codes_no_icda8.xlsx | icd-9 to icda-8. the same 52 with what they co-occur with | no_match/icda8_52_list.R |
| review/9_codes_review_UPDATED.xlsx | icd-9 to icd-10-ca. the 9 icd-9 codes with no icd-10-ca code | no_match/nine_codes_review.R, notes fixed by no_match/nine_codes_notes.R |
| review/e13_d48_review.xlsx | icd-9 to icd-10-ca. a look at icd-9 249 and 239, two of the 9 | no_match/e13_d48_review.R |

no_match/nine_codes_review.R rebuilds the 9 code workbook from scratch and loses
the hand formatting, so it is not in run_all.R. change wording with
no_match/nine_codes_notes.R instead.

## review

| file | what it is | script |
|---|---|---|
| 52_codes_accuracy_effect.csv | icd-9 to icda-8. the scores behind the last tab of the 52 review | no_match/icda8_52_scores.R |
| absolute_threshold_grid.csv | icd-9 to icd-10-ca. fixed cosine cutoff against the relative one, every setting | grid/absolute_threshold_grid.R |
| identical_labels.png | icd-9 and icd-10-ca codes with the exact same label, scored with and without the code number in the text | analysis/identical_labels.R |

## grid

| file | what it is | script |
|---|---|---|
| conditions/*.csv | the full grid for each embedding condition, one file each | grid/full_grid.R |
| full_grid_all.csv | every point from every condition | grid/assemble_full_grid.R |
| full_grid_best.csv | best point per condition and track | grid/assemble_full_grid.R |
| full_grid_family.csv | best per model family | grid/assemble_full_grid.R |
| full_grid_stripping.csv, full_grid_stripping_paired.csv | base text against stripped text | grid/assemble_full_grid.R |
| full_grid_sensitivity.csv | how much the model ranking depends on the setting picked | grid/assemble_full_grid.R |

## tables

split into folders by topic.

| file | what it is | script |
|---|---|---|
| comparison/grid_results_*.csv, best_by_model.csv | the first clinicalbert against sapbert comparison | grid/first_comparison.R |
| comparison/ccs_breakdown_*.csv | that comparison by ccs category | grid/first_comparison.R |
| comparison/regression_summary.csv | categories where sapbert did better or worse | grid/first_comparison_charts.R |
| comparison/bidirectional_roundtrip.csv | mapping backwards, and whether a mapping comes back to where it started | analysis/bidirectional.R |
| comparison/code_prefix_test.csv | code number in the embedding text or not | analysis/code_prefix_test.R |
| errors/error_analysis_*.csv | where correct pairs get lost in the pipeline | analysis/error_analysis.R |
| variability/bootstrap_*.csv | how much the numbers move on a different set of codes | analysis/variability.R |
| categories/ccs_*.csv | all 130 ccs categories | analysis/category_breakdown.R |
| descriptive/similarity_matrix_example.csv | a small corner of a similarity matrix | analysis/similarity_matrix_example.R |
| descriptive/freq_dist_*.csv | how the two signals are spread | analysis/frequency_distributions.R |
| descriptive/per_code_rank.csv | where the correct code ranks, per code | analysis/descriptive_by_code.R |
| descriptive/trend_*.csv | the five trend tables | analysis/trend_tables.R |

## unmatched

the codes with no reference match.

| file | what it is | script |
|---|---|---|
| unmatched_code_handling.csv | what the pipeline outputs for them | no_match/unmatched_codes.R |
| unmatched_*_by_code.csv, unmatched_descriptives_summary.csv, unmatched_top_cooccurrence_pairs.csv | similarity and co-occurrence for those codes | no_match/unmatched_descriptives.R |
| unmatched_codes_handout.html, unmatched_codes.pdf | two page handout of the same | no_match/unmatched_handout.R |
| validation_pairs_*.csv, unmatched_review_*.csv | the validation data as csv, and a sheet to review the unmatched codes | no_match/validation_export.R |

## figures

each plot is named after the table it comes from, and made by the same script.
categories/ has the ccs category charts, unmatched/ has the no-match code
charts, everything else sits at the top.
