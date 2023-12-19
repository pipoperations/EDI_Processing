#!/usr/bin/pwsh
<#PSScriptinfo
.NAME
    Invoke-PIPProcessEDITest.ps1

.AUTHOR
    Brian P. Wood

.COMPANY
    Protective Industrial Products, Inc.

.COPYRIGHT
    2023 (c) Protective Industrial Products, Inc. All rights reserved.

.LICENSE
    MIT License

.TODO
    Implement SMB for CommerceHub
    Maybe enhance with sqlite database file instead of txt customer files

.RELEASENOTES
    V0.01: 10.21.2023 - Initial script in PowerShell
    V0.02: 11.11.2023 - Revised coding style
    V0.03: 11.12.2023 - Added Houser Shoes file rename
    V0.04: 11.13.2023 - Moved to production

.SYNOPSIS
    This program takes a list of files in a msg-out directory parses them for a unique customer number and matches to a list of customer attributes.
    Then retrieves any inbound files from the list of customers and places them in the ftp-out directory.
    Customer files should be in this format
    CustomerName     ABC Corp
    CustomerNumber   1234
    Protocol         sftp
    Host       10.10.10.10
    Username         Brianisawesome
    Password         W3lc0m3!
    PushDirectory    ftp-in
    PullDirectory    ftp-out
    RSAKey           ~/.ssh/privatekey.rsa   
    Use tabs between keys and values
#>

# Set Global Variables

$ConfigFile = "opentest.txt"
$Username = ""
$Password = ""
$GlobalPathin = "/home/eclipseftp/ftp-in/" # In is Outbound to customer
$GlobalPathout = "/home/eclipseftp/ftp-out/" #Out is Inbound from customer
$ConfigPath = "/home/eclipseftp/scripts/config/newscript/"
$ProcessedPath = "/home/eclipseftp/processed/"

function Install-ModuleIfNotExists {
    <#
        .SYNOPSIS
            Proceedure to verify required modules are installed and install them if they don't exist

        .EXAMPLE
            $ModuleName = "Posh-SSH"
            Install-ModuleIfNotExists -moduleName $moduleName
    #>
    param (
        [string]$ModuleName,
        [string]$ModuleSource = "PSGallery"
    )

    if (-not (Get-Module -Name $moduleName -ListAvailable)) {
        Install-Module -Name $moduleName -Repository $moduleSource -Force
    }
}

function Get-PIPFiles {
    <#
        .SYNOPSIS
            Proceedure to list files in a directory specfied by "FilePath"
    #>
    param (
        [string]$FilePath
    )

    # List files in the directory
    $filelist = Get-ChildItem -Path $FilePath -File | Select-Object -ExpandProperty FullName
    return $filelist
}

function Get-PIPEDICustomers {
    <#
    .SYNOPSIS
        Proceedure to parse Customer files into an list of object.
   
    .EXAMPLE
        $objects = Get-PIPEDICustomers -FilePath $ConfigPath 
    #>
    param (
        [string]$FilePath
    )

    $files = Get-ChildItem -Path $FilePath -File
    $objects = @()

    foreach ($file in $files) {
        $obj = New-Object PSCustomObject
        Get-Content -Path $file.FullName | ForEach-Object {
            $keyValue = $_ -split "`t", 2
            if ($keyValue.Count -eq 2) {
                $key = $keyValue[0].Trim()
                $value = $keyValue[1].Trim()
                Add-Member -InputObject $obj -MemberType NoteProperty -Name $key -Value $value
            }
        }

        $objects += $obj
    }

    return $objects
}

function Find-PIPEDICustomer {
    <#
    .SYNOPSIS
        Proceedure to associate a file with a Customer.
    #>
    param (
        [string]$FileName,
        [System.Object[]]$Customers
    )

    # Search file for unique key
    $dataLine = Get-Content -Path $FileName -Raw

    foreach ($customer in $Customers) {
        $CustomerNumber = $customer.CustomerNumber
        $occurs = $dataLine.IndexOf($CustomerNumber)

        if ($occurs -ge 0) {
            # Return filename, and connection info (protocol, ip address, username, password)
            return $customer
        }
    }
}

function Copy-PIPCustomerFile {
    <#
    .SYNOPSIS
        Proceedure to Copy customer files based on direction

    .EXAMPLE
        Copy-PIPCustomerFile -FileName SomeFile -Customer CustomerObject -Direction In/Out
    #>
    param (
        [String]$FileName,
        [System.Object]$Customer,
        [Parameter(Mandatory = $true,
            HelpMessage = "Direction is requires In/Out")]
        [ValidatePattern("IN|OUT")]$Direction
    )

    switch ($Direction) {
        OUT {
            switch ($Customer.Protocol) {
                local {
                    try {
                        $result = Copy-Item -Path $FileName -Destination $Customer.PushDirectory -PassThru
                        /bin/chmod -v  00666 $(join-path -Path $Customer.PushDirectory -ChildPath (split-path $FileName -Leaf)) | Out-Null
                        return $result
                        
                    }
                    catch {
                        return $null
                    }
                }
                sftp {
                    try {
                        $sftpsession = Connect-PIPSFTPServer -Customer $Customer
                        Set-SFTPItem -Path $FileName -Destination $Customer.PushDirectory -SessionId $sftpsession.SessionId -Force -ErrorAction Stop
                        Remove-SFTPSession $sftpsession
                        $result = [PSCustomObject]@{
                            Name = split-path -Path $FileName -Leaf
                        }
                        return $result
                    }
                    Catch {
                        return $null
                    }
                }
            }
        }
        IN {
            switch ($Customer.Protocol) {
                local {
                    try {
                        $result = Copy-Item -Path $FileName -Destination $GlobalPathout -PassThru
                        return $result
                        
                    }
                    catch {
                        return $null
                    }
                }
                sftp {
                    $sftpsession = Connect-PIPSFTPServer -Customer $Customer
                    if ($null -ne $sftpsession) {
                        $remoteFiles = Get-SFTPChildItem -SessionId $sftpsession.SessionId -Path $Customer.PullDirectory -File 
                    }
                    # Download each file to the local directory
                    if ($null -eq $remoteFiles) {
                        write-host "$($Customer.CustomerName) no files found"
                        return
                    }
                    $date = Get-Date -UFormat "%b-%Y"

                    # Create the full path
                    $fullPath = Join-Path -Path $ProcessedPath -ChildPath $Customer.CustomerName
                    $fullPath = Join-Path -Path $fullPath -ChildPath $date
                    
                    # Check if the path exists
                    if (-not (Test-Path -Path $fullPath)) {

                        # If the path doesn't exist, create it
                        New-Item -Path $fullPath -ItemType Directory
                    }
                    Write-Information "preresults"
                    Foreach ($file in $remoteFiles) {
                        Get-SFTPItem -SessionId $sftpSession.SessionId -Path $file.FullName -Destination $GlobalPathout -Force 
                        /bin/chmod -v  00664 $(join-path -Path $GlobalPathout -ChildPath $file.Name) | Out-Null
                        /bin/chown -v :eclipseftp $(join-path -Path $GlobalPathout -ChildPath $file.Name) | Out-Null
                        Get-SFTPItem -SessionId $sftpSession.SessionId -Path $file.FullName -Destination $fullPath -Force
                        Remove-SFTPItem -SessionId $sftpSession.SessionId -Path $file.FullName
                        write-host "$(Get-Date -Format 'HH:mm:ss') $($file.Name) for $($customer.customerName) sucessfully processed $Direction using protocal $($Customer.Protocol)"
                    }
                    Remove-SFTPSession $sftpsession
                }
            }
        }
    }
}

function Move-PIPProcessedCustomerFile {
    <#
    .SYNOPSIS
        Proceedure to Move customer files to the processed directory
    #>
    param (
        [string]$FileName,
        [System.Object]$Customer
    )

    # Get the current date in "yyyy-MM-dd" format
    $date = Get-Date -UFormat "%b-%Y"

    # Create the full path
    $fullPath = Join-Path -Path $ProcessedPath -ChildPath $Customer.CustomerName
    $fullPath = Join-Path -Path $fullPath -ChildPath $date
    
    # Check if the path exists
    if (-not (Test-Path -Path $fullPath)) {

        # If the path doesn't exist, create it
        New-Item -Path $fullPath -ItemType Directory
    }
    Move-Item -Path $FileName -Destination $fullPath -Force
}

function Connect-PIPSFTPServer {
    <#
    .SYNOPSIS
        Process to send files by sftp
    #>
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]$Customer
    )

    $username = $Customer.Username
    $password = $Customer.Password
    $keyfile = Join-Path -Path "/root/.ssh/" -ChildPath $Customer.RSAKey
    $sftphost = $Customer.Host
    $port = $Customer.Port
    
    if ($null -eq $password) {
        $securepassword = New-object System.Security.SecureString
        $connectionauth = "key"
    }
    else {
        $securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        $connectionauth = "password"
    }

    if ($null -eq $port) {
        $port = 22
    }

    $credentials = New-Object System.Management.Automation.PSCredential ($username, $securepassword)
    try {
        switch ($connectionauth) {
            key {
                    $sftpSession = New-SFTPSession -ComputerName $sftphost -Port $port -Credential $credentials -KeyFile $keyfile -AcceptKey -ConnectionTimeout 30
            }
            password {
                    $sftpSession = New-SFTPSession -ComputerName $sftphost -Port $port -Credential $credentials -AcceptKey -ConnectionTimeout 30
            }
        }
    }
    catch {
        write-host "Unable to connect to $sftphost"
        return $null
    }
    return $sftpSession
}

function Invoke-PIPCustomerFileProcessing {
    <#
    .SYNOPSIS
        Reads data files and matches them to customers, then processes them based on customer and direction
    #>
    param (
        [string]$Path,
        [System.Object[]]$Customers,
        [Parameter(Mandatory = $true,
            HelpMessage = "Direction is requires In/Out")]
        [ValidatePattern("IN|OUT")]$Direction
    )
    switch ($Direction) {
        OUT {
            # From PIP to Customer
            $dataFileList = Get-ChildItem -Path $Path -File
            foreach ($file in $dataFileList) {
                $Customer = Find-PIPEDICustomer -FileName $file.FullName -Customers $Customers
                if ($null -ne $Customer) {
                    $customername = $Customer.CustomerName
                    $file = Rename-FileIfNecessary -file $file -Customer $customername
                    $success = Copy-PIPCustomerFile -FileName $file.FullName -Customer $Customer -Direction $Direction
                    if ($null -ne $success) {
                        # Move file to processed directory (customer+date) if successful
                        Move-PIPProcessedCustomerFile -Filename $file.FullName -Customer $Customer
                        write-host ("$(Get-Date -Format 'HH:mm:ss') " + $success.Name + " for $customername sucessfully processed $Direction using protocal " + $Customer.Protocol)
                    }
                    else {
                        write-host ($file.Name + " not processed")
                    }
                    
                }
                else {
                    Write-Output ($file.Name + " Doesn't have a customer")
                }
            }
        }
        IN {
            # From Customer to PIP
            foreach ($customer in $Customers) {
                switch ($customer.Protocol) {
                    local {
                        $dataFileList = Get-ChildItem -Path $Customer.PullDirectory -File
                        if ([string]::IsNullOrEmpty($dataFileList)) {
                            write-host ($Customer.CustomerName + "  no files found")
                        }
                        else {
                            foreach ($file in $dataFileList) {
                                $success = Copy-PIPCustomerFile -FileName $file.FullName -Customer $Customer -Direction $Direction
                                if ($null -ne $success) {
                                    # Move file to processed directory (customer+date) if successful
                                    Move-PIPProcessedCustomerFile -Filename $file.FullName -Customer $Customer
                                    write-host ("$(Get-Date -Format 'HH:mm:ss') " + $success.Name + " for $customername sucessfully processed $Direction using protocal " + $Customer.Protocol)
                                }
                                else {
                                    write-host ($Customer.CustomerName + "  no files found")
                                }
                            }
                        }
                    }
                    sftp {
                        Copy-PIPCustomerFile -Customer $Customer -Direction $Direction
                    }
                }
            }
        }
    }
}

function Rename-FileIfNecessary {
    <#
    .SYNOPSIS
        Proceedure to rename a file if necessary for houser
    #>
    param (
        [Parameter(Mandatory=$true)]
        [string] $filename,
        [Parameter(Mandatory=$true)]
        [string] $customer
    )

    if ($customer -eq "Houser Shoes") {
        $name = split-path -Path $filename -Leaf
        $newFilename = $name.Insert(4, "_")
        $path = split-path -Path $filename -Parent
        $fullpath = Join-Path -Path $path -ChildPath $newFilename
        Rename-Item -Path $filename -NewName $fullpath
        $File = [System.IO.FileInfo] $fullpath
    }
    Return $File
}

<#
    .SYNOPSIS
        Main Program
#>
write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Output "Starting script"
Write-Output "The time is: $(Get-Date -Format 'HH:mm:ss')"
Write-Output "The date is: $(Get-Date -Format 'MM/dd/yyyy')"
Write-Output "`n"

# Check to see if needed modules are installed

Install-ModuleIfNotExists -ModuleName Posh-SSH

# Import needed modules

Import-Module Posh-SSH

# Get Customers from config files

$PIPEDICustomers = Get-PIPEDICustomers -FilePath $ConfigPath

# Send and Receive files
Write-Output "Sending Customer Files"
Write-Output "`n"

Invoke-PIPCustomerFileProcessing -Path $GlobalPathin -Customers $PIPEDICustomers -direction Out

Write-Output "`n"
Write-Output "Retrieving Customer Files"
Write-Output "`n"

Invoke-PIPCustomerFileProcessing -Path $GlobalPathout -Customers $PIPEDICustomers -direction In

Write-Output "`nScript Complete $(Get-Date -Format 'HH:mm:ss')"
