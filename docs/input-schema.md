# Canonical Input Keys Reference

All 22 canonical input keys used by `run_agent.sh`, task contracts, and skill metadata. Use this page to look up what a key means, what query tokens trigger it, and what format its value should take.

## Coordinate Conventions

| Context | Default convention | Accepted alternatives |
|---|---|---|
| Genomic intervals | 0-based half-open `[start, end)` | 1-based closed (must be stated explicitly) |
| Single-site positions | 1-based | — |

**Always state the coordinate convention explicitly** when passing intervals to any skill. Silently assuming a convention is a safety violation (see `docs/safety.md`).

## Assembly Aliases

| Short alias | Canonical name |
|---|---|
| `hg19` | GRCh37 |
| `hg38` | GRCh38 |
| `mm10` | GRCm38 |
| `chm13` | T2T-CHM13 |

## Legacy Key Map

These deprecated keys are still accepted by `run_agent.sh` but are translated to canonical form internally.

| Deprecated key | Canonical key |
|---|---|
| `sequence` | `sequence-or-interval` |
| `coordinate` | `coordinate-or-interval` |
| `variant-spec` | `ref-alt-or-variant-spec` |
| `interval-or-variant` | `coordinate-or-interval` |

Source: `registry/input_schema.yaml` → `legacy_key_map`

## Canonical Keys

### Environment and Runtime

| Key | Type | Example values |
|---|---|---|
| `target-stack-or-model-family` | string | `"ntv3"`, `"evo2 hosted"` |
| `runtime-context` | string | `"mac + conda"`, `"linux docker"` |
| `hardware-context` | string | `"single A100"`, `"cpu only"` |
| `execution-path` | enum | `"hosted api"`, `"local gpu"` |
| `network-proxy-endpoint` | string | `"http://127.0.0.1:7890"` |

### Sequence and Genomic Location

| Key | Type | Notes | Example values |
|---|---|---|---|
| `sequence-or-interval` | union | raw sequence **or** genomic interval | `"ACGTACGT..."`, `"chr19:6700000-6732768"` |
| `assembly` | enum | see assembly aliases above | `"hg38"`, `"mm10"` |
| `species` | enum | | `"human"`, `"mouse"` |
| `coordinate-or-interval` | union | single-site (1-based) or interval (0-based half-open) | `"chr12:1000000"`, `"chr19:6700000-6732768"` |
| `ref-alt-or-variant-spec` | string | allele or variant notation | `"REF A ALT G"`, `"T>G"` |

### Model and Task Objective

| Key | Type | Example values |
|---|---|---|
| `embedding-target` | enum | `"pooled embedding"`, `"token embeddings"` |
| `output-head` | string | `"RNA_SEQ"`, `"bigwig tracks"` |
| `requested-outputs` | list | `"RNA_SEQ"` |
| `task-objective` | string | `"binary classification"`, `"track prediction"` |
| `model-family-objective` | string | `"choose between GPN and GPN-Star"` |
| `objective` | string | `"variant scoring"` |
| `family-choice` | string | `"segment_nt_multi_species"` |
| `ontology-terms` | list | `"UBERON:0001157"` |

### Training and Evaluation

| Key | Type | Example values |
|---|---|---|
| `dataset-schema` | string | `"sequence,label"`, `"seq1,seq2,label"` |
| `compute-constraints` | string | `"single 24GB GPU"`, `"cpu within 2h"` |

### Troubleshooting

| Key | Type | Example values |
|---|---|---|
| `failing-step-or-error` | string | `"HF token unauthorized"`, `"grpc timeout"` |

### Output

| Key | Type | Example values |
|---|---|---|
| `output-dir` | path | `"output/alphagenome"` |

Source: `registry/input_schema.yaml`

## Per-Task Required Subsets

Each task only requires a specific subset of keys. See [Contracts Reference](./contracts.md) for the full required-input table per task.
