# Inference Quickstart

Use this file for embedding extraction with DNABERT2.

## Minimal embedding example

```python
import torch
from transformers import AutoTokenizer, AutoModel

model_id = "zhihan1996/DNABERT-2-117M"
tokenizer = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
model = AutoModel.from_pretrained(model_id, trust_remote_code=True)

seq = "ACGTAGCATCGGATCTATCTATCGACACTTGGTTATCGATCTACGAGCATCTCGTTAGC"
input_ids = tokenizer(seq, return_tensors="pt")["input_ids"]

with torch.no_grad():
    hidden_states = model(input_ids)[0]  # [1, sequence_length, 768]

embedding_mean = hidden_states[0].mean(dim=0)
embedding_max = hidden_states[0].max(dim=0).values

print("hidden", tuple(hidden_states.shape))
print("mean", tuple(embedding_mean.shape))
print("max", tuple(embedding_max.shape))
```

## Alternative loading for `transformers>4.28`

```python
from transformers import AutoModel
from transformers.models.bert.configuration_bert import BertConfig

model_id = "zhihan1996/DNABERT-2-117M"
config = BertConfig.from_pretrained(model_id)
model = AutoModel.from_pretrained(model_id, trust_remote_code=True, config=config)
```

## Notes

- Keep `trust_remote_code=True` in grounded examples.
- DNABERT2 embeddings are `768`-dimensional in the published `117M` checkpoint.
