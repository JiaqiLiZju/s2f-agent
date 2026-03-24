# Length And Memory

Use this file when the request depends on sequence geometry or memory pressure.

## Divisibility rule

NTv3 uses a U-Net-like architecture with downsampling and upsampling, so sequence length must be divisible by `2^num_downsamples`.

Grounded rules from the docs:

- 7 downsample models: length divisible by `128`
- 5 downsample models: length divisible by `32`

## Padding and cropping

- Crop to the nearest valid length when exact endpoints are not critical.
- If padding is necessary, pad with `N` tokens.
- Do not recommend `[PAD]` tokens, because the models were not trained on them.

## Memory

Both `get_pretrained_ntv3_model()` and `get_posttrained_ntv3_model()` support:

```python
use_bfloat16=True
```

Use this when the user needs lower memory usage and accepts minor numerical differences.
