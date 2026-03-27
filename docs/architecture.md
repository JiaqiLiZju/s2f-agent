# s2f Agent Architecture

## Current State

This repository now follows a layered design:

1. `agent/`: orchestrator behavior and routing policy.
2. `registry/`: machine-readable skill index and tag mapping.
   - includes `routing.yaml` (scoring, confidence, alias rules)
   - includes `task_contracts.yaml` (task-level required input contracts)
   - includes `output_contracts.yaml` (task-level output-plan contract schema)
   - includes `recovery_policies.yaml` (retry and fallback defaults)
3. skill packages (`skills/<skill>/` for stable, `skills-dev/<skill>/` for dev): grounded operational behavior and references.
4. `playbooks/`: cross-skill task patterns.
5. `evals/`: routing and quality checks.
6. `scripts/`: installation, linking, provisioning, validation.

## Why This Layout

The skill packages remain model-centric, while orchestration concerns are centralized.

Benefits:

- clearer ownership boundaries
- safer route selection
- easier evaluation and regression tracking
- simpler future migration to `skills/` namespace if needed

## Migration Notes

- A wave-1 set of tested skills has been migrated to the `skills/` namespace:
  - `alphagenome-api`
  - `borzoi-workflows`
  - `nucleotide-transformer-v3`
  - `gpn-models`
  - `evo2-inference`
  - `dnabert2`
  - `segment-nt`
- Root-level paths for the migrated wave-1 skills have been removed.
- `registry/skills.yaml` is now the source for skill enumeration in operational scripts.
- `enabled` in `registry/skills.yaml` is enforced by default across link/route/run/validate/smoke.
- disabled skills can still be included explicitly via `--include-disabled`.
- `skill.yaml` is now present for all packaged skills.
- Routing quality can be checked with `scripts/validate_routing.sh`.
- One-off runtime routing can be executed with `scripts/route_query.sh`.
- `validate_routing.sh` delegates routing to `route_query.sh` to avoid drift between eval logic and runtime logic.
- Runtime router returns a structured `decision` (`route` or `clarify`) plus confidence.
- Full orchestration output can be executed with `scripts/run_agent.sh`.
- `run_agent.sh` prefers task-level required inputs from `registry/task_contracts.yaml` and falls back to skill-level contracts.
- `run_agent.sh` now emits a normalized `plan` object for core tasks.
- `scripts/execute_plan.sh` executes or dry-runs `plan.runnable_steps` and validates expected outputs.
- Skill metadata consistency can be checked with `scripts/validate_skill_metadata.sh`.
