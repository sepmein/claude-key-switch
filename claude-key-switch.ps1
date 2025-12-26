#Requires -Version 5.1

<#
.SYNOPSIS
    Rotate through API keys sequentially

.DESCRIPTION
    Each time you run this script, it switches to the next API key
    from your environment variables and updates your PowerShell profile.

.PARAMETER Help
    Show help message

.PARAMETER Version
    Show version information

.EXAMPLE
    .\claude-key-switch.ps1
    Switches to the next API key and updates your PowerShell profile

.NOTES
    Version: 1.0.0
    Platform: Windows (PowerShell 5.1+)

.LINK
    https://github.com/anthropics/claude-key-switch
#>

[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$Version
)

# ============================================================================
# Constants
# ============================================================================

$script:ScriptDir = $PSScriptRoot
$script:IndexFile = Join-Path $ScriptDir ".key-index"
$script:LockDir = Join-Path $ScriptDir ".key-switch.lock"
$script:EnvVarName = "ANTHROPIC_AUTH_TOKEN"
$script:KeyPrefix = "CLAUDE_KEY_"
$script:MarkerStart = "# claude-key-switch START"
$script:MarkerEnd = "# claude-key-switch END"
$script:ScriptVersion = "1.0.0"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "Error: $Message" -ForegroundColor Red
    exit 1
}

function Write-Success {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

# ============================================================================
# Help and Version
# ============================================================================

function Show-Help {
    Write-Host @"
claude-key-switch - Rotate through API keys sequentially

USAGE:
    .\claude-key-switch.ps1 [OPTIONS]

OPTIONS:
    -Help       Show this help message
    -Version    Show version information

DESCRIPTION:
    Each time you run this script, it switches to the next API key
    from your environment variables and updates your PowerShell profile.

SETUP:
    1. Set environment variables with your API keys in your PowerShell profile:
       `$env:CLAUDE_KEY_1 = 'sk-ant-api03-your-first-key'
       `$env:CLAUDE_KEY_2 = 'sk-ant-api03-your-second-key'
       `$env:CLAUDE_KEY_3 = 'sk-ant-api03-your-third-key'

    2. Run: .\claude-key-switch.ps1

ENVIRONMENT VARIABLES:
    CLAUDE_KEY_1, CLAUDE_KEY_2, CLAUDE_KEY_3, etc. - Your API keys

    The script will update $script:EnvVarName in your PowerShell profile.

FILES:
    .key-index  - Current key index (auto-managed)

EXAMPLES:
    .\claude-key-switch.ps1
        Switch to the next API key

    .\claude-key-switch.ps1 -Help
        Show this help message

"@ -ForegroundColor Cyan
}

# ============================================================================
# Locking Mechanism
# ============================================================================

function Enter-ScriptLock {
    try {
        New-Item -Path $script:LockDir -ItemType Directory -ErrorAction Stop | Out-Null
    } catch {
        Write-ErrorMessage "Script is already running. Please wait for it to complete."
    }
}

function Exit-ScriptLock {
    Remove-Item -Path $script:LockDir -Force -ErrorAction SilentlyContinue
}

# ============================================================================
# Index Management
# ============================================================================

function Read-CurrentIndex {
    if (Test-Path $script:IndexFile) {
        $content = Get-Content -Path $script:IndexFile -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $index = 0
            if ([int]::TryParse($content.Trim(), [ref]$index)) {
                return $index
            }
        }
    }
    return -1
}

function Write-Index {
    param([int]$Index)

    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        Set-Content -Path $tempFile -Value $Index -NoNewline -ErrorAction Stop
        Move-Item -Path $tempFile -Destination $script:IndexFile -Force -ErrorAction Stop
    } catch {
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
        throw
    }
}

# ============================================================================
# Key Management
# ============================================================================

function Count-Keys {
    $count = 0
    $i = 1

    while ($true) {
        $varName = "$script:KeyPrefix$i"
        $val = [Environment]::GetEnvironmentVariable($varName, "Process")

        if ([string]::IsNullOrEmpty($val)) {
            break
        }

        $count++
        $i++
    }

    return $count
}

function Get-KeyAtIndex {
    param([int]$Index)

    $varNum = $Index + 1
    $varName = "$script:KeyPrefix$varNum"

    return [Environment]::GetEnvironmentVariable($varName, "Process")
}

# ============================================================================
# Profile Management
# ============================================================================

function Get-PowerShellProfile {
    # Priority order:
    # 1. Current user, current host (most common)
    # 2. Current user, all hosts

    $profiles = @(
        $PROFILE.CurrentUserCurrentHost,
        $PROFILE.CurrentUserAllHosts
    )

    foreach ($profilePath in $profiles) {
        if (Test-Path $profilePath) {
            return $profilePath
        }
    }

    # No profile exists - create default one
    $defaultProfile = $PROFILE.CurrentUserCurrentHost
    $profileDir = Split-Path -Parent $defaultProfile

    if (-not (Test-Path $profileDir)) {
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $defaultProfile)) {
        New-Item -Path $defaultProfile -ItemType File -Force | Out-Null
    }

    return $defaultProfile
}

function Update-ProfileConfig {
    param(
        [string]$NewKey,
        [string]$ProfilePath
    )

    # Create backup
    $timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $backupFile = "$ProfilePath.backup.$timestamp"

    if (Test-Path $ProfilePath) {
        Copy-Item -Path $ProfilePath -Destination $backupFile -Force
    } else {
        New-Item -Path $ProfilePath -ItemType File -Force | Out-Null
    }

    # Prepare export line
    $exportLine = "`$env:$script:EnvVarName = '$NewKey'"

    # Read existing content
    $content = @()
    if (Test-Path $ProfilePath) {
        $content = Get-Content -Path $ProfilePath -ErrorAction SilentlyContinue
    }

    # Check if markers exist
    $hasMarkers = $content | Where-Object { $_ -match [regex]::Escape($script:MarkerStart) }

    if ($hasMarkers) {
        # Replace content between markers
        $newContent = @()
        $inSection = $false

        foreach ($line in $content) {
            if ($line -match [regex]::Escape($script:MarkerStart)) {
                $newContent += $line
                $newContent += $exportLine
                $inSection = $true
            }
            elseif ($line -match [regex]::Escape($script:MarkerEnd)) {
                $newContent += $line
                $inSection = $false
            }
            elseif (-not $inSection) {
                $newContent += $line
            }
        }

        # Atomic write
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            $newContent | Set-Content -Path $tempFile -Encoding UTF8 -ErrorAction Stop
            Move-Item -Path $tempFile -Destination $ProfilePath -Force -ErrorAction Stop
        } catch {
            if (Test-Path $tempFile) {
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            }
            throw
        }
    }
    else {
        # Append new section
        Add-Content -Path $ProfilePath -Value "" -Encoding UTF8
        Add-Content -Path $ProfilePath -Value $script:MarkerStart -Encoding UTF8
        Add-Content -Path $ProfilePath -Value $exportLine -Encoding UTF8
        Add-Content -Path $ProfilePath -Value $script:MarkerEnd -Encoding UTF8
    }

    Write-Info "Backup created: $backupFile"
}

# ============================================================================
# Main Logic
# ============================================================================

function Invoke-Main {
    # Handle arguments
    if ($Help) {
        Show-Help
        exit 0
    }

    if ($Version) {
        Write-Host "claude-key-switch v$script:ScriptVersion"
        exit 0
    }

    # Acquire lock
    Enter-ScriptLock

    try {
        # Read current state
        $currentIndex = Read-CurrentIndex
        $totalKeys = Count-Keys

        if ($totalKeys -eq 0) {
            Write-ErrorMessage "No API keys found. Set environment variables in your profile:`n  `$env:CLAUDE_KEY_1 = 'your-first-key'`n  `$env:CLAUDE_KEY_2 = 'your-second-key'"
        }

        # Calculate next index with wrap-around
        $nextIndex = ($currentIndex + 1) % $totalKeys

        # Get the key at next index
        $nextKey = Get-KeyAtIndex -Index $nextIndex

        if ([string]::IsNullOrEmpty($nextKey)) {
            Write-ErrorMessage "Failed to read key at index $nextIndex"
        }

        # Detect PowerShell profile
        $profilePath = Get-PowerShellProfile

        # Update profile config
        Update-ProfileConfig -NewKey $nextKey -ProfilePath $profilePath

        # Save new index
        Write-Index -Index $nextIndex

        # Display success message
        $keyNumber = $nextIndex + 1
        Write-Success "✓ Switched to key $keyNumber of $totalKeys"
        Write-Info "Updated: $profilePath"
        Write-Info "Run '. `"$profilePath`"' or restart PowerShell to apply changes"
    }
    finally {
        # Release lock
        Exit-ScriptLock
    }
}

# ============================================================================
# Entry Point
# ============================================================================

Invoke-Main
