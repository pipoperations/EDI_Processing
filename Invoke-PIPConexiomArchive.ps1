#!/usr/bin/pwsh
<#PSScriptinfo
.NAME
    Invoke-PIPConexiomArchive.ps1

.AUTHOR
    Brian Wood

.COMPAANY
    Protective Industrial Products, Inc.

.COPYRIGHT
    2023 (c) Protective Industrial Products, Inc. All rights reserved.

.LICENSE
    MIT License

.RELEASENOTES
    V0.01: 01.20.2024 - Initial release

.SYNOPSIS
    This script is used to archive files from the Conexiom grouped by Month Year.

#>



write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Output "Starting script"
Write-Output "The time is: $(Get-Date -Format 'HH:mm:ss')"
Write-Output "The date is: $(Get-Date -Format 'MM/dd/yyyy')"
Write-Output "`n"

# Set Global Variables
$sourcePath = "/home/conexiom_sftp/PO-in"
$monthYear = Get-Date -UFormat "%b-%Y"
$customerName = "Conexium" 

# Create the destination path
$destinationPath = Join-Path -Path "/home/eclipseftp/processed" -ChildPath $customerName
$destinationPath = Join-Path -Path $destinationPath -ChildPath $monthYear
$destinationPath = Join-Path -Path $destinationPath -ChildPath "PO"
# Create the destination directory if it doesn't exist
if (-not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

# Move all files to the destination path
$files = get-childitem -Path $sourcePath -File
foreach ($file in $files) {
    Move-Item -Path $file.FullName -Destination $destinationPath -Force -PassThru
}