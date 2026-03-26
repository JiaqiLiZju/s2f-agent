# s2f Agent Architecture

## Current State

This repository now follows a layered design:

1. `agent/`: orchestrator behavior and routing policy.
2. `registry/`: machine-readable skill index and tag mapping.
3. skill packages (`<skill>/`): grounded operational behavior and references.
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

- Existing root-level skill paths are preserved for compatibility.
- `registry/skills.yaml` is now the source for skill enumeration in operational scripts.
- `skill.yaml` is now present for all packaged skills.
- Routing quality can be checked with `scripts/validate_routing.sh`.
- One-off runtime routing can be executed with `scripts/route_query.sh`.
- `validate_routing.sh` delegates routing to `route_query.sh` to avoid drift between eval logic and runtime logic.
- Full orchestration output can be executed with `scripts/run_agent.sh`.
- Skill metadata consistency can be checked with `scripts/validate_skill_metadata.sh`.
