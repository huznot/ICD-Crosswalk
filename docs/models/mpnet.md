# mpnet

sentence-transformers/all-mpnet-base-v2

why look at it
- general purpose, no medical training at all
- but it is trained for sentence similarity, which clinicalbert isn't
- good check on whether the medical training is what matters, or just being
  trained for similarity

model card
- base is microsoft/mpnet-base
- fine tuned with contrastive learning on ~1.17 billion sentence pairs
  (reddit, s2orc citation pairs, wikianswers, paq, stack exchange, ms marco, ...)
- meant for sentence similarity, search and clustering
- mean pooling over the token vectors, 768 dims, inputs over 384 word pieces
  get cut

mpnet (song et al. 2020, neurips)
- pretraining that combines bert style masking with xlnet style permutation

sentence-transformers / sbert (reimers and gurevych 2019, emnlp)
- the framework this model comes from, trains bert style models so cosine
  similarity between sentence vectors is meaningful

how we use it
- loaded through sentence-transformers, mean pooling, cosine similarity
- dropped from later work, the head to head is clinicalbert vs sapbert only

sources
- all-mpnet-base-v2 model card. https://huggingface.co/sentence-transformers/all-mpnet-base-v2
- Song K, Tan X, Qin T, Lu J, Liu TY. MPNet: Masked and Permuted Pre-training for Language Understanding. NeurIPS 2020. https://arxiv.org/abs/2004.09297
- Reimers N, Gurevych I. Sentence-BERT: Sentence Embeddings using Siamese BERT-Networks. EMNLP 2019. https://arxiv.org/abs/1908.10084
