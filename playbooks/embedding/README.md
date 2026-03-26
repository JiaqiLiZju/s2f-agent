# Embedding Playbook

## Purpose

Provide a consistent workflow for embedding requests across sequence and coordinate inputs.

## Minimum Input Contract

Required:

- sequence input or genomic interval input
- expected embedding target (token-level, pooled, or track-level representation)

Required for interval workflows:

- species
- assembly
- chromosome naming convention

Optional:

- model preference
- length constraints
- downstream task objective

## Candidate Skills

- `dnabert2`: DNABERT-2 sequence and coordinate embedding workflows.
- `nucleotide-transformer`: classic NT v1/v2 JAX embedding and tokenization workflows.
- `nucleotide-transformer-v3`: NTv3 species-conditioned embedding and track workflows.
- `evo2-inference`: Evo 2 forward/embedding workflows with hosted fallback options.

## Routing Heuristics

1. If the user explicitly names DNABERT-2, use `dnabert2`.
2. If the user asks for NT v1/v2 JAX APIs, use `nucleotide-transformer`.
3. If the user asks for NTv3 species-conditioned outputs, use `nucleotide-transformer-v3`.
4. If hardware or local install constraints are dominant, consider `evo2-inference` hosted path.

## Output Contract

A valid answer should include:

1. chosen model path and rationale
2. token and length expectations
3. runnable minimal code
4. constraints and troubleshooting notes
