# tables

glossary for everything in results/

## workbooks

| file | what it is | script |
|---|---|---|
| head_to_head/clinicalbert_vs_sapbert.xlsx | both models on the same top n and rule, overall and by ccs category | 57 |
| workbooks/1_threshold_frequencies.xlsx | how many pairs each cutoff keeps, with tp, fp and fn | 53 |
| workbooks/2_icda8_code_in_label.xlsx | code number in the label or not, on the icda-8 track | 54 |
| workbooks/3_similarity_gap_by_model.xlsx | similarity of correct pairs against everything else, per model | 55 |
| workbooks/4_counts_by_ccs_category.xlsx | counts for all 130 ccs categories at the plain cutoffs | 56 |
| review/52_codes_review.xlsx | the 52 icd-9 codes with no icda-8 match, by chapter, and scores at every cutoff crossed with every top n | 59 |
| review/52_codes_no_icda8.xlsx | the same 52 with their co-occurrence, 59 reads it | 52 |
| review/9_codes_review_UPDATED.xlsx | the 9 icd-9 codes with no icd-10-ca match | 44, notes fixed by 47 |
| review/e13_d48_review.xlsx | per code look at 249 and 239 | 43 |

44 rebuilds the 9 code workbook from scratch and loses the hand formatting, so
it is not in run_all.R. change wording with 47 instead.

## review

| file | what it is | script |
|---|---|---|
| 52_codes_accuracy_effect.csv | the grid behind the last tab of the 52 review | 58 |
| absolute_threshold_grid.csv | absolute cosine cutoff against the relative one, every setting | 45 |
| identical_labels.png | icd-9 and icd-10-ca codes with the exact same label, scored with and without the code number in the text | 41 |

## grid

| file | what it is | script |
|---|---|---|
| conditions/*.csv | the full grid for each embedding condition, one file each | 07 |
| full_grid_all.csv | every point from every condition | 08 |
| full_grid_best.csv | best point per condition and track | 08 |
| full_grid_family.csv | best per model family | 08 |
| full_grid_stripping.csv, full_grid_stripping_paired.csv | base text against stripped text | 08 |
| full_grid_sensitivity.csv | how much the model ranking depends on the setting picked | 08 |

## tables

split into folders by topic.

| file | what it is | script |
|---|---|---|
| comparison/grid_results_*.csv, best_by_model.csv | the first clinicalbert against sapbert comparison | 02 |
| comparison/ccs_breakdown_*.csv | that comparison by ccs category | 02 |
| comparison/regression_summary.csv | categories where sapbert did better or worse | 03 |
| comparison/bidirectional_roundtrip.csv | mapping backwards, and whether a mapping comes back to where it started | 05 |
| comparison/code_prefix_test.csv | code number in the embedding text or not | 23 |
| errors/error_analysis_*.csv | where correct pairs get lost in the pipeline | 09 |
| reranker/ablation_*.csv | which feature groups the reranker needs | 16 |
| reranker/retrieval_sensitivity_*.csv | reranker over a spread of fixed candidate settings | 17 |
| reranker/learning_curve_*.csv | score against number of training codes | 18 |
| reranker/category_holdout_*.csv | reranker tested on ccs categories it never saw | 19 |
| reranker/top1_accuracy.csv | is the top scoring target a correct one | 20 |
| reranker/portability.csv | the method without co-occurrence data or the chapter table | 29 |
| variability/bootstrap_*.csv, cv_fold_variability.csv | how much the numbers move on a different set of codes | 30 |
| categories/ccs_*.csv | all 130 ccs categories | 31 |
| descriptive/similarity_matrix_example.csv | a small corner of a similarity matrix | 24 |
| descriptive/freq_dist_*.csv | how the two signals are spread | 25 |
| descriptive/per_code_rank.csv | where the correct code ranks, per code | 50 |
| descriptive/trend_*.csv | the five trend tables | 51 |

## rerank

the two stage system. these are on main but the method itself lives on the
`testing` branch.

| file | what it is | script |
|---|---|---|
| candidate_generation_study.csv, chapter_filter_casualties.csv | ways to widen the candidate list, and what the chapter filter drops | 10 |
| rerank_features_10_9.rds, rerank_features_8_9.rds | candidate pool and features | 11 |
| base_emit_*.rds | cache of the original pipeline output, delete to rebuild | 12 |
| cv_rerank_*.rds, cv_rerank_*.csv | cross validated reranker results | 12, 12b |
| csv_export/cv_rerank_predictions.csv | the predictions as csv | 34 |
| precision_coverage_*.csv | precision against how much gets mapped, and the review queue | 13 |

## unmatched

the codes with no reference match.

| file | what it is | script |
|---|---|---|
| unmatched_code_handling.csv | what the pipeline outputs for them | 35 |
| unmatched_*_by_code.csv, unmatched_descriptives_summary.csv, unmatched_top_cooccurrence_pairs.csv | similarity and co-occurrence for those codes | 36 |
| unmatched_codes_handout.html, unmatched_codes.pdf | two page handout of the same | 37 |
| validation_pairs_*.csv, unmatched_review_*.csv | the validation data as csv, and a sheet to review the unmatched codes | 38 |

## figures

each plot is named after the table it comes from, and made by the same script.
categories/ has the ccs category charts, unmatched/ has the no-match code
charts, everything else sits at the top.
