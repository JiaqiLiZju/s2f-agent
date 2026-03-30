# Contributing

## Adding a Skill

1. Create a skill directory under `skills/<skill-id>/` (stable) or `skills-dev/<skill-id>/` (in-progress).
2. Include the required files:
   - `SKILL.md` — concise operational guidance
   - `skill.yaml` — skill metadata (id, path, status, tasks, triggers, env contracts)
   - `agents/openai.yaml` — agent tool contract
   - `references/` — detailed background docs (keep `SKILL.md` focused)
3. Add scripts only for repeated logic worth encoding; keep them in `scripts/`.
4. Register the skill in `registry/skills.yaml` with `enabled: true` (or `false` for dev).
5. Add routing triggers to `registry/tags.yaml` for each task the skill supports.
6. Keep `skill.yaml` and `agents/openai.yaml` aligned in scope.

## Running Validation Before a PR

Run the full validation bundle:

```bash
make validate-agent
```

This covers:
- Registry and metadata consistency
- Input contract completeness
- Migration path integrity
- Routing eval (15 cases)
- Groundedness eval (4 cases)
- Task-success eval (6 cases)

Run a targeted smoke test:

```bash
./scripts/smoke_test.sh --skills-dir "${CODEX_HOME:-$HOME/.codex}/skills"
```

## PR Checklist

- [ ] `make validate-agent` passes with no errors
- [ ] `make eval-routing` passes (routing Top-1 accuracy maintained)
- [ ] `make smoke-lite` passes
- [ ] `SKILL.md` is concise and operational (detailed guidance in `references/`)
- [ ] `registry/skills.yaml` updated if a skill was added, moved, or disabled
- [ ] No hardcoded paths outside of `registry/`-driven resolution
- [ ] No secrets or credentials committed (`.env` is gitignored)

## Coding Conventions

- Shell scripts: POSIX-compatible bash, no external dependencies beyond `awk`, `grep`, `sed`, `git`
- YAML: 2-space indent, no trailing whitespace
- Skill IDs: lowercase, hyphen-separated (e.g. `nucleotide-transformer-v3`)
- Output directories: `output/{skill-id}/` — do not write to repo root or skill directories
- Result JSON: include top-level `skill_id`, `task`, `outputs` envelope fields
