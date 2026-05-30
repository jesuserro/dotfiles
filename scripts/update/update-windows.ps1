param(
  [string]$RunDir = "",
  [switch]$SelfTestNativeArguments,
  [switch]$SelfTestWinGetConsoleText
)

$ErrorActionPreference = "Continue"
if ([string]::IsNullOrWhiteSpace($RunDir)) {
  if ($SelfTestNativeArguments -or $SelfTestWinGetConsoleText) {
    $RunDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-update-native-args-" + [System.Guid]::NewGuid().ToString("N"))
  } else {
    throw "RunDir is required"
  }
}
$LogDir = Join-Path $RunDir "logs"
$ResultFile = Join-Path $RunDir "windows-results.tsv"
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
    [string]$OutputEncoding = "utf8",
    [bool]$DisplayOutput = $true,
    [bool]$DisplayStep = $true
  )
  $log = Join-Path $LogDir $LogName
  $start = Get-Date
  $encoding = Get-NativeEncoding $OutputEncoding
  $argumentString = Join-NativeArguments -NativeArguments $NativeArguments
  if ($DisplayStep) {
    Write-Host ""
    Write-Host "==> $Name"
  }
  if (($NativeArguments.Count -gt 0) -and [string]::IsNullOrWhiteSpace($argumentString)) {
    $message = "native arguments were not serialized; refusing to run $FileName without expected arguments"
    [System.IO.File]::WriteAllText($log, $message, [System.Text.UTF8Encoding]::new($false))
    if ($DisplayStep) { Write-Host $message }
    Add-Result "WARN" $Name "$message; log: $log"
    $script:LastRunLog = $log
    $script:LastRunCode = $null
    $script:LastRunContent = $message
    $script:LastRunElapsed = 0
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
    if ($DisplayOutput -and (-not [string]::IsNullOrWhiteSpace($content))) {
      Write-Host $content
    }
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    if ($code -eq 0) {
      Add-Result "OK" $Name "completed in ${elapsed}s; log: $log"
      if ($DisplayStep) { Write-Host "OK $Name (${elapsed}s)" }
    } else {
      Add-Result "WARN" $Name "exit $code in ${elapsed}s; log: $log"
      if ($DisplayStep) { Write-Host "WARN $Name exit $code (${elapsed}s); log: $log" }
    }
  } catch {
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    [System.IO.File]::WriteAllText($log, $_.Exception.ToString(), [System.Text.UTF8Encoding]::new($false))
    Add-Result "WARN" $Name "exception in ${elapsed}s: $($_.Exception.Message); log: $log"
    if ($DisplayStep) { Write-Host "WARN $Name exception in ${elapsed}s: $($_.Exception.Message); log: $log" }
    $code = $null
  }
  $script:LastRunLog = $log
  $script:LastRunCode = $code
  $script:LastRunContent = if ($null -eq $content) { "" } else { $content }
  $script:LastRunElapsed = $elapsed
}

function Get-WinGetConsoleText {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
  $lines = New-Object System.Collections.Generic.List[string]
  $normalized = $Text -replace "`r", "`n"
  foreach ($rawLine in ($normalized -split "`n")) {
    $line = ($rawLine -replace "`e\[[0-9;?]*[ -/]*[@-~]", "").TrimEnd()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^\s*[-\\|/]\s*$') { continue }
    if (($line.IndexOf([char]0x2588) -ge 0) -or ($line.IndexOf([char]0x2592) -ge 0) -or ($line.IndexOf([char]0x2593) -ge 0) -or ($line.IndexOf([char]0x2591) -ge 0)) { continue }
    if ($line -match '^\s*[#=]{5,}') { continue }
    if ($line -match '^\s*\d+(\.\d+)?\s*(B|KB|MB|GB)\s*/\s*\d+(\.\d+)?\s*(B|KB|MB|GB)') { continue }
    if ($line -match '^\s*\d{1,3}%\s*$') { continue }
    $lines.Add($line)
  }
  return ($lines -join [Environment]::NewLine)
}

function Write-WinGetListStatus {
  param([string]$Name)
  $elapsed = if ($null -eq $script:LastRunElapsed) { 0 } else { $script:LastRunElapsed }
  if ($script:LastRunCode -eq 0) {
    Write-Host "OK $Name (${elapsed}s)"
  } else {
    Write-Host "WARN $Name exit $script:LastRunCode (${elapsed}s); log: $script:LastRunLog"
  }
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
    Write-Host "WARN native argument self-test failed"
    exit 64
  }
  Add-Result "OK" "Argument self-test" "native arguments reached child process"
  Write-Host "OK native argument self-test passed"
  exit 0
}

if ($SelfTestWinGetConsoleText) {
  $sample = @"
-
\
|
/

Name             Id              Version Available Source
Pandoc           John.Pandoc     1.0     2.0       winget

-
"@
  $filtered = Get-WinGetConsoleText $sample
  Write-Host $filtered
  if (($filtered -match '(?m)^\s*[-\\|/]\s*$') -or ($filtered -notlike "*Pandoc*")) {
    Add-Result "WARN" "WinGet console text self-test" "spinner filtering failed"
    exit 65
  }
  Add-Result "OK" "WinGet console text self-test" "spinner filtering passed"
  Write-Host "OK WinGet console text self-test passed"
  exit 0
}

Write-Host "Dotfiles Windows update"
Write-Host "Run directory: $RunDir"

if (Get-Command winget -ErrorAction SilentlyContinue) {
  Run-NativeLogged "WinGet sources" "windows-winget-source.log" "winget" @("source", "update") "utf8" $false
  Write-Host "Full WinGet source log: $script:LastRunLog"

  $winGetListName = "WinGet packages to upgrade"
  Run-NativeLogged $winGetListName "windows-winget-list.log" "winget" @("upgrade", "--include-unknown", "--accept-source-agreements", "--disable-interactivity") "utf8" $false $false
  Write-Host ""
  Write-Host "==> $winGetListName"
  $packageTable = Get-WinGetConsoleText $script:LastRunContent
  if ([string]::IsNullOrWhiteSpace($packageTable)) {
    Write-Host "(no package list output; see log: $script:LastRunLog)"
  } else {
    Write-Host $packageTable
  }
  Write-WinGetListStatus $winGetListName
  Write-Host "Full WinGet package list log: $script:LastRunLog"

  Run-NativeLogged "WinGet packages" "windows-winget-upgrade.log" "winget" @("upgrade", "--all", "--include-unknown", "--silent", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity") "utf8" $false
  Write-Host "Full WinGet upgrade log: $script:LastRunLog"
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

Write-Host ""
Write-Host "==> Windows summary"
Get-Content -Path $ResultFile | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { Write-Host $_ }
Write-Host "Windows update finished. Result: $ResultFile"
