#!/usr/bin/pwsh

# FILEPATH: move_files_to_sftp.ps1

# Import the posh-ssh module
Import-Module -Name posh-ssh

# SFTP connection details
$SftpHost = "ftp.rockybrands.com"
$SftpPort = 22
$SftpUsername = "WCPGFTP"
$SftpPassword = "&d2kc@Mox2"

# Local directory path
$LocalDirectory = "/mnt/lehigh"

# SFTP directory path
$SftpDirectory = "/"
$securepassword = New-object System.Security.SecureString
$securepassword = ConvertTo-SecureString -String $SftpPassword -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ($SftpUsername, $securepassword)

# Connect to the SFTP site
$session = New-SFTPSession -ComputerName $SftpHost -Port $SftpPort -Credential $credentials

# Get all files in the local directory
$files = Get-ChildItem -Path $LocalDirectory -File

# Iterate through each file and upload it to the SFTP site
foreach ($file in $files) {
    Write-Host "Uploading $($file.Name) to $remotePath"
    try {
        Set-SFTPItem -SessionId $session.SessionId -Path $file -Destination $SftpDirectory -Force -Debug
    }
    catch {
        Write-Host "Error uploading $($file.Name): $_"
    }
}
# Disconnect from the SFTP site
Remove-SFTPSession -SessionId $session.SessionId
