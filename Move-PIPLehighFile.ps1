#!/usr/bin/pwsh
<#PSScriptInfo
.NAME
    Move-PIPLehighFile.ps1

.AUTHOR
    Brian Wood

.COMPANYNAME
    Protective Industrial Products, Inc.

.COPYRIGHT
    2023 Protective Industrial Products, Inc.

.LICENSE
    MIT License

.RELEASENOTES
    v1.0.0 - 2023-12-12 - Initial release
    v1.0.1 - 2023-12-13 - Added archive directory of processed files

.SYNOPSIS
    This script will move files from a local directory to an SFTP site.

#>
begin {
    # Import the posh-ssh module
    Import-Module -Name posh-ssh

    # SFTP connection details
    $SftpHost = "ftp.rockybrands.com"
    $SftpPort = 22
    $SftpUsername = "WCPGFTP"
    $SftpPassword = "&d2kc@Mox2"

    # Local directory path
    $LocalDirectory = "/mnt/lehigh"
    $customer = "Lehigh"
    $ProcessedPath = "/home/eclipseftp/processed/"

    # SFTP directory path
    $SftpDirectory = "/"
    $securepassword = New-object System.Security.SecureString
    $securepassword = ConvertTo-SecureString -String $SftpPassword -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential ($SftpUsername, $securepassword)
    write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    Write-Output "Starting script"
    Write-Output "The time is: $(Get-Date -Format 'HH:mm:ss')"
    Write-Output "The date is: $(Get-Date -Format 'MM/dd/yyyy')"
    Write-Output "`n"

    function Move-PIPProcessedCustomerFile {
        <#
        .SYNOPSIS
            Proceedure to Move customer files to the processed directory
        #>
        param (
            [Alias(Path)] [string]$FileName,
            [string] $Customer
        )
    
        # Get the current date in "yyyy-MM-dd" format
        $date = Get-Date -UFormat "%b-%Y"
    
        # Create the full path
        $fullPath = Join-Path -Path $ProcessedPath -ChildPath $Customer
        $fullPath = Join-Path -Path $fullPath -ChildPath $date
        
        # Check if the path exists
        if (-not (Test-Path -Path $fullPath)) {
    
            # If the path doesn't exist, create it
            New-Item -Path $fullPath -ItemType Directory
        }
        Move-Item -Path $FileName -Destination $fullPath -Force
    }
}
process {
    # Connect to the SFTP site
    $session = New-SFTPSession -ComputerName $SftpHost -Port $SftpPort -Credential $credentials

    # Get all files in the local directory
    $files = Get-ChildItem -Path $LocalDirectory -File

    # Iterate through each file and upload it to the SFTP site
    foreach ($file in $files) {
        Write-Host "Uploading $($file.Name) to $remotePath"
        try {
            Set-SFTPItem -SessionId $session.SessionId -Path $file -Destination $SftpDirectory -Force 
            Move-PIPProcessedCustomerFile -Path $file -Customer $customer
        }   
        catch {
            Write-Host "Error uploading $($file.Name): $_"
        }
    }
}
end {
    # Disconnect from the SFTP site
    Remove-SFTPSession -SessionId $session.SessionId
}