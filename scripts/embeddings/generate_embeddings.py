"""
Generates cosine-similarity matrices for ICD-9-CM -> ICD-10-CA and
ICD-9-CM -> ICDA-8, for a chosen embedding model and label-cleaning mode,
in the same multi-sheet xlsx layout the R pipeline expects (one sheet per
CCS_ID group, rows = all target codes, columns = the ICD-9-CM codes in
that CCS group).

Usage:
    python scripts/embeddings/generate_embeddings.py --model clinicalbert --clean base
    python scripts/embeddings/generate_embeddings.py --model sapbert       --clean stripped
    python scripts/embeddings/generate_embeddings.py --model mpnet          --clean stripped

--model:  clinicalbert | sapbert | mpnet
--clean:  base       original label-cleaning only
          stripped   also removes the filler words in FILLER_WORDS
          stopwords  also removes the snowball english stopword list, minus
                     single letters and no/not/nor
          stopwords_raw
                     also removes the snowball english stopword list exactly
                     as published

Output goes to data/generated/cosine_similarity_matrices_{track}_{MODEL}_{clean}.xlsx
"""
import argparse
import re
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import torch

HERE = Path(__file__).resolve().parent
ORIG_BASE = HERE.parent.parent / "data" / "original"
OUT_BASE = HERE.parent.parent / "data" / "generated"

MODEL_IDS = {
    "clinicalbert": "emilyalsentzer/Bio_ClinicalBERT",
    "sapbert": "cambridgeltl/SapBERT-from-PubMedBERT-fulltext",
    "mpnet": "sentence-transformers/all-mpnet-base-v2",
}

# reticulate gave wrong numbers, so python
CLS_MODELS = {"clinicalbert", "sapbert"}


FILLER_WORDS = [
    "and", "or", "nos", "nec", "not otherwise specified",
    "not elsewhere classified", "of", "the", "in", "due to", "type",
]

# snowball english, as published
SNOWBALL = [
    "i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you",
    "your", "yours", "yourself", "yourselves", "he", "him", "his", "himself",
    "she", "her", "hers", "herself", "it", "its", "itself", "they", "them",
    "their", "theirs", "themselves", "what", "which", "who", "whom", "this",
    "that", "these", "those", "am", "is", "are", "was", "were", "be", "been",
    "being", "have", "has", "had", "having", "do", "does", "did", "doing",
    "would", "should", "could", "ought", "i'm", "you're", "he's", "she's",
    "it's", "we're", "they're", "i've", "you've", "we've", "they've", "i'd",
    "you'd", "he'd", "she'd", "we'd", "they'd", "i'll", "you'll", "he'll",
    "she'll", "we'll", "they'll", "isn't", "aren't", "wasn't", "weren't",
    "hasn't", "haven't", "hadn't", "doesn't", "don't", "didn't", "won't",
    "wouldn't", "shan't", "shouldn't", "can't", "cannot", "couldn't",
    "mustn't", "let's", "that's", "who's", "what's", "here's", "there's",
    "when's", "where's", "why's", "how's", "a", "an", "the", "and", "but",
    "if", "or", "because", "as", "until", "while", "of", "at", "by", "for",
    "with", "about", "against", "between", "into", "through", "during",
    "before", "after", "above", "below", "to", "from", "up", "down", "in",
    "out", "on", "off", "over", "under", "again", "further", "then", "once",
    "here", "there", "when", "where", "why", "how", "all", "any", "both",
    "each", "few", "more", "most", "other", "some", "such", "no", "nor",
    "not", "only", "own", "same", "so", "than", "too", "very", "will",
]

# keeping these stops two labels becoming identical
SNOWBALL_KEEP = {"i", "a", "no", "nor", "not"}


def load_filler_words():
    return FILLER_WORDS


def load_stopwords(which):
    if which == "snowball":
        return SNOWBALL
    return [w for w in SNOWBALL if w not in SNOWBALL_KEEP]


def base_clean(text):
    text = str(text).lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def strip_filler(text, filler_words):
    words = sorted(filler_words, key=len, reverse=True)
    for w in words:
        pattern = r"\b" + re.sub(r"\s+", r"\\s+", re.escape(w)) + r"\b"
        text = re.sub(pattern, " ", text)
    return re.sub(r"\s+", " ", text).strip()


def strip_stopwords(text, stop_words):
    kept = [w for w in text.split() if w not in stop_words]
    return " ".join(kept)


def clean_label(text, mode, filler_words, stop_words):
    text = base_clean(text)
    if mode == "stripped":
        text = strip_filler(text, filler_words)
    elif mode in ("stopwords", "stopwords_raw"):
        text = strip_stopwords(text, stop_words)
    return text


def embed_texts_cls(texts, model_id, batch_size=32, max_length=64):
    from transformers import AutoTokenizer, AutoModel

    tok = AutoTokenizer.from_pretrained(model_id)
    model = AutoModel.from_pretrained(model_id)
    model.eval()
    out = []
    with torch.no_grad():
        for i in range(0, len(texts), batch_size):
            batch = texts[i : i + batch_size]
            enc = tok(batch, padding="max_length", max_length=max_length,
                      truncation=True, return_tensors="pt")
            res = model(**enc)
            cls = res[0][:, 0, :]
            out.append(cls.numpy())
            print(f"  {min(i + batch_size, len(texts))}/{len(texts)}", flush=True)
    return np.vstack(out)


def embed_texts_sentence_transformer(texts, model_id, batch_size=32):
    from sentence_transformers import SentenceTransformer

    model = SentenceTransformer(model_id)
    return model.encode(texts, batch_size=batch_size, show_progress_bar=True,
                         convert_to_numpy=True)


def cosine_sim_matrix(a, b):
    a_norm = a / np.linalg.norm(a, axis=1, keepdims=True)
    b_norm = b / np.linalg.norm(b, axis=1, keepdims=True)
    return a_norm @ b_norm.T


def write_ccs_sheets(path, sim_df, icd9_codes, ccs_map, target_col_name):
    # rows = targets, cols = icd9 codes
    with pd.ExcelWriter(path, engine="openpyxl") as writer:
        for ccs_id in sorted(ccs_map.keys()):
            cols = [c for c in ccs_map[ccs_id] if c in sim_df.columns]
            if not cols:
                continue
            sheet_df = sim_df[cols].reset_index()
            sheet_df = sheet_df.rename(columns={"index": target_col_name})
            sheet_name = f"CCS_{ccs_id}"
            sheet_df.to_excel(writer, sheet_name=sheet_name, index=False)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", required=True, choices=list(MODEL_IDS.keys()))
    ap.add_argument("--clean", required=True,
                    choices=["base", "stripped", "stopwords", "stopwords_raw"])
    ap.add_argument("--no-code", action="store_true",
                    help="embed the label only, without the code number prefix")
    ap.add_argument("--max-length", type=int, default=64)
    args = ap.parse_args()

    model_id = MODEL_IDS[args.model]
    filler_words = load_filler_words()
    stop_words = load_stopwords(
        "snowball" if args.clean == "stopwords_raw" else "snowball_safe")

    labels_path = ORIG_BASE / "ICD_Codes_Files_and_Validation_Data" / "ICD_Codes_Labels.xlsx"
    icd9 = pd.read_excel(labels_path, sheet_name="CCS ICD-9-CM-3Level")
    icd10 = pd.read_excel(labels_path, sheet_name="ICD-10-CA-3Level")
    icd8 = pd.read_excel(labels_path, sheet_name="ICDA-8-3Level")

    def build_text(df, code_col, label_col):
        lab = df[label_col].apply(
            lambda s: clean_label(s, args.clean, filler_words, stop_words))
        if args.no_code:
            return lab
        return df[code_col].astype(str) + " " + lab

    icd9["text"]  = build_text(icd9,  "ICD_9_CM",  "ICD_9_CM_LABEL")
    icd10["text"] = build_text(icd10, "ICD_10_CA", "ICD_10_CA_LABEL")
    icd8["text"]  = build_text(icd8,  "ICDA_8",    "ICDA_8_LABEL")

    print(f"Embedding with {model_id} (clean={args.clean})...")
    if args.model in CLS_MODELS:
        emb9 = embed_texts_cls(icd9["text"].tolist(), model_id, max_length=args.max_length)
        emb10 = embed_texts_cls(icd10["text"].tolist(), model_id, max_length=args.max_length)
        emb8 = embed_texts_cls(icd8["text"].tolist(), model_id, max_length=args.max_length)
    else:
        emb9 = embed_texts_sentence_transformer(icd9["text"].tolist(), model_id)
        emb10 = embed_texts_sentence_transformer(icd10["text"].tolist(), model_id)
        emb8 = embed_texts_sentence_transformer(icd8["text"].tolist(), model_id)

    icd9_codes = icd9["ICD_9_CM"].astype(str).tolist()
    icd10_codes = icd10["ICD_10_CA"].astype(str).tolist()
    icd8_codes = icd8["ICDA_8"].astype(str).tolist()

    ccs_map = {}
    for code, ccs_id in zip(icd9_codes, icd9["CCS_ID"].astype(int).tolist()):
        ccs_map.setdefault(ccs_id, []).append(code)

    OUT_BASE.mkdir(parents=True, exist_ok=True)

    sim_10_9 = cosine_sim_matrix(emb10, emb9)
    sim_10_9_df = pd.DataFrame(sim_10_9, index=icd10_codes, columns=icd9_codes)
    tag = args.clean + ("_nocode" if args.no_code else "")
    out_10_9 = OUT_BASE / f"cosine_similarity_matrices_10_9_{args.model}_{tag}.xlsx"
    write_ccs_sheets(out_10_9, sim_10_9_df, icd9_codes, ccs_map, "ICD_10_CA")
    print(f"Wrote {out_10_9}")

    sim_8_9 = cosine_sim_matrix(emb8, emb9)
    sim_8_9_df = pd.DataFrame(sim_8_9, index=icd8_codes, columns=icd9_codes)
    out_8_9 = OUT_BASE / f"cosine_similarity_matrices_8_9_{args.model}_{tag}.xlsx"
    write_ccs_sheets(out_8_9, sim_8_9_df, icd9_codes, ccs_map, "ICDA_8")
    print(f"Wrote {out_8_9}")


if __name__ == "__main__":
    main()
