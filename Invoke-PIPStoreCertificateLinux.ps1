<#
.NAME
    Invoke-PIPStoreCertificateLinux.ps1

.AUTHOR
    Brian Wood

.COMPANY
    Protective Industrial Products, Inc.

.COPYRIGHT
    2023 (c) Protective Industrial Products, Inc. All rights reserved.

.LICENSE
    MIT License

.SYNOPSIS
    This script will install a certificate into the Linux certificate store.

#>
process {
    $StoreName = [System.Security.Cryptography.X509Certificates.StoreName]
    $StoreLocation = [System.Security.Cryptography.X509Certificates.StoreLocation]
    $OpenFlags = [System.Security.Cryptography.X509Certificates.OpenFlags]
    $Store = [System.Security.Cryptography.X509Certificates.X509Store]::new(
    $StoreName::My, $StoreLocation::LocalMachine)

    # Get a certificate
    $X509Certificate2 = [System.Security.Cryptography.X509Certificates.X509Certificate2]
    $CertPath = (Resolve-Path 'ClientCert.pfx').Path
    $Cert = $X509Certificate2::New($CertPath, 'password')

    # Open the store, Add the cert, Close the store.
    $Store.Open($OpenFlags::ReadWrite)
    $Store | get-member
    $Store.Close()
}