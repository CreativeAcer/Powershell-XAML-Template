function Create-AppShortcut {
    param(
        [string]$DesktopPath = [Environment]::GetFolderPath('Desktop'),
        [string]$ShortcutName = "Template Powershell App.lnk"
    )

    try {
        # Ensure we have valid paths
        if (-not $DesktopPath) {
            $DesktopPath = [Environment]::GetFolderPath('Desktop')
            if (-not $DesktopPath) {
                throw "Could not determine desktop path"
            }
        }

        # Get absolute path to the launch script
        $scriptDir = $PSScriptRoot
        if (-not $scriptDir) {
            $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        }
        
        $launchScript = Join-Path -Path $scriptDir -ChildPath "Main.ps1"
        
        if (-not (Test-Path $launchScript)) {
            throw "Launch script not found at: $launchScript"
        }

        Write-Host "Creating shortcut..."
        Write-Host "Desktop Path: $DesktopPath"
        Write-Host "Launch Script: $launchScript"

        # Create shortcut
        $shell = New-Object -ComObject WScript.Shell
        $shortcutPath = Join-Path -Path $DesktopPath -ChildPath $ShortcutName
        
        Write-Host "Creating shortcut at: $shortcutPath"

        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$launchScript`""
        $shortcut.WorkingDirectory = $scriptDir
        $shortcut.IconLocation = "powershell.exe,0"
        $shortcut.Description = "Template Powershell app with XAML"
        
        # Save and verify
        $shortcut.Save()
        
        if (Test-Path $shortcutPath) {
            Write-Host "Shortcut created successfully at: $shortcutPath"
        } else {
            throw "Shortcut file was not created"
        }

        # Clean up
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shortcut) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()

        return $true
    }
    catch {
        Write-Error "Failed to create shortcut: $_"
        return $false
    }
}

# Execute the function immediately when the script is run
Create-AppShortcut