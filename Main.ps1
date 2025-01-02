Add-Type -AssemblyName PresentationFramework
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import required modules
$modulePath = Join-Path $scriptPath "Modules"
Get-ChildItem -Path $modulePath -Filter "*.psm1" | ForEach-Object {
    Import-Module $_.FullName -Force
}

# Import theme
. "$scriptPath\Themes\Theme.ps1"

# Define paths
$loginXamlPath = Join-Path $scriptPath "GUI\LoginWindow.xaml"
$mainXamlPath = Join-Path $scriptPath "GUI\MainWindow.xaml"

# Main execution
if (Show-LoginDialog -XamlPath $loginXamlPath) {
    $mainWindow = Initialize-MainWindow -XamlPath $mainXamlPath
    $mainWindow.ShowDialog()
}