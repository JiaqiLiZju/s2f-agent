# s2f Agent 开发规划（DEVELOPMENT_PLAN）

最后更新：2026-03-31

## 文档职责

- 本文件（`DEVELOPMENT_PLAN.md`）：负责项目目标、架构设计、阶段路线图、验收标准与待办优先级。
- 进度文件（`DEVELOPMENT_PROGRESS.md`）：只记录已完成工作、验证结果、问题与修复、提交记录。
- 维护约定：从本次起，新增“规划类内容”统一写入本文件；进度文件不再新增独立规划章节。

## 项目 Aim

将 `s2f-skills` 从“skills 集合仓库”演进为“面向 genomics workflow 的可路由、可执行、可评测的 s2f agent”。

主目标：

1. 任务识别与技能路由稳定
2. 输入契约检查与风险提示标准化
3. 任务级 playbook 复用
4. 可验证、可回归、可维护的 agent 工程体系

## 首批自动化任务范围（用户确认）

作为 s2f agent 的 P0 自动化目标，优先覆盖以下任务：

1. `variant-effect`
2. `embedding`
3. `fine-tuning`
4. `track-prediction`
5. `environment-setup`

说明：后续路由、契约、评测和执行闭环的优先级，均以这批任务为主线推进。

## P0 运维能力（用户确认）

除任务自动化外，s2f agent 的基础运维能力需同时满足以下两点：

1. 一次配置、持续可用：
   - 环境安装与缓存目录固定到持久化根目录；
   - 模型参数支持预下载并长期复用；
   - 新会话可通过统一 env 文件恢复同一运行上下文。
2. 一键清理、可回到初始态：
   - 支持一键清理配置环境与临时文件；
   - 支持 dry-run 预览；
   - 支持按范围清理（仅 runtime / 仅 temp / 可选清理已安装 skills）。

## P0 任务输出标准化（用户确认）

对以下 4 类核心任务，建立统一输出结构与最小交付标准：

1. `variant-effect`
2. `embedding`
3. `fine-tuning`
4. `track-prediction`

标准化目标：

1. 输出结构一致：
   - `task`、`selected_skill`、`assumptions`、`required_inputs`、`missing_inputs`、`constraints`
   - `runnable_steps`（可执行命令/代码）
   - `expected_outputs`（文件/指标/形状）
   - `fallbacks`（失败后替代路径）
2. 关键科学约束显式化：
   - 坐标约定、长度限制、species/assembly、模型头/输出含义必须明确。
3. 可验证性：
   - 每类任务都提供最小可复现实例与结果检查点。

各任务最小输出契约：

1. `variant-effect`：
   - 变异表示、坐标约定、REF/ALT 假设、输出 modality 与解释边界。
2. `embedding`：
   - 输入类型（序列/区间）、token/长度规则、embedding 粒度与 shape 说明。
3. `fine-tuning`：
   - 数据 schema、训练命令、关键超参与评估产物路径。
4. `track-prediction`：
   - species/assembly/head 选择、长度合法性检查、推理输出与可视化产物。

## 当前基线（2026-03-27）

- 已具备 `agent/ + registry/ + playbooks/ + evals/ + scripts/` 的基础闭环。
- 已具备 `route_query.sh`（route/clarify + confidence）与 `run_agent.sh`（required inputs/missing inputs）。
- 仓库级校验链路已可运行：
  - `validate_registry`
  - `validate_skill_metadata`
  - `validate_routing`
  - `validate_migration_paths`
  - `smoke_test`

## 基线更新（2026-03-30）

- `skill-factory` 已晋升为 stable skill（`skills/skill-factory/`），在路由注册表中启用，可直接通过 `$skill-factory` 触发。
- `validate_input_contracts.sh` 现覆盖 8 个 stable skill（含 skill-factory）。
- `evals/routing/cases.yaml` route_015 已更新为反映 skill-factory 可路由状态（score 245）。
- `make validate-agent` 全部 5 项检查通过（routing eval 15/15）。

## 目标架构

1. `agent/`：主 agent 身份、路由规则、安全边界与策略模板。
2. `skills/` 与 `skills-dev/`：模型/框架专用能力单元（`SKILL.md + skill.yaml + references + scripts`）。
3. `registry/`：机器可读索引、任务标签、路由配置、输入契约。
4. `playbooks/`：跨技能任务标准流程（variant-effect / embedding / fine-tuning / track-prediction / environment-setup）。
5. `evals/`：routing、groundedness、task-success 评测集合。
6. `scripts/`：安装、运行、路由、验证与冒烟测试入口。

## 规划原则（历史规划收敛）

1. 保持 `skill-first`：不将框架细节塞进单体大 prompt。
2. 增加 orchestration 层：主 agent 负责“路由 + 约束 + 一致性”。
3. 先去耦合后迁移：路径与流程先 registry 化，再做目录结构调整。
4. 先评测后扩展：先保证路由与契约稳定，再扩展任务覆盖。

## 从 DEVELOPMENT_PROGRESS.md 迁移的规划内容

### A. s2f agent 化规划（迁移自 2026-03-26）

- 背景结论：
  - 当前仓库已具备较完整 skill packaging 与部署验证能力。
  - 下一阶段应建设“主 agent + 多技能 + playbook + eval”的编排层。
- 总体目标：
  - 主 agent 负责意图识别、路由、输入补全、约束检查、输出一致性。
- 组织策略：
  - 第一层继续按模型/框架组织 skill；
  - 第二层按任务组织 playbook；
  - 第三层由主 agent 完成路由与风险控制。
- 评测规划：
  - `routing`、`groundedness`、`task-success` 三类评测逐步补齐。
- 推进顺序：
  1. 保护既有 skill 内容；
  2. 引入 `agent/` 骨架；
  3. 补齐 `skill.yaml`；
  4. 新建 `playbooks/`；
  5. 建立 `evals/routing`；
  6. 再评估目录迁移。

### B. 目录搬迁评估与规划同步（迁移自 2026-03-26）

- 评估结论：
  - 当时建议短期不做破坏性硬迁移，先做去耦合。
- readiness：
  - registry/path 驱动链路已具备迁移能力；
  - 文档与少量脚本仍存在路径耦合风险。
- 分阶段策略：
  1. Phase A：前置去耦合（路径统一由 registry 推导）。
  2. Phase B：结构迁移并行兼容（必要时保留兼容层）。
  3. Phase C：兼容层收敛，统一到目标结构。

## 分阶段路线图（当前执行版）

### Phase 1：规划收口与契约一致性（进行中）

目标：把“可跑”收口成“可维护”。

关键交付：

1. 规划与进度文档分责（本次已落地）。
2. 统一任务词汇（`routing` / `tags` / `task_contracts` / 文档）。
3. 为 registry 的 `enabled` 字段补齐运行时过滤语义。
4. 补充“已注册但未跟踪目录”的校验（特别是 `skills-dev`）。
5. 固化“持续可用”运行时（持久化根目录 + 模型预下载 + env 文件恢复）。
6. 提供“一键清理”入口（全清 + 分级清理 + dry-run）。
7. 为 `variant-effect` / `embedding` / `fine-tuning` / `track-prediction` 落地统一输出模板。

验收：

- `make validate-agent` 全通过；
- 新增一致性检查脚本通过；
- 文档无冲突任务命名。

### Phase 2：可执行编排（plan -> execute -> verify）

目标：从“路由器”升级为“闭环 agent”。

关键交付：

1. `run_agent` 增加结构化执行计划输出（步骤、工具、前置条件）。
2. 统一 skill 工具契约（输入/输出/副作用/失败码）。
3. 失败恢复策略（重试、降级、备选 skill 切换）。

验收：

- 关键任务可自动生成并执行最小工作流；
- 执行失败可给出确定性恢复路径。

### Phase 3：观测与评测扩展

目标：可量化地优化 agent 质量。

关键交付：

1. 扩展 `evals/routing` 覆盖歧义与澄清场景。
2. 新增 `groundedness` 与 `task-success` 评测集。
3. 输出核心指标：Top-1 路由准确率、clarify 触发率、任务完成率。

验收：

- 每次变更都可通过回归评测对比；
- 指标有趋势线而非单次样本。

### Phase 4：迁移与发布治理

目标：形成稳定发布能力。

关键交付：

1. 目录迁移最终策略定版（`skills/` 与 `skills-dev/` 边界）。
2. 发布 checklist（文档、校验、评测、回归）。
3. CI 化（至少覆盖 validate + routing eval + smoke）。

## 近期优先级（Next 10 项）

1. 统一任务命名冲突并回归测试。
2. 补齐 `enabled` 字段在 `link/routing/run` 链路的生效逻辑。
3. 新增 registry 跟踪性检查（避免引用未纳入版本管理目录）。
4. 把"持久化安装 + 模型预下载 + env 恢复 + 一键清理"纳入发布验收清单。
5. 定义并接入四类任务的标准化输出 schema（text/json 双格式）。
6. 补一版 `groundedness` 最小评测样例集。
7. 补一版 `task-success` 最小评测样例集。
8. 为 `run_agent` 设计结构化 `plan` 输出 schema。
9. 增加失败恢复策略字段（`fallback_skill`, `retry_policy`）。
10. 统一 `README`、`docs/architecture`、`agent/ROUTING` 任务词汇，并补回归模板与版本说明模板。

## Phase 1 已完成交付项（2026-03-30）

### 基因组数据输入优化（input schema & skill contracts）

**背景：** `run_agent.sh` 的 `input_satisfied()` 因 `sequence-or-interval` 与 `coordinate-or-interval` query_tokens 大量重叠，导致区间查询同时命中两个 key，代理无法区分 track-prediction 与 variant-effect 任务。

**改动范围（仅 YAML/shell 层，不修改任何 Python argparse 逻辑）：**

1. `registry/input_schema.yaml`
   - `sequence-or-interval`：顶层去掉 `chr`，新增 `subtypes` 语义注解（不影响 awk 解析）
   - `coordinate-or-interval`：去掉 `interval`，新增 `pos`/`site`/`locus` 专有 token，新增 `subtypes` 含坐标系标注
   - `legacy_key_map`：删除 `chrom: coordinate-or-interval`（过于宽泛，已由 query_tokens 覆盖）
   - `coordinate_conventions`：新增 `assembly_aliases`（hg19→GRCh37 等）
   - `assembly`：examples 补充 `hg19`，query_tokens 补充 `grch38`/`grch37`
   - 遗留 `sequence` key：添加 `deprecated: true` + `replaced_by: sequence-or-interval`

2. `skills/evo2-inference/skill.yaml`
   - `sequence-or-interval` mapping：去掉 `chr`，加 `fasta`
   - `coordinate-or-interval` mapping：去掉 `chr`/`interval`，加 `pos`/`site`/`locus`；`script_flags` 只保留 `--variant-coordinate`
   - 新增 constraint：`interval-flag-is-0based-half-open-variant-coordinate-flag-is-1based-single-site`

3. 全部 8 个 stable skill.yaml（含 borzoi-workflows）
   - `sequence-or-interval` mapping query_tokens：统一去掉 `chr`，加 `fasta`
   - `coordinate-or-interval` mapping query_tokens：统一加 `pos`/`site`/`locus`，去掉 `interval`
   - 各自新增坐标系语义 constraint

4. `scripts/validate_input_contracts.sh`
   - 新增坐标系 annotation 缺失检测（warn 级别，不 exit 1）

**验证结果：**
- `bash scripts/validate_input_contracts.sh`：`passed for 7 stable skill(s) with 0 warning(s)`
- `bash scripts/smoke_test.sh`：`smoke test passed`（全部 28 项通过）

## 新增规划：Execute Plan ENV 预检（2026-03-29）

目标：提升"纯脚本 + YAML"执行链路的鲁棒性，避免因凭证缺失导致真实执行阶段才失败。

设计决策（已确认）：

1. `skill.yaml` 新增可选字段：
   - `required_env`：全量必需（all-of）
   - `optional_env`：可选提示
   - `required_env_any`：组内满足其一（any-of，使用 `A|B` 编码）
2. 预检触发位置：
   - 在 `execute_plan.sh` 中，`run_agent.sh` 返回 `route` 后、执行 runnable steps 前。
3. 严格度策略：
   - `--run`：预检失败立即阻断（fail fast）
   - `--dry-run`：仅报告状态，不阻断流程
4. 变量可见性来源：
   - 优先 process env
   - 其次 repo 根目录 `.env`（仅在 process env 未提供时补充）
5. 首批 rollout 覆盖：
   - `alphagenome-api`：`ALPHAGENOME_API_KEY`
   - `nucleotide-transformer-v3`：`HF_TOKEN`
   - `evo2-inference`：`NVCF_RUN_KEY|EVO2_API_KEY`

验收标准：

1. 缺失 ENV 时，`--run` 在首个 step 之前阻断并输出缺失变量名。
2. 缺失 ENV 时，`--dry-run` 保持可用并输出 `env_precheck` 状态。
3. JSON 输出包含增量字段 `env_precheck`，保持向后兼容。
4. 不输出任何密钥值（仅输出变量名）。
5. `make validate-agent` 全通过。

## 验收指标（建议）

- Routing Top-1 准确率（在评测集上）>= 90%
- 低置信场景 clarify 召回率 >= 95%
- 关键任务最小工作流生成成功率 >= 85%
- 校验链路稳定通过率（main 分支）= 100%
- 四类任务输出模板覆盖率 = 100%（`variant-effect` / `embedding` / `fine-tuning` / `track-prediction`）

## 新增规划：Skill Output 标准化（2026-03-30）

目标：对齐 7 个 skill 的输出目录与结果格式，建立跨 skill 汇总脚本的数据基础。

设计决策（已确认）：

1. 输出目录统一规范：
   - 所有 skill 默认输出到 `output/{skill-id}/`
   - 修复 `dnabert2`（原为 `.`）与 `ntv3`（原为 `nucleotide-transformer-v3/outputs`）的路径偏差
2. 结果 JSON 文件名统一模式：
   - `{skill_prefix}_{task}_{chrom}_{coords}_result.json`
3. 所有 result JSON 顶层新增共享 envelope 字段：
   - `skill_id`：skill 标识符
   - `task`：任务类型（`variant-effect` / `embedding` / `track-prediction`）
   - `outputs`：统一产物路径字典（`plot` / `npz` / `tsv` / `result_json`）
4. 覆盖范围：
   - 修改现有 6 个 skill 脚本
   - 为 `borzoi-workflows` 新建 `scripts/run_borzoi_predict.py`（fastpath variant-effect）
5. 不引入共享 Python 模块（各 skill 运行时环境独立）

验收标准：

1. 所有 skill 产出的 result JSON 包含 `skill_id`、`task`、`outputs` 顶层字段
2. `dnabert2` 输出落入 `output/dnabert2/`，`ntv3` 落入 `output/ntv3/`
3. `borzoi-workflows` 新脚本可执行并输出 TSV/NPZ/PNG/JSON
4. `jq .skill_id output/*/**_result.json` 可跨 skill 一致查询

## 新增规划：公开发布准备（Phase 4 前置，2026-03-30）

目标：面向社区公开发布，建立可维护的文档基础设施。

已完成交付（本次执行）：

1. **README 优化**：精简一句话描述、修正 Star History slug（`s2fm_agent` → `s2f-agent`）、更新 Skill Factory 状态（Dev→Stable）、Bootstrap 章节前置、Maintainers 替换为 CONTRIBUTING 跳转链接。
2. **CHANGELOG.md 新建**：以 `v0.1.0` 为初始公开版本，汇总所有主要里程碑。
3. **CONTRIBUTING.md 新建**：包含 Skill 编写规范、PR 提交流程与发布前验收 checklist。
4. **推送至 `JiaqiLiZju/s2f-agent`**：提交 `55d1534`，main 分支同步完成。

## docs/ 参考文档体系（2026-03-30 落地）

**交付内容：** 在 `docs/` 下新建 7 个参考文档，补全系统文档覆盖缺口。

| 文件 | 对应层 | 解决的覆盖缺口 |
|---|---|---|
| `docs/routing.md` | registry/routing.yaml + agent/ROUTING.md | 评分权重、置信度阈值、别名展开，无人类可查参考 |
| `docs/input-schema.md` | registry/input_schema.yaml | 22 个 canonical key 无集中查询页 |
| `docs/contracts.md` | registry/task_contracts + output_contracts + recovery_policies | 三个互锁契约文件无统一说明 |
| `docs/skills-reference.md` | registry/skills.yaml | 11 个 skill 无一览目录 |
| `docs/scripts-reference.md` | scripts/ | 19 个脚本无用途/依赖参考 |
| `docs/safety.md` | agent/SAFETY.md | 安全规则仅面向 LLM，缺人类可读版本 |
| `docs/evals.md` | evals/ + validate_*.sh | 评测体系无使用说明 |

**验收：** 提交 `1b65cac` 已推送，所有 docs/ 内交叉链接可解析，registry/skill 状态与文档一致。

## VCF 输入标准化规划（2026-03-30 确认）

### 背景

用户主要输入格式为 VCF，现已完成首轮 VCF 批量预测与 skill 脚本提升。后续规划基于本次实践确认。

### 已确认的输出契约

- **格式**：宽表 TSV（每组织两列 mean_diff/log2fc，方便 pandas/Excel）
- **效应统计量**：mean_diff + log2fc（跨 bins/tracks 均值）
- **INFO 透传**：全量透传所有 VCF INFO 字段（动态列，按字母排序）
- **Indel 处理**：尝试预测（不跳过），自动标注 variant_type

### 后续优化方向（待排期）

1. **多 ALT 展开**：当前取第一个 ALT，后续可选择展开为多行（每个 ALT 一行）
2. **`--tissues` JSON 模板**：提供标准组织配置文件示例（`config/tissues_default.json`、`config/tissues_brain.json` 等）
3. **长表输出选项**：`--output-format long`，输出每行为 variant×tissue，方便下游可视化
4. **效应统计扩展**：可选 `max_abs_diff`、`L2 norm`（用户当前选择不需要，后续可按需启用）
5. **eval 覆盖**：为 `run_alphagenome_vcf_batch.py` 添加 routing eval 用例（task=variant-effect + vcf-input）
6. **`case-study/run_vcf_effect.py` 与 skill 脚本同步**：两者逻辑已分叉，后续统一以 skill 脚本为主版本

## Case Study 验证规划（2026-03-31）

### 背景与目标

设计一批真实 case study，系统验证 s2f-agent 在路由、契约、Groundedness 与执行四个维度的能力。每个 case 对应已有 eval 脚本可验证，同时可在真实环境中运行。

### 验证维度

| 维度 | 验证问题 |
|------|---------|
| 路由 | agent 是否能正确选择 primary skill？clarify 时机是否准确？ |
| 契约 | required inputs 是否被正确识别？missing inputs 是否提示？ |
| Groundedness | 输出命令是否真实可执行？有无幻构 flag/API？ |
| 执行 | runnable_steps 是否能真实跑通？产物是否符合 expected_outputs？ |

### Case Study 集合（7 个，分 3 类）

**类别 A：核心任务端到端验证（4 个）**

| ID | Case | Skill | 对应 eval |
|----|------|-------|----------|
| A1 | VCF 批量变异效应预测（AlphaGenome） | alphagenome-api | task_success_007 |
| A2 | NTv3 Track Prediction（chr19 真实区间） | nucleotide-transformer-v3 | task_success_008（基于 task_success_005）|
| A3 | DNABERT2 Embedding（序列输入）| dnabert2 | task_success_009 |
| A4 | Borzoi 变异效应评分（单位点）| borzoi-workflows | task_success_010（路由层对应 route_014）|

**类别 B：边界与澄清行为验证（2 个）**

| ID | Case | 期望决策 | 对应 eval |
|----|------|----------|-----------|
| B1 | 歧义任务（无 task/skill 线索）| clarify | route_016 |
| B2 | 缺失必要输入（AlphaGenome 无坐标）| route + missing_inputs | route_017 |

**类别 C：多 Skill 协同（1 个）**

| ID | Case | Skills | 对应 eval |
|----|------|--------|-----------|
| C1 | Borzoi + GPN 联合变异评分 | borzoi-workflows + gpn-models | route_018（基于 route_009）|

### 实施方式

1. `evals/routing/cases.yaml`：新增 route_016（B1）、route_017（B2）、route_018（C1）
2. `evals/task_success/cases.yaml`：新增 task_success_007～010（A1-A4）
3. `case-study/run_cases.sh`：端到端执行脚本，使用 `case-study/Test.geuvadis.vcf` 等真实数据
4. 验收：`make validate-agent` 全通过（routing eval N/N，task-success eval N/N）

### 相关文件

- Eval 集：`evals/routing/cases.yaml`、`evals/task_success/cases.yaml`
- 验证脚本：`scripts/validate_routing.sh`、`scripts/validate_task_success.sh`
- 真实测试数据：`case-study/Test.geuvadis.vcf`、`case-study/Test.1KG.vcf`
- 执行脚本（待新建）：`case-study/run_cases.sh`

## 变更记录

- 2026-03-31：新增 NTv3 BED 批量预测能力的规划落地同步：`nucleotide-transformer-v3` 支持 `.bed` 批量执行 fastpath，agent 可自动识别 BED 路径并生成批量可执行步骤；track-prediction 输出契约从 metadata 命名统一为 `result.json`，并新增 task-success BED 用例。
- 2026-03-27：新建本文件；迁移并收敛 `DEVELOPMENT_PROGRESS.md` 中的规划内容，建立"规划/进度"双文档分责。
- 2026-03-27：根据用户确认，新增 P0 运维要求：`一次配置持续可用` 与 `一键清理恢复初始态`。
- 2026-03-27：根据用户确认，新增四类核心任务输出标准化要求：`variant-effect` / `embedding` / `fine-tuning` / `track-prediction`。
- 2026-03-29：新增 Execute Plan ENV 预检规划，明确 `required_env` / `required_env_any` 合同字段、`--run` 阻断与 `--dry-run` 非阻断策略、以及首批技能覆盖范围。
- 2026-03-30：新增 Skill Output 标准化规划，统一 7 个 skill 的输出目录、JSON 文件名与 envelope 字段格式。
- 2026-03-30：新增基因组数据输入优化，修复 sequence-or-interval 与 coordinate-or-interval token 重叠问题，完善坐标系语义标注。
- 2026-03-30：新增公开发布准备规划（Phase 4 前置），完成 README 优化、CHANGELOG/CONTRIBUTING 新建与远程推送。
- 2026-03-31：新增 Case Study 验证规划（7 个 case，3 类），对应 eval YAML 扩展与 case-study/run_cases.sh 新建。"规划/进度"双文档分责。
- 2026-03-27：根据用户确认，新增 P0 运维要求：`一次配置持续可用` 与 `一键清理恢复初始态`。
- 2026-03-27：根据用户确认，新增四类核心任务输出标准化要求：`variant-effect` / `embedding` / `fine-tuning` / `track-prediction`。
- 2026-03-29：新增 Execute Plan ENV 预检规划，明确 `required_env` / `required_env_any` 合同字段、`--run` 阻断与 `--dry-run` 非阻断策略、以及首批技能覆盖范围。
- 2026-03-30：新增 Skill Output 标准化规划，统一 7 个 skill 的输出目录、JSON 文件名与 envelope 字段格式。
- 2026-03-30：新增基因组数据输入优化，修复 sequence-or-interval 与 coordinate-or-interval token 重叠问题，完善坐标系语义标注。
- 2026-03-30：新增公开发布准备规划（Phase 4 前置），完成 README 优化、CHANGELOG/CONTRIBUTING 新建与远程推送。
