# clinicalbert

emilyalsentzer/Bio_ClinicalBERT, used in the original pipeline

alsentzer et al. 2019, clinical nlp workshop at naacl
- bert trained on clinical notes, released publicly
- two versions, one on all clinical notes and one on discharge summaries only
- we use the all notes one

model card
- initialized from biobert (pubmed 200k + pmc 270k)
- trained on all notes in the mimic-iii noteevents table, ~880M words
- training is masked language modelling, i.e. predict hidden words
- nothing in the training is about making similar texts end up close together

biobert (lee et al. 2020, bioinformatics)
- bert further trained on pubmed abstracts and pmc full text
- the starting point for clinicalbert

mimic-iii (johnson et al. 2016, scientific data)
- icu records from beth israel deaconess, boston
- notes are free text written by clinicians, so very different from short code labels

how we use it
- [CLS] vector from the last layer, cosine similarity between labels
- no pooling or fine tuning on our side

concerns for our task
- our labels are short names ("diabetes mellitus"), not notes
- it was never trained to compare two pieces of text
- see bert_embeddings.md for why plain bert vectors are weak for similarity

sources
- Alsentzer E, Murphy JR, Boag W, Weng WH, Jin D, Naumann T, McDermott MBA. Publicly Available Clinical BERT Embeddings. Clinical NLP Workshop, NAACL 2019. https://arxiv.org/abs/1904.03323
- Bio_ClinicalBERT model card. https://huggingface.co/emilyalsentzer/Bio_ClinicalBERT
- Lee J, Yoon W, Kim S, Kim D, Kim S, So CH, Kang J. BioBERT: a pre-trained biomedical language representation model for biomedical text mining. Bioinformatics, 2020. https://doi.org/10.1093/bioinformatics/btz682
- Johnson AEW, Pollard TJ, Shen L, et al. MIMIC-III, a freely accessible critical care database. Scientific Data, 2016. https://doi.org/10.1038/sdata.2016.35
