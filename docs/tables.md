# tables

glossary for everything in results/

## workbooks

| file | what it is | script |
|---|---|---|
| head_to_head/clinicalbert_vs_sapbert.xlsx | both models on the same top n and rule, overall and by ccs category | workbooks/clinicalbert_vs_sapbert.R |
| workbooks/1_threshold_frequencies.xlsx | how many pairs each cutoff keeps, with tp, fp and fn | workbooks/threshold_frequencies.R |
| workbooks/2_icda8_code_in_label.xlsx | code number in the label or not, on the icda-8 track | workbooks/icda8_code_in_label.R |
| workbooks/3_similarity_gap_by_model.xlsx | similarity of correct pairs against everything else, per model | workbooks/similarity_gap.R |
| workbooks/4_counts_by_ccs_category.xlsx | counts for all 130 ccs categories at the plain cutoffs | workbooks/category_counts.R |
| review/52_codes_review.xlsx | the 52 icd-9 codes with no icda-8 match, by chapter, and scores at every cutoff crossed with every top n | no_match/icda8_52_review.R |
| review/52_codes_no_icda8.xlsx | the same 52 with their co-occurrence, 59 reads it | no_match/icda8_52_list.R |
| review/9_codes_review_UPDATED.xlsx | the 9 icd-9 codes with no icd-10-ca match | no_match/nine_codes_review.R, notes fixed by no_match/nine_codes_notes.R |
| review/e13_d48_review.xlsx | per code look at 249 and 239 | no_match/e13_d48_review.R |

44 rebuilds the 9 code workbook from scratch and loses the hand formatting, so
it is not in run_all.R. change wording with 47 instead.

## review

| file | what it is | script |
|---|---|---|
| 52_codes_accuracy_effect.csv | the grid behind the last tab of the 52 review | no_match/icda8_52_scores.R |
| absolute_threshold_grid.csv | absolute cosine cutoff against the relative one, every setting | grid/absolute_threshold_grid.R |
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
| reranker/ablation_*.csv | which feature groups the reranker needs | reranker/ablation.R |
| reranker/retrieval_sensitivity_*.csv | reranker over a spread of fixed candidate settings | reranker/retrieval_sensitivity.R |
| reranker/learning_curve_*.csv | score against number of training codes | reranker/learning_curve.R |
| reranker/category_holdout_*.csv | reranker tested on ccs categories it never saw | reranker/category_holdout.R |
| reranker/top1_accuracy.csv | is the top scoring target a correct one | reranker/top1_accuracy.R |
| reranker/portability.csv | the method without co-occurrence data or the chapter table | reranker/portability.R |
| variability/bootstrap_*.csv, cv_fold_variability.csv | how much the numbers move on a different set of codes | analysis/variability.R |
| categories/ccs_*.csv | all 130 ccs categories | analysis/category_breakdown.R |
| descriptive/similarity_matrix_example.csv | a small corner of a similarity matrix | analysis/similarity_matrix_example.R |
| descriptive/freq_dist_*.csv | how the two signals are spread | analysis/frequency_distributions.R |
| descriptive/per_code_rank.csv | where the correct code ranks, per code | analysis/descriptive_by_code.R |
| descriptive/trend_*.csv | the five trend tables | analysis/trend_tables.R |

## rerank

the two stage reranker, from scripts/reranker/.

| file | what it is | script |
|---|---|---|
| candidate_generation_study.csv, chapter_filter_casualties.csv | ways to widen the candidate list, and what the chapter filter drops | analysis/candidate_generation.R |
| rerank_features_10_9.rds, rerank_features_8_9.rds | candidate pool and features | reranker/features.R |
| base_emit_*.rds | cache of the original pipeline output, delete to rebuild | reranker/cv_rerank.R |
| cv_rerank_*.rds, cv_rerank_*.csv | cross validated reranker results | reranker/cv_rerank.R, reranker/merge_cv.R |
| csv_export/cv_rerank_predictions.csv | the predictions as csv | reranker/export_predictions_csv.R |
| precision_coverage_*.csv | precision against how much gets mapped, and the review queue | reranker/precision_coverage.R |

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
