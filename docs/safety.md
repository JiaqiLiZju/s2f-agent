# Agent Safety Rules

This page explains the `s2f` agent's safety policy for developers and users. The policy is enforced by `agent/SAFETY.md` (the agent's operational instructions) and grounded in skill-level caveats under `skills/*/references/caveats.md`.

## Safety Priorities

In order of precedence:

1. **Protect credentials and private data**
2. **Prevent destructive or irreversible operations**
3. **Surface scientific and computational constraints early**
4. **Avoid overstating support or confidence**

## Credential Handling

- API keys and tokens are **never** printed in agent output, logs, or examples.
- All credentials must be passed via environment variables (e.g. `ALPHAGENOME_API_KEY`, `HF_TOKEN`, `NVCF_RUN_KEY`).
- Examples in skill references use placeholder patterns rather than inline values.
- If a command would expose a secret in shell history, the agent warns and offers a safer pattern.

Recommended env loading pattern:

```bash
set -a; source .env; set +a
# credentials are now in the environment, not the command line
```

## Execution Risk Controls

The agent requires explicit user confirmation before:

| Category | Examples |
|---|---|
| Deleting or overwriting user data | `rm -rf output/`, overwriting an existing checkpoint |
| High-cost long-running jobs | Full Evo 2 GPU inference without a cost estimate |
| Mutating global environments | `conda install` into base env, global `pip install` |
| Commands with unclear side effects | Scripts that modify files outside the working directory |

Dry-run mode is the default for `execute_plan.sh`. Pass `--run` only after reviewing the dry-run output:

```bash
# Review first
bash scripts/execute_plan.sh --task variant-effect --query '...' --dry-run
# Then execute
bash scripts/execute_plan.sh --task variant-effect --query '...' --run
```

## Scientific Guardrails

| Rule | Why it matters |
|---|---|
| Always state coordinate convention (0-based vs 1-based) | Off-by-one errors are silent and produce wrong results |
| Never silently infer species or assembly for interval workflows | Wrong assembly maps coordinates to wrong loci |
| Always state sequence length constraints before execution-heavy steps | Models have hard tokenization limits; silent truncation corrupts outputs |
| Do not invent biological interpretation from unsupported model outputs | Model outputs are track predictions, not validated biological claims |

If the agent cannot determine the assembly or coordinate convention from the query, it asks a focused clarification question rather than assuming.

## Groundedness Policy

The agent only uses APIs, CLI flags, and function names grounded in each skill's `references/` files.

| Behavior | Compliant | Non-compliant |
|---|---|---|
| CLI invocation | Use flags verified in `references/scripts.md` | Invent a flag not in any reference |
| Python symbols | Use symbols from skill references | Hallucinate a class or function name |
| Model checkpoints | Use checkpoint IDs listed in `SKILL.md` | Invent a checkpoint name |

When unsure about a symbol or flag, the agent either verifies it in the skill references or avoids using it and explains why.

## Fallback Behavior

When a constraint blocks the requested path:

1. **Explain the exact blocker** — state which constraint is violated and why
2. **Propose a safe alternative** — a concrete path that works within constraints
3. **Keep the response actionable** — include a minimal change the user can make

## For Developers: Adding a Guardrail

- **Agent-level rules** (apply to all skills): add to `agent/SAFETY.md`
- **Skill-level caveats** (apply to one skill): add to `skills/<id>/references/caveats.md`

Skill-level caveats are surfaced in agent responses when that skill is the primary route. Agent-level rules apply regardless of which skill is selected.

## See Also

- `agent/SAFETY.md` — machine-readable safety rules (authoritative source)
- `agent/SYSTEM.md` — out-of-scope list and output quality bar
- [Contracts Reference](./contracts.md) — how missing inputs trigger clarify rather than silent assumptions
