# 最终 XeLaTeX 构建与版式检查报告

## 构建环境

- 引擎：XeTeX 3.141592653-2.6-0.999998（TeX Live 2026）
- 文献处理：Biber 2.21
- 中文文档类：`ctexbook`
- 参考文献样式：`gb7714-2015`

## 正式构建顺序

在 `final/xelatex_project` 中实际执行：

1. `xelatex -interaction=nonstopmode -halt-on-error main.tex`
2. `biber main`
3. `xelatex -interaction=nonstopmode -halt-on-error main.tex`
4. `xelatex -interaction=nonstopmode -halt-on-error main.tex`

四步退出码均为 0。最终日志中：

- LaTeX/Biber 错误：0
- 未定义引用：0
- Overfull/Underfull box：0
- Missing character：0
- 实质性 warning：0

## 产物

- PDF 页数：82
- 页面规格：A4
- PDF 版本：1.7
- PDF SHA-256：`A93A7DE456DF1EF6210B6B6241C1BDB3A4924D2CF079F5B2525AA773B1934670`
- 正文规模：约 50,795 个非空白字符
- 展示公式块：103（其中编号 `equation` 环境 85）
- 图：24
- 表：7
- 参考文献：40

## 视觉检查

使用 Poppler 将最终 PDF 的全部 82 页渲染为 PNG，并生成 7 张接触表逐页检查。未发现空白断页、英文摘要孤页、重复图题、图表裁切、公式溢出、页眉页码异常或明显不可读内容。
