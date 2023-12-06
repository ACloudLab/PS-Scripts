$cert = New-SelfSignedCertificate -FriendlyName "mysite.com" -DnsName mysite.com -CertStoreLocation "cert:\LocalMachine\My" -KeyUsage DigitalSignature,KeyEncipherment,DataEncipherment -KeyAlgorithm RSA -HashAlgorithm SHA256 -KeyLength 2048 -KeyUsageProperty All -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter (Get-Date).AddYears(5)
$pass ="myCertPassword"
$SecuredPass = ConvertTo-SecureString -String $pass -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\LocalMachine\My\$($cert.Thumbprint)" -FilePath custom_cert.pfx -Password $SecuredPass