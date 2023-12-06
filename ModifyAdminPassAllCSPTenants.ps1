Set-ExecutionPolicy bypass

Install-Module AzureAD
Update-Module AzureAD
Install-Module MSOnline
Import-Module MSOnline
Set-ExecutionPolicy bypass
Add-Type -AssemblyName System.Web

################## Debut Parametres ##################

$azUser =  "admin@"
$azUserObjectId = ""
$azGroupObjectId = ""
$tenantList = ""
$azGroup = "GroupeAzure"
$newPass = ""
$newPassword = ""

################## Fin Parametres ##################


################## Debut Fonctions ##################

#Script qui modifie le mot de passe de l'utilisateur dans tous les tenants
$scriptVerifUserExist = {
    
    try
    {
     $userCherche = $azUser + $tenantName
     $checkUser = (Get-AzureADUser -Filter "startswith(UserPrincipalName,'$userCherche')")
     $userObjectId = (Get-AzureADUser -Filter "startswith(UserPrincipalName,'$userCherche')").ObjectID
     
     if($checkUser)
     {
     $userPrincipalName = $checkUser.UserPrincipalName
     # Reset Password
     $newPassword = ConvertTo-SecureString $newPass -AsPlainText -Force
     Set-MsolUserPassword -TenantId $tenant -UserPrincipalName $userPrincipalName -NewPassword $newPass -ForceChangePassword $false
#    Set-AzureADUserPassword -ObjectId $userObjectId -Password $newPassword -ForceChangePasswordNextLogin $false
     
     }

     else
     {
     $azUserObjectId = (Get-AzureADUser -Filter "mail eq '$azUser'").ObjectId
     $azUser + " n'existe pas dans le tenant " + $tenantName
     }
     
    }

    catch
    {
     "Erreur dans le script scriptVerifUserExist"
    }

}

################## Fin Fonctions ##################

$credential = Get-Credential
Connect-MsolService



$tenantList = (Get-MsolPartnerContract).TenantId



$newPass = Read-Host "Entrez le nouveau mot de passe: "

    foreach ($tenant in $tenantList)
    {

     $tenantName = (Get-MsolPartnerContract | Where-Object{$_.tenantId -match $tenant}).DefaultDomainName
     $reponseTenant = ""

     Do
     {
      $reponseTenant = Read-Host "Voulez vous modifier l'administrateur local du tenant '$tenantName' (o / n)?"
     }

     While("o","n" -notcontains $reponseTenant)

     if($reponseTenant -eq "o")
      {
       
       try
       {
        Connect-AzureAD -tenantId $tenant -Credential $credential
       }
       catch
       {
        Connect-AzureAD -tenantId $tenant
       }

       & $scriptVerifUserExist
           
      }

      else
      {
       
      }

    }

Start-Sleep -Seconds 10

Exit




