#!/usr/bin/pwsh
<#PSScriptinfo
.NAME
    Invoke-PIPPIMSysproProcessIN.ps1

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
    1.1.0 - 2023-12-01 - Added functionality to copy files newer than 24 hours and archive msg-out files
    1.2.0 - 2023-12-02 - Added output to show what's being done
    1.2.1 - 2023-12-02 - Added current date and time at the beginning of the script

#>

$currentDateTime = Get-Date
Write-Output "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Output "Current date and time: $currentDateTime"

# Define the new owner
$newOwner = "syspro_sftp:syspro_sftp"

# Get the current date and time
$currentDateTime = Get-Date

# Move files from /mnt/cifs-prod/export/syspro to /home/syspro_sftp/msg-in
$sourcePath = "/mnt/cifs-prod/export/syspro"
$destinationPath = "/home/syspro_sftp/msg-in"

Get-ChildItem -Path $sourcePath | ForEach-Object {
    # Check if the file is newer than 24 hours
    if ($_.LastWriteTime -gt $currentDateTime.AddHours(-24)) {
        Write-Output "Copying $($_.Name) to $destinationPath"
        Copy-Item -Path $_.FullName -Destination $destinationPath
        Write-Output "Changing owner of $($_.Name) to $newOwner"
        Invoke-Expression -Command "chown $newOwner '$destinationPath/$($_.Name)'"
    }
}


