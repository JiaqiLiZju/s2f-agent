# Pre Vs Post

Use this file for grounded NTv3 code patterns.

## Preferred tutorial path (Hugging Face Transformers)

### Pre-trained inference (MLM)

```python
from transformers import AutoModelForMaskedLM, AutoTokenizer

HF_TOKEN = "..."
model_name = "InstaDeepAI/NTv3_8M_pre"

tokenizer = AutoTokenizer.from_pretrained(
    model_name,
    trust_remote_code=True,
    token=HF_TOKEN,
)
model = AutoModelForMaskedLM.from_pretrained(
    model_name,
    trust_remote_code=True,
    token=HF_TOKEN,
)

sequences = ["ATTCCGATTCCGATTCCG", "ATTTCTCTCTCTCTCTGAGATCGATCGATCGAT"]
batch = tokenizer(
    sequences,
    add_special_tokens=False,
    padding=True,
    pad_to_multiple_of=128,
    return_tensors="pt",
)

outs = model(**batch)
print(outs["logits"].shape)
```

### Post-trained inference (species-conditioned)

```python
from transformers import AutoModel, AutoTokenizer

HF_TOKEN = "..."
model_name = "InstaDeepAI/NTv3_100M_post"

tokenizer = AutoTokenizer.from_pretrained(
    model_name,
    trust_remote_code=True,
    token=HF_TOKEN,
)
model = AutoModel.from_pretrained(
    model_name,
    trust_remote_code=True,
    token=HF_TOKEN,
)

seq_length = 2**15
sequences = ["A" * seq_length, "T" * seq_length]
batch = tokenizer(
    sequences,
    add_special_tokens=False,
    padding=True,
    pad_to_multiple_of=128,
    return_tensors="pt",
)

species_ids = model.encode_species(["human", "mouse"])
outs = model(input_ids=batch["input_ids"], species_ids=species_ids)

logits = outs["logits"]
bigwig_logits = outs["bigwig_tracks_logits"]
bed_logits = outs["bed_tracks_logits"]
```

## Real track prediction workflow

For reproducible region-level prediction and plotting, use:

- [scripts/run_track_prediction.py](../scripts/run_track_prediction.py)

It wraps sequence fetching, model loading, inference, and plot generation in one CLI command.

## Legacy compatibility path (JAX helper API)

Use this only when the environment already has `nucleotide_transformer_v3` installed from source:

```python
from nucleotide_transformer_v3.pretrained import get_posttrained_ntv3_model

posttrained_model, tokenizer, _ = get_posttrained_ntv3_model(
    model_name="NTv3_100M_post",
)
```

## Output differences

- `outs["logits"]` keeps full sequence length.
- `outs["bigwig_tracks_logits"]` and `outs["bed_tracks_logits"]` are cropped to the middle 37.5%.
- For input length `32768`, the cropped output length is `12288`.
