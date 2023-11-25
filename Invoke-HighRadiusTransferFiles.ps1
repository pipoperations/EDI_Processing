#!/usr/bin/pwsh
<#PSScriptinfo
.NAME
   Invoke-HighRadiusTransferFiles.ps1

.AUTHER
   Brian Wood

.TODO
   Clean up comments and documentation

.RELEASE NOTES
   1.0.0 - 2023-10-20 - Initial release

.SYNOPSIS
   This script will connect to the HighRadius SFTP server and download files to the local directory. It will then move the files to the remote processed directory.
   This script does not take arguments. It is designed to be run as a cron job.

#>

[CmdletBinding()]
param (
)

begin {

   Import-Module Posh-SSH

   # Set the SFTP server address, RSA key file path, email recipiant and target directory

   $server = "sftp.highradius.com"
   $keyFile = "/root/highradius_id_rsa"
   $targetDirectory = "/outbound/prod/caa/ftp"
   $processedDirectory = "/outbound/prod/caa/ftp/Processed"
   $sftpuser = "ProtectiveIndustrialProducts"
   $From = "relay@pipusa.com"
   $To =  @('bwood@pipusa.com', 'thess@pipusa.com')
   $User = "relay@pipusa.com"
   $Pword = ConvertTo-SecureString -String "vRV!Em229+Y^xYY?" -AsPlainText -Force

   # Set the local directory to compare

   $localDirectory = "/home/kore_sftp/outbound/prod"

   #Setting credentials for the user account

   $nopasswd = New-object System.Security.SecureString
   $creds = New-Object System.Management.Automation.PSCredential ($sftpuser, $nopasswd)
}

process {
   $today = Get-Date -UFormat "%A %m/%d/%Y %R %Z"
   Write-Host $today
   Write-Host "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

   # Log in to the SFTP server using the RSA key

   $sftpSession = New-SFTPSession -ComputerName $server -Credential $creds -KeyFile $keyFile

   # List files in the target directory

   $remoteFiles = Get-SFTPChildItem -SessionId $sftpSession.SessionId -Path $targetDirectory -File

   # List files in the local directory

   $ProcessedFiles = Get-SFTPChildItem -SessionId $sftpSession.SessionId -Path $processedDirectory -File

   # Compare both directories and verify that there aren't any duplicate file names
   $remoteFilenames = $remoteFiles | Select-Object -ExpandProperty Name
   $ProcessedFilenames = $ProcessedFiles| Select-Object -ExpandProperty Name
   if ($ProcessedFilenames -and $remoteFilenames) {
      $duplicates = Compare-Object $remoteFilenames $ProcessedFilenames -IncludeEqual | Where-Object { $_.SideIndicator -eq "==" }
   }

   # Send and email and exit if duplicates are found. If no duplicates are found, download the files and then move the remote files to the remote processed directory

   if ($duplicates) {
      $Body = "Transfer failed! Duplicate files found! EXITING! `n`n" + ($remoteFiles.name -join "`n")
      $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pword
      $response = Send-MailMessage -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -To $To -From $From -Subject "HighRadius Transfer Failed!" -Body $Body
      Write-Warning $Body
      exit
   } else {
      Foreach ($file in $remoteFiles) {
         Get-SFTPItem -SessionId $sftpSession.SessionId -Path $file.FullName -Destination $localDirectory -Verbose
         $destinationFilePath = Join-Path -Path $processedDirectory -ChildPath $file.Name
         Move-SFTPItem -SessionId $sftpSession.SessionId -Path $file.FullName -Destination $destinationFilePath -Verbose
      }
      $Body = "Transfer! `n`n" + ($remoteFiles.name -join "`n")
      $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pword
      $response = Send-MailMessage -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -To $To -From $From -Subject "HighRadius Transfer Success!" -Body $Body
      Write-Host $Body
   }
}
end {
   
      # Close the SFTP session
   
      $result = Remove-SFTPSession $sftpSession
      write-host $result
}

