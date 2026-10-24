# model notes

notes on why we looked at models other than clinicalbert. sources at the bottom.

the labels we embed are short medical names like "diabetes mellitus". we
compare them with cosine similarity, so we need a model that puts two names for
the same condition close together. that's more like matching medical concept
names than reading clinical notes, which is why clinicalbert wasn't a great
fit.

clinicalbert (emilyalsentzer/Bio_ClinicalBERT) is what the original pipeline
used. it starts from biobert and was trained further on the mimic-iii icu notes,
about 880 million words [1, 2, 3, 4]. it learned by filling in hidden words, it
was never trained to put similar meanings close together. the sentence-bert
paper says plain bert vectors like this give "rather bad sentence embeddings,
often worse than averaging glove embeddings" [5]. bert vectors also tend to all
point in similar directions, so unrelated text still scores high [6]. we saw
this on icd-9 to icd-10-ca: correct pairs had a median score of 0.916 and every
other pair 0.841, only 0.075 apart. at its best cutoff (0.90) 78,236 wrong
pairs still got through.

sapbert (cambridgeltl/SapBERT-from-PubMedBERT-fulltext) starts from pubmedbert,
which was trained on pubmed articles [9]. then it was trained on umls 2020AA so
different names for the same medical concept end up close together [7, 8, 10].
umls combines over 100 medical vocabularies, including icd-9-cm and icd-10-cm
[11]. the paper got state of the art results on six medical entity linking
benchmarks [7], which is basically our task. its scores spread out a lot more:
correct pairs median 0.654, everything else 0.220, a gap of 0.434. at its best
cutoff (0.60) only 1,675 wrong pairs got through. that's why its scores look
lower than clinicalbert's, it pushes unrelated pairs further apart.

mpnet (sentence-transformers/all-mpnet-base-v2) has no medical training. it was
trained on about 1.17 billion general sentence pairs to put similar sentences
close together [12, 13]. we tried it to see if the medical training matters or
if being trained for similarity is enough. it was dropped from later work.

for both clinicalbert and sapbert we use the [CLS] vector from the last layer,
which is what the sapbert model card says to do [8]. mpnet uses the average of
all the token vectors, which is how it was trained [12].

best f1 from the full grid, same grid for every model (results/grid/full_grid_best.csv):
icd-9 to icd-10-ca: sapbert 0.552, mpnet 0.540, clinicalbert 0.478 (0.423 with
the original matrices).
icd-9 to icda-8: sapbert 0.761, mpnet 0.741, clinicalbert 0.722 (0.716 original).

head to head on icd-9 to icd-10-ca, same top n and rule 4 for both
(results/head_to_head/clinicalbert_vs_sapbert.xlsx): sapbert f1 0.544 at cutoff
0.60, clinicalbert 0.439 at cutoff 0.95.

bootstrap, 2000 draws over icd-9 codes (results/tables/variability/bootstrap_deltas.csv):
sapbert beats the original clinicalbert by 0.101 f1 on icd-9 to icd-10-ca
(95% range 0.079 to 0.123) and by 0.046 on icd-9 to icda-8 (-0.002 to 0.095,
so just touching zero, sapbert ahead in 97% of draws). mpnet minus sapbert is
+0.003 on icd-9 to icd-10-ca (-0.016 to 0.022) and -0.021 on icd-9 to icda-8
(-0.066 to 0.023), so those two are basically tied.

things a reviewer might ask about:
- mpnet ties sapbert on icd-9 to icd-10-ca, so the gain is mostly from being
  trained for similarity. the argument for sapbert is that its training is
  medical and matches what we're doing, not that it scored higher
- the icda-8 lead over clinicalbert isn't certain
- umls has icd-9-cm and icd-10-cm, so sapbert may have seen some of these
  labels in training
- umls has icd-10-cm (us), not icd-10-ca. both come from the who icd-10 so most
  three character codes match, but not all
- putting the code number in the label ("250 diabetes mellitus") made every
  model worse, so the newer work leaves it out (results/review/identical_labels.png)

sources

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
