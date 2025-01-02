#Called from main.ps1
function Initialize-MainWindow {
    param(
        [string]$XamlPath
    )
    
    $xamlMainWindow = Get-XamlFromFile -XamlPath $XamlPath
    if (-not $xamlMainWindow) { return }
    
    $reader = [System.Xml.XmlNodeReader]::New($xamlMainWindow)
    try {
        $mainWindow = [Windows.Markup.XamlReader]::Load($reader)
    }
    catch {
        Write-Error "Error loading XAML: $($_.Exception.Message)"
        return
    }
    
    # Create a hashtable of all named elements
    $script:namespaceManager = New-Object System.Xml.XmlNamespaceManager($xamlMainWindow.NameTable)
    $script:namespaceManager.AddNamespace("x", "http://schemas.microsoft.com/winfx/2006/xaml")
    $xamlMainWindow.SelectNodes("//*[@x:Name]", $script:namespaceManager) | ForEach-Object {
        $global:MainWindowElements = @{}
    
        # Initialize UI elements and store them in the global hashtable
        $global:MainWindowElements["ProgressBar"] = $mainWindow.FindName("MainProgressBar")
        $global:MainWindowElements["StatusText"] = $mainWindow.FindName("StatusText")
        $global:MainWindowElements["StartButton"] = $mainWindow.FindName("StartButton")
        
        # Verify all elements were found
        if (-not ($global:MainWindowElements["ProgressBar"] -and 
                $global:MainWindowElements["StatusText"] -and 
                $global:MainWindowElements["StartButton"])) {
            Write-Error "Failed to find all required UI elements"
            return
        }
        
        # Configure start button click event
        $global:MainWindowElements["StartButton"].Add_Click({
            Write-Host "Start button clicked"
            
            try {
                # Disable start button immediately to prevent multiple clicks
                $global:MainWindowElements["StartButton"].IsEnabled = $false
                
                # Clean up any existing job and timer
                if ($script:timerState) {
                    Write-Host "Cleaning up previous job state..."
                    $script:timerState.IsRunning = $false
                    if ($script:timerState.Timer) {
                        $script:timerState.Timer.Stop()
                        $script:timerState.Timer = $null
                    }
                    if ($script:timerState.Job) {
                        Remove-Job $script:timerState.Job -Force -ErrorAction SilentlyContinue
                        $script:timerState.Job = $null
                    }
                }

                $global:MainWindowElements["ProgressBar"].Visibility = [System.Windows.Visibility]::Visible
                $global:MainWindowElements["StatusText"].Text = "Processing..."
                
                Write-Host "Creating background job..."
                $newJob = Start-LongRunningProcess -ProcessLogic {
                    try {
                        # Simulate long-running process
                        1..100 | ForEach-Object {
                            Start-Sleep -Milliseconds 50
                            Write-Output $_
                            Write-Host "Progress: $_"
                        }
                    }
                    catch {
                        Write-Error "Error in background process: $($_.Exception.Message)"
                        throw
                    }
                }
                
                if ($newJob -and $newJob.State) {
                    Write-Host "Job created: $($newJob.Id) - State: $($newJob.State)"
                    $timer = New-ProgressTimer -UIElements $global:MainWindowElements -Job $newJob
                    if ($timer) {
                        $timer.Start()
                        Write-Host "Timer started"
                    }
                    else {
                        throw "Failed to create timer"
                    }
                }
                else {
                    throw "Failed to create valid background job"
                }
            }
            catch {
                Write-Host "Error in button click handler: $($_.Exception.Message)"
                $global:MainWindowElements["StatusText"].Text = "Error occurred!"
                $global:MainWindowElements["StartButton"].IsEnabled = $true
                $global:MainWindowElements["ProgressBar"].Visibility = [System.Windows.Visibility]::Collapsed
            }
        })
        
        return $mainWindow
    }
}

Export-ModuleMember -Function Initialize-MainWindow







Export-ModuleMember -Function Initialize-MainWindow