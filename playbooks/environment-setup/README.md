# Environment-Setup Playbook

## Purpose

Provide a contract-aligned orchestration pattern for stack setup and runtime validation.

## Use This When

- The user needs installation or bootstrap guidance.
- The user is choosing runtime paths under hardware constraints.
- The user wants reproducible environment checks before model execution.

## Required Inputs (Canonical Keys)

Required task-contract keys:

- `target-stack-or-model-family`
- `runtime-context`
- `hardware-context`

Optional context that improves setup quality:

- preferred Python executable
- deploy root path
- optional stacks to include

## Skill Selection Heuristics

1. Prefer repository setup scripts first for baseline provisioning.
2. Route to the model-family skill when stack-specific caveats are required.
3. For no-NVIDIA scenarios and Evo2 requests, prefer hosted guidance from `evo2-inference`.

## Runbook (Minimal Reproducible Commands)

Text output:

```bash
bash scripts/run_agent.sh \
  --task environment-setup \
  --query 'Need environment setup for evo2-inference on macOS without NVIDIA GPU' \
  --format text
```

JSON output:

```bash
bash scripts/run_agent.sh \
  --task environment-setup \
  --query 'Need environment setup for evo2-inference on macOS without NVIDIA GPU' \
  --format json
```

Optional bootstrap baseline:

```bash
./scripts/bootstrap.sh
./scripts/link_skills.sh
```

## Learn (Step-by-step + checkpoints + common failures)

Step 1: validate repository wiring.

```bash
make validate-agent
```

Expected checkpoint:

- validation commands finish with exit code `0`
- routing eval summary reports all cases passed

Step 2: request an environment setup plan.

```bash
bash scripts/run_agent.sh \
  --task environment-setup \
  --query 'Need environment setup for evo2-inference on macOS without NVIDIA GPU' \
  --format text
```

Expected checkpoint:

- `decision: route` or focused `clarify`
- `required_inputs` includes stack/runtime/hardware context

Step 3: verify clarify-to-route recovery.

```bash
bash scripts/run_agent.sh --query 'Hello, can you help?' --format text
bash scripts/run_agent.sh \
  --task environment-setup \
  --query 'Need environment setup for ntv3-hf on Linux with one 24GB GPU' \
  --format text
```

Expected checkpoint:

- first call returns `decision: clarify`
- second call returns `decision: route` with reduced or empty `missing_inputs`

Step 4: env precheck behavior for run mode.

```bash
# expected to fail early if ALPHAGENOME_API_KEY is not available
env -u ALPHAGENOME_API_KEY bash scripts/execute_plan.sh \
  --run \
  --task variant-effect \
  --query 'Use $alphagenome-api predict_variant on hg38 chrom=chr12 position=1_000_000 alt=G' \
  --format text
```

Expected checkpoint:

- includes `env_precheck:` block
- reports missing required env var names (never values)
- exits before running the first real step

Common failure signatures and quick fixes:

- `error: query is required` -> add `--query "..."` or provide stdin.
- `decision: clarify` repeats -> include explicit task, runtime context, and hardware context.
- `error: env precheck failed for skill ...` on `execute_plan.sh --run` -> set required env vars in process env or repo `.env`.

## Clarify & Retry

1. Inspect `missing_inputs` for stack, runtime, and hardware context.
2. Clarify missing setup constraints in one focused question.
3. Re-run to obtain a complete setup plan.
4. Use smoke/validation commands before task-level execution.

## Related Playbooks

- [Getting Started](../getting-started/README.md)
- [Troubleshooting](../troubleshooting/README.md)
