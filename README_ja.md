# matlab-openalex-analyze

**Language:** [English](README.md) | 日本語

OpenAlex データを対象とした **診断的トピックマッピング・ワークフロー**のための  
実験的な MATLAB ワークフロー集です。

本リポジトリは、テキスト再構成、表現生成、診断用マップといった  
**中間構造を可視化するための、段階的かつ再現可能なワークフロー**を提供します。

目的は「構造が *存在しうるか* を確認すること」であり、  
モデル最適化や意味的正しさの主張を行うものではありません。

---
## Overview

### Purpose

本リポジトリは、OpenAlex 由来のテキストデータにおける  
**中間的な構造を点検・確認するための診断的ワークフロー**を MATLAB 上で提供します。

焦点は、ワークフローの仕組みと中間成果物にあり、  
検証済みトピックや意思決定向けの出力を生成することではありません。

### Usage boundary

本リポジトリは **診断的・探索的用途のみ**を想定しています。具体的には以下を含みます。

- OpenAlex 由来テキストが分析可能かどうかの確認  
- 解釈に入る前段階での、ベースライン表現とセマンティック表現の比較  
- トピックマッピング手法の教育的・内部向けデモ  
- クラスタリング前提や安定性に関する制御された実験  

以下の用途は想定していません。

- 下流検証を伴わない意思決定への利用  
- 自動化された、または大規模な本番分析  
- 権威的なトピック付与やトレンド報告  

本リポジトリが生成する出力は **診断用成果物**です。  
分析結論、検証済みトピック、意思決定結果として扱うことは意図していません。

---
## Repository position in the OpenAlex–MATLAB workflow

本リポジトリは、OpenAlex–MATLAB ワークフローにおける  
**分析／トピックマッピング（診断）段階**を担います。

全体は以下の 3 段階で構成されます。

1. 取得（Acquisition） — OpenAlex Works の取得  
   → matlab-openalex-pipeline  
2. 正規化（Normalization） — 固定スキーマ CSV の生成（任意）  
   → matlab-openalex-normalize  
3. 分析／トピックマッピング — 診断的ワークフロー（本リポジトリ）

---
## Who this repository is for / not for

### For

MATLAB 上で再現可能なワークフローを用い、  
OpenAlex 由来テキストデータの **中間構造を点検・検証したい利用者**を対象としています。

本格的なテキスト分析基盤への事前投資を前提としません。

### Not for

以下を目的とする利用者は対象外です。

- 本番品質のトピックモデル構築  
- 自動化された分析パイプライン  
- 権威的な意味解釈や最終的なトピック定義  

---
## Repository layout

本リポジトリは、  
**入力 → テキスト再構成 → 表現生成 → 診断**  
という分析ライフサイクルに沿った構成になっています。

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
src/+topicmap 配下の関数群は、汎用 API ではありません。  
各デモを支え、データ変換を明示的にするために存在します。

## Inputs / Outputs

### Input（必須）

- OpenAlex 標準 JSONL（1 行 1 work）
- 入力元：matlab-openalex-pipeline の出力
- 本リポジトリには **小規模サンプルのみ**を同梱します
  （目安：≤1000 works）
- それより大きな JSONL 入力は同梱せず、
  利用者が pipeline 等で生成・取得することを前提とします

例:
```text
data_sample/openalex_MATLAB_cursor_en_1000.standard.jsonl
```

### Output（設計上）

出力は **最終結果ではなく中間分析成果物**です。

- 再構成されたテキスト表  
- ベクトル表現および射影結果  
- クラスタ割当および代表文献  
- 診断用 CSV および図表  

すべての出力は、比較と再現性のために実行単位で保存されます。

---
## Chapter map（examples/）

- Ch_00 — リポジトリ設定および環境診断  
- Ch_01 — CPU 最小構成でのエンドツーエンド診断スモークテスト  
- Ch_02 — TF-IDF によるベースライン構造点検  
- Ch_03 — セマンティック埋め込みを用いた診断的トピックマップ  
- Ch_04 — 密度ベース（HDBSCAN）による構造点検  
- Ch_05 — 複数クラスタリング結果に対する解釈視点の提示  

---
## Token Cleaning Policy（Ch_02）

トークンのクリーニングは **最小限かつ保守的**に行います。

- 除去対象  
  - 単独の x  
  - 数式由来トークン  
  - 短桁の単独数値  

- 保持対象  
  - 分野固有語  
  - 略語および専門用語  

---
## Environment Requirements

- MATLAB R2022b 以降を推奨  
- Text Analytics Toolbox（Ch_02 に必須）  
- Deep Learning Toolbox（Ch_03 のみ必須）  

実行:
```matlab
cfg = topicmap.setup();
cfg = topicmap.env_check(cfg);
```

---

## Relationship to Other Repositories

- 取得：matlab-openalex-pipeline  
- 正規化（任意）：matlab-openalex-normalize  

---
## When to stop here / when to move on

- 探索的診断と中間成果物のみが目的の場合は、ここで終了できます  
- pipeline 標準 JSONL を持っていない場合は、上流に進んでください  

---
## Disclaimer

本リポジトリの作者は MathWorks Japan の従業員です。

本リポジトリは、作者個人による実験的プロジェクトとして
独立に開発されたものであり、MathWorks の製品、サービス、
公式コンテンツ、またはマーケティング活動の一部ではありません。

MathWorks は本リポジトリの内容をレビュー、保証、支持、保守することはありません。
---
## License

MIT License。詳細は LICENSE ファイルを参照してください。

---
## Notes

本プロジェクトはベストエフォートで保守されています。  
不具合報告や質問は GitHub Issues を利用してください。