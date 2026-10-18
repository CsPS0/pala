# =====================================================================
# Pala — Modern All-in-One Telepito es Komponens Kezelo Windowsra
# Hasznalat:
#   Interaktiv: irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex
#   Flagek:     .\install.ps1 -All
#               .\install.ps1 -Cli
#               .\install.ps1 -Desktop
#               .\install.ps1 -Uninstall
# =====================================================================

param(
    [switch]$All,
    [switch]$Cli,
    [switch]$Desktop,
    [switch]$AddToPath,
    [switch]$StartMenu,
    [switch]$DesktopIcon,
    [switch]$Uninstall,
    [string]$Version = ""
)

$ErrorActionPreference = 'Stop'
$Repo = "CsPS0/pala"
$InstallBase = Join-Path $env:LOCALAPPDATA "Pala"
$BinDir = Join-Path $InstallBase "bin"
$DesktopDir = Join-Path $InstallBase "desktop"
$ProgramsFolder = [Environment]::GetFolderPath('Programs')
$DesktopFolder = [Environment]::GetFolderPath('Desktop')

function Show-Banner {
    Write-Host "=============================================================" -ForegroundColor DarkYellow
    Write-Host " Pala — Telepito es Komponens Kezelo (Windows)" -ForegroundColor Yellow
    Write-Host "=============================================================" -ForegroundColor DarkYellow
}

function Add-PathToUserEnv([string]$PathToAdd) {
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $Parts = @()
    if ($CurrentPath) {
        $Parts = $CurrentPath.Split(';') | Where-Object { $_ -ne "" }
    }
    if ($Parts -notcontains $PathToAdd) {
        $NewPath = ($Parts + $PathToAdd) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $NewPath, [EnvironmentVariableTarget]::User)
        $env:Path = "$env:Path;$PathToAdd"
        Write-Host "    [OK] PATH frissitve: $PathToAdd" -ForegroundColor Green
    } else {
        Write-Host "    [i] A $PathToAdd mar szerepel a felhasznaloi PATH-ban." -ForegroundColor Gray
    }
}

function Remove-PathFromUserEnv([string]$PathToRemove) {
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($CurrentPath) {
        $Parts = $CurrentPath.Split(';') | Where-Object { $_ -ne "" -and $_ -ne $PathToRemove }
        $NewPath = $Parts -join ';'
        [Environment]::SetEnvironmentVariable("Path", $NewPath, [EnvironmentVariableTarget]::User)
        Write-Host "    [OK] PATH-bol eltavolitva: $PathToRemove" -ForegroundColor Green
    }
}

function Create-Shortcut([string]$Target, [string]$LinkPath, [string]$Description, [string]$WorkingDir, [string]$IconLocation) {
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($LinkPath)
    $shortcut.TargetPath = $Target
    if ($WorkingDir) { $shortcut.WorkingDirectory = $WorkingDir }
    if ($Description) { $shortcut.Description = $Description }
    if ($IconLocation -and (Test-Path $IconLocation)) { $shortcut.IconLocation = $IconLocation }
    $shortcut.Save()
    Write-Host "    [OK] Parancsikon letrehozva: $LinkPath" -ForegroundColor Green
}

function Uninstall-Pala {
    Write-Host ""
    Write-Host "Pala eltavolitasa folyamatban..." -ForegroundColor Yellow
    
    # Remove Shortcuts
    $StartShortcut = Join-Path $ProgramsFolder "Pala Desktop.lnk"
    $DesktopShortcut = Join-Path $DesktopFolder "Pala.lnk"
    $CliShortcut = Join-Path $ProgramsFolder "Pala CLI.lnk"
    
    if (Test-Path $StartShortcut) { Remove-Item $StartShortcut -Force; Write-Host "    [OK] Start menu parancsikon eltavolitva." -ForegroundColor Green }
    if (Test-Path $DesktopShortcut) { Remove-Item $DesktopShortcut -Force; Write-Host "    [OK] Asztali parancsikon eltavolitva." -ForegroundColor Green }
    if (Test-Path $CliShortcut) { Remove-Item $CliShortcut -Force; Write-Host "    [OK] CLI parancsikon eltavolitva." -ForegroundColor Green }
    
    # Remove from PATH
    Remove-PathFromUserEnv $BinDir
    
    # Remove Installation Files
    if (Test-Path $InstallBase) {
        Remove-Item -Path $InstallBase -Recurse -Force
        Write-Host "    [OK] Telepitett fajlok eltavolitva: $InstallBase" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Pala sikeresen eltavolitva a rendszerbol!" -ForegroundColor Green
    return
}

function Show-CheckboxWizard {
    param(
        [string]$Title,
        [System.Collections.Generic.List[PSObject]]$Items
    )

    $canUseRaw = $false
    try {
        if ($Host.UI.RawUI -and [Console]::WindowWidth -gt 0) {
            $canUseRaw = $true
        }
    } catch {
        $canUseRaw = $false
    }

    if (-not $canUseRaw) {
        Write-Host $Title -ForegroundColor Cyan
        Write-Host "Navigalj a szamokkal vagy fogadd el az alapertelmezettet:`n" -ForegroundColor DarkGray
        foreach ($item in $Items) {
            $def = if ($item.Selected) { "I" } else { "n" }
            $ans = Read-Host "$($item.Label) (I/n) [$def]"
            if ($ans -eq 'i' -or $ans -eq 'I' -or ($ans -eq '' -and $item.Selected)) {
                $item.Selected = $true
            } elseif ($ans -eq 'n' -or $ans -eq 'N' -or ($ans -eq '' -and -not $item.Selected)) {
                $item.Selected = $false
            }
        }
        return
    }

    $cursorIndex = 0
    $count = $Items.Count
    $startTop = [Console]::CursorTop

    $neededLines = $count + 5
    $bufferHeight = [Console]::BufferHeight
    if (($startTop + $neededLines) -ge $bufferHeight) {
        for ($i = 0; $i -lt $neededLines; $i++) { Write-Host "" }
        $startTop = [Console]::CursorTop - $neededLines
    }

    function Redraw-Checklist {
        [Console]::SetCursorPosition(0, $startTop)
        Write-Host "=============================================================" -ForegroundColor DarkYellow
        Write-Host " $Title" -ForegroundColor Yellow
        Write-Host " Hasznalat: Nyilak [Fel/Le], [SZOKOZ] kijeloles, [ENTER] megerosites" -ForegroundColor DarkGray
        Write-Host "-------------------------------------------------------------" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $count; $i++) {
            $item = $Items[$i]
            $pointer = if ($i -eq $cursorIndex) { " > " } else { "   " }
            $box = if ($item.Selected) { "[*]" } else { "[ ]" }
            
            if ($i -eq $cursorIndex) {
                Write-Host "$pointer$box " -NoNewline -ForegroundColor Yellow
                Write-Host "$($item.Label)" -ForegroundColor Yellow
            } else {
                Write-Host "$pointer$box " -NoNewline -ForegroundColor White
                Write-Host "$($item.Label)" -ForegroundColor Gray
            }
        }
        Write-Host "=============================================================" -ForegroundColor DarkYellow
    }

    try { [Console]::CursorVisible = $false } catch {}

    try {
        while ($true) {
            Redraw-Checklist
            $keyInfo = [Console]::ReadKey($true)
            switch ($keyInfo.Key) {
                ([ConsoleKey]::UpArrow) {
                    if ($cursorIndex -gt 0) { $cursorIndex-- } else { $cursorIndex = $count - 1 }
                }
                ([ConsoleKey]::DownArrow) {
                    if ($cursorIndex -lt ($count - 1)) { $cursorIndex++ } else { $cursorIndex = 0 }
                }
                ([ConsoleKey]::Spacebar) {
                    $Items[$cursorIndex].Selected = -not $Items[$cursorIndex].Selected
                }
                ([ConsoleKey]::Enter) {
                    return
                }
                ([ConsoleKey]::Escape) {
                    Write-Host "`nTelepites megszakitva." -ForegroundColor Red
                    exit 0
                }
            }
        }
    } catch {
        return
    } finally {
        try { [Console]::CursorVisible = $true } catch {}
        Write-Host ""
    }
}

if ($Uninstall) {
    Show-Banner
    Uninstall-Pala
    exit 0
}

Show-Banner

# Component selections
$InstallDesktop = $false
$InstallCli = $false
$DoAddToPath = $true
$DoStartMenu = $true
$DoDesktopIcon = $false

if ($All) {
    $InstallDesktop = $true
    $InstallCli = $true
    $DoAddToPath = $true
    $DoStartMenu = $true
    $DoDesktopIcon = $DesktopIcon.IsPresent
} elseif ($Cli) {
    $InstallCli = $true
    $DoAddToPath = $true
    $DoStartMenu = $false
} elseif ($Desktop) {
    $InstallDesktop = $true
    $DoStartMenu = $true
    $DoAddToPath = $false
} else {
    $wizardItems = [System.Collections.Generic.List[PSObject]]::new()
    $wizardItems.Add([PSCustomObject]@{ Id='desktop'; Label='Pala Desktop (Grafikus Flutter asztali alkalmazas)'; Selected=$true })
    $wizardItems.Add([PSCustomObject]@{ Id='cli';     Label='Pala CLI / TUI (Terminalos parancssori kliens)';       Selected=$true })
    $wizardItems.Add([PSCustomObject]@{ Id='path';    Label='Hozzaadas a PATH kornyezeti valtozohoz';             Selected=$true })
    $wizardItems.Add([PSCustomObject]@{ Id='start';   Label='Start menu parancsikon letrehozasa';                 Selected=$true })
    $wizardItems.Add([PSCustomObject]@{ Id='deskicon';Label='Asztali parancsikon letrehozasa';                  Selected=$false })

    Show-CheckboxWizard -Title "Pala Telepito Varazslo — Komponensek kivalasztasa" -Items $wizardItems

    $InstallDesktop = ($wizardItems | Where-Object { $_.Id -eq 'desktop' }).Selected
    $InstallCli     = ($wizardItems | Where-Object { $_.Id -eq 'cli' }).Selected
    $DoAddToPath    = ($wizardItems | Where-Object { $_.Id -eq 'path' }).Selected
    $DoStartMenu    = ($wizardItems | Where-Object { $_.Id -eq 'start' }).Selected
    $DoDesktopIcon  = ($wizardItems | Where-Object { $_.Id -eq 'deskicon' }).Selected
}

if (-not $InstallDesktop -and -not $InstallCli) {
    Write-Host "Nem valasztottal ki egyetlen komponenst sem a telepiteshez. Kilepes." -ForegroundColor Yellow
    exit 0
}

# Resolve version
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "Legfrissebb verzio keresese..." -ForegroundColor DarkGray
    try {
        $ReleaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -TimeoutSec 5 -ErrorAction Stop
        $Version = $ReleaseData.tag_name
    } catch {
        $Version = "latest"
    }
}
Write-Host "Telepitendo verzio: $Version" -ForegroundColor Cyan
Write-Host ""

# Create directories
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
if ($InstallDesktop) {
    New-Item -ItemType Directory -Path $DesktopDir -Force | Out-Null
}

$RepoRoot = $PSScriptRoot
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

# 1. Desktop Installation
if ($InstallDesktop) {
    Write-Host "[+] Pala Desktop telepitese..." -ForegroundColor Yellow
    
    $LocalDesktopExe = "$RepoRoot\app\build\windows\x64\runner\Release\pala.exe"
    $DestDesktopExe = Join-Path $DesktopDir "pala.exe"
    
    if (Test-Path $LocalDesktopExe) {
        $ReleaseDir = Split-Path -Parent $LocalDesktopExe
        Copy-Item -Path "$ReleaseDir\*" -Destination $DesktopDir -Recurse -Force
        Write-Host "    [OK] Helyi asztali alkalmazas masolva ide: $DesktopDir" -ForegroundColor Green
    } else {
        $SetupUrl = if ($Version -eq "latest") {
            "https://github.com/$Repo/releases/latest/download/Pala-Setup.exe"
        } else {
            "https://github.com/$Repo/releases/download/$Version/Pala-Setup.exe"
        }
        $TempSetup = Join-Path $env:TEMP "Pala-Setup.exe"
        Write-Host "    Letoltes: $SetupUrl" -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri $SetupUrl -OutFile $TempSetup -TimeoutSec 120
            Write-Host "    [+] Asztali alkalmazas telepitese a hatterben..." -ForegroundColor Yellow
            $proc = Start-Process -FilePath $TempSetup -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" -Wait -PassThru
            if ($proc.ExitCode -eq 0) {
                Write-Host "    [OK] Pala Desktop sikeresen telepitve!" -ForegroundColor Green
            } else {
                Write-Host "    [!] A telepito kilepesi kodja: $($proc.ExitCode)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "    [!] Figyelem: A Pala-Setup.exe letoltese sikertelen: $_" -ForegroundColor Red
        } finally {
            if (Test-Path $TempSetup) { Remove-Item $TempSetup -Force -ErrorAction SilentlyContinue }
        }
    }
}

# 2. CLI Installation
if ($InstallCli) {
    Write-Host "[+] Pala CLI / TUI telepitese..." -ForegroundColor Yellow
    $LocalCli = Join-Path $RepoRoot "pala.exe"
    $DestCli = Join-Path $BinDir "pala.exe"
    
    if (Test-Path $LocalCli) {
        Copy-Item -Path $LocalCli -Destination $DestCli -Force
        Write-Host "    [OK] Helyi pala.exe masolva ide: $DestCli" -ForegroundColor Green
    } else {
        $CliDownloadUrl = if ($Version -eq "latest") {
            "https://github.com/$Repo/releases/latest/download/pala.exe"
        } else {
            "https://github.com/$Repo/releases/download/$Version/pala.exe"
        }
        Write-Host "    Letoltes: $CliDownloadUrl" -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri $CliDownloadUrl -OutFile $DestCli -TimeoutSec 60
            Write-Host "    [OK] Letoltve es telepitve: $DestCli" -ForegroundColor Green
        } catch {
            Write-Host "    [!] Figyelem: A CLI binaris letoltese sikertelen: $_" -ForegroundColor Red
        }
    }
    
    if ($DoAddToPath) {
        Add-PathToUserEnv $BinDir
    }
}

# 3. Shortcuts
$InstalledDesktopExe = Join-Path $env:LOCALAPPDATA "Programs\Pala\pala.exe"
if (-not (Test-Path $InstalledDesktopExe)) {
    $InstalledDesktopExe = Join-Path $DesktopDir "pala.exe"
}
$InstalledCliExe = Join-Path $BinDir "pala.exe"

if ($DoStartMenu) {
    if ($InstallDesktop -and (Test-Path $InstalledDesktopExe)) {
        Create-Shortcut -Target $InstalledDesktopExe -LinkPath (Join-Path $ProgramsFolder "Pala Desktop.lnk") -Description "Pala Desktop — Modern Kreta Kliens"
    }
    if ($InstallCli -and (Test-Path $InstalledCliExe)) {
        Create-Shortcut -Target $InstalledCliExe -LinkPath (Join-Path $ProgramsFolder "Pala CLI.lnk") -Description "Pala CLI — Terminalos Kreta Kliens"
    }
}

if ($DoDesktopIcon) {
    $TargetExe = if ($InstallDesktop -and (Test-Path $InstalledDesktopExe)) { $InstalledDesktopExe } else { $InstalledCliExe }
    if (Test-Path $TargetExe) {
        Create-Shortcut -Target $TargetExe -LinkPath (Join-Path $DesktopFolder "Pala.lnk") -Description "Pala — Modern Kreta Kliens"
    }
}

# Save uninstaller helper into install directory
$UninstallScript = Join-Path $InstallBase "uninstall.ps1"
@"
Write-Host "Pala eltavolitasa..." -ForegroundColor Yellow
`$ProgramsFolder = [Environment]::GetFolderPath('Programs')
`$DesktopFolder = [Environment]::GetFolderPath('Desktop')
Remove-Item -Path (Join-Path `$ProgramsFolder "Pala Desktop.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path `$ProgramsFolder "Pala CLI.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path `$DesktopFolder "Pala.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path `$DesktopFolder "Pala Desktop.lnk") -Force -ErrorAction SilentlyContinue
`$CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if (`$CurrentPath) {
    `$Parts = `$CurrentPath.Split(';') | Where-Object { `$_ -ne "" -and `$_ -ne "$BinDir" }
    [Environment]::SetEnvironmentVariable("Path", (`$Parts -join ';'), [EnvironmentVariableTarget]::User)
}
Remove-Item -Path "$InstallBase" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Pala sikeresen eltavolitva!" -ForegroundColor Green
"@ | Set-Content -Path $UninstallScript -Encoding utf8

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " A telepites es beallitas sikeresen befejezodott!" -ForegroundColor Green
Write-Host " Inditas: " -ForegroundColor White
if ($InstallCli) {
    Write-Host "   - Terminalban:       pala" -ForegroundColor Cyan
}
if ($InstallDesktop) {
    Write-Host "   - Start menubol:     Pala Desktop" -ForegroundColor Cyan
}
Write-Host " Eltavolitas barmikor:   $UninstallScript" -ForegroundColor DarkGray
Write-Host "=============================================================" -ForegroundColor Green
