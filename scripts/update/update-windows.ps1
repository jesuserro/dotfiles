[CmdletBinding()]
param(
  [string]$RunDir = "",
  [switch]$IncludeUnknown,
  [string]$RetryFailedFromTsv = "",
  [switch]$SelfTestNativeArguments,
  [switch]$SelfTestWinGetConsoleText,
  [switch]$SelfTestWinGetPackageResults,
  [switch]$SelfTestWinGetPackageWorkflow,
  [switch]$SelfTestWinGetPresentationNoPackages,
  [switch]$SelfTestWinGetPresentationWarnings,
  [switch]$SelfTestLiveLogging
)

$ErrorActionPreference = "Continue"
if ([string]::IsNullOrWhiteSpace($RunDir)) {
  if ($SelfTestNativeArguments -or $SelfTestWinGetConsoleText -or $SelfTestWinGetPackageResults -or $SelfTestWinGetPackageWorkflow -or $SelfTestWinGetPresentationNoPackages -or $SelfTestWinGetPresentationWarnings -or $SelfTestLiveLogging) {
    $RunDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dotfiles-update-native-args-" + [System.Guid]::NewGuid().ToString("N"))
  } else {
    $runRoot = if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
      Join-Path $env:LOCALAPPDATA "dotfiles\update-runs"
    } else {
      Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles\update-runs"
    }
    $RunDir = Join-Path $runRoot ("{0}-{1}" -f (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ"), $PID)
  }
}
$LogDir = Join-Path $RunDir "logs"
$ResultFile = Join-Path $RunDir "windows-results.tsv"
$WinGetResultFile = Join-Path $RunDir "windows-winget-results.tsv"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
Set-Content -Path $ResultFile -Value "" -Encoding UTF8
Set-Content -Path $WinGetResultFile -Value "package_id`tpackage_name`tversion_before`tversion_target`tversion_after`tstatus`texit_code`tduration_seconds`tlog_path`tmessage" -Encoding UTF8
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
    [scriptblock]$ConsoleLineFilter = $null,
    [bool]$DisplayOutput = $true,
    [bool]$VerboseOutput = $false
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
          if ($DisplayOutput -and (-not [string]::IsNullOrWhiteSpace($displayLine))) {
            if ($VerboseOutput) { Write-Verbose $displayLine } else { Write-Host $displayLine }
          }
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
          if ($DisplayOutput -and (-not [string]::IsNullOrWhiteSpace($displayLine))) {
            if ($VerboseOutput) { Write-Verbose $displayLine } else { Write-Host $displayLine }
          }
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
    [string]$FileName = "winget",
    [bool]$DisplayOutput = $true,
    [bool]$VerboseOutput = $false
  )
  return Invoke-NativeLiveProcess -FileName $FileName -NativeArguments $NativeArguments -LogPath $LogPath -OutputEncoding $OutputEncoding -ConsoleLineFilter { param($line) Get-WinGetConsoleLine $line } -DisplayOutput $DisplayOutput -VerboseOutput $VerboseOutput
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
  if (-not $DisplayStep) {
    Write-Verbose "$Name log: $log"
    if (-not [string]::IsNullOrWhiteSpace($script:LastRunContent)) {
      Write-Verbose $script:LastRunContent
    }
  }
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

function ConvertTo-TsvValue {
  param([AllowNull()][object]$Value)
  if ($null -eq $Value) { return "" }
  return ([string]$Value) -replace "`t", " " -replace "(`r`n|`r|`n)", " "
}

function Add-WinGetDetailedResult {
  param(
    [string]$PackageId,
    [string]$PackageName,
    [string]$VersionBefore,
    [string]$VersionTarget,
    [string]$VersionAfter,
    [ValidateSet("OK", "WARN", "FAIL")][string]$Status,
    [AllowNull()][object]$ExitCode,
    [int]$DurationSeconds,
    [string]$LogPath,
    [string]$Message
  )
  $fields = @(
    $PackageId,
    $PackageName,
    $VersionBefore,
    $VersionTarget,
    $VersionAfter,
    $Status,
    $ExitCode,
    $DurationSeconds,
    $LogPath,
    $Message
  ) | ForEach-Object { ConvertTo-TsvValue $_ }
  Add-Content -Path $WinGetResultFile -Value ($fields -join "`t") -Encoding UTF8
}

function Test-Truthy {
  param([string]$Value)
  return ($Value -match '^(?i:1|true|yes|y|on)$')
}

function Get-WinGetIncludeUnknownEnabled {
  return ($IncludeUnknown.IsPresent -or (Test-Truthy $env:DOTFILES_WINGET_INCLUDE_UNKNOWN))
}

function Get-ColumnIndex {
  param([string]$Header, [string[]]$Labels)
  foreach ($label in $Labels) {
    $index = $Header.IndexOf($label, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -ge 0) { return $index }
  }
  return -1
}

function Get-Slice {
  param([string]$Text, [int]$Start, [int]$End)
  if ($Start -lt 0 -or $Start -ge $Text.Length) { return "" }
  $length = if ($End -lt 0) { $Text.Length - $Start } else { [Math]::Min($End, $Text.Length) - $Start }
  if ($length -le 0) { return "" }
  return $Text.Substring($Start, $length).Trim()
}

function Get-WinGetPackagePlanFromText {
  param([string]$Text)
  $packages = New-Object System.Collections.ArrayList
  if ([string]::IsNullOrWhiteSpace($Text)) { return @() }

  $lines = @(($Text -replace "`r", "`n") -split "`n")
  $headerIndex = -1
  $columns = $null
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $header = ($lines[$i] -replace "`e\[[0-9;?]*[ -/]*[@-~]", "").TrimEnd()
    $idStart = Get-ColumnIndex $header @("Id")
    $versionStart = Get-ColumnIndex $header @("Version", "Versi")
    $availableStart = Get-ColumnIndex $header @("Available", "Disponible")
    if (($idStart -ge 0) -and ($versionStart -gt $idStart) -and ($availableStart -gt $versionStart)) {
      $sourceStart = Get-ColumnIndex $header @("Source", "Origen")
      $columns = [pscustomobject]@{
        Id = $idStart
        Version = $versionStart
        Available = $availableStart
        Source = $sourceStart
      }
      $headerIndex = $i
      break
    }
  }
  if ($headerIndex -lt 0) { return @() }

  $afterSeparator = $false
  for ($i = $headerIndex + 1; $i -lt $lines.Count; $i++) {
    $line = ($lines[$i] -replace "`e\[[0-9;?]*[ -/]*[@-~]", "").TrimEnd()
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^\s*-{3,}') {
      $afterSeparator = $true
      continue
    }
    if (-not $afterSeparator) { continue }
    if ($line -match '(?i)(upgrades?|actualizaci(?:o|\u00f3)n(?:es)?)\s+(?:available|disponible)') { break }
    if ($line -match '(?i)^(No installed package found|No se encontr(?:o|\u00f3)|No hay actualizaciones|No available upgrades)') { break }

    $sourceEnd = -1
    $name = Get-Slice $line 0 $columns.Id
    $id = Get-Slice $line $columns.Id $columns.Version
    $current = Get-Slice $line $columns.Version $columns.Available
    $available = if ($columns.Source -gt $columns.Available) { Get-Slice $line $columns.Available $columns.Source } else { Get-Slice $line $columns.Available $sourceEnd }
    $source = if ($columns.Source -gt $columns.Available) { Get-Slice $line $columns.Source -1 } else { "" }
    if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($available)) { continue }
    [void]$packages.Add([pscustomobject]@{
      PackageName = $name
      PackageId = $id
      CurrentVersion = $current
      AvailableVersion = $available
      Source = $source
    })
  }
  return @($packages)
}

function Get-WinGetInstalledVersionFromText {
  param([string]$Text, [string]$PackageId)
  $tablePackages = Get-WinGetPackagePlanFromText $Text
  foreach ($package in $tablePackages) {
    if ($package.PackageId -eq $PackageId) {
      return $package.CurrentVersion
    }
  }
  foreach ($line in (($Text -replace "`r", "`n") -split "`n")) {
    if ($line -match [regex]::Escape($PackageId)) {
      $parts = @($line.Trim() -split '\s{2,}' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
      if ($parts.Count -ge 3) { return $parts[2] }
    }
  }
  return ""
}

function Get-WinGetRetryPlanFromTsv {
  param([string]$Path)
  if (-not (Test-Path $Path)) {
    Add-Result "WARN" "WinGet retry" "retry TSV not found: $Path"
    return @()
  }
  $rows = @(Import-Csv -Path $Path -Delimiter "`t" -ErrorAction SilentlyContinue | Where-Object { $_.status -ne "OK" })
  $packages = New-Object System.Collections.ArrayList
  foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.package_id)) { continue }
    [void]$packages.Add([pscustomobject]@{
      PackageName = $row.package_name
      PackageId = $row.package_id
      CurrentVersion = $row.version_before
      AvailableVersion = $row.version_target
      Source = ""
    })
  }
  return @($packages)
}

function Get-SafeLogToken {
  param([string]$Value)
  $safe = $Value -replace '[^A-Za-z0-9._-]+', '_'
  if ([string]::IsNullOrWhiteSpace($safe)) { return "package" }
  return $safe
}

function Get-WinGetKnownMessage {
  param([AllowNull()][object]$ExitCode, [string]$Text)
  if ("$ExitCode" -eq "1618" -or $Text -match '(?i)(another installation|another installer|msi transaction|instalaci(?:o|\u00f3)n.*curso)') {
    return "Another installer/MSI transaction is already running. Rerun later."
  }
  if ($Text -match '(?i)(0x80071130|Fast Cache data not found)') {
    return "WinGet cache/source issue. Suggested fix: winget source reset --force; winget source update"
  }
  if ($null -ne $ExitCode -and "$ExitCode" -ne "") {
    return "exit $ExitCode"
  }
  return "unknown result"
}

function Write-WinGetPlan {
  param([object[]]$Packages, [bool]$RetryMode)
  if ($Packages.Count -eq 0) { return }
  if ($RetryMode) {
    Write-Host ""
    Write-Host "Retry plan:"
  } else {
    Write-Host ""
    Write-Host "Plan:"
  }
  for ($i = 0; $i -lt $Packages.Count; $i++) {
    $package = $Packages[$i]
    Write-Host ("  {0}. {1} [{2}] {3} -> {4}" -f ($i + 1), $package.PackageName, $package.PackageId, $package.CurrentVersion, $package.AvailableVersion)
  }
}

function Write-WinGetNoPackages {
  param([int]$ElapsedSeconds)
  Write-Host ("OK no packages to upgrade in {0}s" -f $ElapsedSeconds)
  $script:WinGetConsoleSummary = [pscustomobject]@{
    Planned = 0
    Updated = 0
    Failed = 0
    NoPackages = $true
    FailedRows = @()
    RetryMode = $false
  }
}

function Invoke-NativeCaptured {
  param(
    [string]$LogName,
    [string]$FileName,
    [string[]]$NativeArguments,
    [string]$OutputEncoding = "utf8"
  )
  $log = Join-Path $LogDir $LogName
  $start = Get-Date
  $encoding = Get-NativeEncoding $OutputEncoding
  $argumentString = Join-NativeArguments -NativeArguments $NativeArguments
  $content = ""
  $code = $null
  try {
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $FileName
    $psi.Arguments = $argumentString
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = $encoding
    $psi.StandardErrorEncoding = $encoding
    $psi.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $psi
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $code = [int]$process.ExitCode
    $content = (($stdoutTask.Result, $stderrTask.Result) | Where-Object { -not [string]::IsNullOrEmpty($_) }) -join [Environment]::NewLine
    $content = $content -replace "`r`n", "`n" -replace "`r", "`n"
  } catch {
    $content = $_.Exception.ToString()
  } finally {
    if ($null -ne $process) { $process.Dispose() }
  }
  [System.IO.File]::WriteAllText($log, $content, [System.Text.UTF8Encoding]::new($false))
  return [pscustomobject]@{
    ExitCode = $code
    Content = $content
    LogPath = $log
    Elapsed = [int]((Get-Date) - $start).TotalSeconds
  }
}

function Invoke-WinGetPackageUpgrades {
  param([object[]]$Packages, [bool]$IncludeUnknownEnabled, [bool]$RetryMode)
  $updated = 0
  $failed = 0
  $warned = 0
  Write-Host ""
  Write-Host "Upgrading:"
  for ($i = 0; $i -lt $Packages.Count; $i++) {
    $package = $Packages[$i]
    $logName = "windows-winget-upgrade-{0:D3}-{1}.log" -f ($i + 1), (Get-SafeLogToken $package.PackageId)
    $log = Join-Path $LogDir $logName
    $arguments = @("upgrade", "--id", $package.PackageId, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements")
    if ($IncludeUnknownEnabled) { $arguments += "--include-unknown" }
    Write-Host ("  [{0}/{1}] {2} [{3}]" -f ($i + 1), $Packages.Count, $package.PackageName, $package.PackageId)
    Write-Host ("        {0} -> {1}" -f $package.CurrentVersion, $package.AvailableVersion)
    Write-Verbose "Package log: $log"
    $start = Get-Date
    $verboseNativeOutput = ($VerbosePreference -ne "SilentlyContinue")
    $code = Invoke-WinGetLiveFiltered -FileName "winget" -NativeArguments $arguments -LogPath $log -OutputEncoding "utf8" -DisplayOutput $verboseNativeOutput -VerboseOutput $true
    $content = if (Test-Path $log) { Get-Content -Path $log -Raw -ErrorAction SilentlyContinue } else { "" }
    $elapsed = [int]((Get-Date) - $start).TotalSeconds
    $versionAfter = ""
    $status = "OK"
    $message = "updated successfully"
    if ($code -ne 0) {
      $status = "FAIL"
      $failed++
      $message = Get-WinGetKnownMessage $code $content
      Write-Host ("        WARN failed exit {0}; log: {1}" -f $code, $log)
    } else {
      $verify = Invoke-NativeCaptured ("windows-winget-verify-{0:D3}-{1}.log" -f ($i + 1), (Get-SafeLogToken $package.PackageId)) "winget" @("list", "--id", $package.PackageId, "--exact") "utf8"
      Write-Verbose "Verification log: $($verify.LogPath)"
      $versionAfter = Get-WinGetInstalledVersionFromText $verify.Content $package.PackageId
      if ([string]::IsNullOrWhiteSpace($versionAfter)) {
        $versionAfter = $package.AvailableVersion
        $status = "WARN"
        $warned++
        $message = "verification_status=WARN; could not parse final installed version; expected $($package.AvailableVersion)"
        Write-Host ("        WARN verification ambiguous; log: {0}" -f $log)
      } elseif ($versionAfter -ne $package.AvailableVersion) {
        $status = "WARN"
        $warned++
        $message = "verification_status=WARN; installed version $versionAfter differs from target $($package.AvailableVersion)"
        Write-Host ("        WARN verification ambiguous; log: {0}" -f $log)
      } else {
        $updated++
        Write-Host ("        OK updated in {0}s" -f $elapsed)
      }
    }
    Add-WinGetDetailedResult $package.PackageId $package.PackageName $package.CurrentVersion $package.AvailableVersion $versionAfter $status $code $elapsed $log $message
    if ($status -eq "OK") {
      Add-Result "OK" "WinGet package $($package.PackageName) [$($package.PackageId)]" "$($package.CurrentVersion) -> $versionAfter; log: $log"
    } elseif ($status -eq "WARN") {
      Add-Result "WARN" "WinGet package $($package.PackageName) [$($package.PackageId)]" "$($package.CurrentVersion) -> $versionAfter; $message; log: $log"
    } else {
      Add-Result "WARN" "WinGet package $($package.PackageName) [$($package.PackageId)]" "$($package.CurrentVersion) -> $($package.AvailableVersion) exit $code; $message; log: $log"
    }
  }
  return [pscustomobject]@{
    Planned = $Packages.Count
    Updated = $updated
    Warned = $warned
    Failed = $failed
    Skipped = 0
    RetryMode = $RetryMode
  }
}

function Write-WinGetPackageSummary {
  param([object]$Summary)
  $rows = @(Import-Csv -Path $WinGetResultFile -Delimiter "`t" -ErrorAction SilentlyContinue)
  $nonOk = @($rows | Where-Object { $_.status -ne "OK" })
  $status = if ($nonOk.Count -eq 0) { "OK" } else { "WARN" }
  Write-Host ""
  Write-Host "==> WinGet package summary"
  if ($Summary.RetryMode) {
    Write-Host ("{0} {1} planned, {2} updated, {3} still failed" -f $status, $Summary.Planned, $Summary.Updated, $nonOk.Count)
  } else {
    Write-Host ("{0} {1} planned, {2} updated, {3} failed, {4} skipped" -f $status, $Summary.Planned, $Summary.Updated, $nonOk.Count, $Summary.Skipped)
  }
  $updatedRows = @($rows | Where-Object { $_.status -eq "OK" })
  if ($updatedRows.Count -gt 0) {
    Write-Host ""
    Write-Host "Updated:"
    foreach ($row in $updatedRows) {
      Write-Host ("  OK {0} {1} -> {2}" -f $row.package_name, $row.version_before, $row.version_after)
    }
  }
  if ($nonOk.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed:"
    foreach ($row in $nonOk) {
      $target = if ([string]::IsNullOrWhiteSpace($row.version_target)) { $row.version_after } else { $row.version_target }
      Write-Host ("  WARN {0} {1} -> {2} exit {3}" -f $row.package_name, $row.version_before, $target, $row.exit_code)
      Write-Host ("    message: {0}" -f $row.message)
    }
    Write-Host ""
    Write-Host ("Retry failed packages: .\scripts\update\update-windows.ps1 -RetryFailedFromTsv `"{0}`"" -f $WinGetResultFile)
  }
  Write-Host "WinGet package results: $WinGetResultFile"
}

function Set-WinGetConsoleSummary {
  param([object]$Summary)
  $rows = @(Import-Csv -Path $WinGetResultFile -Delimiter "`t" -ErrorAction SilentlyContinue)
  $nonOk = @($rows | Where-Object { $_.status -ne "OK" })
  $script:WinGetConsoleSummary = [pscustomobject]@{
    Planned = $Summary.Planned
    Updated = $Summary.Updated
    Failed = $nonOk.Count
    NoPackages = $false
    FailedRows = $nonOk
    RetryMode = $Summary.RetryMode
  }
}

function Get-WslConsoleSummary {
  param([string]$StatusText, [AllowNull()][object]$StatusCode, [AllowNull()][object]$UpdateCode)
  if (($StatusCode -ne 0) -or ($UpdateCode -ne 0)) {
    return "WSL: warnings; see logs"
  }
  $distro = ""
  $version = ""
  foreach ($line in (($StatusText -replace "`r", "`n") -split "`n")) {
    if ($line -match '(?i)^\s*Default Distribution:\s*(.+)$') { $distro = $Matches[1].Trim() }
    if ($line -match '(?i)^\s*Distribuci(?:o|\u00f3)n predeterminada:\s*(.+)$') { $distro = $Matches[1].Trim() }
    if ($line -match '(?i)^\s*Default Version:\s*(.+)$') { $version = $Matches[1].Trim() }
    if ($line -match '(?i)^\s*Versi(?:o|\u00f3)n predeterminada:\s*(.+)$') { $version = $Matches[1].Trim() }
  }
  if (-not [string]::IsNullOrWhiteSpace($distro) -and -not [string]::IsNullOrWhiteSpace($version)) {
    return "WSL: $distro, version $version, up to date"
  }
  if (-not [string]::IsNullOrWhiteSpace($distro)) {
    return "WSL: $distro, up to date"
  }
  return "WSL: up to date"
}

function Write-WindowsSemanticSummary {
  $resultRows = @()
  if (Test-Path $ResultFile) {
    $resultRows = @(Import-Csv -Path $ResultFile -Delimiter "`t" -Header "status", "area", "name", "message" | Where-Object { -not [string]::IsNullOrWhiteSpace($_.status) })
  }
  $warningRows = @($resultRows | Where-Object { $_.status -match '^(WARN|FAIL|INCIDENT)$' })
  $winGetFailures = @()
  if ($null -ne $script:WinGetConsoleSummary) {
    $winGetFailures = @($script:WinGetConsoleSummary.FailedRows)
  }
  $status = if (($warningRows.Count -gt 0) -or ($winGetFailures.Count -gt 0)) { "WARN" } else { "OK" }

  Write-Host ""
  Write-Host "==> Summary"
  if ($status -eq "OK") {
    Write-Host "OK Windows update completed"
  } else {
    Write-Host "WARN Windows update completed with warnings"
  }

  if ($null -eq $script:WinGetConsoleSummary) {
    Write-Host "WinGet: not available"
  } elseif ($script:WinGetConsoleSummary.NoPackages) {
    Write-Host "WinGet: no packages to upgrade"
  } else {
    Write-Host ("WinGet: {0} updated, {1} failed" -f $script:WinGetConsoleSummary.Updated, $script:WinGetConsoleSummary.Failed)
  }

  if (-not [string]::IsNullOrWhiteSpace($script:WslConsoleSummary)) {
    Write-Host $script:WslConsoleSummary
  }

  if ($winGetFailures.Count -gt 0) {
    Write-Host "Failed:"
    foreach ($row in $winGetFailures) {
      Write-Host ("  {0} [{1}] exit {2}" -f $row.package_name, $row.package_id, $row.exit_code)
    }
    Write-Host "Retry:"
    Write-Host ("  .\scripts\update\update-windows.ps1 -RetryFailedFromTsv `"{0}`"" -f $WinGetResultFile)
  }
  Write-Host "Logs: $LogDir"
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

if ($SelfTestWinGetPackageWorkflow) {
  Write-Host "Dotfiles Windows update WinGet package workflow self-test"
  Write-Host "Run directory: $RunDir"
  $sample = @(
    "Name             Id                         Version       Available     Source"
    "----------------------------------------------------------------------------"
    "GitHub CLI       GitHub.cli                 2.78.0        2.79.0        winget"
    "Pandoc           JohnMacFarlane.Pandoc      3.7.0         3.8.0         winget"
    "2 upgrades available."
  ) -join [Environment]::NewLine
  $packages = @(Get-WinGetPackagePlanFromText $sample)
  if (($packages.Count -ne 2) -or ($packages[0].PackageId -ne "GitHub.cli") -or ($packages[1].AvailableVersion -ne "3.8.0")) {
    Add-Result "WARN" "WinGet package workflow self-test" "upgrade table parsing failed"
    Write-Host "WARN WinGet package workflow self-test failed"
    exit 68
  }
  Add-WinGetDetailedResult "GitHub.cli" "GitHub CLI" "2.78.0" "2.79.0" "2.79.0" "OK" 0 4 "logs/windows-winget-upgrade-001-GitHub.cli.log" "updated successfully"
  Add-WinGetDetailedResult "JohnMacFarlane.Pandoc" "Pandoc" "3.7.0" "3.8.0" "" "FAIL" 1618 5 "logs/windows-winget-upgrade-002-JohnMacFarlane.Pandoc.log" (Get-WinGetKnownMessage 1618 "")
  $retry = @(Get-WinGetRetryPlanFromTsv $WinGetResultFile)
  $header = (Get-Content -Path $WinGetResultFile -TotalCount 1)
  $previousIncludeUnknown = $env:DOTFILES_WINGET_INCLUDE_UNKNOWN
  $env:DOTFILES_WINGET_INCLUDE_UNKNOWN = "1"
  $includeUnknownFromEnv = Get-WinGetIncludeUnknownEnabled
  $env:DOTFILES_WINGET_INCLUDE_UNKNOWN = $previousIncludeUnknown
  if (($header -ne "package_id`tpackage_name`tversion_before`tversion_target`tversion_after`tstatus`texit_code`tduration_seconds`tlog_path`tmessage") -or ($retry.Count -ne 1) -or ($retry[0].PackageId -ne "JohnMacFarlane.Pandoc") -or ($retry[0].CurrentVersion -ne "3.7.0") -or (-not $includeUnknownFromEnv) -or ((Get-WinGetKnownMessage 1 "Fast Cache data not found") -notlike "*winget source reset --force*")) {
    Add-Result "WARN" "WinGet package workflow self-test" "TSV, retry, include-unknown, or known-error behavior failed"
    Write-Host "WARN WinGet package workflow self-test failed"
    exit 68
  }
  Set-Content -Path $ResultFile -Value "" -Encoding UTF8
  Add-Result "OK" "WinGet package workflow self-test" "package workflow helpers passed"
  Write-Host "OK WinGet package workflow self-test passed"
  exit 0
}

if ($SelfTestWinGetPresentationNoPackages) {
  Write-Verbose "Run directory: $RunDir"
  Write-Host "==> WinGet"
  Write-Verbose "WinGet sources log: $(Join-Path $LogDir "windows-winget-source.log")"
  Write-Verbose "WinGet package list log: $(Join-Path $LogDir "windows-winget-list.log")"
  Write-Host "OK sources updated in 3s"
  Add-Result "OK" "WinGet sources" "completed in 3s; log: $(Join-Path $LogDir "windows-winget-source.log")"
  Add-Result "OK" "WinGet packages" "no packages to upgrade"
  Write-WinGetNoPackages -ElapsedSeconds 4
  $script:WslConsoleSummary = "WSL: Ubuntu, version 2, up to date"
  Write-WindowsSemanticSummary
  exit 0
}

if ($SelfTestWinGetPresentationWarnings) {
  Write-Verbose "Run directory: $RunDir"
  Write-Host "==> WinGet"
  Write-Host "OK sources updated in 3s"
  $packages = @(
    [pscustomobject]@{ PackageName = "GitHub CLI"; PackageId = "GitHub.cli"; CurrentVersion = "2.78.0"; AvailableVersion = "2.79.0" },
    [pscustomobject]@{ PackageName = "Pandoc"; PackageId = "JohnMacFarlane.Pandoc"; CurrentVersion = "3.7.0"; AvailableVersion = "3.8.0" }
  )
  Write-WinGetPlan -Packages $packages -RetryMode $false
  $failedLog = Join-Path $LogDir "windows-winget-upgrade-002-JohnMacFarlane.Pandoc.log"
  Write-Host ""
  Write-Host "Upgrading:"
  Write-Host "  [1/2] GitHub CLI [GitHub.cli]"
  Write-Host "        2.78.0 -> 2.79.0"
  Write-Host "        OK updated in 58s"
  Write-Host "  [2/2] Pandoc [JohnMacFarlane.Pandoc]"
  Write-Host "        3.7.0 -> 3.8.0"
  Write-Host "        WARN failed exit 1618; log: $failedLog"
  Add-WinGetDetailedResult "GitHub.cli" "GitHub CLI" "2.78.0" "2.79.0" "2.79.0" "OK" 0 58 (Join-Path $LogDir "windows-winget-upgrade-001-GitHub.cli.log") "updated successfully"
  Add-WinGetDetailedResult "JohnMacFarlane.Pandoc" "Pandoc" "3.7.0" "3.8.0" "" "FAIL" 1618 2 $failedLog (Get-WinGetKnownMessage 1618 "")
  Add-Result "OK" "WinGet package GitHub CLI [GitHub.cli]" "2.78.0 -> 2.79.0; log: $(Join-Path $LogDir "windows-winget-upgrade-001-GitHub.cli.log")"
  $knownMessage = Get-WinGetKnownMessage 1618 ""
  Add-Result "WARN" "WinGet package Pandoc [JohnMacFarlane.Pandoc]" "3.7.0 -> 3.8.0 exit 1618; $knownMessage; log: $failedLog"
  Set-WinGetConsoleSummary -Summary ([pscustomobject]@{ Planned = 2; Updated = 1; RetryMode = $false })
  $script:WslConsoleSummary = "WSL: Ubuntu, version 2, up to date"
  Write-WindowsSemanticSummary
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

Write-Verbose "Run directory: $RunDir"

if (Get-Command winget -ErrorAction SilentlyContinue) {
  $includeUnknownEnabled = Get-WinGetIncludeUnknownEnabled
  $retryMode = -not [string]::IsNullOrWhiteSpace($RetryFailedFromTsv)
  Write-Host "==> WinGet"
  Run-NativeLogged "WinGet sources" "windows-winget-source.log" "winget" @("source", "update") "utf8" $false $false
  if ($script:LastRunCode -eq 0) {
    Write-Host ("OK sources updated in {0}s" -f $script:LastRunElapsed)
  } else {
    Write-Host ("WARN sources update exit {0}; log: {1}" -f $script:LastRunCode, $script:LastRunLog)
  }

  if ($retryMode) {
    $packages = @(Get-WinGetRetryPlanFromTsv $RetryFailedFromTsv)
    Write-Verbose "Retry TSV: $RetryFailedFromTsv"
    $packageListElapsed = 0
  } else {
    $winGetListName = "WinGet packages to upgrade"
    $listArguments = @("upgrade", "--accept-source-agreements", "--disable-interactivity")
    if ($includeUnknownEnabled) { $listArguments += "--include-unknown" }
    Run-NativeLogged $winGetListName "windows-winget-list.log" "winget" $listArguments "utf8" $false $false
    $packageListElapsed = if ($null -eq $script:LastRunElapsed) { 0 } else { $script:LastRunElapsed }
    $packageTable = Get-WinGetConsoleText $script:LastRunContent
    $packages = @(Get-WinGetPackagePlanFromText $packageTable)
  }
  Write-WinGetPlan -Packages $packages -RetryMode $retryMode
  if ($packages.Count -eq 0) {
    Add-Result "OK" "WinGet packages" "no packages to upgrade"
    Write-WinGetNoPackages -ElapsedSeconds $packageListElapsed
  } else {
    $winGetSummary = Invoke-WinGetPackageUpgrades -Packages $packages -IncludeUnknownEnabled $includeUnknownEnabled -RetryMode $retryMode
    Set-WinGetConsoleSummary -Summary $winGetSummary
  }
} else {
  Add-Result "WARN" "WinGet" "winget not found on Windows PATH"
  $script:WinGetConsoleSummary = $null
}

if (Get-Command wsl -ErrorAction SilentlyContinue) {
  Run-NativeLogged "WSL status" "windows-wsl-status.log" "wsl" @("--status") "unicode" $false $false
  $wslStatusContent = $script:LastRunContent
  $wslStatusCode = $script:LastRunCode
  Run-NativeLogged "WSL update" "windows-wsl-update.log" "wsl" @("--update") "unicode" $false $false
  $wslUpdateCode = $script:LastRunCode
  $script:WslConsoleSummary = Get-WslConsoleSummary -StatusText $wslStatusContent -StatusCode $wslStatusCode -UpdateCode $wslUpdateCode
  Add-Result "INFO" "WSL restart" "If WSL reports a pending restart, run later from PowerShell after this WSL session: wsl --shutdown"
} else {
  Add-Result "WARN" "WSL update" "wsl command not found on Windows PATH"
  $script:WslConsoleSummary = "WSL: command not found"
}

Write-WindowsSemanticSummary
