# s2f Agent Tutorials

This folder provides a step-by-step learning path for using the `s2f` agent.

## Learning Path

1. [01-quickstart-agent.md](./01-quickstart-agent.md)
2. [02-variant-effect.md](./02-variant-effect.md)
3. [03-embedding.md](./03-embedding.md)
4. [04-track-prediction.md](./04-track-prediction.md)
5. [05-fine-tuning.md](./05-fine-tuning.md)
6. [06-troubleshooting-and-clarify.md](./06-troubleshooting-and-clarify.md)

## Prerequisites

- Repository cloned locally.
- Bash environment with required tools available.
- Skills linked for discovery:

```bash
./scripts/link_skills.sh
```

Environment variable precheck is enforced for `execute_plan.sh --run` when the routed skill defines env contracts in `skill.yaml`.
Current first-rollout contracts:

- `alphagenome-api`: `ALPHAGENOME_API_KEY`
- `nucleotide-transformer-v3`: `HF_TOKEN`
- `evo2-inference`: one-of `NVCF_RUN_KEY` or `EVO2_API_KEY`

## Expected Outcomes

After completing this tutorial set, you should be able to:

- choose the right command (`route_query.sh`, `run_agent.sh`, `execute_plan.sh`)
- read and act on `decision`, `missing_inputs`, and `plan`
- run dry-run plan validation before execution-heavy workflows
- recover from low-confidence routing and missing-input clarify paths

## Command Safety Tip

Use single quotes for queries that contain `$skill` names so your shell does not expand them:

```bash
bash scripts/run_agent.sh --query 'Use $alphagenome-api for variant-effect'
```

## Contract References

- [Variant-Effect Playbook](../playbooks/variant-effect/README.md)
- [Embedding Playbook](../playbooks/embedding/README.md)
- [Track-Prediction Playbook](../playbooks/track-prediction/README.md)
- [Fine-Tuning Playbook](../playbooks/fine-tuning/README.md)
- [Environment-Setup Playbook](../playbooks/environment-setup/README.md)
