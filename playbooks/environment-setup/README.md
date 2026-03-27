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

## Output Expectations (Runtime Defaults)

`environment-setup` currently has no dedicated entry in `registry/output_contracts.yaml`.
The runtime still returns a normalized `plan` object. A high-quality response should include:

- explicit assumptions about OS/runtime and hardware
- runnable setup or validation steps
- expected setup verification outputs
- fallback path when local setup constraints block progress

## Minimal Reproducible Commands

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

## Clarify Flow (When Inputs Are Missing)

1. Inspect `missing_inputs` for stack, runtime, and hardware context.
2. Clarify missing setup constraints in one focused question.
3. Re-run to obtain a complete setup plan.
4. Use smoke/validation commands before task-level execution.

## Matching Tutorial

- [Quickstart Agent Tutorial](../../tutorials/01-quickstart-agent.md)
- [Troubleshooting and Clarify Tutorial](../../tutorials/06-troubleshooting-and-clarify.md)
