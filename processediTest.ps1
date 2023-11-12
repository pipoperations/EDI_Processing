######################################################################
##
## NAME
##  processedi.tcl
##
## AUTHOR
##  Brian P. Wood
##
## TODO: Implement SMB for CommerciaHub
## TODO: Maybe enhance with sqlite database file instead of txt customer files
## TODO: #14 Implement archive by month for Jay 👎
##
## HISTORY
##  V0.01 10.21.2023 - Initial script in PowerShell
##  
## NOTES
##  This program takes a list of files in a msg-out directory parses them for a unique customer number and matches to a list of customer attributes.
##  Customer files should be in this format
##  CustomerName     ABC Corp
##  CustomerNumber   1234
##  Protocol         sftp
##  Host       10.10.10.10
##  Username         Brianisawesome
##  Password         W3lc0m3!
##  PushDirectory    ftp-in
##  PullDirectory    ftp-out
##  Use tabs between keys and values
##
#######################################################################

$ConfigFile = "opentest.txt"
$Username = ""
$Password = ""
# $GlobalPathin = "/home/eclipseftp/test/ftp-in/"
$GlobalPathin = "/home/eclipseftp/dev/ftp-in/"
$GlobalPathout = "/home/eclipseftp/test/ftp-out/"
$ConfigPath = "/home/eclipseftp/scripts/config/test/"
$ProcessedPath = "/home/eclipseftp/processed/"
$systemTime = Get-Date

# Proceedure to list files in a directory specfied by "FilePath"
#--------------------------------------------------------------------

function Get-PIPFiles {
    param (
        [string]$FilePath
    )

    # List files in the directory
    $filelist = Get-ChildItem -Path $FilePath -File | Select-Object -ExpandProperty FullName
    return $filelist
}

# Proceedure to parse Customer files into an list of object.
#--------------------------------------------------------------------
function Get-PIPEDICustomers {
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

# Example usage:

# $objects = EDI -FilePath $ConfigPath
# $objects | ForEach-Object {
#     Write-Output $_
# }

function Find-PIPEDICustomer {
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

    return 0
}

function Copy-PIPCustomerFile {
    param (
        [String]$FileName,
        [System.Object]$Customer,
        [Parameter(Mandatory=$true,
            HelpMessage="Direction is requires In/Out")]
            [ValidatePattern("IN|OUT")]$Direction
    )
    # debug Write-Output ("Copy-PIPCustomerFile " + $Customer.Protocol + " " + $Customer.PushDirectory + " " + $Direction)
    switch ($Direction){
        OUT{
            Write-Host ("function " + $MyInvocation.MyCommand.Name + " Direction $Direction")
        }
        IN{
            Write-Host ("function " + $MyInvocation.MyCommand.Name + " Direction $Direction")
        }
    }
}

# Reads data files and matches them to customers, then sends them via protocol
#--------------------------------------------------------------------------
function Invoke-PIPCustomerFileProcessing {
    param (
        [string]$Path,
        [System.Object[]]$Customers,
        [Parameter(Mandatory=$true,
            HelpMessage="Direction is requires In/Out")]
            [ValidatePattern("IN|OUT")]$Direction
    )
    Write-Output "Path $Path"
        switch ($Direction) {
        OUT{
            Write-Host ("function " + $MyInvocation.MyCommand.Name + " Direction $Direction")
            # From PIP to Customer
            $dataFileList = Get-ChildItem -Path $Path -File
            Write-output "sendfile $dataFileList"

            foreach ($file in $dataFileList) {
                Write-Output $file.FullName
                $Customer = Find-PIPEDICustomer -FileName $file.FullName -Customers $Customers
                if ($null -ne $Customer) {
                    $customername = $Customer.CustomerName
                    Copy-PIPCustomerFile -FileName $file.FullName -Customer $Customer -Direction $Direction
                    if ($success -eq 0) {
                        # SendFile should return 0 if it is successful
                    #     MoveOutboundFile -file $file -customername $customername
                        write-output ($file.Name + " has $customername and the direction is $Direction and the protocal is " + $Customer.Protocol)
                    }
                } else {
                    Write-Output ($file.Name + " Doesn't have a customer")
                }
            }
        }
        IN{
            # From Customer to PIP
            Write-Host ("function " + $MyInvocation.MyCommand.Name + " Direction $Direction")
        }
    }
    return 0
}


#==========================================================================
# Main
#==========================================================================

Write-Output "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
Write-Output "Starting script"
Write-Output "The time is: $(Get-Date -Format 'HH:mm:ss')"
Write-Output "The date is: $(Get-Date -Format 'MM/dd/yyyy')"

$PIPEDICustomers = Get-PIPEDICustomers -FilePath $ConfigPath
$PIPEDICustomers | ForEach-Object {Write-Output $_}

# Find-PIPEDICustomer -FileName $GlobalPathin -Customers $PIPEDICustomers
$FilesTest = Get-ChildItem -Path $GlobalPathin
Write-Output = "GlobalPath Files $FilesTest"

Invoke-PIPCustomerFileProcessing -Path $GlobalPathin -Customers $PIPEDICustomers -direction Out

