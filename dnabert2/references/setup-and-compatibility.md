# Setup And Compatibility

Use this file when users need a grounded DNABERT2 environment setup.

## Recommended baseline setup

```bash
conda create -n dna python=3.8
conda activate dna
python -m pip install -r requirements.txt
```

The upstream `requirements.txt` pins:

- `transformers==4.29.2`
- `torch==1.13.1`
- `peft==0.3.0`
- `accelerate==0.20.3`
- `evaluate==0.4.0`
- `scikit-learn==1.2.2`
- `einops==0.6.1`
- `omegaconf==2.3.0`

## Optional flash-attention/triton path

The README documents an optional Triton-from-source path before installing requirements:

```bash
git clone https://github.com/openai/triton.git
cd triton/python
pip install cmake
pip install -e .
```

Treat this as optional and environment-sensitive.

## Transformers loading compatibility

Use one of the grounded loading patterns:

1. `transformers==4.28`:
- `AutoTokenizer.from_pretrained(..., trust_remote_code=True)`
- `AutoModel.from_pretrained(..., trust_remote_code=True)`

2. `transformers>4.28`:
- Build `BertConfig` first
- Pass `config=config` into `AutoModel.from_pretrained(..., trust_remote_code=True, config=config)`

## Minimal environment smoke check

```bash
python - <<'PY'
import torch
from transformers import AutoTokenizer, AutoModel
model_id = "zhihan1996/DNABERT-2-117M"
_ = AutoTokenizer.from_pretrained(model_id, trust_remote_code=True)
_ = AutoModel.from_pretrained(model_id, trust_remote_code=True)
print("dnabert2_load_ok", torch.__version__)
PY
```
