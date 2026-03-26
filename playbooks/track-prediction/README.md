# Track-Prediction Playbook

## Purpose

Provide a consistent workflow for sequence-to-track prediction tasks.

## Minimum Input Contract

Required:

- sequence or genomic interval
- species and assembly (for interval workflows)
- target output head or modality

Optional:

- model preference
- output length/center-crop expectation
- plotting or export format

## Candidate Skills

- `nucleotide-transformer-v3`: species-conditioned post-trained track workflows.
- `segment-nt`: SegmentNT/SegmentEnformer/SegmentBorzoi segmentation outputs.
- `borzoi-workflows`: Borzoi tutorial and interpretation workflows.

## Routing Heuristics

1. If user mentions NTv3 species-conditioned outputs, use `nucleotide-transformer-v3`.
2. If user asks for SegmentNT-family segmentation outputs or rescaling, use `segment-nt`.
3. If user asks for Borzoi tutorial scripts or interpretation gradients, use `borzoi-workflows`.

## Output Contract

A valid answer should include:

1. chosen method and rationale
2. length and model-head constraints
3. runnable minimal inference snippet
4. caveats for output interpretation
