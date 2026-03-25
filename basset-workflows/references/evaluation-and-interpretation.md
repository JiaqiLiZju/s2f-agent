# Evaluation and Interpretation

Use this file for grounded post-training Basset workflows.

## Test-set evaluation

Use `basset_test.lua` to report performance metrics and ROC outputs:

```bash
basset_test.lua <model_file> <data_file> test_out
```

Grounded option:

- `-cuda` for GPU execution.

## Sequence activity prediction

Use `basset_predict.lua` to score prepared sequence inputs:

```bash
basset_predict.lua <model_file> <data_file> <out_file>
```

Grounded options include:

- `-cuda`
- `-norm`

## Motif and influence analysis

Use first-layer interpretation scripts from `docs/visualization.md`:

```bash
basset_motifs.py -s 1000 -t -o motifs_out <model_file> <test_hdf5_file>
basset_motifs_infl.py ...
```

Common options to surface when requested:

- `-m` for motif table / MEME DB related inputs
- `-d` for precomputed model output HDF5
- `-s` sample size
- `-o` output directory

## Saturated mutagenesis

HDF5-driven run:

```bash
basset_sat.py -t 46 -n 200 -s 10 -o satmut <model_file> <test_hdf5_file>
```

FASTA-driven run:

```bash
basset_sat.py -t -1 -n 200 -o satmut_hox <model_file> satmut_eg/hoxa_boundary.fa
```

## Variant analysis from VCF

Compute SNP Accessibility Difference (SAD):

```bash
basset_sad.py -l 600 -i -o sad -s -t <targets_file> <model_file> <vcf_file>
```

Inspect local allele mutagenesis around SNP loci:

```bash
basset_sat_vcf.py -t 6 -o sad/sat <model_file> <vcf_file>
```

For VCF workflows, keep assumptions explicit:

- genome FASTA may be required (`-f`)
- sequence length and center options should match model expectations (`-l`, `-n`)
- optional columns (index SNP / score) are interpreted via documented switches (`-i`, `-s`)
