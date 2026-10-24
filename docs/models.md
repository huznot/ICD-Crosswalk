# models

notes on the three embedding models we tried, why each one was considered,
and what happened. sources are at the bottom, numbered like [1].

## the job the model has to do

each code label is a short medical name, like "diabetes mellitus" or
"malignant neoplasm of breast". the model turns each label into a vector, and
we compare vectors with cosine similarity. a good model puts two labels for
the same condition close together and unrelated ones far apart.

that's closer to matching medical concept names (what papers call entity
linking) than to understanding clinical notes. that difference is the main
reason we looked past clinicalbert.

## clinicalbert (what the original pipeline used)

- model: `emilyalsentzer/Bio_ClinicalBERT` [1, 2]
- starts from biobert [3], which was trained on pubmed and pmc articles, then
  trained further on every note in mimic-iii [4], about 880 million words of
  icu notes [2]
- it's trained to fill in hidden words in notes. it was never trained to put
  similar meanings close together
- we take the [CLS] vector from the last layer
- the sentence-bert paper says this kind of plain bert vector "yields rather
  bad sentence embeddings, often worse than averaging glove embeddings" [5]

what we saw (icd-9 to icd-10-ca, `results/workbooks/3_similarity_gap_by_model.xlsx`):

- every score sits high. correct pairs have a median of 0.916 and every other
  pair 0.841, a gap of only 0.075
- at its best fixed cutoff (0.90), 78,236 wrong pairs still get through, about
  11% of all the non-matching pairs. the cutoff can't separate right from wrong
  very well
- this fits a known property of bert vectors: they aren't spread evenly in
  every direction (they're anisotropic), so unrelated texts can still score
  high [6]

## sapbert

- model: `cambridgeltl/SapBERT-from-PubMedBERT-fulltext` [7, 8]
- starts from pubmedbert [9], which was trained from scratch on pubmed
  abstracts and full text articles
- then trained on umls 2020AA [8, 10] so that different names for the same
  medical concept end up close together. umls brings together over 100 medical
  vocabularies [11], including icd-9-cm and icd-10-cm
- built for this kind of task: the paper reports state of the art results on
  six medical entity linking benchmarks [7]
- we take the [CLS] vector from the last layer, as the model card says [8]

what we saw:

- the scores spread out. correct pairs median 0.654, every other pair 0.220,
  a gap of 0.434 (clinicalbert's was 0.075)
- at its best fixed cutoff (0.60) only 1,675 wrong pairs get through, 0.23%
- this is why sapbert's scores look lower overall. it isn't worse at reading
  medical terms, it pushes unrelated pairs much further apart

## mpnet

- model: `sentence-transformers/all-mpnet-base-v2` [12]
- general purpose, no medical training. it's mpnet [13] trained on about 1.17
  billion sentence pairs (reddit, stack exchange, wikianswers, ms marco and
  others) to put similar sentences close together [12]
- uses the average of all token vectors (mean pooling), which is how it was
  trained [12]
- we tried it as a check: is the medical training what helps, or is it enough
  for a model to be trained for similarity?

what we saw: it does about as well as sapbert (see results below). mpnet was
dropped from later work, and the head to head is clinicalbert vs sapbert only.

## results

best f1 from the full grid (relative cutoff, same grid for every model):

| model | icd-9 to icd-10-ca | icd-9 to icda-8 |
|---|---|---|
| clinicalbert, original matrices | 0.423 | 0.716 |
| clinicalbert, best text version | 0.478 | 0.722 |
| sapbert | 0.552 | 0.761 |
| mpnet | 0.540 | 0.741 |

from `results/grid/full_grid_best.csv`.

head to head on icd-9 to icd-10-ca, same top n and rule 4 for both, only the
fixed cutoff differs (`results/head_to_head/clinicalbert_vs_sapbert.xlsx`):

| | cutoff | precision | recall | f1 |
|---|---|---|---|---|
| clinicalbert | 0.95 | 0.557 | 0.362 | 0.439 |
| sapbert | 0.60 | 0.658 | 0.464 | 0.544 |

are the differences real? bootstrap over icd-9 codes, 2000 draws, comparing
sapbert and mpnet (base text) against the original clinicalbert matrices
(`results/tables/variability/bootstrap_deltas.csv`):

| comparison | track | f1 difference | 95% range |
|---|---|---|---|
| sapbert minus clinicalbert | icd-9 to icd-10-ca | +0.101 | 0.079 to 0.123 |
| sapbert minus clinicalbert | icd-9 to icda-8 | +0.046 | -0.002 to 0.095 |
| mpnet minus sapbert | icd-9 to icd-10-ca | +0.003 | -0.016 to 0.022 |
| mpnet minus sapbert | icd-9 to icda-8 | -0.021 | -0.066 to 0.023 |

## the short version for the paper

- clinicalbert was trained to read clinical notes, not to compare labels. its
  scores all bunch together, so a cosine cutoff can't tell right from wrong
- sapbert was trained on umls to put different names for the same medical
  concept close together, which is the same job as matching code labels
- on icd-9 to icd-10-ca sapbert beats clinicalbert by about 0.10 f1 and the
  bootstrap range doesn't come near zero

## weak spots to be ready for

- **mpnet ties sapbert on icd-9 to icd-10-ca.** the gain comes from being
  trained for similarity, and mpnet has that too. the case for sapbert is that
  its training is medical and matches the task, not that it scored higher
- **on icd-9 to icda-8 the lead is less certain.** sapbert is ahead in 97% of
  bootstrap draws, but the 95% range just touches zero
- **umls includes icd-9-cm and icd-10-cm**, so sapbert may have seen some of
  these labels during training. that's fine for the task (it's what you'd want
  in practice) but a reviewer might ask
- **icd-10-ca is the canadian version.** umls has icd-10-cm (the us version),
  not icd-10-ca. both are built on the who icd-10, so most three character
  codes match, but not all
- **the code number in the label hurt every model.** "250 diabetes mellitus"
  scored worse than "diabetes mellitus", so the newer work uses labels without
  the number (see `results/review/identical_labels.png`)

## sources

1. Alsentzer E, Murphy JR, Boag W, Weng WH, Jin D, Naumann T, McDermott MBA. Publicly Available Clinical BERT Embeddings. Clinical NLP Workshop, NAACL 2019. https://arxiv.org/abs/1904.03323
2. Bio_ClinicalBERT model card. https://huggingface.co/emilyalsentzer/Bio_ClinicalBERT
3. Lee J, Yoon W, Kim S, Kim D, Kim S, So CH, Kang J. BioBERT: a pre-trained biomedical language representation model for biomedical text mining. Bioinformatics, 2020. https://doi.org/10.1093/bioinformatics/btz682
4. Johnson AEW, Pollard TJ, Shen L, et al. MIMIC-III, a freely accessible critical care database. Scientific Data, 2016. https://doi.org/10.1038/sdata.2016.35
5. Reimers N, Gurevych I. Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks. EMNLP 2019. https://arxiv.org/abs/1908.10084
6. Ethayarajh K. How Contextual are Contextualized Word Representations? Comparing the Geometry of BERT, ELMo, and GPT-2 Embeddings. EMNLP 2019. https://arxiv.org/abs/1909.00512
7. Liu F, Shareghi E, Meng Z, Basaldella M, Collier N. Self-Alignment Pretraining for Biomedical Entity Representations. NAACL 2021. https://arxiv.org/abs/2010.11784
8. SapBERT model card. https://huggingface.co/cambridgeltl/SapBERT-from-PubMedBERT-fulltext
9. Gu Y, Tinn R, Cheng H, et al. Domain-Specific Language Model Pretraining for Biomedical Natural Language Processing. ACM Transactions on Computing for Healthcare, 2021. https://arxiv.org/abs/2007.15779
10. Bodenreider O. The Unified Medical Language System (UMLS): integrating biomedical terminology. Nucleic Acids Research, 2004. https://doi.org/10.1093/nar/gkh061
11. UMLS source vocabulary list. https://www.nlm.nih.gov/research/umls/sourcereleasedocs/index.html
12. all-mpnet-base-v2 model card. https://huggingface.co/sentence-transformers/all-mpnet-base-v2
13. Song K, Tan X, Qin T, Lu J, Liu TY. MPNet: Masked and Permuted Pre-training for Language Understanding. NeurIPS 2020. https://arxiv.org/abs/2004.09297
