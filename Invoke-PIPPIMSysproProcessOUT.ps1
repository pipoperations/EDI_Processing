<#PSScriptinfo
.NAME
    Invoke-PIPPIMSysproProcessOUT.ps1

.AUTHOR
    Brian Wood
    
.COMPANY
    Protective Industrial Products, Inc.

.COPYRIGHT
    2023 (c) Protective Industrial Products, Inc. All rights reserved.

.LICENSE
    MIT License

.RELEASE NOTES
    1.0.0 - 2023-11-27 - Initial release

#>

# Get the current date and time
$currentDateTime = Get-Date
Write-Output "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Output "Current date and time: $currentDateTime"


# Move files from /home/syspro_sftp/msg-out with names starting with "PIMDATA" to /mnt/cifs-prod/import
$sourcePath = "/home/syspro_sftp/msg-out"
$destinationPath = "/mnt/cifs-prod/import"
$archivePath = "/home/syspro_sftp/msg-out/archive"

Get-ChildItem -Path $sourcePath -Filter "PIMDATA*" | ForEach-Object {
    # Check if the file is newer than 24 hours
    if ($_.LastWriteTime -gt $currentDateTime.AddHours(-24)) {
        # Copy the file to the archive folder
        Write-Output "Copying $($_.Name) to $archivePath"
        Copy-Item -Path $_.FullName -Destination $archivePath
        # Move the file to the destination folder
        Write-Output "Moving $($_.Name) to $destinationPath"
        Move-Item -Path $_.FullName -Destination $destinationPath
    }
}