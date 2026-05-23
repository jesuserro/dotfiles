param(
  [Parameter(Mandatory = $true)]
  [string]$RunDir
)

$ErrorActionPreference = "Continue"
$LogDir = Join-Path $RunDir "logs"
$ResultFile = Join-Path $RunDir "windows-results.tsv"
$DoneFile = Join-Path $RunDir "windows.done"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Set-Content -Path $ResultFile -Value "" -Encoding UTF8

function Add-Result {
  param([string]$Status, [string]$Name, [string]$Message)
  Add-Content -Path $ResultFile -Value "$Status`tWindows`t$Name`t$Message" -Encoding UTF8
}

function Run-Logged {
  param([string]$Name, [string]$LogName, [scriptblock]$Block)
  $log = Join-Path $LogDir $LogName
  $start = Get-Date
  $code = $null
  try {
    & $Block *> $log
    $code = if ($LASTEXITCODE -ne $null) { [int]$LASTEXITCODE } else { 0 }
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    if ($code -eq 0) {
      Add-Result "OK" $Name "completed in ${elapsed}s; log: $log"
    } else {
      Add-Result "WARN" $Name "exit $code in ${elapsed}s; log: $log"
    }
  } catch {
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    $_ | Out-File -FilePath $log -Append -Encoding UTF8
    Add-Result "WARN" $Name "exception in ${elapsed}s: $($_.Exception.Message); log: $log"
  }
  $script:LastRunLog = $log
  $script:LastRunCode = $code
}

function Add-WinGetPackageResults {
  param([string]$LogPath)
  if (-not (Test-Path $LogPath)) { return }
  $text = Get-Content -Path $LogPath -Raw -ErrorAction SilentlyContinue
  if ([string]::IsNullOrWhiteSpace($text)) { return }

  $currentName = $null
  $currentId = $null
  $foundAny = $false
  foreach ($line in ($text -split "`r?`n")) {
    if ($line -match '^\(\d+/\d+\)\s+(?:Encontrado|Found)\s+(.+?)\s+\[([^\]]+)\]') {
      $currentName = $Matches[1].Trim()
      $currentId = $Matches[2].Trim()
      continue
    }
    if ($currentName -and $line -match '(?:c[oó]digo de salida|exit code):\s*(-?\d+)') {
      Add-Result "WARN" "WinGet package $currentName [$currentId]" "upgrade failed with code $($Matches[1])"
      $foundAny = $true
      $currentName = $null
      $currentId = $null
      continue
    }
    if ($currentName -and $line -match '(?:Se instal[oó] correctamente|Successfully installed|Successfully updated)') {
      Add-Result "OK" "WinGet package $currentName [$currentId]" "updated successfully"
      $foundAny = $true
      $currentName = $null
      $currentId = $null
      continue
    }
  }
  if ((-not $foundAny) -and ($script:LastRunCode -ne 0)) {
    Add-Result "WARN" "WinGet package details" "could not parse package-level results; see log: $LogPath"
  }
}

Write-Host "Dotfiles Windows update"
Write-Host "Run directory: $RunDir"

if (Get-Command winget -ErrorAction SilentlyContinue) {
  Run-Logged "WinGet sources" "windows-winget-source.log" { winget source update }
  Run-Logged "WinGet packages" "windows-winget-upgrade.log" {
    winget upgrade --all --include-unknown --silent --accept-package-agreements --accept-source-agreements
  }
  Add-WinGetPackageResults $script:LastRunLog
} else {
  Add-Result "WARN" "WinGet" "winget not found on Windows PATH"
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
  Run-Logged "WSL status" "windows-wsl-status.log" { wsl --status; wsl --version }
  Run-Logged "WSL update" "windows-wsl-update.log" { wsl --update }
  Add-Result "INFO" "WSL restart" "If WSL reports a pending restart, run later from PowerShell after this WSL session: wsl --shutdown"
} else {
  Add-Result "WARN" "WSL update" "wsl command not found on Windows PATH"
}

New-Item -ItemType File -Force -Path $DoneFile | Out-Null
Write-Host "Windows update finished. Result: $ResultFile"
