<#
.SYNOPSIS
    .
.DESCRIPTION
    Installs the new Xero certificate and give the appPool user read permissions on the private key
.PARAMETER AppPoolName
    The name if the appPool the application runs under
.EXAMPLE
    install-xero-cert.ps1 "AppPool"   
#>

#Requires -RunAsAdministrator

if ($null -eq $args[0]){
    $message="Must provide name of AppPool that requires access to certificate. Use Get-Help command for usage."
    Write-Host $message -ForegroundColor Red
    exit 1;
}

$appPoolName = $args[0]

Set-StrictMode -Version Latest
Import-Module WebAdministration

$certRoot = Get-ChildItem "Cert:\LocalMachine\Root" | Where thumbprint -eq "{cert-thumbprint}"
if ($null -ne $certRoot) {
    Remove-Item cert:\LocalMachine\Root\{cert-thumbprint}
}
$certMy = Get-ChildItem "Cert:\LocalMachine\My" | Where thumbprint -eq "{cert-thumbprint}"
if ($null -ne $certMy) {
    Remove-Item cert:\LocalMachine\My\{cert-thumbprint} -DeleteKey
}
$certBytes = [System.Convert]::FromBase64String("cert as base 64")
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certBytes, "password", "MachineKeySet,PersistKeySet")
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")
$store.Open("ReadWrite")
$store.Add($cert)
$store.Close()
$store2 = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
$store2.Open("ReadWrite")
$store2.Add($cert)
$store2.Close()
$certificate = Get-ChildItem "Cert:\LocalMachine\My" | Where thumbprint -eq "{cert-thumbprint}"
if ($null -eq $certificate) {
    $message="Certificate with thumbprint:{cert-thumbprint} does not exist at Cert:\LocalMachine\My"
    Write-Host $message -ForegroundColor Red
    exit 1;
} else {
    $appPoolUser = "IIS AppPool\"+$appPoolName
    $rsaCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($certificate)
    $fileName = $rsaCert.key.UniqueName
    $path = "$env:ALLUSERSPROFILE\Microsoft\Crypto\RSA\MachineKeys\$fileName"
    $permissions = Get-Acl -Path $path
    $access_rule = New-Object System.Security.AccessControl.FileSystemAccessRule($appPoolUser, 'Read', 'None', 'None', 'Allow')
    $permissions.AddAccessRule($access_rule)
    Set-Acl -Path $path -AclObject $permissions
}
