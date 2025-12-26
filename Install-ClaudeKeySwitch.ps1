#Requires -Version 5.1

<#
.SYNOPSIS
    Interactive installer for claude-key-switch

.DESCRIPTION
    Guides you through setting up API keys in your PowerShell profile

.NOTES
    Version: 1.0.0
    Platform: Windows (PowerShell 5.1+)

.LINK
    https://github.com/anthropics/claude-key-switch
#>

# ============================================================================
# Constants
# ============================================================================

$script:ScriptDir = $PSScriptRoot
$script:SwitchScript = Join-Path $ScriptDir "claude-key-switch.ps1"

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("━" * 50) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("━" * 50) -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Read-Prompt {
    param([string]$Message)
    Write-Host "? " -NoNewline -ForegroundColor Yellow
    Write-Host $Message -NoNewline
    Write-Host " " -NoNewline
    return Read-Host
}

function Stop-WithError {
    param([string]$Message)
    Write-ErrorMessage $Message
    exit 1
}

# ============================================================================
# Welcome Banner
# ============================================================================

function Show-Welcome {
    Clear-Host

    Write-Host @"
   ______ __                __           __ __
  / ____// /____ _ __  __ ____/ /___       / //_/___   __  __
 / /    / // __ ``// / / // __  // _ \     / ,<  / _ \ / / / /
/ /___ / // /_/ // /_/ // /_/ //  __/    / /| |/  __// /_/ /
\____//_/ \__,_/ \__,_/ \__,_/ \___/    /_/ |_|\___/ \__, /
                                                    /____/
   _____         _  __         __
  / ___/ _      __(_)/ /_ _____ / /_
  \__ \ | | /| / / // __// ___// __ \
 ___/ / | |/ |/ / // /_ / /__ / / / /
/____/  |__/|__/_/ \__/ \___//_/ /_/

"@ -ForegroundColor Cyan

    Write-Host "Installation & Setup" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "This script will help you set up claude-key-switch"
    Write-Info "It will add API keys to your PowerShell profile"
    Write-Host ""
}

# ============================================================================
# Step 1: Choose Profile
# ============================================================================

function Select-Profile {
    Write-Header "Step 1: Choose Your PowerShell Profile"

    Write-Info "Which profile do you want to configure?"
    Write-Host ""
    Write-Host "  1) Current User, Current Host (recommended)" -ForegroundColor White
    Write-Host "     $($PROFILE.CurrentUserCurrentHost)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  2) Current User, All Hosts" -ForegroundColor White
    Write-Host "     $($PROFILE.CurrentUserAllHosts)" -ForegroundColor Green
    Write-Host ""

    while ($true) {
        $choice = Read-Prompt "Enter your choice [1 or 2]:"

        switch ($choice) {
            "1" {
                $profilePath = $PROFILE.CurrentUserCurrentHost
                $profileType = "Current User, Current Host"
                break
            }
            "2" {
                $profilePath = $PROFILE.CurrentUserAllHosts
                $profileType = "Current User, All Hosts"
                break
            }
            default {
                Write-Warning "Invalid choice. Please enter 1 or 2."
                continue
            }
        }
        break
    }

    Write-Success "Selected: $profileType"
    Write-Success "Profile: $profilePath"

    # Create profile if it doesn't exist
    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path $profileDir)) {
        Write-Warning "Profile directory doesn't exist. Creating $profileDir"
        New-Item -Path $profileDir -ItemType Directory -Force | Out-Null
        Write-Success "Created profile directory"
    }

    if (-not (Test-Path $profilePath)) {
        Write-Warning "Profile doesn't exist. Creating $profilePath"
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
        Write-Success "Created profile"
    }

    return $profilePath
}

# ============================================================================
# Step 2: Collect API Keys
# ============================================================================

function Get-ApiKeys {
    Write-Header "Step 2: Add Your API Keys"

    Write-Info "Enter your API keys (one at a time)"
    Write-Info "Press Enter with empty input when done"
    Write-Host ""

    $keys = @()
    $keyCount = 0

    while ($true) {
        $keyNum = $keyCount + 1
        $apiKey = Read-Prompt "API Key #$keyNum (or press Enter to finish):"

        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            if ($keyCount -eq 0) {
                Write-Warning "You must enter at least one API key"
                continue
            }
            break
        }

        # Basic validation
        if ($apiKey.Length -lt 20) {
            Write-Warning "API key seems too short. Are you sure it's correct?"
            $confirm = Read-Prompt "Continue anyway? [y/N]:"
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                continue
            }
        }

        $keys += $apiKey
        $keyCount++
        Write-Success "Added key #$keyNum"
    }

    Write-Host ""
    Write-Success "Total keys to add: $keyCount"

    return $keys
}

# ============================================================================
# Step 3: Review and Confirm
# ============================================================================

function Confirm-Installation {
    param(
        [string]$ProfilePath,
        [array]$Keys
    )

    Write-Header "Step 3: Review & Confirm"

    Write-Host "Summary:" -ForegroundColor White
    Write-Host "  • Profile: " -NoNewline
    Write-Host $ProfilePath -ForegroundColor Green
    Write-Host "  • Number of keys: " -NoNewline
    Write-Host $Keys.Count -ForegroundColor Green
    Write-Host ""

    Write-Warning "This will add the following to your profile:"
    Write-Host ""
    Write-Host "# claude-key-switch - API Keys" -ForegroundColor Cyan
    Write-Host "# Added by installer on $(Get-Date)" -ForegroundColor Cyan

    for ($i = 0; $i -lt $Keys.Count; $i++) {
        $keyNum = $i + 1
        Write-Host "`$env:CLAUDE_KEY_$keyNum = '<your-key-$keyNum>'" -ForegroundColor Cyan
    }
    Write-Host ""

    $confirm = Read-Prompt "Proceed with installation? [Y/n]:"

    if ($confirm -eq "n" -or $confirm -eq "N") {
        Stop-WithError "Installation cancelled by user"
    }
}

# ============================================================================
# Step 4: Install
# ============================================================================

function Install-Keys {
    param(
        [string]$ProfilePath,
        [array]$Keys
    )

    Write-Header "Step 4: Installing"

    # Create backup
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupFile = "$ProfilePath.backup-$timestamp"

    if (Test-Path $ProfilePath) {
        Copy-Item -Path $ProfilePath -Destination $backupFile -Force
        Write-Success "Created backup: $backupFile"
    }

    # Check if keys already exist
    $content = Get-Content -Path $ProfilePath -ErrorAction SilentlyContinue
    $hasExisting = $content | Where-Object { $_ -match "# claude-key-switch - API Keys" }

    if ($hasExisting) {
        Write-Warning "Found existing claude-key-switch keys in profile"
        $replace = Read-Prompt "Replace existing keys? [y/N]:"

        if ($replace -eq "y" -or $replace -eq "Y") {
            # Remove old keys section
            $newContent = @()
            $skip = $false

            foreach ($line in $content) {
                if ($line -match "# claude-key-switch - API Keys") {
                    $skip = $true
                }
                elseif ($skip -and $line -match '^\s*\$env:CLAUDE_KEY_\d+') {
                    # Skip this line
                    continue
                }
                elseif ($skip -and $line -match '^\s*$') {
                    # End of keys section
                    $skip = $false
                    continue
                }
                elseif (-not $skip) {
                    $newContent += $line
                }
            }

            $newContent | Set-Content -Path $ProfilePath -Encoding UTF8
            Write-Success "Removed old keys"
        }
        else {
            Write-Warning "Keeping existing keys. New keys will be appended."
        }
    }

    # Add keys to profile
    Add-Content -Path $ProfilePath -Value "" -Encoding UTF8
    Add-Content -Path $ProfilePath -Value "# claude-key-switch - API Keys" -Encoding UTF8
    Add-Content -Path $ProfilePath -Value "# Added by installer on $(Get-Date)" -Encoding UTF8

    for ($i = 0; $i -lt $Keys.Count; $i++) {
        $keyNum = $i + 1
        $key = $Keys[$i]
        Add-Content -Path $ProfilePath -Value "`$env:CLAUDE_KEY_$keyNum = '$key'" -Encoding UTF8
    }

    Write-Success "Added API keys to profile"

    # Add convenient alias
    $content = Get-Content -Path $ProfilePath -ErrorAction SilentlyContinue
    $hasAlias = $content | Where-Object { $_ -match "Set-Alias.*switch-key" }

    if (-not $hasAlias) {
        Add-Content -Path $ProfilePath -Value "" -Encoding UTF8
        Add-Content -Path $ProfilePath -Value "# claude-key-switch - Convenient alias" -Encoding UTF8
        Add-Content -Path $ProfilePath -Value "function Switch-Key { & '$script:SwitchScript'; . `$PROFILE }" -Encoding UTF8
        Add-Content -Path $ProfilePath -Value "Set-Alias -Name switch-key -Value Switch-Key" -Encoding UTF8
        Write-Success "Added 'switch-key' alias"
    }

    return $backupFile
}

# ============================================================================
# Step 5: Completion
# ============================================================================

function Show-Completion {
    param(
        [string]$ProfilePath,
        [int]$KeyCount,
        [string]$BackupFile
    )

    Write-Header "Installation Complete! 🎉"

    Write-Host "✓ Successfully installed claude-key-switch" -ForegroundColor Green
    Write-Host ""

    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. Reload your PowerShell profile:" -ForegroundColor White
    Write-Host "     . `"$ProfilePath`"" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. Test the installation:" -ForegroundColor White
    Write-Host "     & `"$script:SwitchScript`"" -ForegroundColor Cyan
    Write-Host "     or use the alias:" -ForegroundColor White
    Write-Host "     switch-key" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  3. View help:" -ForegroundColor White
    Write-Host "     Get-Help `"$script:SwitchScript`" -Full" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Quick Reference:" -ForegroundColor White
    Write-Host "  • Your keys are stored as: " -NoNewline
    Write-Host "CLAUDE_KEY_1, CLAUDE_KEY_2, ..." -ForegroundColor Green
    Write-Host "  • Each run switches to the next key automatically"
    Write-Host "  • Keys wrap around (last → first)"
    Write-Host "  • Backup created at: " -NoNewline
    Write-Host $BackupFile -ForegroundColor Yellow
    Write-Host ""

    Write-Host "To add more keys later:" -ForegroundColor White
    Write-Host "  Edit " -NoNewline
    Write-Host $ProfilePath -ForegroundColor Green -NoNewline
    Write-Host " and add:"
    Write-Host "  `$env:CLAUDE_KEY_$($KeyCount + 1) = 'your-new-key'" -ForegroundColor Cyan
    Write-Host ""

    Write-Info "Configuration file: $ProfilePath"
    Write-Info "Script location: $script:SwitchScript"

    Write-Host ""
    Write-Host ("━" * 50) -ForegroundColor Cyan
    Write-Host "Happy switching! 🔄" -ForegroundColor Green
    Write-Host ("━" * 50) -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# Main Logic
# ============================================================================

function Invoke-Main {
    # Check if main script exists
    if (-not (Test-Path $script:SwitchScript)) {
        Stop-WithError "claude-key-switch.ps1 not found in $script:ScriptDir"
    }

    # Welcome
    Show-Welcome

    # Step 1: Choose profile
    $profilePath = Select-Profile

    # Step 2: Collect keys
    $keys = Get-ApiKeys

    # Step 3: Confirm
    Confirm-Installation -ProfilePath $profilePath -Keys $keys

    # Step 4: Install
    $backupFile = Install-Keys -ProfilePath $profilePath -Keys $keys

    # Step 5: Completion
    Show-Completion -ProfilePath $profilePath -KeyCount $keys.Count -BackupFile $backupFile
}

# ============================================================================
# Entry Point
# ============================================================================

Invoke-Main
