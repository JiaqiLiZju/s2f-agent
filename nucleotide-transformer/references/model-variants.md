# Model Variants

Use this file when the user needs help choosing among the classic Nucleotide Transformer models.

## NT v1 models

These are the first-generation models:

- `500M_human_ref`
- `500M_1000G`
- `2B5_1000G`
- `2B5_multi_species`

Key properties grounded by the docs:

- encoder-only transformers
- learnable positional encodings
- 6 kbp context
- pretraining on either human reference, 1000 Genomes, or multispecies data

## NT v2 models

These are the optimized second-generation models:

- `50M_multi_species_v2`
- `100M_multi_species_v2`
- `250M_multi_species_v2`
- `500M_multi_species_v2`

Key properties grounded by the docs:

- rotary positional embeddings
- SwiGLU activations
- no biases and no dropout
- up to 2,048 tokens and about 12 kbp context
- multispecies pretraining

## Selection guidance

- Choose v1 when the user explicitly names a v1 checkpoint or wants the exact original paper models.
- Choose v2 when the user wants the improved architecture or longer context.
- Choose `500M_human_ref` only when a human-reference-only model is specifically desired.
- Choose multispecies models when the user wants broader organism coverage.
