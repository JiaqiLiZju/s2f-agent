# Model Catalog

Use this file when the user asks which NTv3 checkpoint to use.

## Main production checkpoints

Pre-trained:

- `NTv3_8M_pre`
- `NTv3_100M_pre`
- `NTv3_650M_pre`

Post-trained:

- `NTv3_100M_post`
- `NTv3_650M_post`

## Intermediate and ablation checkpoints

Use these only when the user explicitly asks for experimental or intermediate variants:

- `NTv3_8M_pre_8kb`
- `NTv3_100M_pre_8kb`
- `NTv3_100M_post_131kb`
- `NTv3_650M_pre_8kb`
- `NTv3_650M_post_131kb`
- `NTv3_5downsample_pre_8kb`
- `NTv3_5downsample_pre`
- `NTv3_5downsample_post_131kb`
- `NTv3_5downsample_post`

## Selection guidance

- Choose pre-trained models for embeddings and self-supervised modeling.
- Choose post-trained models for functional tracks and genome annotations.
- Prefer the main production checkpoints unless the user needs a particular context or downsampling regime.
