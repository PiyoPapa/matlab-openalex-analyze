# # matlab-openalex-analyze

Experimental MATLAB workflows for **diagnostic topic analysis** on OpenAlex data.
This repository focuses on *making intermediate structure visible*—from text
reconstruction to baseline and semantic mappings—rather than producing final or
optimized analytical results.

It is intended for controlled, time-bounded exploration, not for production use
or comprehensive research analytics.
 
---

## Repository position in the OpenAlex–MATLAB workflow
## Overview

- **Who this is for**  
  Professionals who are *not* full-time text-analytics developers, but who need to
  inspect research-topic structure reproducibly within MATLAB.

- **What problem this addresses**  
  Understanding whether OpenAlex-derived text data is *analytically usable* before
  committing to deeper modeling or interpretation.

- **What layer this represents**  
  The *analysis and diagnostic* layer, operating directly on pipeline-standard JSONL.

## What this repository provides (and what it doesn't)

**Provides**

- Text reconstruction from OpenAlex standard JSONL
- Baseline structure inspection (TF-IDF, PCA, k-means)
- Semantic embeddings and maps for *diagnostic comparison*
- Explicit intermediate artifacts (CSV, MAT, figures) for inspection

**Does NOT provide**

- A general-purpose visualization framework
- Optimized or production-grade topic models
- End-to-end OpenAlex ingestion or CSV normalization
- Authoritative or finalized topic interpretations

## Repository position in the OpenAlex–MATLAB workflow
This repository is part of a three-stage workflow for analyzing OpenAlex data in MATLAB.

1. **Acquisition** — fetch OpenAlex Works  
   → [`matlab-openalex-pipeline`](https://github.com/PiyoPapa/matlab-openalex-pipeline)

2. **Normalization** — fixed-schema, versioned CSVs  
   → [`matlab-openalex-normalize`](https://github.com/PiyoPapa/matlab-openalex-normalize)

3. **Analysis / topic mapping** — diagnostics and semantic maps (**this repository**)

## Scope and design principles
This repository is intentionally **experimental and narrow in scope**.
Its design follows a small set of constraints shared across the OpenAlex–MATLAB workflow:

- **Pipeline-first inputs**  
  Only OpenAlex *standard JSONL* is treated as canonical input.
  Schema stabilization is delegated upstream.

- **Stepwise diagnostics**  
  Each stage answers a limited question (e.g., text quality, structure presence,
  semantic continuity) before moving forward.

- **Reproducibility over polish**  
  Intermediate states are preserved to support comparison, failure analysis,
  and iterative refinement.

Advanced analytics, large-scale optimization, and domain-specific interpretation
are explicitly out of scope and expected to live in downstream repositories.

---

## Repository structure

The repository is organized to mirror the **analysis lifecycle**:
input ingestion → text reconstruction → representation → diagnostics.
The structure is intentionally shallow to keep execution paths visible.

```text
├─ data_sample/
│  └─ *.standard.jsonl        # small OpenAlex samples (≤1000 works)
├─ src/
│  └─ +topicmap/
│     ├─ read_pipeline_jsonl.m    # JSONL ingestion
│     ├─ reconstruct_abstract.m   # abstract reconstruction
│     ├─ extract_text.m           # title + abstract assembly
│     ├─ clean_text.m             # minimal token cleanup
│     └─ env_check.m              # environment diagnostics
└─ examples/
   ├─ Ch_00_Setup_Paths_and_Diagnostics.mlx      # pipeline sanity check
   ├─ Ch_01_CPU_Minimal_JSONL_to_Map.mlx
   ├─ Ch_02_From_Pipeline_JSONL.mlx
   ├─ Ch_03_Semantic_Topic_Map.mlx
   ├─ Ch_04_HDBSCAN_Child_Clusters.mlx
   └─ Ch_05_explicit-purpose.mlx
```
The src/+topicmap functions are not a general-purpose API.
They exist to support the demos and to make data transformations explicit.

## Input / Output contract

### Input (Required)

- Format: OpenAlex standard JSONL (one work per line)
- Source: output of matlab-openalex-pipeline
- Assumptions:

Example:
```text
data_sample/openalex_MATLAB_cursor_en_1000.standard.jsonl
```
Sample files are intentionally small and exist only to
support fast, local diagnostic execution.

### Output (By design)

Outputs are intermediate analytical artifacts, not final results.
Depending on the demo, these include:

- reconstructed text tables
- vector representations and projections
- cluster assignments and representatives
- diagnostic CSVs and figures

All outputs are written to run-specific directories to
support comparison and reproducibility.

## Demos / diagnostic stages
The demos are ordered as progressive diagnostic stages.
Each demo assumes that the previous stage has validated its inputs.

### Ch_01_CPU_Minimal_JSONL_to_Map.mlx  
**Purpose:** pipeline sanity check

- Runs from **sample standard JSONL** (CSV is accepted only as a legacy fallback)
- If precomputed embeddings are available, uses them; otherwise falls back to **TF-IDF**
- Confirms: ingestion → vectorization → (PCA) → k-means → artifacts saved under `runDir`

This demo exists solely to confirm that the execution environment
and data path are functional.

### Ch_02_From_Pipeline_JSONL.mlx  (Core Entry Point)

**Purpose:** baseline structure and text-quality diagnostics

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

### Ch_03_Semantic_Topic_Map.mlx  (Semantic Baseline)

**Purpose:** semantic topic mapping using Transformer embeddings

**What this demo does**

1. Reads OpenAlex standard JSONL (same input contract as Ch_02)
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

---

### Ch_04_HDBSCAN_Child_Clusters.mlx  (Density Diagnostic)

**Purpose:**  
Density-based diagnostic to test whether the semantic space contains
statistically separable topic regions.

**What this demo does**

1. Reuses Transformer embeddings generated in `demo_03`
2. Applies PCA-reduced embedding space for clustering
3. Runs **HDBSCAN** to detect density-separated parent clusters
4. Optionally attempts **child clustering** within each parent cluster
5. Reports:
   - number of detected clusters
   - noise ratio
   - stability under parameter sweeps

**Key interpretation**

- If HDBSCAN returns **a single cluster with high noise**,
  the space should be interpreted as **continuous rather than discretely clustered**
- This outcome is **diagnostic**, not a failure

**What this demo intentionally does NOT do**

- No forced partitioning
- No semantic labeling
- No assumption that clusters must exist

**Outputs**

- `demo04_parent_clusters.csv`  
  Parent cluster labels and noise assignment

- `demo04_parent_representatives.csv`  
  Representative papers per detected parent cluster (if applicable)

- `demo04_parent_stability.csv`  
  Parameter sweep summary (stability diagnostics)

- `demo04_parent_state.mat`, `demo04_child_state.mat`  
  Saved intermediate states for reproducibility

> demo_04 exists to answer a single question:  
> **"Does the data *want* to be clustered?"**

---

### Ch_05_explicit-purpose.mlx  (Diagnostic Comparison)

**Purpose:**  
Side-by-side comparison between:

- **density-detected structure** (HDBSCAN)
- **user-imposed summarization** (k-means)

on the **same semantic embedding space**.

**What this demo does**

1. Reuses embeddings and UMAP coordinates from `demo_03`
2. Runs HDBSCAN as a **structure detector**
3. Runs k-means with a small K sweep as a **constructive summarization**
4. Reports diagnostic metrics (e.g. mean silhouette)
5. Visualizes both results on the same 2D UMAP map

**Key interpretation**

- A visually separable k-means partition does **not** imply
  statistically stable topic separation
- HDBSCAN returning a single cluster indicates
  a **continuous semantic landscape**

**Outputs**

- `demo05_hdbscan.csv`  
  Density-based diagnostic result

- `demo05_kmeans_silhouette.csv`  
  Silhouette scores across tested K values

- `demo05_kmeans_K*.csv`  
  Cluster assignments for the selected K (e.g., `demo05_kmeans_K9.csv`)

- `demo05_parallel_hdbscan_vs_kmeans_*.png`  
  Side-by-side visualization

- `demo05_step1_state.mat`, `demo05_step2_state.mat`  
  Saved intermediate states for reproducibility

> demo_05 is explicitly **diagnostic**, not prescriptive.  
> It is designed to prevent over-interpretation of visually pleasing clusters.

---

## Token Cleaning Policy (Ch_02)

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
- Text Analytics Toolbox (required for Ch_02 TF-IDF)
- Deep Learning Toolbox (only required for Ch_03)

Run:
```matlab
cfg = topicmap.setup();
cfg = topicmap.env_check(cfg);
```
to verify availability.
> env_check reports global readiness. Demo-specific prerequisites are validated inside each demo script.
---

## Intended Use

This repository is intended for **diagnostic and exploratory use only**, including:

- inspecting whether OpenAlex-derived text is analytically usable
- comparing baseline vs semantic representations *before interpretation*
- educational or internal demonstrations of topic-mapping mechanics
- controlled experiments on clustering assumptions and stability

It is **not intended** for:

- decision-making without downstream validation
- automated or large-scale production analysis
- authoritative topic labeling or trend reporting
- replacement of domain expertise or commercial analytics tools
 
---

## Relationship to Other Repositories

This repository is designed to operate **within a deliberately split workflow**.
Each repository enforces a single responsibility.

### matlab-openalex-pipeline  
Responsible for OpenAlex data acquisition and API interaction.

### matlab-openalex-normalize  
Optional schema stabilization and CSV normalization.

This repository:

- consumes **pipeline-standard JSONL directly**
- does **not** depend on normalized CSVs
- assumes upstream data integrity, not downstream interpretation

Any extension beyond diagnostic topic mapping
should be implemented as a **separate downstream repository**.

---

## Disclaimer
The author is an employee of MathWorks Japan.
This repository is a personal experimental project developed independently
and is not part of any MathWorks product, service, or official content.

MathWorks does not review, endorse, support, or maintain this repository.
All opinions and implementations are solely those of the author.

## License
MIT License. See the LICENSE file for details.

## A note for contributors
This repository prioritizes:
- clarity over abstraction
- reproducibility over convenience
- explicit configuration over magic defaults

## Contact
This project is maintained on a best-effort basis and does not provide official support.

For bug reports or feature requests, please use GitHub Issues.
If you plan to extend it, please preserve the principles stated above.