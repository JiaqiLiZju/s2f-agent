# Environment-Setup Playbook

## Purpose

Provide a consistent setup workflow for model-stack installation and validation.

## Minimum Input Contract

Required:

- target stack or model family
- operating system/runtime context
- hardware context (GPU/CPU, CUDA availability)

Optional:

- preferred Python executable
- deployment root path
- whether to include optional stacks (NTv3/Borzoi/Evo2)

## Candidate Skills

- `alphagenome-api`
- `gpn-models`
- `nucleotide-transformer`
- `nucleotide-transformer-v3`
- `borzoi-workflows`
- `evo2-inference`

## Routing Heuristics

1. If user requests stack provisioning, prioritize repository scripts first.
2. If user specifies one model family, route to that skill for stack-specific caveats.
3. If user has no NVIDIA GPU and asks for Evo2 generation, route to hosted API guidance.

## Output Contract

A valid answer should include:

1. selected stack path and prerequisites
2. minimal install command sequence
3. post-install validation command
4. common failure modes and fallback path
