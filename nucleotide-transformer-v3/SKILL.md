---
name: nucleotide-transformer-v3
description: Use Nucleotide Transformer v3 for long-context multispecies JAX inference, including pre-trained embeddings, post-trained functional-track prediction, genome annotation, species-conditioned runs, and memory-aware configuration. Use when Codex needs to write, fix, explain, or review code or notebooks involving `get_pretrained_ntv3_model`, `get_posttrained_ntv3_model`, NTv3 model names, species tokens, base-resolution outputs, sequence-length divisibility, or NTv3 inference constraints.
---

# Nucleotide Transformer v3

## Overview

Use this skill for NTv3 only. Keep answers grounded in the local NTv3 docs and prefer the documented JAX inference path with explicit sequence-length checks.

## Follow This Decision Flow

1. Choose the NTv3 stage.
- Use pre-trained models for embeddings and masked-language-model style outputs.
- Use post-trained models for species-conditioned functional-track and genome-annotation prediction.

2. Choose a model size or checkpoint family.
- Use the main production checkpoints first.
- Only surface ablation or intermediate checkpoints when the user explicitly needs them.

3. Validate sequence length before writing code.
- Sequence length must be divisible by `2^num_downsamples`.
- For the main 7-downsample models, the divisor is `128`.
- Use [scripts/check_valid_length.py](scripts/check_valid_length.py) when the user gives a concrete sequence length.

4. Handle conditioning and outputs correctly.
- Use `tokenizer.batch_np_tokenize(...)` for tokenization.
- For post-trained models, get `species_tokens` from `posttrained_model.encode_species(...)`.
- Explain that functional-track and annotation outputs are cropped to the middle 37.5%, while MLM logits stay at full length.

5. Address memory explicitly.
- Use `use_bfloat16=True` when memory is tight and the user accepts reduced precision.
- Mention that the docs report only small inference differences between bfloat16 and full precision.

## Grounded API Surface

Treat the following names and patterns as grounded by the bundled docs:

- `from nucleotide_transformer_v3.pretrained import get_pretrained_ntv3_model`
- `from nucleotide_transformer_v3.pretrained import get_posttrained_ntv3_model`
- `get_pretrained_ntv3_model(...)`
- `get_posttrained_ntv3_model(...)`
- `tokenizer.batch_np_tokenize(...)`
- `model(tokens)`
- `posttrained_model.encode_species(...)`
- `posttrained_model(tokens=tokens, species_tokens=species_tokens)`
- `use_bfloat16=True`
- `outs["logits"]`
- `outs["bigwig_tracks_logits"]`
- `outs["bed_tracks_logits"]`

Grounded main model names:

- `NTv3_8M_pre`
- `NTv3_100M_pre`
- `NTv3_650M_pre`
- `NTv3_100M_post`
- `NTv3_650M_post`

Do not invent alternate inference wrappers or training code from this skill alone.

## Response Style

- Prefer concise JAX examples with exact model names.
- Surface divisibility rules before discussing large-context runs.
- State clearly whether a sequence should be cropped or padded with `N`.

## References

- Read [references/model-catalog.md](references/model-catalog.md) for checkpoint selection.
- Read [references/pre-vs-post.md](references/pre-vs-post.md) for code patterns and output differences.
- Read [references/length-and-memory.md](references/length-and-memory.md) for divisibility, padding, and precision guidance.
- Use [scripts/check_valid_length.py](scripts/check_valid_length.py) to validate concrete input lengths.
