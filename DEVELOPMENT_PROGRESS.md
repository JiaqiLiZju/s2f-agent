# 开发进度整理

最后更新：2026-03-24

## 项目目标

本仓库用于沉淀面向基因组基础模型与相关工具链的 Codex skills，使用户可以通过显式调用 `$skill-name` 或自动触发的方式，直接获得更可靠、更 grounded 的代码生成、参数选择、推理说明与排错支持。

## 当前已完成工作

### 1. 已完成 skills 构建

当前已完成并纳入仓库管理的 skill 共 6 个：

1. `alphagenome-api`
   - 面向 AlphaGenome API 的安装、variant prediction、可视化与边界约束
   - 已补充 `references/quickstart.md`、`references/workflows.md`、`references/caveats.md`

2. `evo2-inference`
   - 面向 Evo 2 的本地推理、Hosted API / NIM 选型、checkpoint 选择与硬件约束
   - 已补充 `references/setup-matrix.md`、`references/usage-patterns.md`、`references/deployment-caveats.md`

3. `gpn-models`
   - 面向 GPN / GPN-MSA / PhyloGPN / GPN-Star 的家族选择与 grounded CLI / loading workflow
   - 已补充 `references/framework-selection.md`、`references/loading-and-cli.md`、`references/caveats.md`

4. `nucleotide-transformer`
   - 面向经典 NT v1/v2 的 JAX + Haiku 推理、6-mer tokenization、embeddings 提取与长度约束
   - 已补充 `references/model-variants.md`、`references/usage-patterns.md`、`references/tokenization-and-limits.md`

5. `nucleotide-transformer-v3`
   - 面向 NTv3 的 pre-trained / post-trained 推理、species conditioning、长度整除规则与内存优化
   - 已补充 `references/model-catalog.md`、`references/pre-vs-post.md`、`references/length-and-memory.md`

6. `segment-nt`
   - 面向 SegmentNT / SegmentEnformer / SegmentBorzoi 的 segmentation inference、概率读取与约束处理
   - 已补充 `references/family-selection.md`、`references/inference-patterns.md`、`references/constraints.md`

### 2. 已补充辅助脚本

为减少重复解释和手算，新增了两个 helper scripts：

1. `nucleotide-transformer-v3/scripts/check_valid_length.py`
   - 用于检查 NTv3 输入长度是否满足 `2^num_downsamples` 的整除要求
   - 可输出最近的合法长度建议

2. `segment-nt/scripts/compute_rescaling_factor.py`
   - 用于根据 token 数或近似 bp 长度计算 SegmentNT 的 `rescaling_factor`
   - 默认按 6-mer + CLS 的近似方式估算

### 3. 已补充项目级说明文档

已新增和更新仓库总览文档：

- `README.md`

目前 README 已覆盖：

- 仓库结构
- 当前 6 个 skills 的用途与调用方式
- `SKILL.md`、`references/`、`scripts/`、`agents/openai.yaml` 的职责
- fresh-machine deployment 流程

### 4. 已补充部署层

为支持在新机器上直接部署和测试，新增了以下部署脚本：

1. `scripts/link_skills.sh`
   - 将 skills 链接或复制到 `~/.codex/skills` 或指定目录

2. `scripts/provision_stack.sh`
   - 在目标机器上创建软件环境
   - 支持的 stack：
     - `alphagenome`
     - `gpn`
     - `nt-jax`
     - `evo2-light`
     - `evo2-full`

3. `scripts/smoke_test.sh`
   - 检查仓库结构、skills 安装路径、helper scripts、可选 Python imports

4. `scripts/bootstrap.sh`
   - 一键部署入口
   - 默认执行：
     - skills 链接
     - `alphagenome` / `gpn` / `nt-jax` 三套核心环境准备
     - smoke test

5. `Makefile`
   - 提供一键命令入口：
     - `make link-skills`
     - `make bootstrap`
     - `make bootstrap-evo2-light`
     - `make bootstrap-evo2-full`
     - `make smoke`

## 当前验证状态

### skills 结构校验

以下 skills 已通过 `quick_validate.py`：

- `alphagenome-api`
- `evo2-inference`
- `gpn-models`
- `nucleotide-transformer`
- `nucleotide-transformer-v3`
- `segment-nt`

### helper scripts 校验

已完成的样例验证：

- `check_valid_length.py 32768`
  - 返回合法
- `check_valid_length.py 33000`
  - 返回不合法，并给出最近合法长度
- `compute_rescaling_factor.py --sequence-length-bp 40008`
  - 输出 `num_tokens_inference=6669`
  - 输出 `rescaling_factor=3.2563476562`

### 部署脚本校验

已完成静态验证：

- `bash -n` 校验以下脚本语法通过：
  - `scripts/link_skills.sh`
  - `scripts/provision_stack.sh`
  - `scripts/smoke_test.sh`
  - `scripts/bootstrap.sh`

- 已验证帮助输出或 dry-run：
  - `link_skills.sh --list`
  - `provision_stack.sh --help`
  - `smoke_test.sh --help`
  - `bootstrap.sh --help`
  - `make help`
  - `make -n bootstrap`
  - `make -n bootstrap-evo2-light`

- repo-level smoke test 已通过

## 当前仓库状态总结

目前仓库已经具备以下能力：

1. 可以让 Codex 直接发现并调用 6 个已完成 skill
2. 可以在新机器上按 stack 拆分方式部署对应软件环境
3. 可以通过 shell 或 Makefile 进行一键部署
4. 可以通过 smoke test 检查部署结果是否完整

## 当前未完成项

以下内容尚未完成或尚未落地验证：

1. `CHM13` skill 还未构建
2. 一键部署流程尚未在全新目标机器上做真实安装验证
3. Evo2 的目标机硬件适配仍依赖部署者提供正确的 `TORCH_INSTALL_CMD`
4. NT / NTv3 的 JAX 安装在不同 CUDA / TPU 环境下仍需要部署者指定合适的 `JAX_INSTALL_CMD`

## 下一步建议

建议按以下顺序继续推进：

1. 在新机器上实际执行一次：
   - `make bootstrap`
   - 或 `./scripts/bootstrap.sh`

2. 如果目标机需要 Evo2：
   - 先验证 `evo2-light`
   - 再决定是否需要 `evo2-full`

3. 完成 `CHM13` skill

4. 视部署反馈补充：
   - `.env.example`
   - `make doctor`
   - Dockerfile
   - Linux / WSL / macOS 的额外部署说明

## 说明

本次整理仅保存开发成果与部署脚本，不在当前机器上实际安装外部软件栈。实际安装与验证应在目标测试机器上完成。
