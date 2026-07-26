# 最终 XeLaTeX 构建与版式检查报告

## 2026-07-26 独立复核后的构建状态

本次已同步修改 `MASTER_THESIS_FINAL_CANDIDATE.md`、
`MASTER_THESIS_FINAL_CANDIDATE.tex` 和 `xelatex_project/main.tex`。实际检查
系统 PATH、常见 TeX Live/MiKTeX 安装位置及 Codex 捆绑依赖后，当前环境只有
Poppler，没有 XeLaTeX 和 Biber。因此本次不能重新生成 PDF；现存
`MASTER_THESIS_FINAL_CANDIDATE.pdf` 及下述哈希、页数和视觉检查结果均属于
上一版构建，不能作为本次源文件修订已进入 PDF 的证据。

该环境缺口不影响 MATLAB 代码、测试、Markdown/LaTeX 同步和 Git 提交，但在
具有 XeLaTeX/Biber 的环境中应按 README 的四遍命令重建并重新执行逐页视觉核验。
为排除既有二进制损坏，本次仍用 Poppler 重新渲染了旧 PDF 全部 82 页并检查 7 张
接触表；未见新增的空白页、裁切或渲染损坏。该检查只说明旧 PDF 完整，不证明本次
源文件修订已进入 PDF。

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
