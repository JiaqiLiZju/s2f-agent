# Variant-Effect Playbook

## Purpose

Provide a consistent, cross-skill workflow for variant-effect requests.

## Minimum Input Contract

Required:

- `assembly`
- `chrom`
- coordinate definition (`position` or `[start, end)`)
- REF/ALT alleles or a reproducible variant specification

Optional but often important:

- species
- requested output modality (for example RNA-seq tracks)
- tissue or ontology terms
- desired runtime path (local vs hosted)

## Candidate Skills

- `alphagenome-api`: API-based variant prediction with plotting workflow.
- `borzoi-workflows`: Borzoi tutorial-grounded variant scoring and interpretation.
- `gpn-models`: model family selection and grounded variant-related workflows.
- `evo2-inference`: REF-vs-ALT proxy patterns, especially for hosted and long-context workflows.

## Routing Heuristics

1. If the user explicitly asks for AlphaGenome API methods, pick `alphagenome-api`.
2. If the user asks for Borzoi tutorial scripts, pick `borzoi-workflows`.
3. If the user needs framework selection or uncertainty resolution, pick `gpn-models`.
4. If local GPU constraints block heavy local paths, consider `evo2-inference` hosted path.

## Output Contract

A valid answer should include:

1. chosen method and rationale
2. coordinate convention and assumptions
3. runnable minimal example
4. caveats and fallback path
