# what we got with each model

score spread, icd-9 to icd-10-ca (results/workbooks/3_similarity_gap_by_model.xlsx)
- clinicalbert: correct pairs median 0.916, every other pair 0.841, gap 0.075
- sapbert: 0.654 vs 0.220, gap 0.434
- mpnet: 0.704 vs 0.161, gap 0.543
- clinicalbert at its best fixed cutoff (0.90) still lets 78,236 wrong pairs
  through, sapbert at 0.60 lets 1,675 through
- matches what bert_embeddings.md predicts. sapbert's scores look lower because
  it pushes unrelated pairs far apart, not because it reads the labels worse

best f1 over the full grid, same grid for every model (results/grid/full_grid_best.csv)
- icd-9 to icd-10-ca: sapbert 0.552, mpnet 0.540, clinicalbert 0.478
  (0.423 with the original matrices)
- icd-9 to icda-8: sapbert 0.761, mpnet 0.741, clinicalbert 0.722 (0.716 original)

head to head, icd-9 to icd-10-ca, same top n and rule 4 for both
(results/head_to_head/clinicalbert_vs_sapbert.xlsx)
- sapbert f1 0.544 at cutoff 0.60 (precision 0.658, recall 0.464)
- clinicalbert f1 0.439 at cutoff 0.95 (precision 0.557, recall 0.362)

bootstrap, 2000 draws resampling icd-9 codes (results/tables/variability/bootstrap_deltas.csv)
- sapbert minus original clinicalbert, icd-9 to icd-10-ca: +0.101 f1, 95% range
  0.079 to 0.123
- same on icd-9 to icda-8: +0.046, range -0.002 to 0.095. touches zero,
  sapbert ahead in 97% of draws
- mpnet minus sapbert, icd-9 to icd-10-ca: +0.003, range -0.016 to 0.022
- mpnet minus sapbert, icd-9 to icda-8: -0.021, range -0.066 to 0.023
- so mpnet and sapbert are basically tied, both clearly beat clinicalbert on
  icd-9 to icd-10-ca

other things worth knowing
- the gain over clinicalbert is mostly from being trained for similarity,
  mpnet has that too. sapbert's case is that its training is medical and is
  the same kind of task as ours (matching medical names)
- putting the code number in front of the label ("250 diabetes mellitus") made
  every model worse on icd-9 to icd-10-ca, so the newer work leaves it out
  (results/review/identical_labels.png). on icd-9 to icda-8 it barely mattered,
  see results/workbooks/2_icda8_code_in_label.xlsx
