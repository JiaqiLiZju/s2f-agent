---
name: segment-nt
description: Use SegmentNT, SegmentEnformer, and SegmentBorzoi for JAX-based genomic segmentation at nucleotide resolution, including model-family selection, inference setup, feature-probability extraction, and sequence-length troubleshooting. Use when Codex needs to write, fix, explain, or review code or notebooks involving `get_pretrained_segment_nt_model`, `get_pretrained_segment_enformer_model`, `get_pretrained_segment_borzoi_model`, SegmentNT rescaling, segmentation logits, or sequence constraints for nucleotide-resolution annotation.
---

# SegmentNT Family

## Overview

Use this skill for segmentation models built around the NT ecosystem. Prefer the family-specific inference entry point that the local docs actually show.

## Follow This Decision Flow

1. Choose the segmentation family.
- Use `SegmentNT` for NT-backbone segmentation on sequences up to 30 kb, with documented generalization to 50 kb.
- Use `SegmentEnformer` for longer Enformer-based segmentation runs.
- Use `SegmentBorzoi` for Borzoi-based segmentation on very long sequences.

2. Set up the grounded JAX inference pattern.
- Initialize JAX device selection explicitly.
- Load the pretrained model with the matching helper.
- Replicate parameters, state, and keys across devices where required.
- Run inference with `jax.pmap(...)`.

3. Handle family-specific constraints.
- `SegmentNT` does not handle any `N` in the sequence.
- `SegmentNT` requires the number of DNA tokens, excluding the prepended CLS token, to be divisible by 4.
- For `SegmentNT` inference above 30 kb, compute the rescaling factor with [scripts/compute_rescaling_factor.py](scripts/compute_rescaling_factor.py).

4. Read outputs correctly.
- Convert logits to probabilities with `jax.nn.softmax(..., axis=-1)[..., -1]`.
- For `SegmentNT`, use `config.features`.
- For `SegmentEnformer` and `SegmentBorzoi`, use `FEATURES`.

## Grounded API Surface

Treat the following names and patterns as grounded by the bundled docs:

- `from nucleotide_transformer.pretrained import get_pretrained_segment_nt_model`
- `from nucleotide_transformer.enformer.pretrained import get_pretrained_segment_enformer_model`
- `from nucleotide_transformer.borzoi.pretrained import get_pretrained_segment_borzoi_model`
- `tokenizer.batch_tokenize(...)`
- `hk.transform(...)`
- `hk.transform_with_state(...)`
- `jax.pmap(...)`
- `jax.nn.softmax(...)`
- `config.features`
- `FEATURES.index(...)`

Grounded SegmentNT model names:

- `segment_nt`
- `segment_nt_multi_species`

Do not invent alternate segmentation wrappers or hidden post-processing functions unless the user provides another grounded source.

## Response Style

- Choose the family before writing code.
- Call out `N` handling and length assumptions early for SegmentNT.
- Keep probability extraction examples explicit and runnable.

## References

- Read [references/family-selection.md](references/family-selection.md) for model-family choice.
- Read [references/inference-patterns.md](references/inference-patterns.md) for grounded code snippets.
- Read [references/constraints.md](references/constraints.md) for `N` handling, rescaling, and token divisibility.
- Use [scripts/compute_rescaling_factor.py](scripts/compute_rescaling_factor.py) when SegmentNT runs exceed the training length.
