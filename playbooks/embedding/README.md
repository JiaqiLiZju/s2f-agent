# Embedding Playbook

## Purpose

Provide a contract-aligned orchestration pattern for embedding requests.

## Use This When

- The user asks for sequence or interval embeddings.
- The user needs token-level or pooled representation guidance.
- The user wants model-path selection before coding.

## Required Inputs (Canonical Keys)

Required task-contract keys:

- `sequence-or-interval`
- `embedding-target`

Optional context that improves execution quality:

- species and assembly for interval workflows
- model preference
- sequence length constraints

## Skill Selection Heuristics

1. Prefer `dnabert2` when the user explicitly mentions DNABERT-2.
2. Prefer `nucleotide-transformer-v3` for NTv3 species-conditioned embedding paths.
3. Prefer `nucleotide-transformer` only when classic NT v1/v2 JAX behavior is required.
4. Prefer `evo2-inference` when hosted fallback is important.

## Output Expectations (Mapped to Output Contract)

For `embedding` in `registry/output_contracts.yaml`, a high-quality response should map to:

- `assumptions`: tokenization/length compatibility and explicit embedding granularity
- `runnable_steps`: embedding-oriented orchestration command chain
- `expected_outputs`: embedding metadata and shape expectations
- `fallbacks`: compatible secondary embedding skill path
- `retry_policy`: clarify missing embedding target, then retry once

## Minimal Reproducible Commands

Text output:

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task embedding \
  --query 'Use $dnabert2 for pooled embedding on a genomic interval' \
  --format json
```

## Clarify Flow (When Inputs Are Missing)

1. Inspect `missing_inputs` for `sequence-or-interval` and `embedding-target`.
2. Clarify one missing input at a time with concrete examples.
3. Re-run the same task query with clarified values.
4. Confirm plan fields before downstream execution.

## Matching Tutorial

- [Embedding Tutorial](../../tutorials/03-embedding.md)
- [Troubleshooting and Clarify Tutorial](../../tutorials/06-troubleshooting-and-clarify.md)
