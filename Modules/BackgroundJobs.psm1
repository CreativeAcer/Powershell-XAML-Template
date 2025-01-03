function Start-LongRunningProcess {
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ProcessLogic,
        
        [Parameter(Mandatory=$false)]
        [Object[]]$ArgumentList
    )
    
    Write-Host "Starting background job..."
    
    try {
        $job = Start-Job -ScriptBlock $ProcessLogic -ArgumentList $ArgumentList -ErrorAction Stop
        Write-Host "Job created with ID: $($job.Id)"
        Write-Host "Job state: $($job.State)"
        return $job
    }
    catch {
        Write-Host "Error creating job: $($_.Exception.Message)"
        return $null
    }
}


function New-ProgressTimer {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$UIElements,
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.Job]$Job
    )
    
    Write-Host "Creating timer for job: $($Job.Id)"
    
    # Store UI elements in script scope to maintain access
    $script:timerState = @{
        Timer = New-Object System.Windows.Threading.DispatcherTimer
        Job = $Job
        LastProgressValue = 0
        IsRunning = $true
        UIElements = $UIElements.Clone()
    }
    
    $script:timerState.Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    
    $script:timerState.Timer.Add_Tick({
        if (-not $script:timerState.IsRunning) {
            if ($script:timerState.Timer) { 
                $script:timerState.Timer.Stop()
                $script:timerState.Timer = $null
            }
            return
        }

        try {
            $currentJob = $script:timerState.Job
            if (-not $currentJob -or -not $currentJob.State) {
                Write-Host "Job is no longer valid"
                $script:timerState.IsRunning = $false
                if ($script:timerState.Timer) { 
                    $script:timerState.Timer.Stop()
                    $script:timerState.Timer = $null
                }
                $script:timerState.UIElements["StatusText"].Text = "Process failed!"
                $script:timerState.UIElements["StartButton"].IsEnabled = $true
                return
            }

            Write-Host "Timer tick - Job state: $($currentJob.State)"
            
            switch ($currentJob.State) {
                "Completed" {
                    Write-Host "Job completed successfully"
                    $script:timerState.IsRunning = $false
                    if ($script:timerState.Timer) { 
                        $script:timerState.Timer.Stop()
                        $script:timerState.Timer = $null
                    }
                    $script:timerState.UIElements["MainProgressBar"].Value = 100
                    $script:timerState.UIElements["StatusText"].Text = "Process completed!"
                    $script:timerState.UIElements["StartButton"].IsEnabled = $true
                    
                    # Add completion message to output
                    $script:timerState.UIElements["OutputTextBox"].Dispatcher.Invoke({
                        $script:timerState.UIElements["OutputTextBox"].AppendText("Process completed successfully!`r`n")
                        $script:timerState.UIElements["OutputTextBox"].ScrollToEnd()
                    })
                    
                    Remove-Job $currentJob -Force
                    $script:timerState.Job = $null
                }
                "Failed" {
                    Write-Host "Job failed"
                    $script:timerState.IsRunning = $false
                    if ($script:timerState.Timer) { 
                        $script:timerState.Timer.Stop()
                        $script:timerState.Timer = $null
                    }
                    $script:timerState.UIElements["StatusText"].Text = "Process failed!"
                    $script:timerState.UIElements["StartButton"].IsEnabled = $true
                    
                    # Add failure message to output
                    $script:timerState.UIElements["OutputTextBox"].Dispatcher.Invoke({
                        $script:timerState.UIElements["OutputTextBox"].AppendText("Process failed!`r`n")
                        $script:timerState.UIElements["OutputTextBox"].ScrollToEnd()
                    })
                    
                    Remove-Job $currentJob -Force
                    $script:timerState.Job = $null
                }
                "Running" {
                    $progress = Receive-Job $currentJob -Keep
                    if ($progress) {
                        $lastValue = $progress | Select-Object -Last 1
                        Write-Host "Progress update: $lastValue"
                        $script:timerState.LastProgressValue = $lastValue
                        $script:timerState.UIElements["MainProgressBar"].Value = $lastValue
                        
                        # Add progress update to output
                        $script:timerState.UIElements["OutputTextBox"].Dispatcher.Invoke({
                            $script:timerState.UIElements["OutputTextBox"].AppendText("Progress: $lastValue`r`n")
                            $script:timerState.UIElements["OutputTextBox"].ScrollToEnd()
                        })
                    }
                }
                default {
                    Write-Host "Unexpected job state: $($currentJob.State)"
                    # Add unexpected state message to output
                    $script:timerState.UIElements["OutputTextBox"].Dispatcher.Invoke({
                        $script:timerState.UIElements["OutputTextBox"].AppendText("Unexpected job state: $($currentJob.State)`r`n")
                        $script:timerState.UIElements["OutputTextBox"].ScrollToEnd()
                    })
                }
            }
        }
        catch {
            Write-Host "Error in timer tick: $($_.Exception.Message)"
            $script:timerState.IsRunning = $false
            if ($script:timerState.Timer) {
                $script:timerState.Timer.Stop()
                $script:timerState.Timer = $null
            }
            try {
                $script:timerState.UIElements["StatusText"].Text = "Error occurred!"
                $script:timerState.UIElements["StartButton"].IsEnabled = $true
                
                # Add error message to output
                $script:timerState.UIElements["OutputTextBox"].Dispatcher.Invoke({
                    $script:timerState.UIElements["OutputTextBox"].AppendText("Error occurred: $($_.Exception.Message)`r`n")
                    $script:timerState.UIElements["OutputTextBox"].ScrollToEnd()
                })
            }
            catch {
                Write-Host "Failed to update UI elements: $($_.Exception.Message)"
            }
            if ($script:timerState.Job) {
                Remove-Job $script:timerState.Job -Force -ErrorAction SilentlyContinue
                $script:timerState.Job = $null
            }
        }
    })
    
    return $script:timerState.Timer
}


function New-UIResponsivenessTimer {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$UIElements
    )
    
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(50)  # Update every 50ms for smooth animation
    
    # Store state in script scope
    $script:uiTimerState = @{
        RotationAngle = 0
        TimeFormat = "HH:mm:ss.fff"
        Timer = $timer
        UIElements = $UIElements
    }
    
    $timer.Add_Tick({
        try {
            # Update spinner rotation
            $script:uiTimerState.RotationAngle = ($script:uiTimerState.RotationAngle + 10) % 360
            $script:uiTimerState.UIElements["SpinTransform"].Angle = $script:uiTimerState.RotationAngle
            
            # Update timestamp
            $script:uiTimerState.UIElements["TimeDisplay"].Text = (Get-Date).ToString($script:uiTimerState.TimeFormat)
        }
        catch {
            Write-Host "Error updating UI responsiveness indicators: $($_.Exception.Message)"
            if ($script:uiTimerState.Timer) {
                $script:uiTimerState.Timer.Stop()
                $script:uiTimerState.Timer = $null
            }
        }
    })
    
    return $timer
}

Export-ModuleMember -Function Start-LongRunningProcess, New-ProgressTimer, New-UIResponsivenessTimer