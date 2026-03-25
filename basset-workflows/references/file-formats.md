# File Formats

Use this file to validate Basset data assumptions before writing commands.

## BED format

Grounded fields from `docs/file_specs.md`:

- `chrom`
- `start`
- `end`
- `name` (unused)
- `score` (unused)
- `strand`
- `accessibilities` (comma-separated list of integer indexes)

## Activity table format

- Tab-separated file.
- Row index format: `chrom:start:end:strand` matching BED entries.
- Columns: sample names.
- Values: binary `0/1` accessibility/binding/activity labels.

## HDF5 datasets expected by Basset

Basset looks for these dataset names:

- `train_in`
- `train_out`
- `valid_in`
- `valid_out`
- `test_in`
- `test_out`
- `test_headers`

## Model format

- Serialized Torch7 model (`.th`) files.
- `basset_train.lua` writes epoch checkpoints and best-validation model artifacts.

## VCF notes for SNP workflows

`basset_sad.py` and `basset_sat_vcf.py` consume VCF inputs and may rely on:

- genome FASTA (`-f`)
- sequence length matching model setup (`-l`)
- optional SNP metadata columns interpreted by script options (`-i`, `-s`)
