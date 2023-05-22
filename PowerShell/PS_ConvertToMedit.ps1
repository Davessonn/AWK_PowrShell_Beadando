param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({Test-Path $_})]
    [string] $InputFile,

    [Parameter(Position = 1)]
    [string] $OutputFile
)

# Ellenőrizzük, hogy a kimeneti fájl neve megadva van-e. Ha nincs megadva, akkor a kimenet alapértelmezett értéket kap.
if (-not $OutputFile) {
    $OutputFile =  "PS_output.mesh" # [IO.Path]::ChangeExtension($InputFile, ".mesh")
}

# Olvassuk be a bemeneti fájlt
$vrmlContent = Get-Content -Path $InputFile -Raw

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

$pointsText = $vrmlContent.Substring($pointIndex, $coordIndexIndex - $pointIndex).Trim()
$coordIndexText = $vrmlContent.Substring($coordIndexIndex).Trim()


# Koordináták feldolgozása és hozzáadása a MEDIT tartalomhoz
$points = $pointsText -split '\r?\n' | Where-Object { $_ -match '\d+\.\d+\s\d+\.\d+\s\d+\.\d+' }

$points | ForEach-Object {
    $point = $_ -split '\s+' | Select-Object -Skip 1
    $meditContent += "{0}, {1} {2} {3}`n" -f ++$node_idx, $point[0], $point[1], $point[2]
}

# Háromszögek feldolgozása és hozzáadása a MEDIT tartalomhoz
$meditContent += "Triangles`n"
$triangles = $coordIndexText -split '\r?\n' | Where-Object { $_ -match '\d+(?:,\s\d+)*,\s-1' }
$triangles | ForEach-Object {
    $indices = ($_ -split '#')[0].Trim()
    $indices | ForEach-Object {
        $numbers = $_ -split ','
        $meditContent += "{0} {1} {2} {3}`n" -f ++$elem_idx, $numbers[0].Trim(), $numbers[1].Trim(), $numbers[2].Trim(), $numbers[3].Trim()
    }
}

# MEDIT tartalom kimenetének írása a fájlba
$meditContent += "End"
$meditContent | Set-Content -Path $OutputFile

Write-Host "A VRML fájl sikeresen átalakítva MEDIT fájlra: $OutputFile"