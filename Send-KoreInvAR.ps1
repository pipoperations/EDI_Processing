# PowerShell equivalent of UploadFileRest.tcl using Invoke-RestMethod

# Constants
$AuthToken = "Token bc4a678384584fbd92ee0c0fc6deaa11506a61d6f6218d0f633ef011da2c0906" | ConvertTo-SecureString -AsPlainText -Force
$path = "C:\path\to\kore_sftp\ftp-up\"  # Update the path as per your environment
$processedpath = "C:\path\to\kore_sftp\processed\"  # Update the path as per your environment
$Ledger_Type = "ar"
$date = Get-Date -Format "yy-MM-dd"

# Function to list files in a directory specified by "filepath"
function ListFiles($filepath) {
    return Get-ChildItem -Path $filepath -File
}

$filelist = ListFiles $path
foreach ($file in $filelist) {
    $Reference_Date = $file.LastWriteTime.ToString("yyyy-MM-dd")
    Write-Host $file.Name
    Write-Host $Reference_Date

    $headers = @{
        "Authorization" = $AuthToken
        "Content-Type" = "text/csv"
        "Reference-Date" = $Reference_Date
        "Ledger-Type" = $Ledger_Type
        "Ledger-Code" = "PIP_INC_AR"
    }

    if ($file.Name -like "*OPENAR*") {
        $headers["Report-Type"] = "open"
    } elseif ($file.Name -like "*_INVPAY_*") {
        $headers["Report-Type"] = "cleared"
    }

    if ($headers.ContainsKey("Report-Type")) {
        $uri = "https://pip.cashanalytics.com/api/ledger_transaction_uploaders"
        $body = Get-Content -Path $file.FullName -Raw

        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data"
            Write-Host "Response: $response"
        }
        catch {
            Write-Host "Error: $_"
        }

        Move-Item -Path $file.FullName -Destination $processedpath
    }
}
