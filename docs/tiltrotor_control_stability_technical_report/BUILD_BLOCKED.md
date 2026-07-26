# 报告二进制构建限制

## 当前环境核查

已检查系统 `PATH`、MiKTeX 常见目录以及 TeX Live 2024—2026 常见目录。本机当前未找到：

- `xelatex`
- `biber`

本机已找到：

- Microsoft Word：`C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE`
- Pandoc：`C:\Program Files\Pandoc\pandoc.exe`
- 项目指定 MATLAB R2021a：`F:\matlab\R2021a\bin\matlab.exe`

因此，本任务可以从最新 Markdown 与数值结果实际生成可编辑 DOCX，并可用 Word 更新域、导出临时 QA PDF 和逐页检查；但无法按要求执行 XeLaTeX—Biber—XeLaTeX—XeLaTeX 链。仓库中不提供冒充本次最新构建的旧 PDF，Draft PR 保持 Draft。

## PDF 精确重建命令

安装含 `xelatex`、`biber`、`ctex`、`biblatex-gb7714-2015` 和所需字体的 TeX 发行版后，在报告目录执行：

```powershell
Set-Location 'docs\tiltrotor_control_stability_technical_report\xelatex_project'
xelatex -interaction=nonstopmode -halt-on-error main.tex
biber main
xelatex -interaction=nonstopmode -halt-on-error main.tex
xelatex -interaction=nonstopmode -halt-on-error main.tex
```

随后检查：

```powershell
pdfinfo main.pdf
pdftoppm -png -r 150 main.pdf '..\rendered_pdf\page'
```

必须继续核查编译日志中的 error、undefined citation/reference、overfull/underfull、缺字和字体替代，并逐页检查空白、裁切、重叠、公式越界、页眉页脚和中文显示。只有该流程完成后，`main.pdf` 才能作为最新 PDF 交付。
