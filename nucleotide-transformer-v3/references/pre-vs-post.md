# Pre Vs Post

Use this file for the grounded NTv3 code patterns.

## Pre-trained inference

```python
import jax.numpy as jnp
from nucleotide_transformer_v3.pretrained import get_pretrained_ntv3_model

model, tokenizer, config = get_pretrained_ntv3_model(
    model_name="NTv3_100M_pre",
    embeddings_layers_to_save=(10,),
)

sequences = ["ATTCCGATTCCGATTCCG", "ATTTCTCTCTCTCTCTGAGATCGATCGATCGAT"]
tokens = tokenizer.batch_np_tokenize(sequences)

outs = model(tokens)
print(outs["embeddings_10"].shape)
```

## Post-trained inference

```python
import jax.numpy as jnp
from nucleotide_transformer_v3.pretrained import get_posttrained_ntv3_model

posttrained_model, tokenizer, config = get_posttrained_ntv3_model(
    model_name="NTv3_100M_post",
)

seq_length = 2**15
sequences = ["A" * seq_length, "T" * seq_length]
tokens = tokenizer.batch_np_tokenize(sequences)

species = "human"
species_tokens = posttrained_model.encode_species(species)

outs = posttrained_model(
    tokens=tokens,
    species_tokens=species_tokens,
)

logits = outs["logits"]
bigwig_logits = outs["bigwig_tracks_logits"]
bed_logits = outs["bed_tracks_logits"]
```

## Output differences

- `outs["logits"]` keeps full sequence length.
- `bigwig_tracks_logits` and `bed_tracks_logits` are cropped to the middle 37.5%.
- For a sequence length of `32768`, the docs give a cropped length of `12288`.
