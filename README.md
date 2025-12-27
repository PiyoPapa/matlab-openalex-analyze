# matlab-openalex-analyze

**Language:** English | [日本語](README_ja.md)

Experimental MATLAB workflows for **diagnostic topic-mapping workflows** on OpenAlex data.
This repository provides stepwise, reproducible workflows to make intermediate
structure visible (text reconstruction, representations, and diagnostic maps).

The purpose is to validate *whether* structure appears, not to optimize models
or assert semantic correctness.
 
---
## Overview

**Purpose**
This repository provides diagnostic workflows for inspecting intermediate
structure in OpenAlex-derived text data within MATLAB.

It focuses on *workflow mechanics and intermediate artifacts*, not on producing
validated topics or decision-ready outputs.

**Usage boundary**

This repository is intended for **diagnostic and exploratory use only**, including:

- inspecting whether OpenAlex-derived text is analytically usable
- comparing baseline vs semantic representations *before interpretation*
- educational or internal demonstrations of topic-mapping mechanics
- controlled experiments on clustering assumptions and stability

It is **not intended** for:

- decision-making without downstream validation
- automated or large-scale production analysis
- authoritative topic labeling or trend reporting

Outputs produced by this repository are diagnostic artifacts.
They are intended for inspection and comparison, not as analytical conclusions,
validated topics, or decision-support results.

## Repository position in the OpenAlex–MATLAB workflow

This repository occupies the **analysis / topic-mapping (diagnostic)** stage
within a three-step OpenAlex–MATLAB workflow:

1. Acquisition — fetch OpenAlex Works  
   → `matlab-openalex-pipeline`
2. Normalization — fixed-schema, versioned CSVs (optional)  
   → `matlab-openalex-normalize`
3. Analysis / topic mapping — diagnostic workflows (**this repository**)

## Who this repository is for / not for

**For**

Users who need to inspect and validate intermediate structure in OpenAlex-derived
text data using reproducible MATLAB workflows, without assuming prior investment
in full-scale text analytics systems.

**Not for**

Users seeking production-grade topic models, automated analytics pipelines,
or authoritative semantic interpretations.

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

## Chapter map (examples/)

- **Ch_00** — Repository setup and environment diagnostics  
- **Ch_01** — CPU-minimal end-to-end diagnostic smoke test  
- **Ch_02** — TF-IDF–based baseline structure inspection  
- **Ch_03** — Semantic embedding–based diagnostic topic map  
- **Ch_04** — Density-based (HDBSCAN) structural inspection  
- **Ch_05** — Interpretation viewpoints across diagnostic clusterings

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