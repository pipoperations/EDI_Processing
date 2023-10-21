Import-Module Posh-SSH

$filesDirectory = "/home/eclipseftp/scripts/config"
$i = 0

# Create an empty hashtable to store the key-value pairs
$customer = New-Object pscustomobject

# Get all the files in the directory and loop through each file
$files = Get-ChildItem -Path $filesDirectory -File
foreach ($file in $files) {
    $filesHashtable = @{}
    # Get the contents of the file as a string
    Write-Host $file
    $fileContents = Get-Content $file.FullName -Raw | Where-Object { $_ -ne "" }
    $customerKey = $file.Name

    # Split the contents of the file into key-value pairs using the newline character
    $fileKeyValuePairs = $fileContents.Split("`n")

    # Add each key-value pair to the hashtable
   foreach ($valuepair in $fileKeyValuePairs) { 
        $keyValuePair = $valuepair.Split("`t")
        $key = $keyValuePair[0]
        $value = $keyValuePair[1]
        Write-Host $key
        Write-host $value
        $filesHashtable[$key] = $value
        write-host $i
        }
        $customer[$customerKey]=[PSCustomObject]$filesHashtable
        Write-host $customer
        $i++
}

# Output the hashtable to the console
#foreach ($entity in $customer.Values) {
#    if ($entity["Protocol"] -eq "sftp") {
#        $Pword = ConvertTo-SecureString -String $entity["Password"] -AsPlainText -Force
#        $sftpuser = $entity["Username"]
#        $creds = New-Object System.Management.Automation.PSCredential ($sftpuser, $Pword)
#        $sftpSession = New-SFTPSession -ComputerName $entity["Host"] -Credential $creds
#        Write-Output "Pull"
#        Write-Output $entity["PullDirectory"]
#        Get-SFTPChildItem -SessionId $sftpSession.SessionId -Path $entity["PullDirectory"]
#    }    
#}



