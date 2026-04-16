# s2f-agent 案例研究执行与撰写规划 (Case Study Plan)

## 2026-04-16：Variant-Effect Playbook 对齐测试记录（开发侧）

### 目标

将 Case Study 2（variant-effect）相关的执行文案与 agent 合同语义统一到当前有效入口，确保手稿叙事中的“多模型异构编排”能够对应到可复现实操路径。

### 本轮落地要点

1. 统一执行入口叙事（不再引用已下线脚本）

- 单位点：`skills/alphagenome-api/scripts/run_alphagenome_predict_variant.py`
- 批量 VCF：`skills/alphagenome-api/scripts/run_alphagenome_vcf_batch.py`
- 编排层：`run_agent.sh` + `execute_plan.sh`

2. 统一输出契约叙事

- 单位点产物：`alphagenome_variant-effect_<...>_result.json` + overlay plot
- 批量产物：`<vcf_stem>_tissues.tsv`（含 INFO 透传与 8 组织效应列）
- 重试语义：`clarify-missing-inputs-then-connectivity-proxy-retry-once`

3. 统一 Case-study 样例路径表达

- `task_success_007` 与 A1 案例文案更新到当前有效 VCF 路径表达；
- `vcf-input` 示例调整为通用占位路径，避免论文/文档绑定历史目录结构。

### 对手稿叙事的直接价值

- Case Study 2 中“统一异构输出对象”的论述与实际执行合同一致；
- 可直接在 Results 中引用“编排层命令 + 产物契约 + 重试语义”三段式证据；
- 降低 reviewer 复现实验时因旧路径失效导致的歧义。

## 总体叙事逻辑：从“宏观调控语法”到“微观变异效应”

本次手稿的 Results 部分将通过两个串联的案例研究来展示系统能力：

Case Study 1 (Macro): 展示系统如何编排基础模型 (gLMs) 来学习和提取全基因组的“调控语法”（从特征提取、微调到连续图谱预测）。

Case Study 2 (Micro): 展示系统如何针对具体的“语法破坏”（单核苷酸变异），通过路由多个异构模型，输出统一格式的生物学推断。

## Case Study 1: 基因组基础模型的特征提取、微调与连续图谱预测

(Embedding Extraction, Model Fine-tuning, and Track Prediction)

1. 核心生物学假设 (Biological Hypotheses)

假设 A: 在基础模型微调中，保留细粒度标签（Fine-grained labels，如特定发育阶段的转录活性）比粗粒度的二元标签更能迫使注意力机制学到物种特异性的时序调控语法。

假设 B: 大语言模型的高权重注意力矩阵（Attention matrices）可以被降维并解释为生物学可读的顺式调控元件（Cis-regulatory elements）。

2. 意图与工作流设计 (Workflow Design)
本案例被设计为一个具有先后顺序的串联 Pipeline，以避免内容过于臃肿，同时展示代理处理长流程的能力：

Phase 1A (Embedding & Fine-tuning): 输入带有细粒度标签的昆虫（例如果蝇）启动子序列集。使用 s2f-agent 提取零样本嵌入，并编排针对特定任务（Task objective）的微调代码。

Phase 1B (Track Prediction): 利用微调后的模型（或同类 gLM），在目标基因组区间上预测连续的调控信号（如染色质可及性）。

3. 凸显的 s2f-agent 核心能力 (Key Agent Capabilities)

强制数据集与算力契约 (Dataset & Compute Contracts): 证明系统能处理不同分词器（Tokenizers）的差异，并根据 compute-constraints（算力约束）安全地生成分布式训练的执行步骤，而非盲目生成导致 OOM 的代码。

输出头标准化 (Output-head Normalization): 在 Track prediction 中，展示代理如何自动规范化多轨输出。

4. 预期可视化伪影 (Expected Output Artifacts)

带有专业英文标签的图表，例如：Attention Weight Distribution across Developmental Stages, Motif Enrichment in High-Attention Regions。

## Case Study 2: 多异构模型驱动的变异效应预测

(Variant Effect Prediction via Multi-Skill Orchestration)

1. 核心生物学假设 (Biological Hypotheses)

假设 C: GWAS 命中区域内的候选非编码变异通过破坏远端增强子的活性，导致组织特异性的启动子互作失效。

2. 意图与工作流设计 (Workflow Design)
输入一个标准的非编码变异 VCF 文件。通过改变自然语言 prompt 的侧重点，展示 s2f-agent **“多对一”（Multiple Skills to One Playbook）**的动态路由能力：

路径 A (AlphaGenome): 侧重于组织特异性的综合突变效应打分（Tissue-specific scoring）。

路径 B (Borzoi): 侧重于 3D 空间构象与长距离染色质互作的破坏评估（3D interaction assessment）。

路径 C (GPN): 侧重于基于大语言模型的零样本进化约束评估（Evolutionary constraint likelihood）。

3. 凸显的 s2f-agent 核心能力 (Key Agent Capabilities)

智能路由与意图澄清 (Smart Routing & Clarify): 展示当 VCF 缺少坐标系 (0-based/1-based) 或 Assembly 版本时，系统如何拦截请求并触发 clarify，保障科学计算安全。

归一化输出契约 (Unified Output Contracts): （本节高光） 展示尽管 AlphaGenome、Borzoi 和 GPN 的底层架构和依赖天差地别，s2f-agent 的执行层能将它们输出整合为一个统一的宽表 (Wide-format table)。

4. 预期代码/可视化伪影 (Expected Output Artifacts)

一段合并异构预测结果的数据框代码 (DataFrame code)，展示统一的表头合并：

Variant_ID (由 orchestrator 统一格式化)

Tissue_Score (来自 AlphaGenome)

Contact_Frequency_Shift (来自 Borzoi)

Evolutionary_Constraint_Score (来自 GPN)

## 撰写与修改建议 (Writing & Integration Guidelines)

### 更新 Introduction & Discussion:

修改原稿中仅强调 Variant-Effect 的说辞，确保宏观（全基因组预测与微调）和微观（单点变异）并重。

在 Discussion 中强调：s2f-agent 不仅解决了模型环境不兼容的工程问题，更通过 clarify 机制和强制输出契约，防止了研究者在非人模式生物研究中常犯的“坐标系/组装版本盲目假设”的错误。

### 图表联动 (Figure Interactivity):

在描述 Case Study 2 时，明确在文中提及横向对比图（例如：“As illustrated in the horizontal axis of Fig. X, the agent routes identical VCF inputs across three distinct skills...”）。


## s2f-agent 案例研究撰写蓝图 (Manuscript-Focused Version)

本蓝图旨在将案例研究直接映射为手稿 Results 部分的两个新增小节（对应原草稿的 3.4 和 3.5 节）。叙事主线为：“从破译人类细胞特异性调控语法，到跨模型评估真实疾病单点变异的联合破坏效应”。

## 小节 3.4 (新增): 破译调控语法 —— 基础模型的契约化微调与人类连续图谱预测

(Results 3.4: Decoding human regulatory grammar through contract-driven gLM fine-tuning and track prediction)

1. 叙事核心 (Narrative Focus):
强调 s2f-agent 如何处理复杂的人类基因组表观遗传学数据。重点突出系统在微调基础模型（如 NTv3）时，对高通量测序数据（BED/BigWig）的规范化处理、坐标系对齐以及算力约束契约 (Compute Constraints)。

2. 核心实验设计 (Track 与 BED 选择建议):

目标细胞系: 建议选择 ENCODE 库中注释最完善的 K562 (白血病细胞，代表血液/免疫轴) 或 HepG2 (肝癌细胞，代表代谢轴)。

输入 BED (分类标签): 使用保守的 IDR thresholded peak files（如 K562_ATAC_narrowPeak.bed 和 K562_H3K27ac_broadPeak.bed）。将结合了 ATAC+ 且 H3K27ac+ 的区域定义为“活跃增强子/启动子”。

输入 Track (连续回归信号): 对应细胞系的 Fold-change over control signal tracks (BigWig 格式)。让模型不仅预测“是/否”具有调控功能，而是预测连续的调控强度。

3. 模拟对话流程 (Simulated Agent Interaction):

User Prompt: "Fine-tune Nucleotide Transformer v3 (NTv3) to predict continuous ATAC-seq and H3K27ac signal tracks in human K562 cells, using the active enhancer regions defined in K562_active_enhancers.bed on the hg38 assembly."

Agent 内部响应 (展示能力):

意图识别与契约校验: 识别出 fine-tuning 和 track-prediction 混合意图。强制检查输入序列长度是否超出 NTv3 的 6kb 上下文窗口限制，并验证 hg38 的坐标边界。

数据模式对齐 (Dataset Schema): 自动生成代码，将 BED 文件的区间转化为适用于 NTv3 的 k-mer 序列张量，并将 BigWig 的连续信号作为回归损失的 Target。

执行计划生成: 输出带有显存保护策略（如 Gradient Accumulation, LoRA 等参数高效微调策略）的 PyTorch 训练脚本。

4. 论文图表设计 (Figure Design - Fig X):

Panel A (Workflow): s2f-agent 接收大片段人类基因组 BED 和 Track 信号，自动处理分词并生成分布式训练脚本的流程图。

Panel B (Biological Finding): 展示微调后的模型在独立测试集（如 Held-out 染色体 chr8）上的预测 Track 与真实实验 Track（ATAC/H3K27ac）的 Pearson 相关性散点图。

Panel C (Interpretability): 提取模型在某个知名红系特异性调控元件（如珠蛋白基因簇 Globin Locus）上的 Attention 权重分布，证明模型自动学习到了 GATA1 或 TAL1 等关键转录因子的结合基序（Motif）。

## 小节 3.5 (重写原 3.4): 统一异构模型 —— 真实疾病精细定位变异的多视角效应推断

(Results 3.5: Unifying heterogeneous model workflows for multi-perspective variant effect inference in complex diseases)

1. 叙事核心 (Narrative Focus):
解决目前 S2F 领域最大的痛点：面对同一个真实的疾病相关 VCF（如 GWAS 精细定位结果），如何无缝调用不同侧重点的模型（生化指标 vs. 3D构象 vs. 进化保守性）来缩小致病变异候选范围，并且不被繁杂的环境配置和输出格式淹没。

2. 核心真实案例选择 (Real-world Application):

疾病场景: 建议使用 冠心病 (CAD, Coronary Artery Disease) 或 血脂异常 (Lipid Traits) 的非编码 GWAS 精细定位 (Fine-mapped) 变异集。

输入 VCF: 构建一个名为 CAD_finemapped_noncoding.vcf 的文件，包含 9p21 位点或 SORT1 基因上游等著名的非编码致病 SNP。这些 SNP 往往不改变蛋白质，而是破坏了肝脏 (Liver) 中的增强子。

3. 模拟对话流程 (Simulated Agent Interaction):

Initial User Prompt: "Evaluate the causal potential of the variants in CAD_finemapped_noncoding.vcf."

Agent 行为 1 (安全拦截 - Clarify): 系统输出 [CLARIFY] 拦截请求："Warning: Genome assembly and coordinate system (0-based/1-based) are unspecified. For human GWAS data, specifying hg19 or hg38 is critical. Proceeding may lead to invalid biological inferences. Please specify."

Refined User Prompt: "Score CAD_finemapped_noncoding.vcf on hg38 (1-based) using AlphaGenome for tissue-specific functional effects, Borzoi for 3D chromatin interactions, and GPN for evolutionary constraints."

Agent 行为 2 (多路路由与统一输出): 系统将同一个真实 VCF 路由到三个完全独立的 Skills，屏蔽底层差异，最终返回一个对齐的宽表 (Wide-format table)。

4. 论文图表设计 (Figure Design - Fig Y):

Panel A (Routing Logic): s2f-agent 将 CAD 的 VCF 输入分发到 alphagenome-api, borzoi-workflows, 和 gpn-models 的星型路由拓扑图。

Panel B (Unified Output Object): 展示系统生成的 Pandas DataFrame，突出表头：Variant_ID (rsID), Liver_Enhancer_Score_Drop (来自 AlphaGenome), Contact_Frequency_Shift_with_SORT1 (来自 Borzoi), Evolutionary_Constraint_Score (来自 GPN) 被安全地对齐。

Panel C (Biological Finding - 真实发现案例): 通过 s2f-agent 的联合评分系统，成功从数百个连锁不平衡 (LD) 区间的 SNP 中“大海捞针”。例如，展示一个 3D 雷达图或多轴散点图，指出目标 SNP (如 rs12740374) 在三个模型中均显示出极端的破坏性：它特异性地削弱了肝脏组织的活性 (AlphaGenome)，打破了与 SORT1 基因启动子的 3D 互作循环 (Borzoi)，并且位于高度保守的调控序列中 (GPN)，从而在多模态层面锁定其作为 Causal Variant 的身份。

## 下一步行动指南 (Next Steps for the Author)

获取 ENCODE 与 GWAS 数据: 下载少量示例性质的 K562 peak 数据，以及公共的 CAD GWAS Fine-mapping 结果（如从 GWAS Catalog 或 1000 Genomes 提取相关 SNP）。

生成实验日志: 在你的终端中，实际输入上述的 Refined Prompts，收集 s2f-agent 返回的真实 JSON/Markdown 计划对象，作为论文的核心补充材料。

整合入草稿: 使用上述提供的叙事结构和真实生物学案例，替换并扩写现有的 draft-v2.md 手稿。重点强调 s2f-agent 是促成这些跨维度生物学发现的“催化剂”层。
