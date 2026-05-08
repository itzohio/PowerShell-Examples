# EDEN-XANDER Minecraft Autoclicker - Fileless Edition
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Threading;
public class MCAC {
    [DllImport("user32.dll")] public static extern bool GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")] public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(uint vKey);
}
"@

$random = New-Object System.Random
$cps = 12  # Valeur initiale
$running = $false
$breakMode = $true

function Get-HumanInterval {
    param([int]$targetCPS)
    $base = 1000.0 / $targetCPS
    $jitter = $random.NextGaussian(0, 1.8) * 2.5   # Distribution gaussienne humaine
    $humanCurve = $base + $jitter + $random.Next(-4,5)
    return [Math]::Max(18, $humanCurve)   # Minimum réaliste
}

# Détection bloc (via pixel ou mémoire Minecraft - version simple pixel pour screenshare)
function Is-Air-Block {
    # À améliorer avec lecture mémoire Minecraft si tu veux (pointer sur processus)
    # Pour l'instant : on autorise toujours le clic en mode break si tu tiens le click
    return $true
}

Write-Host "EDEN-XANDER Autoclicker chargé - F1: Toggle | F2: BreakMode | Molette: CPS" -ForegroundColor Cyan

while ($true) {
    if ([MCAC]::GetAsyncKeyState(0x70)) {  # F1
        $running = !$running
        Start-Sleep -Milliseconds 300
    }
    if ([MCAC]::GetAsyncKeyState(0x71)) {  # F2
        $breakMode = !$breakMode
        Write-Host "Break Block Mode: $breakMode"
        Start-Sleep -Milliseconds 200
    }

    # Slider CPS avec molette (exemple)
    if ([MCAC]::GetAsyncKeyState(0x0A)) { $cps = [Math]::Min(30, $cps + 1); Start-Sleep -Milliseconds 80 }  # Molette haut
    if ([MCAC]::GetAsyncKeyState(0x0B)) { $cps = [Math]::Max(0, $cps - 1); Start-Sleep -Milliseconds 80 }

    if ($running) {
        $interval = Get-HumanInterval $cps
        
        # Mode Break Block intelligent
        if ($breakMode -and (GetAsyncKeyState -vKey 0x01)) {  # Left click held
            # Simule un seul click efficace
            [MCAC]::mouse_event(0x0002, 0, 0, 0, 0)  # Down
            Start-Sleep -Milliseconds ($random.Next(18,35))
            [MCAC]::mouse_event(0x0004, 0, 0, 0, 0)  # Up
            Start-Sleep -Milliseconds ($interval * 1.2)  # Pause plus longue après break
        } else {
            # Autoclick normal avec randomization
            [MCAC]::mouse_event(0x0002, 0, 0, 0, 0)
            Start-Sleep -Milliseconds ($random.Next(8,18))
            [MCAC]::mouse_event(0x0004, 0, 0, 0, 0)
            Start-Sleep -Milliseconds ([int]$interval)
        }
        
        # Micro jitter humain supplémentaire
        if ($random.Next(0,100) -lt 12) {
            Start-Sleep -Milliseconds ($random.Next(1,7))
        }
    }
    Start-Sleep -Milliseconds 1
}