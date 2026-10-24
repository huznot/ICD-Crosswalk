# plain bert vectors for similarity

background on why clinicalbert's similarity scores all come out high

reimers and gurevych 2019 (sentence-bert, emnlp)
- common practice is averaging bert's output layer or taking the [CLS] token
- "this common practice yields rather bad sentence embeddings, often worse than
  averaging glove embeddings"
- their fix is training on sentence pairs so cosine similarity means something

ethayarajh 2019 (emnlp)
- bert, elmo and gpt-2 representations are not isotropic in any layer, they
  sit in a narrow part of the space instead of spreading out
- so two unrelated pieces of text can still get a high cosine score

what this means for us
- clinicalbert is plain bert style, never trained on pairs
- expect its scores to be bunched together near the top, and a cosine cutoff
  to have a hard time separating right from wrong
- sapbert and mpnet are both trained so that similar things are close and
  different things are far, so their scores should spread out more

sources
- Reimers N, Gurevych I. Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks. EMNLP 2019. https://arxiv.org/abs/1908.10084
- Ethayarajh K. How Contextual are Contextualized Word Representations? Comparing the Geometry of BERT, ELMo, and GPT-2 Embeddings. EMNLP 2019. https://arxiv.org/abs/1909.00512
