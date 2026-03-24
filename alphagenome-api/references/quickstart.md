# Quick Start

Use this file for the smallest grounded AlphaGenome workflow.

## Install

Prefer an isolated Python environment, then install from a local clone:

```bash
git clone https://github.com/google-deepmind/alphagenome.git
pip install ./alphagenome
```

If the repository is already present, install from that checkout instead of recloning.

## Create the client

Start from this minimal scaffold:

```python
from alphagenome.data import genome
from alphagenome.models import dna_client

API_KEY = "YOUR_API_KEY"
model = dna_client.create(API_KEY)
```

## Run a minimal variant prediction

Use a variant workflow when the task is "compare REF vs ALT" or "estimate the effect of this mutation."

```python
from alphagenome.data import genome
from alphagenome.models import dna_client

API_KEY = "YOUR_API_KEY"
model = dna_client.create(API_KEY)

interval = genome.Interval(
    chromosome="chr22",
    start=36_200_000,
    end=36_250_000,
)
variant = genome.Variant(
    chromosome="chr22",
    position=36_201_698,
    reference_bases="A",
    alternate_bases="C",
)

outputs = model.predict_variant(
    interval=interval,
    variant=variant,
    ontology_terms=["UBERON:0001157"],
    requested_outputs=[dna_client.OutputType.RNA_SEQ],
)
```

Replace the coordinates, alleles, ontology term, and output list with task-specific values.

## Stay conservative

- Treat `predict_variant(...)` as the only grounded prediction call from the bundled source.
- Confirm any interval-only helper or additional output enum against the installed package or official docs before using it.
- Keep the requested interval at or below 1,000,000 base pairs.
