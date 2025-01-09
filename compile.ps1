
param (
    [string] $filename,
    [string] $output = "Spool-Weight"
)

Write-Host "Compiling file:" $filename
Write-Host ""

$line_pattern = "(include|use)\s*<(.+?)>"
$comment_pattern = '^\s*//'

$global:pathRoot = $PSScriptRoot
$global:dependencies = @()

Write-Host $global:pathRoot

function Search-File-Dependencies {
    param (
        [string]$path
    )

    $lines = Get-Content -Path $path
    $match = $lines | Where-Object {$_ -match $line_pattern -and $_ -notmatch $comment_pattern }
    $filenames = $match | ForEach-Object {
        if ($_ -match $line_pattern)
        {
            $matches[2]
        }
    }

    return $filenames
}

function Discover-ScadFile-Dependencies {
    param(
        [string]$path,
        [int]$depth=0
    )

    $root_dir = Split-Path -Path $path -Parent
    $deps = Search-File-Dependencies $path
    foreach($dep in $deps)
    {
        $global:dependencies += [PSCustomObject]@{Path = [System.IO.Path]::GetFullPath($global:pathRoot + "\" + $root_dir + "\" + $dep); Depth = $depth+1}
        Discover-ScadFile-Dependencies ($root_dir + "\" + $dep) ($depth+1)
    }
}

function Discover-Dependencies {
    param(
        [string]$path
    )

    Discover-ScadFile-Dependencies $path

    return $global:dependencies | Sort-Object -Property Depth -Descending | Select-Object -ExpandProperty Path -Unique
}

function Concat-ScadFile {
    param(
        [string]$path,
        [string]$outputPath
    )

    $name = "// " + [System.IO.Path]::GetFileName($path)
    Add-Content -path $outputPath -Value "// =============="
    Add-Content -path $outputPath -Value $name
    Add-Content -path $outputPath -Value "// =============="

    $lines = Get-Content -Path $path
    foreach($line in $lines) {
        if ($line -notmatch $line_pattern) {
            Add-Content -Path $outputPath -Value $line
        }
    }

}

$dependencies = Discover-Dependencies $filename
$dependencies += [System.IO.Path]::GetFullPath($global:pathRoot + "\" + $filename)

$dateTag = Get-Date -Format yyyyMMdd
$outputFolder = [System.IO.Path]::GetFullPath($global:pathRoot + "\output\")
$outputPath = [System.IO.Path]::GetFullPath($global:pathRoot + "\output\" + $output + "-" + $dateTag + ".scad")

New-Item -ItemType Directory -Force -Path $outputFolder

if (Test-Path -Path $outputPath)
{
    Remove-Item -Path $outputPath
}

Write-Host "Order of files to compile:"
foreach ($dep in $dependencies)
{
    Write-Host "  " $dep
    Concat-ScadFile $dep $outputPath
}

Write-Host "Done.  Written to " $outputPath