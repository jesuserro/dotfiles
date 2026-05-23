param(
  [string]$RunDir = "",
  [switch]$SelfTestNativeArguments
)

$ErrorActionPreference = "Continue"
if ([string]::IsNullOrWhiteSpace($RunDir)) {
  if ($SelfTestNativeArguments) {
    $RunDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-update-native-args-" + [System.Guid]::NewGuid().ToString("N"))
  } else {
    throw "RunDir is required"
  }
}
$LogDir = Join-Path $RunDir "logs"
$ResultFile = Join-Path $RunDir "windows-results.tsv"
$DoneFile = Join-Path $RunDir "windows.done"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Set-Content -Path $ResultFile -Value "" -Encoding UTF8
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)

function Add-Result {
  param([string]$Status, [string]$Name, [string]$Message)
  Add-Content -Path $ResultFile -Value "$Status`tWindows`t$Name`t$Message" -Encoding UTF8
}

function Join-NativeArguments {
  param([string[]]$NativeArguments)
  $quoted = @()
  foreach ($arg in $NativeArguments) {
    if ($arg -match '[\s"]') {
      $quoted += '"' + ($arg -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
    } else {
      $quoted += $arg
    }
  }
  return ($quoted -join ' ')
}

function Get-NativeEncoding {
  param([string]$EncodingName)
  switch ($EncodingName) {
    "unicode" { return [System.Text.Encoding]::Unicode }
    "utf8" { return [System.Text.UTF8Encoding]::new($false) }
    default { return [System.Text.UTF8Encoding]::new($false) }
  }
}

function Run-NativeLogged {
  param(
    [string]$Name,
    [string]$LogName,
    [string]$FileName,
    [string[]]$NativeArguments,
    [string]$OutputEncoding = "utf8"
  )
  $log = Join-Path $LogDir $LogName
  $start = Get-Date
  $encoding = Get-NativeEncoding $OutputEncoding
  $argumentString = Join-NativeArguments -NativeArguments $NativeArguments
  Write-Host ""
  Write-Host "==> $Name"
  if (($NativeArguments.Count -gt 0) -and [string]::IsNullOrWhiteSpace($argumentString)) {
    $message = "native arguments were not serialized; refusing to run $FileName without expected arguments"
    [System.IO.File]::WriteAllText($log, $message, [System.Text.UTF8Encoding]::new($false))
    Write-Host $message
    Add-Result "WARN" $Name "$message; log: $log"
    $script:LastRunLog = $log
    $script:LastRunCode = $null
    return
  }
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $FileName
  $psi.Arguments = $argumentString
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.StandardOutputEncoding = $encoding
  $psi.StandardErrorEncoding = $encoding
  $psi.CreateNoWindow = $true
  try {
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.Result
    $stderr = $stderrTask.Result
    $code = [int]$process.ExitCode
    $content = (($stdout, $stderr) | Where-Object { -not [string]::IsNullOrEmpty($_) }) -join [Environment]::NewLine
    $content = $content -replace "`r`n", "`n" -replace "`r", "`n"
    [System.IO.File]::WriteAllText($log, $content, [System.Text.UTF8Encoding]::new($false))
    if (-not [string]::IsNullOrWhiteSpace($content)) {
      Write-Host $content
    }
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    if ($code -eq 0) {
      Add-Result "OK" $Name "completed in ${elapsed}s; log: $log"
      Write-Host "OK $Name (${elapsed}s)"
    } else {
      Add-Result "WARN" $Name "exit $code in ${elapsed}s; log: $log"
      Write-Host "WARN $Name exit $code (${elapsed}s); log: $log"
    }
  } catch {
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    [System.IO.File]::WriteAllText($log, $_.Exception.ToString(), [System.Text.UTF8Encoding]::new($false))
    Add-Result "WARN" $Name "exception in ${elapsed}s: $($_.Exception.Message); log: $log"
    Write-Host "WARN $Name exception in ${elapsed}s: $($_.Exception.Message); log: $log"
    $code = $null
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

if ($SelfTestNativeArguments) {
  Write-Host "Dotfiles Windows update native argument self-test"
  Write-Host "Run directory: $RunDir"
  $separator = [char]31
  $echoScript = Join-Path $RunDir "echo-native-args.ps1"
  [System.IO.File]::WriteAllText($echoScript, 'Write-Output ($args -join [char]31)', [System.Text.UTF8Encoding]::new($false))
  Run-NativeLogged "Argument self-test source" "native-args-source.log" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $echoScript, "source", "update", "value with spaces", 'quote"inside') "utf8"
  Run-NativeLogged "Argument self-test status" "native-args-status.log" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $echoScript, "--status") "utf8"
  $sourceLog = Get-Content -Path (Join-Path $LogDir "native-args-source.log") -Raw
  $statusLog = Get-Content -Path (Join-Path $LogDir "native-args-status.log") -Raw
  $sourceExpected = "source${separator}update${separator}value with spaces${separator}quote`"inside"
  if (($sourceLog -notlike "*$sourceExpected*") -or ($statusLog -notlike "*--status*")) {
    Add-Result "WARN" "Argument self-test" "native arguments did not reach child process"
    New-Item -ItemType File -Force -Path $DoneFile | Out-Null
    Write-Host "WARN native argument self-test failed"
    exit 64
  }
  Add-Result "OK" "Argument self-test" "native arguments reached child process"
  New-Item -ItemType File -Force -Path $DoneFile | Out-Null
  Write-Host "OK native argument self-test passed"
  exit 0
}

Write-Host "Dotfiles Windows update"
Write-Host "Run directory: $RunDir"

if (Get-Command winget -ErrorAction SilentlyContinue) {
  Run-NativeLogged "WinGet sources" "windows-winget-source.log" "winget" @("source", "update") "utf8"
  Run-NativeLogged "WinGet packages" "windows-winget-upgrade.log" "winget" @("upgrade", "--all", "--include-unknown", "--silent", "--accept-package-agreements", "--accept-source-agreements") "utf8"
  Add-WinGetPackageResults $script:LastRunLog
} else {
  Add-Result "WARN" "WinGet" "winget not found on Windows PATH"
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
  Run-NativeLogged "WSL status" "windows-wsl-status.log" "wsl" @("--status") "unicode"
  Run-NativeLogged "WSL update" "windows-wsl-update.log" "wsl" @("--update") "unicode"
  Add-Result "INFO" "WSL restart" "If WSL reports a pending restart, run later from PowerShell after this WSL session: wsl --shutdown"
} else {
  Add-Result "WARN" "WSL update" "wsl command not found on Windows PATH"
}

New-Item -ItemType File -Force -Path $DoneFile | Out-Null
Write-Host ""
Write-Host "==> Windows summary"
Get-Content -Path $ResultFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Write-Host $_ }
Write-Host "Windows update finished. Result: $ResultFile"
