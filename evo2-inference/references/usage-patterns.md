# Usage Patterns

Use this file for the smallest grounded Evo 2 examples.

## Verify installation

After installation or hardware configuration changes, run:

```bash
python -m evo2.test.test_evo2_generation --model_name evo2_7b
```

Swap in another grounded checkpoint name if needed.

## Forward pass

Use this when the user wants logits over a DNA sequence:

```python
import torch
from evo2 import Evo2

evo2_model = Evo2("evo2_7b")

sequence = "ACGT"
input_ids = torch.tensor(
    evo2_model.tokenizer.tokenize(sequence),
    dtype=torch.int,
).unsqueeze(0).to("cuda:0")

outputs, _ = evo2_model(input_ids)
logits = outputs[0]

print("Logits:", logits)
print("Shape:", logits.shape)
```

## Embeddings

Use intermediate embeddings for downstream tasks:

```python
import torch
from evo2 import Evo2

evo2_model = Evo2("evo2_7b")

sequence = "ACGT"
input_ids = torch.tensor(
    evo2_model.tokenizer.tokenize(sequence),
    dtype=torch.int,
).unsqueeze(0).to("cuda:0")

layer_name = "blocks.28.mlp.l3"

outputs, embeddings = evo2_model(
    input_ids,
    return_embeddings=True,
    layer_names=[layer_name],
)

print("Embeddings shape:", embeddings[layer_name].shape)
```

Do not invent alternate layer names. If the user needs a different layer, verify it from the installed model or official examples.

## Generation

Use this for prompt-conditioned DNA completion:

```python
from evo2 import Evo2

evo2_model = Evo2("evo2_7b")

output = evo2_model.generate(
    prompt_seqs=["ACGT"],
    n_tokens=400,
    temperature=1.0,
    top_k=4,
)

print(output.sequences[0])
```

## Hosted API pattern

Use this when the user cannot or does not want to install locally:

```python
import os
import requests

key = os.getenv("NVCF_RUN_KEY") or input("Paste the Run Key: ")

r = requests.post(
    url=os.getenv(
        "URL",
        "https://health.api.nvidia.com/v1/biology/arc/evo2-40b/generate",
    ),
    headers={"Authorization": f"Bearer {key}"},
    json={
        "sequence": "ACTGACTGACTGACTG",
        "num_tokens": 8,
        "top_k": 1,
        "enable_sampled_probs": True,
    },
)

print(r.status_code)
print(r.text[:200])
```

Add file handling only when the user needs to persist JSON or ZIP responses.
