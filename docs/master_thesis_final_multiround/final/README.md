# 最终提交候选包

## 核心文件

- `MASTER_THESIS_FINAL_CANDIDATE.pdf`：82 页提交候选 PDF。
- `MASTER_THESIS_FINAL_CANDIDATE.tex`：单文件 LaTeX 归档版本。
- `MASTER_THESIS_FINAL_CANDIDATE.md`：可检索的 Markdown 正文。
- `xelatex_project/`：可复现 XeLaTeX 工程，含 `main.tex`、`references.bib` 和 24 幅正文图。
- `raw_figure_data/`：图表原始 CSV/MAT/Markdown 数据与来源记录。
- `scripts/`：论文生成、外部旋翼指标复算、九/十三状态共享块审计和 PDF 接触表脚本。
- `build_logs/`：正式 XeLaTeX/Biber/XeLaTeX/XeLaTeX 四遍构建日志。

## 审计文件

- `FINAL_SCIENTIFIC_AUDIT.md`
- `FINAL_LANGUAGE_AUDIT.md`
- `FINAL_LOGIC_AUDIT.md`
- `FINAL_UNRESOLVED_ISSUES.md`
- `FINAL_LATEX_BUILD_REPORT.md`
- `FINAL_FORMULA_CODE_PARAMETER_TEST_MAPPING.md`
- `CLAIM_EVIDENCE_MATRIX_FINAL.csv`
- `PARAMETER_PROVENANCE_FINAL.csv`
- `REFERENCE_TRACEABILITY_FINAL.csv`
- `FIGURE_SOURCE_INDEX_FINAL.csv`

## 构建

在 `xelatex_project` 中依次运行：

```text
xelatex -interaction=nonstopmode -halt-on-error main.tex
biber main
xelatex -interaction=nonstopmode -halt-on-error main.tex
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

本包使用 XeTeX/TeX Live 2026 与 Biber 2.21 实际构建。论文科学边界、失败点与未验证假设见最终审计报告，不得把本稿描述为 XV-15 高保真复现或整机试验验证。
