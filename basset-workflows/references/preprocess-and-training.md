# Preprocess and Training

Use this file for grounded Basset data-prep and training command flows.

## Preprocess entry points

### Merge feature BEDs into unified training inputs

Use `preprocess_features.py` with a table of label + BED path rows:

```bash
preprocess_features.py -y -m 200 -s 600 -o features -c /path/to/chrom.sizes sample_beds.txt
```

Grounded variants from tutorials:

- Add new datasets on top of an existing compendium:

```bash
preprocess_features.py -y -m 200 -s 600 \
  -a ../data/encode_roadmap_act.txt \
  -b ../data/encode_roadmap.bed \
  -o db_cd4 \
  -c ../data/genomes/human.hg19.genome \
  cd4_sample.txt
```

- Isolated dataset workflow using negatives:

```bash
basset_sample.py ../data/encode_roadmap.bed ../data/encode_roadmap_act.txt 50000 neg

preprocess_features.py -y -m 200 -s 600 \
  -b neg.bed -n \
  -o learn_cd4 \
  -c ../data/genomes/human.hg19.genome \
  cd4_sample.txt
```

### Build HDF5 train/valid/test tensors

Use `seq_hdf5.py` after FASTA + activity table generation:

```bash
seq_hdf5.py -c -v 3000 -t 3000 learn_cd4.fa learn_cd4_act.txt learn_cd4.h5
```

Other grounded split examples:

```bash
seq_hdf5.py -c -v 75000 -t 75000 db_cd4.fa db_cd4_act.txt db_cd4.h5
seq_hdf5.py -c -t 71886 -v 70000 ../data/er.fa ../data/er_act.txt ../data/er.h5
```

## Train the model

Minimal grounded pattern:

```bash
basset_train.lua -job params.txt -save cd4_cnn learn_cd4.h5
```

Grounded GPU example from tutorial docs:

```bash
basset_train.lua -cuda -job pretrained_params.txt -stagnant_t 10 all_data_ever.h5
```

## Training options to surface when relevant

Grounded options in `docs/learning.md` and `tutorials/train.md`:

- `-cuda`: run on GPU
- `-job`: hyperparameter table file
- `-save`: output prefix for checkpoints/models
- `-stagnant_t`: early-stop window on stagnant validation loss
- `-restart`: resume from checkpoint
- `-seed`: initialize from an existing model

Keep suggestions tied to these documented switches unless the user supplies additional verified code context.
