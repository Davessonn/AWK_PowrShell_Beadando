param (
    [Parameter(ValueFromPipeline = $true)]
    [String[]]$InputObject,
    [Parameter(Mandatory = $true)]
    [String]$OutputFile
)

Begin {
    $outputLines = @()
    $outputLines += "# MEDIT"
    $outputLines += "MeshVersionFormatted 1"
    $outputLines += "Dimension 3"
    $outputLines += "Vertices"
    $nodeIndex = 1
    $elemIndex = 1
}

Process {
    foreach ($line in $InputObject) {
        if ($line -match "point[[:space:]]+\[") {
            $i = 1
            while ($line -notmatch "\]") {
                if (-not [string]::IsNullOrWhiteSpace($line) -and $line -notmatch "^#") {
                    $coords = $line -split '\s+' | Where-Object { $_ -ne '' }
                    $outputLines += "$nodeIndex, $($coords[0]) $($coords[1]) $($coords[2])"
                    $i++
                    $nodeIndex++
                }
                $line = Read-Host
            }
        } elseif ($line -match "coordIndex[[:space:]]+\[") {
            $i = 1
            while ($line -notmatch "\]") {
                if (-not [string]::IsNullOrWhiteSpace($line) -and $line -notmatch "^#") {
                    $indices = $line -split '\s+' | Where-Object { $_ -ne '' }
                    if ($elemIndex -eq 1) {
                        $outputLines += "Triangles"
                    }
                    $outputLines += "$elemIndex, $($indices[0]) $($indices[1]) $($indices[2])"
                    $i++
                    $elemIndex++
                }
                $line = Read-Host
            }
        }
    }
}

End {
    if ($elemIndex -eq 1) {
        $outputLines += "Error: no elements found"
        exit 1
    }
    $outputLines += "End"

    $outputLines | Set-Content -Path $OutputFile -Encoding UTF8
}