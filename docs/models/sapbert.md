# sapbert

cambridgeltl/SapBERT-from-PubMedBERT-fulltext

liu et al. 2021, naacl
- "self-alignment pretraining", trains so that synonyms of the same medical
  concept end up close together
- uses umls synonyms, metric learning over 4M+ concepts
- target task is medical entity linking: given a name, find the concept
- state of the art on six entity linking benchmarks with one model, no task
  specific training
- this is pretty much our problem, we match a code label to the right label in
  another coding system

model card
- base model is pubmedbert (abstract + fulltext)
- trained on umls 2020AA, english only
- output is the [CLS] vector of the last layer, inputs are short entity names

pubmedbert (gu et al. 2021, acm transactions on computing for healthcare)
- bert trained from scratch on pubmed text, not continued from general bert
- they found from scratch beats continuing from general text when there's a
  lot of domain text

umls (bodenreider 2004, nucleic acids research)
- nlm's metathesaurus, links 100+ medical vocabularies under shared concept ids
- source list includes icd9cm and icd10cm
- icd-10-ca is not in it, only the us icd-10-cm. both are based on who icd-10
  so most three character codes line up but not all
- since icd-9-cm is in umls, sapbert has probably seen some of our labels

how we use it
- [CLS] vector from the last layer, same as clinicalbert, as the model card says

sources
- Liu F, Shareghi E, Meng Z, Basaldella M, Collier N. Self-Alignment Pretraining for Biomedical Entity Representations. NAACL 2021. https://arxiv.org/abs/2010.11784
- SapBERT model card. https://huggingface.co/cambridgeltl/SapBERT-from-PubMedBERT-fulltext
- Gu Y, Tinn R, Cheng H, et al. Domain-Specific Language Model Pretraining for Biomedical Natural Language Processing. ACM Transactions on Computing for Healthcare, 2021. https://arxiv.org/abs/2007.15779
- Bodenreider O. The Unified Medical Language System (UMLS): integrating biomedical terminology. Nucleic Acids Research, 2004. https://doi.org/10.1093/nar/gkh061
- UMLS source vocabularies. https://www.nlm.nih.gov/research/umls/sourcereleasedocs/index.html
