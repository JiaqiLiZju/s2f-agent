# Fine-Tune Workflows

Use this file when the user asks for NTv3 fine-tuning or notebook-to-script conversion.

Primary evidence source for this reference:

- `Readme/NTv3/02_fine_tuning_pretrained_model_biwig.ipynb`
- `Readme/NTv3/03_fine_tuning_posttrained_model_biwig.ipynb`
- `Readme/NTv3/04_fine_tuning_pretrained_model_annotation.ipynb`

## Scope and Execution Mode

- NTv3 fine-tuning in this repository is notebook-first.
- Keep the boundary explicit: provide reproducible workflow guidance and command templates, but do not claim a packaged one-command training CLI exists in this repo.

## Shared Preflight Checklist

1. Gated model access is available (`HF_TOKEN` or `huggingface-cli login`).
2. Runtime dependencies are installed:
   - `transformers`, `torch`, `pyfaidx`, `pyBigWig`, `torchmetrics`
3. Sequence length is valid for the selected checkpoint:
   - divisor = `2 ** num_downsamples`
4. Target cropping behavior is explicit:
   - `keep_target_center_fraction` affects bigwig/annotation heads.
5. Hardware plan is explicit:
   - device, dtype, batch size, accumulation steps.

## Workflow A: Pretrained -> BigWig Tracks

Notebook source: `02_fine_tuning_pretrained_model_biwig.ipynb`

Typical config keys:

- `model_name`
- `hf_repo_id`
- `species`
- `sequence_length`
- `keep_target_center_fraction`
- `bigwig_file_ids`
- `batch_size`
- `num_steps_training`
- `learning_rate`
- `weight_decay`

Typical training pattern:

- build genomic window dataset
- tokenize DNA inputs with `AutoTokenizer(..., trust_remote_code=True)`
- center-crop targets for track heads
- optimize with Poisson-style track loss
- report correlation metrics on validation/test sets

Typical outputs to report:

- training/validation metric logs
- evaluation summary on held-out windows
- best checkpoint path (or explicit not-executed status)

## Workflow B: Posttrained -> BigWig Tracks

Notebook source: `03_fine_tuning_posttrained_model_biwig.ipynb`

Typical config keys:

- `model_name`
- `species_name`
- `sequence_length`
- `keep_target_center_fraction`
- `mini_batch_size`
- `num_accumulation_gradient`
- `num_steps_training`
- `initial_learning_rate`
- `end_learning_rate`
- `num_steps_warmup`

Typical training pattern:

- post-trained model path with species-conditioned head behavior
- gradient accumulation for memory control
- warmup + decay learning-rate schedule
- track-wise correlation metrics for validation/test

Typical outputs to report:

- optimizer/scheduler config snapshot
- train/val loss curves
- checkpoint selection criterion and saved checkpoint path

## Workflow C: Pretrained -> Annotation Heads

Notebook source: `04_fine_tuning_pretrained_model_annotation.ipynb`

Typical config keys:

- `model_name`
- `species_name`
- `sequence_length`
- `keep_target_center_fraction`
- `batch_size`
- `num_steps_training`
- `learning_rate`
- `weight_decay`

Typical training pattern:

- annotation target construction and center-crop alignment
- classification-style objective (for example focal-loss family)
- per-label metrics tracking during train/val/test

Typical outputs to report:

- per-label metric table
- aggregate validation/test metrics
- final checkpoint and inference-ready settings

## Notebook-To-Script Guidance

When users ask to "convert to script" or "give training command":

1. Start from one notebook workflow only (A/B/C) to avoid mixed assumptions.
2. Freeze and print all config keys first.
3. Keep data, model, loss, metrics, optimizer, scheduler, and checkpoint IO as separate blocks.
4. Emit explicit placeholders for user dataset paths and project-specific save directories.
5. Label non-executed placeholders clearly instead of fabricating results.

## Case-Study Prep Artifacts (case-study/ntv3)

When running `bash case-study/ntv3/run_ntv3_finetuning_prep.sh`, interpret outputs as planning artifacts:

- `fine_tuning_plan.json`: routed plan from `run_agent.sh` with `decision`, `primary_skill`, and planned runnable steps.
- `train-command.sh`: notebook-to-script template entrypoint; this is a handoff scaffold, not proof of executed training.
- `eval-metrics.json`: expected to contain `status=not_executed` for prep-only flow plus `selected_skill` and `planned_train_command`.
- `prep_report.json`: links prep artifacts and records context-length planning details.
- `validate_dataset.log` and `length_check.log`: dataset/schema and divisibility checkpoints.

Use these artifacts to decide whether the workflow is ready to move into notebook training.

## Handoff: Prep -> Notebook Training

1. Confirm prep passed: required artifact files exist and `fine_tuning_plan.json` has `decision=route`.
2. Open the matching notebook family (`02_*`, `03_*`, or `04_*`) based on head type and pretrained/posttrained path.
3. Copy resolved assumptions from prep into notebook config cells:
   - model id, species, sequence/context length, divisor, dataset paths.
4. Keep the prep-generated `train-command.sh` as an execution template and provenance note.
5. Start training in notebook/runtime; replace prep placeholder metrics with real train/eval outputs.

## Failure Recovery Paths (Prep Phase)

1. Length invalid (`check_valid_length.py` fails):
   - round context length to nearest valid multiple (`2 ** num_downsamples`) and rerun prep.
2. Dataset schema invalid (`validate_dataset.log` fails):
   - repair headers/columns/types to match intended workflow (`sequence,label` for the current case-study prep) and rerun prep.
3. Token missing or gated model auth failure (`HF_TOKEN` unavailable/unauthorized):
   - export valid `HF_TOKEN` (or run `huggingface-cli login`), then rerun prep from the start.
