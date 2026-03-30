# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] — 2026-03-30

Initial public release.

### Added

- **Agent runtime**: `route_query.sh`, `run_agent.sh`, `execute_plan.sh` — full route → plan → execute pipeline
- **Skill catalog**: 11 packaged skills across 5 task families (variant-effect, embedding, track-prediction, fine-tuning, environment-setup)
  - Stable: `alphagenome-api`, `borzoi-workflows`, `dnabert2`, `evo2-inference`, `gpn-models`, `nucleotide-transformer-v3`, `segment-nt`, `skill-factory`
  - Dev: `basset-workflows`, `bpnet`, `nucleotide-transformer`
- **Registry**: machine-readable `skills.yaml`, `routing.yaml`, `tags.yaml`, `task_contracts.yaml`, `output_contracts.yaml`, `recovery_policies.yaml`, `input_schema.yaml`
- **Playbooks**: cross-skill task guidance for `variant-effect`, `embedding`, `track-prediction`, `fine-tuning`, `environment-setup`
- **Eval suites**: routing (15 cases), groundedness (4 cases), task-success (6 cases)
- **Validation chain**: `validate_registry`, `validate_skill_metadata`, `validate_input_contracts`, `validate_routing`, `validate_groundedness`, `validate_task_success`
- **Bootstrap tooling**: `bootstrap.sh`, `provision_stack.sh`, `prefetch_models.sh`, `clean_runtime.sh` — persistent env setup with model prefetch and one-click cleanup
- **CI**: GitHub Actions workflow (`agent-ci.yml`) running validate + eval + smoke on push/PR
- **Input schema standardization**: canonical coordinate conventions (`coordinate-or-interval`, `sequence-or-interval`), assembly aliases, per-skill constraint annotations
- **Output standardization**: unified `output/{skill-id}/` directories, shared result JSON envelope (`skill_id`, `task`, `outputs`)
- **ENV precheck**: `execute_plan.sh` validates `required_env` / `required_env_any` before execution; blocks on `--run`, warns on `--dry-run`
- **Tutorials**: 6 step-by-step tutorials covering quickstart through troubleshooting
- **Docs**: architecture, routing, contracts, evals, input-schema, safety, scripts-reference, skills-reference
