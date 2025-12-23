# OpenAlex Topic Map (MATLAB)

This repository provides a **MATLAB-based workflow** for exploring research topics from  
**OpenAlex standard JSONL outputs**, focusing on **text reconstruction, baseline mapping, and diagnostic analysis**.

The goal is **not** to claim analytical optimality at early stages, but to offer a **transparent, reproducible pipeline**
that clearly separates:

- data ingestion and text reconstruction
- baseline structure inspection (TF-IDF)
- semantic modeling with Transformer embeddings (MiniLM) and 2D mapping

---

## Scope and Philosophy

This project is designed around the following principles:

- **Pipeline-first**  
  Input is always OpenAlex *standard JSONL* (one work per line).
  CSV-based normalization is intentionally out of scope here.

- **Stepwise interpretability**  
  Each demo has a clearly defined responsibility.
  Interpretation depth increases only when the underlying representation justifies it.

- **Reproducibility over polish**  
  Intermediate CSVs and diagnostics are preserved to support iteration and comparison.

---

## Repository Structure (Relevant Parts)
```text
├─ data_sample/
│  └─ *.standard.jsonl        # small OpenAlex samples (≤1000 works)
├─ src/
│  └─ +topicmap/
│     ├─ read_pipeline_jsonl.m
│     ├─ reconstruct_abstract.m
│     ├─ extract_text.m
│     ├─ clean_text.m
│     └─ env_check.m
└─ examples/
   ├─ demo_01_cpu_minimal.mlx
   ├─ demo_02_from_pipeline_jsonl.mlx
   └─ demo_03_semantic_topic_map.mlx
```


## Input Data

### Standard JSONL (Required)

- **Format**: one OpenAlex *work* per line  
- **Source**: output of `matlab-openalex-pipeline`
- **Typical size**: ≤1000 works for demos

Example:
```text
data_sample/openalex_MATLAB_cursor_en_1000.standard.jsonl
```
> These samples are **trimmed for quick local execution**  
> and are **not intended for final analysis quality evaluation**.

## Demos Overview

### demo_01_cpu_minimal.mlx  
**Purpose:** sanity check

- Uses precomputed embeddings
- Confirms plotting, clustering, and run directory logic
- No OpenAlex-specific assumptions

> This demo exists mainly for environment validation.

### demo_02_from_pipeline_jsonl.mlx  (Core Entry Point)

**Purpose:**  
Baseline topic mapping and text-quality diagnostics from raw OpenAlex JSONL.

**What it does**

1. Reads OpenAlex standard JSONL  
2. Reconstructs text (`title + abstract`)
3. Applies conservative token cleanup
4. Builds **TF-IDF baseline embedding**
5. Generates a **2D PCA map + k-means clustering**
6. Exports diagnostic CSVs

**What it intentionally does NOT do**

- No BERT embeddings
- No semantic claims beyond baseline structure
- No aggressive text normalization

**Outputs**

- `demo02_cluster_terms.csv`  
  Top TF-IDF terms per cluster (with `min_df` filtering)

- `demo02_cluster_representatives.csv`  
  Representative papers closest to each cluster centroid

- `demo02_text_anomalies.csv`  
  Short / missing / structurally suspicious texts

These outputs are meant for:
- checking text reconstruction quality
- identifying cleaning issues
- validating cluster stability before semantic modeling

---

### demo_03_semantic_topic_map.mlx  (Semantic Baseline)

**Purpose:** semantic topic mapping using Transformer embeddings

**What this demo does**

1. Reads OpenAlex standard JSONL (same input contract as demo_02)
2. Reconstructs text (`title + abstract`) and applies the same conservative cleaning
3. Computes Transformer embeddings using  
   `documentEmbedding(Model="all-MiniLM-L6-v2")`
4. Applies dimensionality reduction: **PCA(50) → UMAP(2)**
5. Performs clustering with **k-means (K=12)** as a stable semantic baseline
6. Extracts **representative papers per cluster** using cosine distance
   to the centroid in embedding space
7. Exports figures and CSV artifacts for reproducibility

**What this demo intentionally does NOT do**

- No multilingual processing
- No hierarchical or child clusters
- No HDBSCAN
- No manual semantic labeling or interpretation

**Outputs**

- `demo03_embeddings.mat`  
  Raw embedding matrix and aligned metadata

- `demo03_umap2d.csv`  
  2D UMAP coordinates with cluster assignment

- `demo03_cluster_representatives.csv`  
  Representative papers per cluster (work_id, year, title, cosine distance)

- `demo03_map.pdf`, `demo03_map.png`  
  Publication-style semantic topic map

> demo_03 assumes demo_02 has already stabilized text quality and structure.  
> It serves as a **semantic baseline**, not an optimized or final analytics endpoint.
 
> demo_03 assumes demo_02 has already stabilized text quality and structure.

---

## Token Cleaning Policy (demo_02)

Cleaning is intentionally **minimal and conservative**:

- Removed:
  - standalone `x`
  - `x1`, `x2`, … (math variable artifacts)
  - 1–2 digit standalone numbers
- Preserved:
  - `xray` (from `x-ray`)
  - domain abbreviations (`x4DSTEM`, etc.)

This avoids destroying domain-specific terminology
while suppressing obvious mathematical noise.

---

## Environment Requirements

- MATLAB R2022b or later recommended
- Text Analytics Toolbox (required for demo_02 TF-IDF)
- Deep Learning Toolbox (only required for demo_03)

Run:
```matlab
cfg = topicmap.setup();
cfg = topicmap.env_check(cfg);
```
to verify availability.

---

## Intended Use

This repository is suitable for:

- exploratory research trend mapping
- educational demonstrations
- method comparison (TF-IDF vs BERT)
- reproducible topic analysis workflows in MATLAB

It is **not** a black-box analytics product.

---

## Relationship to Other Repositories

### matlab-openalex-pipeline
Responsible for robust OpenAlex data acquisition

### matlab-openalex-normalize
Optional CSV normalization (not required here)

This repository starts **after** data acquisition,  
directly from pipeline-standard JSONL.

---

## License / Notes

- Sample data included here is for demonstration only
- Users should regenerate JSONL from OpenAlex for real analyses