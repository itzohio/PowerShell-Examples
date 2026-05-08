# EDEN-XANDER Minecraft Autoclicker v2 - Fileless Fixed
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class MCAC {
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [DllImport("user32.dll")] public static extern void mouse_event(int dwFlags, int dx, int dy, int cButtons, int dwExtraInfo);
}
"@

$random = New-Object System.Random
$cps = 12
$running = $false
$breakMode = $true

# === Gaussian Random (Box-Muller) ===
function Get-Gaussian {
    param([double]$mean = 0, [double]$stdDev = 1)
    $u1 = $random.NextDouble()
    $u2 = $random.NextDouble()
    $randStdNormal = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)
    return $mean + $stdDev * $randStdNormal
}

function Get-HumanInterval {
    param([int]$targetCPS)
    $base = 1000.0 / $targetCPS
    $jitter = (Get-Gaussian -mean 0 -stdDev 2.2) * 2.8
    $human = $base + $jitter + $random.Next(-5, 6)
    return [Math]::Max(22, [Math]::Min(120, $human))  # Bornes réalistes
}

Write-Host "EDEN-XANDER Autoclicker v2 chargé - F1: Toggle | F2: BreakMode | Molette: ±CPS" -ForegroundColor Cyan

while ($true) {
    # Toggle
    if ([MCAC]::GetAsyncKeyState(0x70) -ne 0) {  # F1
        $running = !$running
        Write-Host "Autoclicker: $running" -ForegroundColor Green
        Start-Sleep -Milliseconds 250
    }
    
    # Break Mode
    if ([MCAC]::GetAsyncKeyState(0x71) -ne 0) {  # F2
        $breakMode = !$breakMode
        Write-Host "Break Block Mode: $breakMode" -ForegroundColor Yellow
        Start-Sleep -Milliseconds 200
    }

    # CPS Slider (molette)
    if ([MCAC]::GetAsyncKeyState(0x0A) -ne 0) { $cps = [Math]::Min(30, $cps + 1); Start-Sleep -Milliseconds 70 }
    if ([MCAC]::GetAsyncKeyState(0x0B) -ne 0) { $cps = [Math]::Max(1, $cps - 1); Start-Sleep -Milliseconds 70 }

    if ($running) {
        $interval = Get-HumanInterval $cps

        if ($breakMode -and ([MCAC]::GetAsyncKeyState(0x01) -ne 0)) {
            # === MODE BREAK BLOCK (un seul click efficace) ===
            [MCAC]::mouse_event(0x0002, 0, 0, 0, 0)  # Left Down
            Start-Sleep -Milliseconds ($random.Next(16, 32))
            [MCAC]::mouse_event(0x0004, 0, 0, 0, 0)  # Left Up
            Start-Sleep -Milliseconds ([int]($interval * 1.35))  # Pause plus naturelle après cassage
        } 
        else {
            # === Autoclick normal randomisé ===
            [MCAC]::mouse_event(0x0002, 0, 0, 0, 0)
            Start-Sleep -Milliseconds ($random.Next(9, 19))
            [MCAC]::mouse_event(0x0004, 0, 0, 0, 0)
            Start-Sleep -Milliseconds ([int]$interval)
        }

        # Micro-pauses humaines aléatoires
        if ($random.Next(0, 100) -lt 15) {
            Start-Sleep -Milliseconds ($random.Next(2, 9))
        }
    }
    Start-Sleep -Milliseconds 2
}
