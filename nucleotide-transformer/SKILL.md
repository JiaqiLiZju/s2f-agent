---
name: nucleotide-transformer
description: Use the classic InstaDeep Nucleotide Transformer v1 and v2 models for JAX-based DNA sequence inference, embeddings extraction, model selection, and tokenization-aware troubleshooting. Use when Codex needs to write, fix, explain, or review code or notebooks involving `get_pretrained_model`, NT v1/v2 model names, 6-mer tokenization, JAX/Haiku inference, embeddings layer selection, or Nucleotide Transformer sequence-length limits.
---

# Nucleotide Transformer

## Overview

Use this skill for the original Nucleotide Transformer family only. Keep responses grounded in the local docs and prefer the JAX + Haiku inference path they actually document.

## Follow This Decision Flow

1. Choose the NT generation.
- Use NT v1 when the user explicitly wants `500M_human_ref`, `500M_1000G`, `2B5_1000G`, or `2B5_multi_species`.
- Use NT v2 when the user wants the more efficient rotary / SwiGLU models with longer 12 kbp context.

2. Check sequence length and tokenization assumptions.
- NT uses 6-mer tokenization with special handling for `N`.
- If the sequence contains `N`, or the length is not divisible by 6, tokenization falls back to single nucleotides around those regions.
- Use the limits in [references/tokenization-and-limits.md](references/tokenization-and-limits.md) before promising that a sequence will fit.

3. Use the grounded JAX inference path.
- Import `get_pretrained_model` from `nucleotide_transformer.pretrained`.
- Tokenize with `tokenizer.batch_tokenize(...)`.
- Transform the forward function with `hk.transform(...)`.
- Call `forward_fn.apply(parameters, random_key, tokens)`.

4. Handle embeddings carefully.
- `embeddings_layers_to_save` is 1-indexed.
- If the user asks for final embeddings from a Roberta LM head model, note the special behavior described in the docs.

5. Present the smallest working example.
- Return runnable JAX code first.
- Mention GPU/TPU support only as a capability note, not as a hidden dependency.

## Grounded API Surface

Treat the following names and patterns as grounded by the bundled docs:

- `from nucleotide_transformer.pretrained import get_pretrained_model`
- `get_pretrained_model(...)`
- `tokenizer.batch_tokenize(...)`
- `hk.transform(forward_fn)`
- `forward_fn.apply(parameters, random_key, tokens)`
- `embeddings_layers_to_save=(...)`

Supported model names grounded by the docs:

- `500M_human_ref`
- `500M_1000G`
- `2B5_1000G`
- `2B5_multi_species`
- `50M_multi_species_v2`
- `100M_multi_species_v2`
- `250M_multi_species_v2`
- `500M_multi_species_v2`

Do not invent PyTorch, Hugging Face Transformers, or alternate inference entry points unless the user provides a separate grounded source.

## Response Style

- Prefer concrete JAX examples over broad architectural summaries.
- Surface tokenization behavior whenever the user mentions `N`, odd sequence lengths, or exact context limits.
- State clearly whether a recommendation targets v1 or v2.

## References

- Read [references/model-variants.md](references/model-variants.md) for NT v1/v2 model selection.
- Read [references/usage-patterns.md](references/usage-patterns.md) for the grounded JAX inference pattern.
- Read [references/tokenization-and-limits.md](references/tokenization-and-limits.md) for 6-mer behavior and sequence limits.
