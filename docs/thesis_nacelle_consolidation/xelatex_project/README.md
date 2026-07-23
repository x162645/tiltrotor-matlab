# XeLaTeX 编译说明

本工程以 `main.tex` 为入口，图件从上级 `figures` 目录读取。建议使用完整 TeX Live：

```powershell
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
```

本机生成环境未发现 XeLaTeX，因此交付 PDF 使用同一 Markdown 和图件经独立排版器生成；`main.tex` 与 `thesis_body.tex` 已直接面向 XeLaTeX。
