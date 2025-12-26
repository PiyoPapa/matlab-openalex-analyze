# matlab-openalex-analyze

Experimental MATLAB workflows for **diagnostic topic analysis** on OpenAlex data.
This repository focuses on *making intermediate structure visible*—from text
reconstruction to baseline and semantic mappings—rather than producing final or
optimized analytical results.

It is intended for controlled, time-bounded exploration, not for production use
or comprehensive research analytics.
 
---
## Who this repository is for

Professionals who are **not full-time text analytics developers**, but who need to:

- inspect whether OpenAlex-derived text data is analytically usable
- validate structure and representation *before* interpretation
- do so reproducibly within MATLAB

This repository is **not** for:
- general-purpose visualization frameworks
- production-grade or automated topic modeling
- data acquisition or fixed-schema CSV normalization

## Overview

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
### In scope
- diagnostic, stepwise exploration on pipeline-standard JSONL
- preserving intermediate artifacts (CSV/MAT/figures) for inspection and comparison

### Out of scope
- optimized or production-grade topic models
- authoritative topic interpretation or decision-making outputs
- end-to-end ingestion (handled by pipeline) or fixed-schema CSV normalization (optional via normalize)

This repository prioritizes reproducibility, transparency, and explicit configuration.

---

## Repository layout

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

## Inputs / Outputs

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

## Examples / demos
The demos are ordered as progressive diagnostic stages.
Each demo assumes that the previous stage has validated its inputs.

### Ch_01_CPU_Minimal_JSONL_to_Map.mlx  
**Purpose:** environment and pipeline sanity check  
**Outputs:** baseline PCA map, k-means clusters, diagnostic artifacts

### Ch_02_From_Pipeline_JSONL.mlx  (Core Entry Point)
**Purpose:** baseline text-quality and structural diagnostics  
**Outputs:** TF-IDF baseline clusters, reconstructed text tables, anomaly reports

### Ch_03_Semantic_Topic_Map.mlx  (Semantic Baseline)
**Purpose:** semantic representation baseline using Transformer embeddings  
**Outputs:** embedding state, UMAP projection, representative papers per cluster

### Ch_04_HDBSCAN_Child_Clusters.mlx  (Density Diagnostic)
**Purpose:** test whether semantic space supports density-separated structure  
**Outputs:** parent cluster labels, noise ratio, stability diagnostics

### Ch_05_explicit-purpose.mlx  (Diagnostic Comparison)
**Purpose:** contrast density-detected vs user-imposed structure  
**Outputs:** parallel HDBSCAN / k-means diagnostics and comparison figures


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

- **Acquisition:**  
  [`matlab-openalex-pipeline`](https://github.com/PiyoPapa/matlab-openalex-pipeline)

- **Optional normalization:**  
  [`matlab-openalex-normalize`](https://github.com/PiyoPapa/matlab-openalex-normalize)

This repository consumes **pipeline-standard JSONL directly** and focuses only on
diagnostic topic analysis.

---
## When to stop here / when to move on

- You can stop here if you only need exploratory diagnostics and intermediate artifacts.
- You should move upstream if you do not already have pipeline-standard JSONL:
  - acquisition: `matlab-openalex-pipeline`
  - optional normalization: `matlab-openalex-normalize`

## Disclaimer 
The author is an employee of MathWorks Japan. 
This repository is a personal experimental project developed independently and is not part of any MathWorks product, service, or official content. 
MathWorks does not review, endorse, support, or maintain this repository. 
All opinions and implementations are solely those of the author.

## License 
MIT License. See the LICENSE file for details. 

## Notes
This project is maintained on a best-effort basis.
For bug reports or questions, please use GitHub Issues.