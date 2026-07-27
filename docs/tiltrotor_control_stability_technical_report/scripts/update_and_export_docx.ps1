param(
    [Parameter(Mandatory = $true)]
    [string]$DocxPath,
    [Parameter(Mandatory = $true)]
    [string]$PdfPath
)

$resolvedDocx = (Resolve-Path -LiteralPath $DocxPath).Path
$resolvedPdfParent = (Resolve-Path -LiteralPath (Split-Path -Parent $PdfPath)).Path
$resolvedPdf = Join-Path $resolvedPdfParent (Split-Path -Leaf $PdfPath)

$word = $null
$document = $null
try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0
    $document = $word.Documents.Open($resolvedDocx, $false, $false)
    foreach ($field in $document.Fields) {
        [void]$field.Update()
    }
    foreach ($toc in $document.TablesOfContents) {
        [void]$toc.Update()
    }
    $document.Repaginate()
    $pageCount = $document.ComputeStatistics(2)
    $document.Save()
    $document.ExportAsFixedFormat($resolvedPdf, 17)
    Write-Output "WORD_FIELD_UPDATE_OK=1"
    Write-Output "WORD_PAGE_COUNT=$pageCount"
    Write-Output "WORD_QA_PDF=$resolvedPdf"
}
finally {
    if ($null -ne $document) {
        $document.Close($false)
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document)
    }
    if ($null -ne $word) {
        $word.Quit()
        [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
