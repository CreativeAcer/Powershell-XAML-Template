# PowerShell GUI Template

A modern PowerShell GUI application template demonstrating non-blocking background task execution with real-time progress updates. This template showcases how to build responsive Windows desktop applications using PowerShell and XAML, with a focus on proper thread management and UI responsiveness.

## Key Features

- 🔄 Non-blocking background task execution
- 📊 Real-time progress updates with visual feedback
- ⚡ Responsive UI with visual confirmation
- 🎯 Thread-safe UI updates
- 🧩 Modular, maintainable architecture
- 🎨 Customizable XAML-based interface

## Core Concepts

### Thread Management
- Main UI thread remains responsive during long operations
- Background jobs handle intensive processing
- Visual indicator confirms UI thread responsiveness
- Timer-based progress updates without blocking

### Progress Tracking
- Real-time progress bar updates
- Status text updates for operation states
- Visual spinning indicator for UI responsiveness
- Timestamp display showing active UI thread

## Project Structure

```
MyPowerShellApp/
├── src/
│   ├── GUI/
│   │   ├── MainWindow.xaml       # Main window with progress elements
│   │   └── LoginWindow.xaml      # Authentication interface
│   ├── Modules/
│   │   ├── Authentication.psm1   # Login functionality
│   │   ├── GuiManager.psm1       # Window and control management
│   │   ├── BackgroundJobs.psm1   # Thread and progress handling
│   │   └── XamlLoader.psm1       # XAML parsing utilities
│   ├── Themes/
│   │   └── Theme.ps1             # UI customization
│   ├── Create-AppShortcut.ps1    # Script that creates the shortcut to the app
│   ├── Create-Shortcut.bat       # Run this file to create the desktop shortcut
│   └── Main.ps1                  # Application entry point
└── README.md
```

## How It Works

### Background Job Processing
```powershell
# BackgroundJobs.psm1 handles threaded operations
function Start-LongRunningProcess {
    param([ScriptBlock]$ProcessLogic)
    # Creates separate thread for intensive tasks
    $job = Start-Job -ScriptBlock $ProcessLogic
    return $job
}
```

### Progress Monitoring
```powershell
# Timer-based progress updates
function New-ProgressTimer {
    # Updates UI elements safely from background thread
    # Maintains UI responsiveness during processing
}
```

### UI Thread Indicator
```powershell
# Visual confirmation of responsive UI
function New-UIResponsivenessTimer {
    # Spinning animation and timestamp
    # Freezes if UI thread blocks
}
```

## Key Components

### 1. Background Job Management
- Separate thread for intensive operations
- Non-blocking progress updates
- Safe job cleanup and error handling

### 2. UI Responsiveness
- Spinning indicator shows active UI thread
- Real-time timestamp updates
- Visual feedback for user operations

### 3. Progress Tracking
- Progress bar with percentage complete
- Status text updates
- Detailed operation logging

## Implementation Examples

### Starting a Background Task
```powershell
$newJob = Start-LongRunningProcess -ProcessLogic {
    # Your intensive operation here
    1..100 | ForEach-Object {
        Start-Sleep -Milliseconds 50
        Write-Output $_  # Reports progress
    }
}
```

### Monitoring Progress
```powershell
$timer = New-ProgressTimer -UIElements $UIElements -Job $newJob
$timer.Start()  # Begins progress tracking
```

## Best Practices

1. **Thread Safety**
   - Use dispatcher for UI updates
   - Maintain proper job cleanup
   - Handle cross-thread operations safely

2. **Progress Updates**
   - Regular, non-blocking updates
   - Clear status communication
   - Proper error handling

3. **UI Responsiveness**
   - Visual confirmation of active UI
   - Proper thread management
   - Clean state management

## Customization

### 1. Modify Background Tasks
```powershell
# Update ProcessLogic in GuiManager.psm1
$ProcessLogic = {
    # Your custom processing here
    # Use Write-Output for progress
}
```

### 2. Update Progress Visualization
- Modify MainWindow.xaml for different progress elements
- Adjust timer intervals in BackgroundJobs.psm1
- Customize progress reporting format

### 3. Add Features
- Create new module files for additional functionality
- Update GuiManager.psm1 for new UI interactions
- Extend BackgroundJobs.psm1 for different job types

## Requirements

- Windows PowerShell 5.1+
- .NET Framework 4.5+
- Administrator privileges

## License

MIT License - See LICENSE file for details.

This template demonstrates proper thread management and UI responsiveness in PowerShell GUI applications, serving as a foundation for building desktop tools with background processing capabilities.