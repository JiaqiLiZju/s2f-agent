# Deployment Caveats

Use this file when the task is about Docker, NIM, long sequences, or troubleshooting.

## Docker

Use Docker when the user wants an isolated local runtime:

```bash
docker build -t evo2 .
docker run -it --rm --gpus '"device=0"' -v ./huggingface:/root/.cache/huggingface evo2 bash
```

Inside the container, validate with:

```bash
python -m evo2.test.test_evo2_generation --model_name evo2_7b
```

Mention that the volume mount preserves downloaded Hugging Face models between runs.

## NIM and hosted API

- Use Nvidia hosted API for the lowest-friction remote path.
- Use NIM when the user wants a self-hosted service deployment.
- Keep shell and Python examples short unless the user specifically asks for a full client.

## Long sequences

- Evo 2 models can handle long context lengths, but forward passes on very long sequences may still be slow in Vortex.
- For embedding very long sequences, point the user to Savanna or Nvidia BioNemo.
- Mention teacher prompting only as a caveat, not as a detailed procedure, because the README does not provide a full workflow here.

## Common failure checks

Run these checks in order:

1. Confirm the platform is Linux or WSL2 with NVIDIA GPUs.
2. Confirm the selected checkpoint matches the available hardware.
3. Confirm the user installed Transformer Engine when choosing FP8-dependent models.
4. Confirm Flash Attention installed against a compatible PyTorch build.
5. Re-run the packaged generation test after any environment change.

## Training and finetuning boundary

- Route training or finetuning work to Savanna or Nvidia BioNemo.
- Do not fabricate detailed training commands from this README alone.
