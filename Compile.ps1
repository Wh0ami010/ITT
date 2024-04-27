


param (
    [string]$OutputScript = "itt.ps1",
    [string]$StartScript = ".\Scripts\start.ps1",
    [string]$FunctionsDirectory = ".\Functions",
    [string]$DatabaseDirectory = ".\Database",
    [string]$InterfaceDirectory = ".\interface",
    [string]$LoopsDirectory = ".\loops",
    [string]$LoadXamlScript = ".\scripts\loadXmal.ps1",
    [string]$MainScript = ".\scripts\main.ps1"
)

# Initialize synchronized hashtable
$OFS = "`r`n"
$sync = [Hashtable]::Synchronized(@{})
$sync.PSScriptRoot = $PSScriptRoot
$sync.configs = @{}


# Function to write content to output script
function WriteToScript {
    param (
        [string]$Content
    )
    Add-Content -Path $OutputScript -Value $Content
}

# Function to handle file content generation
function AddFileContentToScript {
    param (
        [string]$FilePath
    )
    $Content = Get-Content -Path $FilePath -Raw
    WriteToScript -Content $Content
}

# Function to process files in a directory
function ProcessDirectory {
    param (
        [string]$Directory
    )
    Get-ChildItem $Directory -Recurse -File | ForEach-Object {
        AddFileContentToScript -FilePath $_.FullName
    }
}

# Main script generation
try {
    if (Test-Path -Path $OutputScript) {
        Remove-Item -Path $OutputScript -Force
    }

    # Write script header
    WriteToScript -Content @"
# ###################################################################################
# #                                                                                 #
# #   ___ _____ _____   _____ __  __    _    ____    _    ____  _____ _    _  _     #
# #  |_ _|_   _|_   _| | ____|  \/  |  / \  |  _ \  / \  |  _ \| ____| |  | || |    #
# #   | |  | |   | |   |  _| | |\/| | / _ \ | | | |/ _ \ | | | |  _| | |  | || |_   #
# #   | |  | |   | |   | |___| |  | |/ ___ \| |_| / ___ \| |_| | |___| |__|__   _|  #
# #  |___| |_|   |_|   |_____|_|  |_/_/   \_\____/_/   \_\____/|_____|_____| |_|    #
# #                                                                                 #
# #                     This file is automatically generated                        #
# #                          https://github.com/emadadel4                           #
# #                          https://t.me/emadadel4                                 #  
# #                                                                                 #
# ###################################################################################
"@

    WriteToScript -Content @"

#===========================================================================
#region End Start
#===========================================================================

"@

    AddFileContentToScript -FilePath $StartScript

    WriteToScript -Content @"
#===========================================================================
#endregion End Start
#===========================================================================

"@


    WriteToScript -Content @"
#===========================================================================
#region Start Functions
#===========================================================================

"@

    ProcessDirectory -Directory $FunctionsDirectory

    WriteToScript -Content @"
#===========================================================================
#endregion End Functions
#===========================================================================

"@


    WriteToScript -Content @"
#===========================================================================
#region Start Database /APPS/TWEEAKS/Quotes/OST
#===========================================================================

"@

    Get-ChildItem .\Database | Where-Object {$psitem.extension -eq ".json"} | ForEach-Object {
        $json = (Get-Content $psitem.FullName -Raw).replace("'", "''")
        $sync.configs.$($psitem.BaseName) = $json | ConvertFrom-Json
        Write-output "`$sync.configs.$($psitem.BaseName) = '$json' `| ConvertFrom-Json" | Out-File ./itt.ps1 -Append -Encoding default
    }

    WriteToScript -Content @"
#===========================================================================
#endregion End Database /APPS/TWEEAKS/Quotes/OST
#===========================================================================

"@

    WriteToScript -Content @"
#===========================================================================
#region Start WPF Window
#===========================================================================

"@

    $XamlPath = Join-Path -Path $InterfaceDirectory -ChildPath "window.xaml"
    $AppXamlPath = Join-Path -Path $InterfaceDirectory -ChildPath "Controls/taps.xaml"
    $StylePath = Join-Path -Path $InterfaceDirectory -ChildPath "Themes/style.xaml"
    $ColorsPath = Join-Path -Path $InterfaceDirectory -ChildPath "Themes/colors.xaml"

    $XamlContent = (Get-Content -Path $XamlPath -Raw) -replace "'", "''"
    $AppXamlContent = Get-Content -Path $AppXamlPath -Raw
    $StyleContent = Get-Content -Path $StylePath -Raw
    $ColorsContent = Get-Content -Path $ColorsPath -Raw

    $XamlContent = $XamlContent -replace "{{Taps}}", $AppXamlContent
    $XamlContent = $XamlContent -replace "{{Style}}", $StyleContent
    $XamlContent = $XamlContent -replace "{{Colors}}", $ColorsContent

   
    $AppsCheckboxes  = ""
    foreach ($App  in $sync.configs.applications) {
        $AppsCheckboxes += @"
    <CheckBox Content="$($App.Name)" Tag="$($App.category)" />
"@
    }

    $TweaksCheckboxes  = ""
    foreach ($Tweak  in $sync.configs.tweaks) {
        $TweaksCheckboxes  += @"
    <CheckBox Content="$($Tweak.Name)" />
"@
}


    $XamlContent = $XamlContent -replace "{{Apps}}", $AppsCheckboxes 
    $XamlContent = $XamlContent -replace "{{Tweeaks}}", $TweaksCheckboxes 

    WriteToScript -Content "`$inputXML = '$XamlContent'"

    WriteToScript -Content @"
#===========================================================================
#endregion End WPF Window
#===========================================================================

"@

    WriteToScript -Content @"
#===========================================================================
#region Start loadXmal
#===========================================================================

"@

    AddFileContentToScript -FilePath $LoadXamlScript

    WriteToScript -Content @"
#===========================================================================
#endregion End loadXmal
#===========================================================================

"@

    # Write Loops section
    WriteToScript -Content @"
#===========================================================================
#region Start Loops
#===========================================================================

"@

    ProcessDirectory -Directory $LoopsDirectory

    WriteToScript -Content @"
#===========================================================================
#endregion Start Loops
#===========================================================================

"@

    # Write Main [Buttons Events] section
    WriteToScript -Content @"
#===========================================================================
#region Start Main [Buttons Events]
#===========================================================================

"@

    AddFileContentToScript -FilePath $MainScript

    WriteToScript -Content @"
#===========================================================================
#endregion End Main [Buttons Events]
#===========================================================================

"@

./itt.ps1

}


catch {
    Write-Error "An error occurred: $_"
}
