# Length And Memory

Use this file when the request depends on sequence geometry or memory pressure.

## Divisibility rule

NTv3 uses a U-Net-like architecture with downsampling and upsampling, so sequence length must be divisible by `2^num_downsamples`.

Grounded rules:

- 7 downsample models: length divisible by `128`
- 5 downsample models: length divisible by `32`

## Tokenization and sequence handling

- In the HF tutorial path, use `pad_to_multiple_of=128` for batched tokenization.
- Crop to nearest valid length when exact endpoints are not critical.
- If padding is necessary, pad with `N` tokens.
- Do not recommend `[PAD]` tokens for biological sequence padding.

## Memory and dtype

- GPU inference can use reduced precision to cut memory usage.
- Typical setup from the tutorial:
  - `torch.bfloat16` on Ampere+ GPUs (`compute capability >= 8`)
  - `torch.float16` on older CUDA GPUs
  - `torch.float32` on CPU
- Legacy JAX helper path supports `use_bfloat16=True` when available.
