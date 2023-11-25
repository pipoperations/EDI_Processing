<#PSScriptInfo
.NAME
    Get-PIPRiskDetections.ps1

.AUTHOR
    Brian Wood

.COMPANY
    Protective Industrial Products, Inc.

.COPYRIGHT
    2023 (c) Protective Industrial Products, Inc. All rights reserved.

.LICENSE
    MIT License

.RELEASE
    1.0.2 

.RELEASE NOTES
    1.0.0   2021-09-22  Brian Wood  Initial release.
    1.0.1   2022-09-22  Brian Wood  Added Certificate Authentication
    1.0.2   2023-11-24  Brian Wood  Updated comments and code cleanup

.SYNOPSIS
    This script will get the risk detections from Azure AD and send an email to the specified recipients.

#>

<#
.NOTES
    # Do some prep work
    $StoreName = [System.Security.Cryptography.X509Certificates.StoreName]
    $StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]
    $OpenFlags = [System.Security.Cryptography.X509Certificates.OpenFlags]
    $Store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
    $StoreName::My, $StoreLocation::CurrentUser)

    # Get a certificate
    $X509Certificate2 = [System.Security.Cryptography.X509Certificates.X509Certificate2]
    $CertPath = (Resolve-Path -LiteralPath '/etc/ssl/certs/star.pipusa.com.pfx').Path
    $Cert = $X509Certificate2::New($CertPath, 'pipusa')

    # Open the store, Add the cert, Close the store.
    $Store.Open($OpenFlags::ReadWrite)
    $Store.Add($Cert)
    $Store.Close()

#>
#Requires -Modules Microsoft.Graph.Identity.SignIns
begin {
    Import-Module -Name Microsoft.Graph.Identity.SignIns
    Select-MgProfile -Name beta
    #Generate Access Token to use in the connection string to MSGraph
    $AppId = 'b78d8f62-a6c6-487c-be33-abde8889bf70'
    $TenantId = '75ec60a8-d8f4-473b-8b5d-1b449c3cba33'
}
process {
    #Connect to Graph using certificate
    Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint "3FA3380639EDEA475D094DA4624E09BD1E75F874"
    #Get Risk Detections in the Past 24 hours and create the message body
    $Body = (Get-MgRiskDetection -All -Sort ActivityDateTime | Where-Object {$_.ActivityDateTime -gt (Get-Date).AddDays(-1)} | Select-Object -Unique -Property UserDisplayName,RiskEventType,DetectionTimingType,IPAddress,RiskLevel,RiskState,ActivityDateTime)
    if (!$Body){
        $Body = ("There have been no risk detections in the past 24 hours!")
    }
    else{

        $Body = ($Body | ConvertTo-html | Out-String -Width 50)
    }
}
end {
    #Send an email using the relay account
    $From = "azurealerts@pipusa.com"
    $To = @('bwood@pipusa.com', 'egutowski@pipusa.com')
    $User = "relay@pipusa.com"
    $Pword = ConvertTo-SecureString -String "vRV!Em229+Y^xYY?" -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pword
    Send-MailMessage -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -To $To -From $From -Subject "Risk Detections" -BodyAsHtml -Body $Body
}