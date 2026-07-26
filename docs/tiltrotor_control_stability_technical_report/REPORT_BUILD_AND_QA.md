# Report Build And QA Record

## Scope

This record covers the report sources and editable Word deliverable generated
from the current control-stability result CSV files. It does not represent an
external aircraft validation or a final PDF release.

## Source Generation

The current report set was generated from the latest assessment outputs:

- `TECHNICAL_REPORT.md`
- `xelatex_project/main.tex`
- `xelatex_project/references.bib`
- `TECHNICAL_REPORT_EDITABLE.docx`

The DOCX is editable and was generated with native Word tables, five inserted
figures, a field-based table of contents, and editable OMML equations. A
structural inspection found 380 paragraphs, 10 native tables, 138 display
equations, 220 total OMML objects, and one TOC field.

## PDF Build Status

The required XeLaTeX-Biber-XeLaTeX-XeLaTeX build was not executed because this
machine has neither `xelatex` nor `biber`. The environment search also found no
installed MiKTeX or TeX Live distribution. No pre-existing PDF is represented
as a current report output.

After installing a TeX distribution with the packages and fonts named in
`BUILD_BLOCKED.md`, rebuild from `xelatex_project` with the four commands
recorded there. Then inspect compiler diagnostics and render every PDF page
before treating the PDF as a delivery artifact.

## DOCX Render QA Status

The standard DOCX renderer could not run because LibreOffice is not installed.
Microsoft Word and Pandoc are installed, so the latest editable DOCX was
generated. A subsequent Word COM field-update and PDF-export QA attempt did
not produce a QA PDF within the allotted execution time; the Word process was
then terminated after it had remained responsive but produced no output.

Consequently:

- editable-structure checks are complete;
- Word field/page update and rendered-page inspection are **not complete**;
- no DOCX QA PDF is included;
- no claim is made that DOCX pagination, clipping, or page-level layout has
  been finally verified.

## Required Remaining QA

1. Run `scripts/update_and_export_docx.ps1` with the current DOCX and a new QA
   PDF destination, allowing Word to finish normally.
2. Render the resulting PDF to page images and inspect every page for blank
   pages, clipping, overlap, equation overflow, figure/table captions, headers,
   footers, page numbers, and Chinese font substitution.
3. Install the missing TeX toolchain and perform the separate XeLaTeX PDF build
   and page-level QA described above.
