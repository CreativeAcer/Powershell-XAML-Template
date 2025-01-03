#Called from main.ps1
# GuiManager.psm1

# Function to initialize the MainWindow
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
    
    # Initialize the global elements hashtable
    $global:MainWindowElements = @{ }
    
    # Find all named controls
    $xamlMainWindow.SelectNodes("//*[@x:Name]", $script:namespaceManager) | ForEach-Object {
        $name = $_.GetAttribute("Name", $script:namespaceManager.LookupNamespace("x"))
        $global:MainWindowElements[$name] = $mainWindow.FindName($name)
        Write-Host "Found control: $name"
    }

    # Verify all required elements were found
    $requiredElements = @("MainProgressBar", "StatusText", "StartButton", "SpinTransform", "OutputTextBox")
    if (-not ($requiredElements | ForEach-Object { $global:MainWindowElements[$_] })) {
        Write-Error "Failed to find all required UI elements"
        return
    }

    # Initialize UI responsiveness timer for the clock
    $script:uiResponsivenessTimer = New-UIResponsivenessTimer -UIElements $global:MainWindowElements
    if ($script:uiResponsivenessTimer) {
        $script:uiResponsivenessTimer.Start()
        Write-Host "UI responsiveness timer started"
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

            # Clear previous output
            $global:MainWindowElements["OutputTextBox"].Clear()
            $global:MainWindowElements["OutputTextBox"].AppendText("Starting new process...`r`n")
            
            $global:MainWindowElements["MainProgressBar"].Visibility = [System.Windows.Visibility]::Visible
            $global:MainWindowElements["StatusText"].Text = "Processing..."
            
            Write-Host "Creating background job..."

            # This function can be any function you want to pass to the background
            $demoFunction = {
                param($startValue)
                1..100 | ForEach-Object {
                    Start-Sleep -Milliseconds 100
                    $progress = $startValue + $_
                    Write-Progress -PercentComplete (($progress / 100) * 100) -Status "Processing..." -Activity "Job in Progress" -CurrentOperation "Progress: $progress"
                    Write-Output $progress  # This sends the progress value back to the main script
                }
            }

            # Define the argument value for the job
            $startValue = 0

            # Start the background job using the function and initial parameter
            $newJob = Start-LongRunningProcess -ProcessLogic $demoFunction -ArgumentList $startValue
            
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
            $global:MainWindowElements["MainProgressBar"].Visibility = [System.Windows.Visibility]::Collapsed
            $global:MainWindowElements["OutputTextBox"].AppendText("Error occurred: $($_.Exception.Message)`r`n")
        }
    })

    # Add window cleanup
    $mainWindow.Add_Closed({
        if ($script:uiResponsivenessTimer) {
            $script:uiResponsivenessTimer.Stop()
            $script:uiResponsivenessTimer = $null
            Write-Host "UI responsiveness timer stopped"
        }
    })
    
    return $mainWindow
}

Export-ModuleMember -Function Initialize-MainWindow