# Do some prep work
#$StoreName = [System.Security.Cryptography.X509Certificates.StoreName]
#$StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]
#$OpenFlags = [System.Security.Cryptography.X509Certificates.OpenFlags]
#$Store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
#    $StoreName::My, $StoreLocation::CurrentUser)

# Get a certificate
#$X509Certificate2 = [System.Security.Cryptography.X509Certificates.X509Certificate2]
#$CertPath = (Resolve-Path -LiteralPath '/etc/ssl/certs/star.pipusa.com.pfx').Path
#$Cert = $X509Certificate2::New($CertPath, 'pipusa')

# Open the store, Add the cert, Close the store.
#$Store.Open($OpenFlags::ReadWrite)
#$Store.Add($Cert)
#$Store.Close()

Install-Module -Name Microsoft.Graph.Identity.SignIns -scope AllUsers
Select-MgProfile -Name beta
#Generate Access Token to use in the connection string to MSGraph
$AppId = 'b78d8f62-a6c6-487c-be33-abde8889bf70'
$TenantId = '75ec60a8-d8f4-473b-8b5d-1b449c3cba33'


#Connect to Graph using certificate
Connect-MgGraph -ClientId $AppId -TenantId $TenantId -CertificateThumbprint "95051149E399A1094AD7C3E3581386192BD941CF"
#Get Risk Detections in the Past 24 hours and create the message body
$Body = (Get-MgRiskDetection -All -Sort ActivityDateTime | Where-Object {$_.ActivityDateTime -gt (Get-Date).AddDays(-1)} | Select-Object -Unique -Property UserDisplayName,RiskEventType,DetectionTimingType,IPAddress,RiskLevel,RiskState,ActivityDateTime)
if (!$Body){
    $Body = ("There have been no risk detections in the past 24 hours!")
}
else{

    $Body = ($Body | ConvertTo-html | Out-String -Width 50)
}
#Send an email using the relay account
$From = "azurealerts@pipusa.com"
$To = @('bwood@pipusa.com', 'egutowski@pipusa.com')
$User = "relay@pipusa.com"
$Pword = ConvertTo-SecureString -String "vRV!Em229+Y^xYY?" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pword
Send-MailMessage -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -To $To -From $From -Subject "Risk Detections" -BodyAsHtml -Body $Body
