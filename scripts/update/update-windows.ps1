param(
  [string]$RunDir = "",
  [switch]$SelfTestNativeArguments,
  [switch]$SelfTestWinGetConsoleText,
  [switch]$SelfTestWinGetPackageResults,
  [switch]$SelfTestLiveLogging
)

$ErrorActionPreference = "Continue"
if ([string]::IsNullOrWhiteSpace($RunDir)) {
  if ($SelfTestNativeArguments -or $SelfTestWinGetConsoleText -or $SelfTestWinGetPackageResults -or $SelfTestLiveLogging) {
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

function Get-WinGetConsoleLine {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  $line = ($Text -replace "`e\[[0-9;?]*[ -/]*[@-~]", "").TrimEnd()
  if ([string]::IsNullOrWhiteSpace($line)) { return $null }
  if ($line -match '^\s*[-\\|/]\s*$') { return $null }
  if ($line -match '^\s*[\u2588\u2592\s]+(?:\d{1,3}%\s*)?$') { return $null }
  if ($line -match '(?i)(Updating (?:all sources|source)|Actualizando (?:todos los or(?:i|\u00ed)genes|origen)|Done|Listo|Encontrado|Found|Descargando|Downloading|El hash del instalador se verific(?:o|\u00f3) correctamente|Installer hash|Iniciando instalaci(?:o|\u00f3)n|Installing|Iniciando la desinstalaci(?:o|\u00f3)n|Uninstalling|Instalado correctamente|Se instal(?:o|\u00f3) correctamente|Successfully installed|Successfully updated|Error|failed|exit code|c(?:o|\u00f3)digo de salida|actualizaciones disponibles|upgrades available)') {
    return $line
  }
  return $null
}

function Invoke-NativeLiveProcess {
  param(
    [string]$FileName,
    [string[]]$NativeArguments,
    [string]$LogPath,
    [string]$OutputEncoding = "utf8",
    [scriptblock]$ConsoleLineFilter = $null
  )
  $encoding = Get-NativeEncoding $OutputEncoding
  $argumentString = Join-NativeArguments -NativeArguments $NativeArguments
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $FileName
  $psi.Arguments = $argumentString
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.StandardOutputEncoding = $encoding
  $psi.StandardErrorEncoding = $encoding
  $psi.CreateNoWindow = $true

  $writer = [System.IO.StreamWriter]::new($LogPath, $false, [System.Text.UTF8Encoding]::new($false))
  try {
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdoutDone = $false
    $stderrDone = $false
    $stdoutTask = $process.StandardOutput.ReadLineAsync()
    $stderrTask = $process.StandardError.ReadLineAsync()
    while ((-not $stdoutDone) -or (-not $stderrDone)) {
      $activeTasks = @()
      if (-not $stdoutDone) { $activeTasks += $stdoutTask }
      if (-not $stderrDone) { $activeTasks += $stderrTask }
      if ($activeTasks.Count -eq 0) { break }
      [void][System.Threading.Tasks.Task]::WaitAny($activeTasks, 100)

      if ((-not $stdoutDone) -and $stdoutTask.IsCompleted) {
        $line = $stdoutTask.Result
        if ($null -eq $line) {
          $stdoutDone = $true
        } else {
          $writer.WriteLine($line)
          $writer.Flush()
          $displayLine = if ($null -eq $ConsoleLineFilter) { $line } else { & $ConsoleLineFilter $line }
          if (-not [string]::IsNullOrWhiteSpace($displayLine)) { Write-Host $displayLine }
          $stdoutTask = $process.StandardOutput.ReadLineAsync()
        }
      }
      if ((-not $stderrDone) -and $stderrTask.IsCompleted) {
        $line = $stderrTask.Result
        if ($null -eq $line) {
          $stderrDone = $true
        } else {
          $writer.WriteLine($line)
          $writer.Flush()
          $displayLine = if ($null -eq $ConsoleLineFilter) { $line } else { & $ConsoleLineFilter $line }
          if (-not [string]::IsNullOrWhiteSpace($displayLine)) { Write-Host $displayLine }
          $stderrTask = $process.StandardError.ReadLineAsync()
        }
      }
    }
    $process.WaitForExit()
    return [int]$process.ExitCode
  } finally {
    $writer.Dispose()
    if ($null -ne $process) { $process.Dispose() }
  }
}

function Invoke-WinGetLiveFiltered {
  param(
    [string[]]$NativeArguments,
    [string]$LogPath,
    [string]$OutputEncoding = "utf8",
    [string]$FileName = "winget"
  )
  return Invoke-NativeLiveProcess -FileName $FileName -NativeArguments $NativeArguments -LogPath $LogPath -OutputEncoding $OutputEncoding -ConsoleLineFilter { param($line) Get-WinGetConsoleLine $line }
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

function Run-NativeLiveLogged {
  param(
    [string]$Name,
    [string]$LogName,
    [string]$FileName,
    [string[]]$NativeArguments,
    [string]$OutputEncoding = "utf8",
    [string]$StartMessage = "",
    [bool]$FilterWinGetConsole = $false
  )
  $log = Join-Path $LogDir $LogName
  $start = Get-Date
  $encoding = Get-NativeEncoding $OutputEncoding
  $argumentString = Join-NativeArguments -NativeArguments $NativeArguments
  Write-Host ""
  Write-Host "==> $Name"
  if (-not [string]::IsNullOrWhiteSpace($StartMessage)) {
    Write-Host $StartMessage
  }
  Write-Host "Full log: $log"
  if (($NativeArguments.Count -gt 0) -and [string]::IsNullOrWhiteSpace($argumentString)) {
    $message = "native arguments were not serialized; refusing to run $FileName without expected arguments"
    [System.IO.File]::WriteAllText($log, $message, [System.Text.UTF8Encoding]::new($false))
    Write-Host $message
    Add-Result "WARN" $Name "$message; log: $log"
    $script:LastRunLog = $log
    $script:LastRunCode = $null
    $script:LastRunContent = $message
    $script:LastRunElapsed = 0
    return
  }

  $script:LiveRunCode = $null
  try {
    if ($FilterWinGetConsole) {
      $code = Invoke-WinGetLiveFiltered -FileName $FileName -NativeArguments $NativeArguments -LogPath $log -OutputEncoding $OutputEncoding
    } else {
      $code = Invoke-NativeLiveProcess -FileName $FileName -NativeArguments $NativeArguments -LogPath $log -OutputEncoding $OutputEncoding
    }
    $content = if (Test-Path $log) { Get-Content -Path $log -Raw -ErrorAction SilentlyContinue } else { "" }
    $content = $content -replace "`r`n", "`n" -replace "`r", "`n"
    [System.IO.File]::WriteAllText($log, $content, $encoding)
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
    $content = $_.Exception.ToString()
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
    if ($line -match '^\s*[\u2588\u2592\s]+(?:\d{1,3}%\s*)?$') { continue }
    if ($line -match '^\s*[#=]{5,}') { continue }
    if ($line -match '^\s*\d+(\.\d+)?\s*(B|KB|MB|GB)\s*/\s*\d+(\.\d+)?\s*(B|KB|MB|GB)') { continue }
    if ($line -match '^\s*\d{1,3}%\s*$') { continue }
    $lines.Add($line)
  }
  return ($lines -join [Environment]::NewLine)
}

function Get-WinGetUpgradeCount {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return 0 }

  $normalized = $Text -replace "`r", "`n"
  foreach ($rawLine in ($normalized -split "`n")) {
    if ($rawLine -match '(?i)^\s*(\d+)\s+(?:upgrades?|actualizaci(?:o|\u00f3)n(?:es)?)\s+(?:available|disponible(?:s)?)') {
      return [int]$Matches[1]
    }
  }

  $afterSeparator = $false
  $count = 0
  foreach ($rawLine in ($normalized -split "`n")) {
    $line = $rawLine.Trim()
    if ($line -match '^-{3,}$') {
      $afterSeparator = $true
      continue
    }
    if (-not $afterSeparator) { continue }
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '(?i)^(No installed package found|No se encontr(?:o|\u00f3)|No hay actualizaciones)') { break }
    $count++
  }
  return $count
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
    if ($currentName -and $line -match '(?:c(?:o|\u00f3)digo de salida|exit code):\s*(-?\d+)') {
      Add-Result "WARN" "WinGet package $currentName [$currentId]" "upgrade failed with code $($Matches[1])"
      $foundAny = $true
      $currentName = $null
      $currentId = $null
      continue
    }
    if ($currentName -and $line -match '(?:Se instal(?:o|\u00f3) correctamente|Successfully installed|Successfully updated)') {
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

function Get-NonEmptyLines {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return @() }
  return @(Get-Content -Path $Path -ErrorAction Stop | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Assert-LinesEqual {
  param(
    [string]$Name,
    [string[]]$Expected,
    [string[]]$Actual
  )
  if ($Expected.Count -ne $Actual.Count) {
    Write-Host "WARN $Name line count mismatch: expected $($Expected.Count), got $($Actual.Count)"
    Write-Host "Expected:"
    $Expected | ForEach-Object { Write-Host "  $_" }
    Write-Host "Actual:"
    $Actual | ForEach-Object { Write-Host "  $_" }
    return $false
  }
  for ($i = 0; $i -lt $Expected.Count; $i++) {
    if ($Expected[$i] -ne $Actual[$i]) {
      Write-Host "WARN $Name mismatch at line $($i + 1)"
      Write-Host "Expected: $($Expected[$i])"
      Write-Host "Actual:   $($Actual[$i])"
      return $false
    }
  }
  return $true
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

if ($SelfTestWinGetPackageResults) {
  Write-Host "Dotfiles Windows update WinGet package parser self-test"
  Write-Host "Run directory: $RunDir"
  $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "../..")
  $fixtureDir = Join-Path $repoRoot "tests/fixtures/winget"
  $cases = @("english-success", "english-failure", "spanish-mixed", "unknown")
  foreach ($caseName in $cases) {
    $log = Join-Path $fixtureDir "${caseName}.log"
    $expected = Join-Path $fixtureDir "${caseName}.expected.tsv"
    if ((-not (Test-Path $log)) -or (-not (Test-Path $expected))) {
      Add-Result "WARN" "WinGet package parser self-test" "missing fixture for ${caseName}"
      Write-Host "WARN missing fixture for ${caseName}"
      exit 67
    }
    Set-Content -Path $ResultFile -Value "" -Encoding UTF8
    $script:LastRunCode = 0
    Add-WinGetPackageResults $log
    $actualLines = Get-NonEmptyLines $ResultFile
    $expectedLines = Get-NonEmptyLines $expected
    if (-not (Assert-LinesEqual $caseName $expectedLines $actualLines)) {
      Add-Result "WARN" "WinGet package parser self-test" "${caseName} fixture mismatch"
      exit 67
    }
    Write-Host "OK ${caseName}"
  }
  Set-Content -Path $ResultFile -Value "" -Encoding UTF8
  Add-Result "OK" "WinGet package parser self-test" "fixtures matched"
  Write-Host "OK WinGet package parser self-test passed"
  exit 0
}

if ($SelfTestWinGetConsoleText) {
  $shade = [string]([char]0x2592)
  $block = [string]([char]0x2588)
  $oAcute = [string]([char]0x00f3)
  $sample = @(
    "-"
    "\"
    "|"
    "/"
    ($shade * 10)
    (($block * 10) + " 40%")
    ""
    "Name             Id              Version Available Source"
    "Pandoc           John.Pandoc     1.0     2.0       winget"
    "Updating source: winget"
    "Done"
    "(1/2) Encontrado Pandoc [JohnMacFarlane.Pandoc]"
    "Descargando https://example.invalid/pandoc.msi"
    "El hash del instalador se verific${oAcute} correctamente"
    "Iniciando instalaci${oAcute}n..."
    "C${oAcute}digo de salida del instalador: 1603"
    "(2/2) Found Cursor [Anysphere.Cursor]"
    "Downloading https://example.invalid/cursor.exe"
    "Installer hash verified successfully"
    "Installing..."
    "Successfully installed"
    ""
    "-"
  ) -join [Environment]::NewLine
  $filtered = Get-WinGetConsoleText $sample
  $eventLines = ($sample -replace "`r", "`n" -split "`n" | ForEach-Object { Get-WinGetConsoleLine $_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join [Environment]::NewLine
  $englishCount = Get-WinGetUpgradeCount "2 upgrades available."
  $spanishCount = Get-WinGetUpgradeCount "3 actualizaciones disponibles."
  Write-Host $filtered
  Write-Host $eventLines
  if (($filtered -match '(?m)^\s*[-\\|/]\s*$') -or ($filtered -match '[\u2588\u2592]') -or ($eventLines -match '(?m)^\s*[-\\|/]\s*$') -or ($eventLines -match '[\u2588\u2592]') -or ($filtered -notlike "*Pandoc*") -or ($eventLines -notlike "*Updating source*") -or ($eventLines -notlike "*1603*") -or ($eventLines -notlike "*Cursor*") -or ($eventLines -notlike "*Successfully installed*") -or ($englishCount -ne 2) -or ($spanishCount -ne 3)) {
    Add-Result "WARN" "WinGet console text self-test" "spinner filtering failed"
    exit 65
  }
  Add-Result "OK" "WinGet console text self-test" "spinner filtering passed"
  Write-Host "OK WinGet console text self-test passed"
  exit 0
}

if ($SelfTestLiveLogging) {
  Write-Host "Dotfiles Windows update live logging self-test"
  Write-Host "Run directory: $RunDir"
  $emitScript = Join-Path $RunDir "emit-live-output.ps1"
  [System.IO.File]::WriteAllText($emitScript, 'Write-Output "live-first"; Start-Sleep -Seconds 2; Write-Output "live-second"; exit 23', [System.Text.UTF8Encoding]::new($false))
  Run-NativeLiveLogged "Live logging self-test" "native-live.log" "powershell.exe" @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $emitScript) "utf8" "Updating 2 packages with WinGet..."
  if (($script:LastRunCode -ne 23) -or ($script:LastRunContent -notlike "*live-first*") -or ($script:LastRunContent -notlike "*live-second*")) {
    Add-Result "WARN" "Live logging self-test verification" "live output or exit code was not preserved"
    Write-Host "WARN live logging self-test failed"
    exit 66
  }
  Write-Host "OK live logging self-test passed"
  exit 0
}

Write-Host "Dotfiles Windows update"
Write-Host "Run directory: $RunDir"

if (Get-Command winget -ErrorAction SilentlyContinue) {
  Run-NativeLiveLogged "WinGet sources" "windows-winget-source.log" "winget" @("source", "update") "utf8" "Updating WinGet sources..." $true
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

  $winGetPackageCount = Get-WinGetUpgradeCount $packageTable
  Run-NativeLiveLogged "WinGet packages" "windows-winget-upgrade.log" "winget" @("upgrade", "--all", "--include-unknown", "--silent", "--accept-package-agreements", "--accept-source-agreements") "utf8" "Updating $winGetPackageCount packages with WinGet..." $true
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
