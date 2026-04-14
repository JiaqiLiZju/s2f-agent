# Skill Catalog

All 11 packaged skills. Individual `SKILL.md` files are the operational source of truth for each skill. This page is the orientation catalog for choosing a skill.

## Stable Skills (enabled by default)

| Skill ID | Family | Tasks | Key triggers | Path | Docs |
|---|---|---|---|---|---|
| `alphagenome-api` | api-variant-prediction | variant-effect, interval-prediction, plotting, troubleshooting | alphagenome, dna_client, predict_variant | `skills/alphagenome-api` | [SKILL.md](../skills/alphagenome-api/SKILL.md) |
| `borzoi-workflows` | sequence-to-signal | environment-setup, track-prediction, variant-effect, interpretation, tutorial-playbooks | borzoi, westminster, baskerville, human_gtex | `skills/borzoi-workflows` | [SKILL.md](../skills/borzoi-workflows/SKILL.md) |
| `dnabert2` | transformer-embedding-and-finetuning | embedding, gue-evaluation, fine-tuning, csv-validation | dnabert2, zhihan1996/DNABERT-2-117M, gue | `skills/dnabert2` | [SKILL.md](../skills/dnabert2/SKILL.md) |
| `evo2-inference` | genome-language-model-inference | environment-setup, forward, embedding, generation, hosted-api | evo2, nvcf, flash-attn | `skills/evo2-inference` | [SKILL.md](../skills/evo2-inference/SKILL.md) |
| `gpn-models` | phylogenetic-language-models | framework-selection, loading, training, variant-scoring | gpn, phylogpn, gpn-star | `skills/gpn-models` | [SKILL.md](../skills/gpn-models/SKILL.md) |
| `nucleotide-transformer-v3` | transformers-ntv3 | environment-setup, embedding, fine-tuning, track-prediction, troubleshooting | ntv3, species-conditioning, post-trained, bigwig, annotation | `skills/nucleotide-transformer-v3` | [SKILL.md](../skills/nucleotide-transformer-v3/SKILL.md) |
| `segment-nt` | segmentation-heads | segmentation-inference, rescaling-factor, constraints, troubleshooting | segmentnt, segmentenformer, segmentborzoi | `skills/segment-nt` | [SKILL.md](../skills/segment-nt/SKILL.md) |

## Dev Skills (disabled by default)

Dev skills require `--include-disabled` to participate in routing, linking, and validation.

| Skill ID | Family | Tasks | Key triggers | Path | Docs |
|---|---|---|---|---|---|
| `basset-workflows` | legacy-cnn-regulatory | preprocessing, training, prediction, interpretation | basset, torch7, sad | `skills-dev/basset-workflows` | [SKILL.md](../skills-dev/basset-workflows/SKILL.md) |
| `bpnet` | profile-prediction-and-attribution | preprocessing, training, prediction, attribution | bpnet, shap, motif | `skills-dev/bpnet` | [SKILL.md](../skills-dev/bpnet/SKILL.md) |
| `nucleotide-transformer` | jax-haiku-transformers | environment-setup, tokenization, embedding, attention-analysis | nucleotide-transformer, nt-jax, 6-mer | `skills-dev/nucleotide-transformer` | [SKILL.md](../skills-dev/nucleotide-transformer/SKILL.md) |
| `skill-factory` | skilling-and-scaffolding | skill-scaffold, skill-registry-update, skill-template-generation, skill-validation | skill-factory, scaffold-skill, create-skill, generate-skill | `skills-dev/skill-factory` | [SKILL.md](../skills-dev/skill-factory/SKILL.md) |

## Skill Families

| Family | Description |
|---|---|
| `api-variant-prediction` | Cloud API-based variant effect prediction (AlphaGenome). Requires `ALPHAGENOME_API_KEY`. |
| `sequence-to-signal` | Sequence-to-track prediction with multi-species Borzoi models. Strong for interval-based variant scoring and tissue-resolved track outputs. |
| `transformer-embedding-and-finetuning` | DNABERT-2 transformer for embeddings, GUE evaluation, and supervised fine-tuning from CSV. |
| `genome-language-model-inference` | Evo 2 large genome language model. Supports local GPU and hosted NVCF API paths. |
| `phylogenetic-language-models` | GPN family (GPN, PhyloGPN, GPN-Star) using multiple sequence alignments for variant scoring. |
| `transformers-ntv3` | NTv3 species-conditioned transformer. Supports embedding, track prediction, and notebook-first fine-tuning workflows for bigwig/annotation objectives. |
| `segmentation-heads` | SegmentNT family (SegmentNT, SegmentEnformer, SegmentBorzoi) for genomic element segmentation with rescaling constraints. |
| `legacy-cnn-regulatory` | Classic Basset CNN (Torch7) for regulatory prediction and SAD analysis. Dev only. |
| `profile-prediction-and-attribution` | BPNet profile prediction with SHAP-based attribution and motif integration. Dev only. |
| `jax-haiku-transformers` | Classic NT v1/v2 JAX/Haiku inference with 6-mer tokenization. Dev only. |
| `skilling-and-scaffolding` | Tooling for scaffolding new skill packages from specs. Dev only. |

## Fine-Tuning Routing Notes

- Default fine-tuning route for generic CSV classification/regression requests remains `dnabert2`.
- Route to `nucleotide-transformer-v3` when the request explicitly targets NTv3 and/or species-conditioned `bigwig` / `annotation` workflows (including `case-study/ntv3` prep phrasing).

## Including Disabled Skills

All operational scripts (`link_skills.sh`, `route_query.sh`, `run_agent.sh`, `validate_*.sh`, `smoke_test.sh`) exclude disabled skills by default. To opt in:

```bash
bash scripts/link_skills.sh --include-disabled
bash scripts/route_query.sh --query "..." --include-disabled
bash scripts/validate_routing.sh --include-disabled
```

## Skill Discovery

`registry/skills.yaml` is the single source of truth for all operational scripts. The `enabled` field is enforced at runtime — a skill not listed or listed with `enabled: false` will not be routed to, linked, or validated by default.

To check that all enabled skill paths resolve correctly:

```bash
bash scripts/validate_registry.sh
# or
make validate-registry
```

## See Also

- [Routing Reference](./routing.md) — how the router selects among skills
- [Architecture](./architecture.md) — layer overview and migration notes
- `registry/skills.yaml` — authoritative skill index
