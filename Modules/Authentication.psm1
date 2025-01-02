function Test-Credentials {
    param(
        [string]$Username,
        [string]$Password
    )
    
    # Replace this with your actual authentication logic
    return $Username -eq "admin" -and $Password -eq "password"
}

function Show-LoginDialog {
    param(
        [string]$XamlPath
    )
    
    $xamlLoginWindow = Get-XamlFromFile -XamlPath $XamlPath
    if (-not $xamlLoginWindow) { return $false }
    
    $reader = [System.Xml.XmlNodeReader]::New($xamlLoginWindow)
    $loginWindow = [Windows.Markup.XamlReader]::Load($reader)
    
    $loginButton = $loginWindow.FindName("LoginButton")
    $usernameTextBox = $loginWindow.FindName("UsernameTextBox")
    $passwordBox = $loginWindow.FindName("PasswordBox")
    
    $loginButton.Add_Click({
        $username = $usernameTextBox.Text
        $password = $passwordBox.Password
        
        if (Test-Credentials -Username $username -Password $password) {
            $loginWindow.DialogResult = $true
            $loginWindow.Close()
        } else {
            [System.Windows.MessageBox]::Show("Invalid credentials!", "Error")
        }
    })
    
    return $loginWindow.ShowDialog()
}

Export-ModuleMember -Function Show-LoginDialog, Test-Credentials