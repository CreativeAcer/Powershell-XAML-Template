# PowerShell GUI Template

A modular, XAML-based PowerShell GUI application template designed to serve as a starting point for building Windows desktop applications. This template demonstrates best practices for structuring a PowerShell GUI project, including proper separation of concerns, background job handling, and theme management.

## Features

- 🔒 Login system with customizable authentication
- 🎨 Themeable UI using XAML
- 🧩 Modular architecture for easy expansion
- 🔄 Background job processing with progress tracking
- 📊 Progress bar demonstration
- 🎯 Clean and organized project structure

## Project Structure

```
MyPowerShellApp/
├── src/
│   ├── GUI/
│   │   ├── MainWindow.xaml       # Main application window
│   │   └── LoginWindow.xaml      # Login window
│   ├── Modules/
│   │   ├── Authentication.psm1   # Login and authentication logic
│   │   ├── GuiManager.psm1       # Window management
│   │   ├── BackgroundJobs.psm1   # Background processing
│   │   └── XamlLoader.psm1       # XAML file handling
│   ├── Themes/
│   │   └── Theme.ps1             # UI theme definitions
│   └── Main.ps1                  # Application entry point
└── README.md
```

## Requirements

- Windows PowerShell 5.1 or later
- .NET Framework 4.5 or later
- Administrator privileges (for background jobs)

## Quick Start

1. Clone the repository
2. Navigate to the src directory
3. Run Main.ps1 as Administrator
4. Login with default credentials:
   - Username: admin
   - Password: password

## Customization Guide

### Modifying the Theme
Edit `src/Themes/Theme.ps1` to customize colors and styles:

```powershell
$Global:AppTheme = @{
    PrimaryColor = "#1E90FF"          # Change primary color
    SecondaryColor = "#4682B4"        # Change secondary color
    BackgroundColor = "#F0F8FF"       # Change background
    # Add more theme properties as needed
}
```

### Adding New Windows
1. Create a new XAML file in the GUI folder
2. Create a corresponding management function in GuiManager.psm1
3. Add initialization in Main.ps1

### Implementing Custom Authentication
Modify `src/Modules/Authentication.psm1`:

```powershell
function Test-Credentials {
    param(
        [string]$Username,
        [string]$Password
    )
    # Add your authentication logic here
    # Return $true for valid credentials
}
```

### Adding Background Tasks
1. Modify the ProcessLogic scriptblock in GuiManager.psm1
2. Update progress reporting as needed
3. Customize error handling

## Best Practices

- Keep UI logic separate from business logic
- Use the provided module structure for new features
- Follow the existing error handling patterns
- Maintain proper cleanup of background jobs
- Use script-scoped variables carefully

## Common Customizations

1. **Change Window Size/Layout**
   - Modify the XAML files in the GUI folder
   - Adjust Grid/StackPanel properties

2. **Add New Controls**
   - Add XAML elements to window files
   - Create corresponding handlers in GuiManager.psm1

3. **Modify Progress Tracking**
   - Update BackgroundJobs.psm1 timer settings
   - Adjust progress bar behavior

4. **Add New Features**
   - Create new module in Modules folder
   - Import in Main.ps1
   - Add UI elements as needed

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with PowerShell and Windows Presentation Foundation (WPF)
- Uses XAML for UI definitions
- Incorporates modern PowerShell best practices