# Caveats

Use this file when the request involves unclear model selection, alignment assumptions, or support questions.

## Alignment boundaries

- `GPN` uses unaligned genomes.
- `GPN-MSA` requires aligned genomes for both training and inference.
- `PhyloGPN` uses alignments during training, but does not require them for inference or fine-tuning.
- `GPN-Star` requires aligned genomes for both training and inference.

If the user does not have an alignment available at inference time, do not steer them to `GPN-MSA` or `GPN-Star`.

## Deprecation note

- The README says `GPN-MSA` is deprecated in favor of `GPN-Star`.
- Mention this when users ask for a new alignment-based workflow without naming a specific family.

## Grounding boundary

- The README gives explicit CLI training, embeddings, and VEP commands only for the single-sequence `GPN` path.
- For `GPN-MSA`, `PhyloGPN`, and `GPN-Star`, prefer grounded model-loading snippets and route detailed usage to the linked notebooks or analysis directories.
- Do not invent tokenizer calls, prediction wrappers, or hidden preprocessing steps for those families without verification.

## Training on other species

- For GPN-MSA training on other species, the README points to GitHub issues and discussions instead of a direct command recipe.
- Another source for plant alignments named in the README is PlantRegMap.
- Treat these as pointers, not as fully grounded workflows.

## Support links

- Direct usage questions to GitHub Discussions.
- Direct bugs or feature requests to GitHub Issues.
