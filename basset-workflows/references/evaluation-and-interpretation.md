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

## Real interval prediction to plot (hg38/human)

Use this conservative flow when the user asks for a real genomic interval prediction plus visualization:

1. Fetch reference sequence for interval (for example from UCSC API) and save FASTA.
2. Run Basset prediction using a real `.th` model.
3. Plot predicted track values from the output table.

Minimal command chain:

```bash
# 1) interval -> FASTA
python3 - <<'PY'
import requests
chrom = "chr19"
start = 6700000
end = 6702768
assembly = "hg38"
url = f"https://api.genome.ucsc.edu/getData/sequence?genome={assembly};chrom={chrom};start={start};end={end}"
seq = requests.get(url, timeout=60).json()["dna"].upper()
with open("region.fa", "w") as f:
    f.write(f">{chrom}:{start}-{end}({assembly})\n{seq}\n")
PY

# 2) FASTA -> prediction table (requires th + model.th)
basset_predict.py <model_file.th> region.fa region_pred.txt

# 3) prediction table -> PNG plot
python3 - <<'PY'
import matplotlib.pyplot as plt
import numpy as np
y = np.loadtxt("region_pred.txt", delimiter="\t")
if y.ndim > 1:
    y = y[0]
plt.figure(figsize=(12,4))
plt.plot(np.arange(len(y)), y)
plt.xlabel("Target index")
plt.ylabel("Predicted accessibility")
plt.title("Basset prediction for chr19:6700000-6702768 (hg38)")
plt.tight_layout()
plt.savefig("region_pred_plot.png", dpi=180)
PY
```

Practical constraints:

- `basset_predict.py` shells out to `basset_predict.lua`, so `th` must be available.
- Prediction quality depends on model/data compatibility (especially sequence length and training context).
- If a request is specifically for profile-style genomic track plots across base positions, prefer a model/workflow that natively outputs positional tracks (for example Basenji), or clearly state Basset output limitations.

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
