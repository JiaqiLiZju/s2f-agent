---
name: evo2-inference
description: Install, configure, and use Evo 2 for DNA sequence scoring, embeddings, and generation across local GPU inference, Docker, and Nvidia hosted API or NIM deployments. Use when Codex needs to write, fix, explain, or review Evo 2 Python code, shell commands, notebooks, or deployment steps involving checkpoint selection, hardware compatibility, `Evo2(...)`, tokenization, forward passes, embeddings extraction, generation, or Evo 2 installation and troubleshooting.
---

# Evo 2 Inference

## Overview

Use this skill to produce conservative Evo 2 setup instructions and runnable Python snippets. Prefer the simplest supported path first, and keep hardware assumptions explicit.

## Follow This Decision Flow

1. Choose the execution path.
- Use local inference when the user has supported Linux or WSL2, CUDA, and NVIDIA GPUs.
- Use Nvidia hosted API when the user wants generation without local installation.
- Use Nvidia NIM when the user wants a self-hosted service endpoint.

2. Choose the checkpoint that matches the hardware.
- Prefer `evo2_7b` for the lightest widely usable local path.
- Treat `evo2_20b`, `evo2_40b`, and `evo2_1b_base` as FP8-dependent models that require Transformer Engine and Hopper GPUs.
- Treat `evo2_40b` as a multi-GPU workload that needs multiple H100 GPUs.

3. Choose the task mode.
- Use a forward pass when the user wants logits or sequence likelihood style scoring.
- Use embeddings when the user wants downstream representations or classifiers.
- Use generation when the user wants sequence completion or design from prompts.

4. Validate the environment before going deep.
- Confirm Python 3.11 or 3.12.
- Confirm CUDA 12.1+, cuDNN 9.3+, and a compatible Torch build for local inference.
- Run the packaged generation test after installation or configuration changes.

5. Present the smallest working example.
- Return a short runnable snippet first.
- Add Docker, NIM, or hosted API examples only when the user is on that path.
- Route training and finetuning requests to Savanna or BioNemo instead of inventing unsupported local instructions.

## Grounded API Surface

Treat the following names and patterns as grounded by the bundled README:

- `from evo2 import Evo2`
- `Evo2("evo2_7b")`
- `evo2_model.tokenizer.tokenize(sequence)`
- `evo2_model(input_ids)`
- `evo2_model(input_ids, return_embeddings=True, layer_names=[...])`
- `evo2_model.generate(...)`
- `python -m evo2.test.test_evo2_generation --model_name evo2_7b`

Verify any additional helper, tokenizer behavior, or advanced inference option against the installed package or official docs before relying on it.

## Response Style

- Prefer a hardware-aware recommendation before giving install commands.
- State clearly when a request is incompatible with the user's platform.
- Call out when a model choice implies FP8, Transformer Engine, Hopper GPUs, or multiple GPUs.
- Keep training and finetuning guidance high level unless a grounded source is available.

## References

- Read [references/setup-matrix.md](references/setup-matrix.md) for system requirements and checkpoint compatibility.
- Read [references/usage-patterns.md](references/usage-patterns.md) for local forward, embeddings, generation, and hosted API code patterns.
- Read [references/deployment-caveats.md](references/deployment-caveats.md) for Docker, NIM, long-sequence caveats, and troubleshooting.
