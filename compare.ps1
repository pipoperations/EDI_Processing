#!/usr/bin/pwsh

Import-Module Posh-SSH

# Set the SFTP server address, RSA key file path, email recipiant and target directory

$server = "sftp.highradius.com"
$keyFile = "/root/highradius_id_rsa"
$targetDirectory = "/outbound/prod/caa/ftp"
$processedDirectory = "/outbound/prod/caa/ftp/Processed"
$sftpuser = "ProtectiveIndustrialProducts"
$From = "relay@pipusa.com"
$To =  @('bwood@pipusa.com', 'thess@pipusa.com', 'aqureshi@pipusa.com')
$User = "relay@pipusa.com"
$Pword = ConvertTo-SecureString -String "vRV!Em229+Y^xYY?" -AsPlainText -Force

# Set the local directory to compare

$localDirectory = "/home/kore_sftp/outbound/prod"

#Setting credentials for the user account

$nopasswd = New-object System.Security.SecureString
$creds = New-Object System.Management.Automation.PSCredential ($sftpuser, $nopasswd)

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

# Close the SFTP session

$result = Remove-SFTPSession $sftpSession
write-host $result
