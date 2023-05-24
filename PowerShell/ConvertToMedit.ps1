param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({Test-Path $_})]
    [string] $InputFile,

    [Parameter(Position = 1)]
    [string] $OutputFile
)

# Ellenőrizzük, hogy a kimeneti fájl neve megadva van-e. Ha nincs megadva, akkor a kimenetet a bemeneti fájl nevére alakítjuk.
if (-not $OutputFile) {
    $OutputFile =  "output.mesh" # [IO.Path]::ChangeExtension($InputFile, ".mesh")
}

# Olvassuk be a bemeneti fájlt
$vrmlContent = Get-Content -Path $InputFile -Raw

# Ellenőrizzük az input fejlécét, hogy megfelel-e
$firstLine = ($vrmlContent -split "`n")[0]
$firstLine = $firstLine -split '\s+'
if ($firstLine[0] -ne "#VRML" -or $firstLine[1] -notmatch '^V[0-9]\.[0-9]' -or $firstLine[2] -ne "utf8") {
    Write-Host "Incorrect header!"
    exit 1
}

# Definiáljuk a MEDIT fájl tartalmát
$meditContent = @"
# MEDIT
MeshVersionFormatted 1
Dimension 3
Vertices

"@

# Szövegfeldolgozás és adatok kinyerése a VRML tartalomból
$pointIndex = $vrmlContent.IndexOf("point [") + 7
$coordIndexIndex = $vrmlContent.IndexOf("coordIndex [") + 12

$pointsText = $vrmlContent.Substring($pointIndex, $coordIndexIndex - $pointIndex)
$coordIndexText = $vrmlContent.Substring($coordIndexIndex).Trim()

# Koordináták feldolgozása és hozzáadása a MEDIT tartalomhoz
$points = $pointsText -split '\r?\n' | Where-Object { $_ -match '\d+\.\d+\s\d+\.\d+\s\d+\.\d+' }

$points | ForEach-Object {
    $point =$_ -split '\s+' | Where-Object {$_ -ne ""}
    Write-Host "Point: " $point
    $point | ForEach-Object {
        $pointIndexes = $_ -split '\s'
        Write-Host "Pointindexes: "$pointIndexes
       
    }
    
    if ($pointIndexes.Length -lt 3) {
        $meditContent += "Not enough point"
    } elseif ($pointIndexes.Length -gt 3) {
        $meditContent += "Too much point"
    } else {
        $meditContent += "{0} {1} {2}`n" -f $point[0], $point[1], $point[2]
    }
        
    
}
Write-Host $pointIndexes.Length

# Háromszögek feldolgozása és hozzáadása a MEDIT tartalomhoz
$meditContent += "Triangles`n"
$triangles = $coordIndexText -split '\r?\n' | Where-Object { $_ -match '\d+(?:,\s\d+)*,\s-1' }
$triangles | ForEach-Object {
    $trianglesIndexes = $_.Trim()
    $trianglesIndexes | ForEach-Object {
        $coordinates = $_ -split ', '
        if ($coordinates.Length -lt 4) {
            $meditContent += "Not enough point for a triangle`n"
            return
        } elseif ($coordinates.Length -gt 4) {
            $meditContent += "Too much point for a triangle`n"
            return
        } else {
            $meditContent += "{0} {1} {2}`n" -f $coordinates[0].Trim(), $coordinates[1].Trim(), $coordinates[2].Trim(), $coordinates[3].Trim()
        }
        
    }
}

# MEDIT tartalom kimenetének írása a fájlba
$meditContent += "End"
$meditContent | Set-Content -Path $OutputFile

Write-Host "The VRML file has been successfully converted to a MEDIT file: $OutputFile"