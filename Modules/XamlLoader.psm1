function Get-XamlFromFile {
    param(
        [parameter(Mandatory=$true)]
        [string]$XamlPath
    )
    
    try {
        [xml]$xaml = Get-Content -Path $XamlPath -ErrorAction Stop
        return $xaml
    }
    catch {
        Write-Error "Failed to load XAML file: $XamlPath"
        Write-Error $_.Exception.Message
        return $null
    }
}

Export-ModuleMember -Function Get-XamlFromFile