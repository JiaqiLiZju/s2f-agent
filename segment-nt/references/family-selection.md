# Family Selection

Use this file when the user asks for a segmentation model but has not chosen a backbone.

## SegmentNT

Choose `SegmentNT` when the user wants:

- segmentation with the Nucleotide Transformer backbone
- inference on sequences around 30 kb, with possible extension to 50 kb
- `segment_nt` or `segment_nt_multi_species`

## SegmentEnformer

Choose `SegmentEnformer` when the user wants:

- Enformer-based segmentation
- the documented inference shape based on `196_608` bp inputs

## SegmentBorzoi

Choose `SegmentBorzoi` when the user wants:

- Borzoi-based segmentation
- the documented inference shape based on `524_288` bp inputs

## Feature scope

The docs describe segmentation at single-nucleotide resolution across gene and regulatory elements, including:

- protein-coding genes
- lncRNAs
- UTRs
- exons and introns
- splice sites
- polyA signal
- promoters
- enhancers
- CTCF-bound sites
