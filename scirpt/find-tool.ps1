param(
    [string]$ToolName = "flutter",
    [string]$ExeName = "bin\flutter.bat",
    [int]$MaxDepth = 5
)

$ErrorActionPreference = 'SilentlyContinue'

$drives = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root

foreach ($drive in $drives) {
    $dirs = Get-ChildItem -Path $drive -Directory -Filter "*$ToolName*" -Recurse -Depth $MaxDepth
    foreach ($dir in $dirs) {
        $target = Join-Path $dir.FullName $ExeName
        if (Test-Path $target) {
            Write-Output $dir.FullName
            exit 0
        }
    }
}

exit 1
