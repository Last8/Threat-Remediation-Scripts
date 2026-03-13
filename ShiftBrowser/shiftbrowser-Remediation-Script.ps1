# ============================================================================
# Script: Invoke-ShiftPUPRemediation_Enhanced
# Purpose: Eradicates "Shift" Adware, including randomized payload drops
# ============================================================================

$Results = @()
$DelaySeconds = 3

Write-Host "[+] Starting ENHANCED Shift PUP Eradication Protocol..." -ForegroundColor Cyan

# ----------------------------------------------------------------------------
# 1. PROCESS TERMINATION: Catch randomized "Shift*.exe" process names
# ----------------------------------------------------------------------------
Write-Host "[*] Phase 1: Hunting active 'Shift' processes (including variants)..." -ForegroundColor Yellow

# Use Regex to match any process name starting with "Shift" (case-insensitive)
$ShiftProcs = Get-Process | Where-Object {$_.ProcessName -match "(?i)^Shift"}

if ($ShiftProcs) {
    foreach ($Proc in $ShiftProcs) {
        Stop-Process -Id $Proc.Id -Force -ErrorAction SilentlyContinue
        $Results += [PSCustomObject]@{Phase="Process"; Action="Killed"; Target="$($Proc.ProcessName).exe (PID: $($Proc.Id))"}
        Write-Host "  -> Killed $($Proc.ProcessName).exe (PID: $($Proc.Id))" -ForegroundColor Green
    }
} else {
    Write-Host "  -> No active shift processes found." -ForegroundColor DarkGray
}

Start-Sleep -Seconds $DelaySeconds

# ----------------------------------------------------------------------------
# 2. SCHEDULED TASK REMOVAL: Catch tasks executing randomized file names
# ----------------------------------------------------------------------------
Write-Host "`n[*] Phase 2: Hunting scheduled tasks..." -ForegroundColor Yellow

# Match task names containing "Shift" OR actions executing "Shift*.exe"
$SuspiciousTasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -match "(?i)Shift" -or $_.Actions.Execute -match "(?i)Shift.*\.exe"
}

if ($SuspiciousTasks) {
    foreach ($Task in $SuspiciousTasks) {
        Unregister-ScheduledTask -TaskName $Task.TaskName -Confirm:$false -ErrorAction SilentlyContinue
        $Results += [PSCustomObject]@{Phase="Task"; Action="Deleted"; Target=$Task.TaskName}
        Write-Host "  -> Deleted scheduled task: $($Task.TaskName)" -ForegroundColor Green
    }
} else {
    Write-Host "  -> No matching scheduled tasks found." -ForegroundColor DarkGray
}

Start-Sleep -Seconds $DelaySeconds

# ----------------------------------------------------------------------------
# 3. REGISTRY CLEANUP: Catch Run keys pointing to randomized executables
# ----------------------------------------------------------------------------
Write-Host "`n[*] Phase 3: Cleaning Registry Run keys across ALL user hives..." -ForegroundColor Yellow
$RegFound = $false

$UserHives = Get-ChildItem -Path "Registry::HKEY_USERS" -ErrorAction SilentlyContinue | Where-Object {$_.Name -match "S-1-5-21"}

foreach ($Hive in $UserHives) {
    $RunKeyPath = "$($Hive.PSPath)\Software\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path $RunKeyPath) {
        $RunValues = Get-ItemProperty -Path $RunKeyPath -ErrorAction SilentlyContinue
        
        # Match "ShiftAutoLaunch" OR any run key data pointing to "Shift*.exe"
        $MaliciousProperties = $RunValues | Get-Member -MemberType NoteProperty | Where-Object {
            $_.Name -match "(?i)ShiftAutoLaunch" -or $RunValues.($_.Name) -match "(?i)Shift.*\.exe"
        }

        foreach ($Prop in $MaliciousProperties) {
            Remove-ItemProperty -Path $RunKeyPath -Name $Prop.Name -Force -ErrorAction SilentlyContinue
            $Results += [PSCustomObject]@{Phase="Registry"; Action="Deleted"; Target="HKU\$($Hive.PSChildName)\...\Run\$($Prop.Name)"}
            Write-Host "  -> Deleted Registry Value for user SID $($Hive.PSChildName)" -ForegroundColor Green
            $RegFound = $true
        }
    }
}

if (-not $RegFound) {
    Write-Host "  -> No malicious registry keys found." -ForegroundColor DarkGray
}

Start-Sleep -Seconds $DelaySeconds

# ----------------------------------------------------------------------------
# 4. FILE SYSTEM CLEANUP: Target AppData AND Randomized Downloads
# ----------------------------------------------------------------------------
Write-Host "`n[*] Phase 4: Cleaning File System (AppData & Downloads)..." -ForegroundColor Yellow

# 4A. Target the installed AppData directories
$ShiftDirs = Get-ChildItem -Path "C:\Users\*\AppData\Local\Shift" -Directory -ErrorAction SilentlyContinue

# 4B. Target the downloaded installer/payload variants (e.g., "Shift - PDF_xjsh88.exe")
$ShiftDownloads = Get-ChildItem -Path "C:\Users\*\Downloads\Shift*.exe" -File -ErrorAction SilentlyContinue

$AllFiles = @()
if ($ShiftDirs) { $AllFiles += $ShiftDirs }
if ($ShiftDownloads) { $AllFiles += $ShiftDownloads }

if ($AllFiles.Count -gt 0) {
    foreach ($Item in $AllFiles) {
        $PathToRemove = $Item.FullName
        Remove-Item -Path $PathToRemove -Recurse -Force -ErrorAction SilentlyContinue
        $Results += [PSCustomObject]@{Phase="File System"; Action="Deleted"; Target=$PathToRemove}
        Write-Host "  -> Deleted Target: $PathToRemove" -ForegroundColor Green
    }
} else {
    Write-Host "  -> No malicious files or directories found on disk." -ForegroundColor DarkGray
}

# ----------------------------------------------------------------------------
# 5. SUMMARY
# ----------------------------------------------------------------------------
Write-Host "`n[+] Remediation Protocol Complete!" -ForegroundColor Cyan

if ($Results.Count -gt 0) {
    Write-Host "Summary of removed items:" -ForegroundColor White
    $Results | Format-Table -AutoSize -Wrap
} else {
    Write-Host "[-] System appears clean. No adware artifacts were found or removed." -ForegroundColor Green
}
