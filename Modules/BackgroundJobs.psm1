function Start-LongRunningProcess {
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$ProcessLogic
    )
    
    Write-Host "Starting background job..."
    
    try {
        $job = Start-Job -ScriptBlock $ProcessLogic -ErrorAction Stop
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
                    $script:timerState.UIElements["ProgressBar"].Value = 100
                    $script:timerState.UIElements["StatusText"].Text = "Process completed!"
                    $script:timerState.UIElements["StartButton"].IsEnabled = $true
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
                    Remove-Job $currentJob -Force
                    $script:timerState.Job = $null
                }
                "Running" {
                    $progress = Receive-Job $currentJob -Keep
                    if ($progress) {
                        $lastValue = $progress | Select-Object -Last 1
                        Write-Host "Progress update: $lastValue"
                        $script:timerState.LastProgressValue = $lastValue
                        $script:timerState.UIElements["ProgressBar"].Value = $lastValue
                    }
                }
                default {
                    Write-Host "Unexpected job state: $($currentJob.State)"
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

Export-ModuleMember -Function Start-LongRunningProcess, New-ProgressTimer