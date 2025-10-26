<#
    Script Name: Get-CustomLogs.ps1
    Description: This script collects logs from predefined locations on a Windows machine, compresses them into a ZIP file, and uploads the ZIP file to an Azure Blob Storage using AzCopy.
    Author: Bruno Siqueira
    Releases:
        - 1.0 | 2025-10-25 | Initial version

    Notes:
        - Customize the $logsToCollect array to specify which log paths to collect.
        - Set the $registryInventory variable to $true if you want to export registry information.
        - The script uses a SAS URL for uploading to Azure Blob Storage; ensure the URL has appropriate permissions.
#>

## Script configuration
$registryInventory = $true                                                                              # Set to $true to export registry information, $false to skip
$logsToCollect = @(                                                                                     # Array of hashtables defining log source paths and destination folder names
    @{
        LogSourcePath = "$env:WinDir\Logs\Software"                                                     # Path where the original log files are located
        DstFolderName = 'Software_Logs'                                                                 # Name of the destination folder to store the log files that will be collected
    },
    @{
        LogSourcePath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs"
        DstFolderName = 'IME_Logs'
    },
    @{
        LogSourcePath = "$env:WinDir\System32\winevt\Logs"
        DstFolderName = 'WinEvent_Logs'
    }
)

## Sets variables
$baseFolderPath = (Join-Path -Path $env:Temp -ChildPath 'CollectedLogs')                                                # Full path to the base folder
$logFolderName = "CustomLogs-$($env:COMPUTERNAME)-$(Get-Date -Format FileDateTimeUniversal)"                            # Unique folder name for the log collection
$logFileName = $logFolderName + '.zip'                                                                                  # Name of the final ZIP file
$logFolderPath = (Join-Path -Path $baseFolderPath -ChildPath $logFolderName)                                            # Full path to the log folder

try {
    ## Creates the destination folder structure
    New-Item -Path $logFolderPath -ItemType Directory -Force

    ## Go through the list, copying the logs to the specific destination folder
    $logsToCollect | ForEach-Object {
        New-Item -Path $logFolderPath -Name $_.DstFolderName -ItemType Directory -Force                                 # Creates the destination subfolder   
        Copy-Item -Path "$($_.LogSourcePath)\*" -Destination "$logFolderPath\$($_.DstFolderName)" -Recurse -Force       # Copies the logs files to the destination folder
    }

    ## Export registry information
    if ($registryInventory) {
        New-Item -Path $logFolderPath -Name 'Registry' -ItemType Directory -Force
        Start-Process -FilePath "reg.exe" -ArgumentList "EXPORT HKEY_LOCAL_MACHINE\SOFTWARE `"$logFolderPath\Registry\HKLM_SOFTWARE.reg`"" -WindowStyle Hidden -Wait
        Start-Process -FilePath "reg.exe" -ArgumentList "EXPORT HKEY_LOCAL_MACHINE\SYSTEM `"$logFolderPath\Registry\HKLM_SYSTEM.reg`"" -WindowStyle Hidden -Wait
    }

    ## Compacts the log folder
    Compress-Archive -Path $logFolderPath -DestinationPath $logFolderPath -CompressionLevel Optimal

    ## Download and extract AzCopy
    $azcopyDownloadUrl = "https://aka.ms/downloadazcopy-v10-windows"                                                    # AzCopy download URL
    $azcopyFilePath = (Join-Path -Path $baseFolderPath -ChildPath "azcopy.zip")                                         # Path to store the downloaded AzCopy ZIP file
    Start-BitsTransfer -Source $azcopyDownloadUrl -Destination $azcopyFilePath                                          # Download AzCopy
    Expand-Archive -LiteralPath $azcopyFilePath -DestinationPath "$baseFolderPath\" -Force                              # Extract AzCopy 
    Copy-Item -Path "$baseFolderPath\*\azcopy.exe" -Destination $baseFolderPath                                         # Move AzCopy executable to base folder

    ## Upload the Zip file to the Blob Storage using AzCopy
    $sasUrlroot = 'https://springintune01.blob.core.windows.net/intune-software-logs'
    $sasUrl = 'https://springintune01.blob.core.windows.net/intune-software-logs?sp=racw&st=2025-10-24T18:46:43Z&se=2035-10-25T03:01:43Z&spr=https&sv=2024-11-04&sr=c&sig=G7Mh%2F5Bwk13q6ti39Cf1rq%2FPOosFzktF0NzJOPiP1X4%3D'
    Start-Process -FilePath "$baseFolderPath\azcopy.exe" -ArgumentList "copy $logFileName $sasUrl" -WorkingDirectory $baseFolderPath -NoNewWindow -Wait
    $logFileUrl = "$sasUrlroot/$logFileName"

    ## Cleanup
    Remove-Item -Path $baseFolderPath -Recurse -Force -ErrorAction SilentlyContinue

    ## Outputs the URL to download the uploaded log file
    Write-Host "Use this URL to download the log file: $logFileUrl"
}
catch {
    Write-Host "An error occurred: $_ | Stack Trace: $($_.ScriptStackTrace)"
}
