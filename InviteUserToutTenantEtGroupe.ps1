Install-Module -Name AzureAD
Update-Module -Name AzureAD
Install-Module -Name MSOnline
Import-Module MSOnline

################## Debut Parametres ##################

$azUser =  ""
$azUserObjectId = ""
$azGroupObjectId = ""
$tenantList = ""
$azGroup = "GroupeAzure"

################## Fin Parametres ##################


################## Debut Fonctions ##################

#Script qui verifie si l'utilisateur est deja dans le tenant, si il ne l'ai pas, il est invite
$scriptInviteUser = {
    
    try
    {
     $checkUser = (Get-AzureADUser -Filter "mail eq '$azUser'").ObjectId
     
     if(!$checkUser)
     {
      New-AzureADMSInvitation -InvitedUserEmailAddress $azUser -SendInvitationMessage $True -InviteRedirectUrl "http://myapps.microsoft.com"
      $azUser + " n'existe pas nous l'invitons a l'instant"
      Start-Sleep -Seconds 20
     }

     else
     {
     $azUserObjectId = (Get-AzureADUser -Filter "mail eq '$azUser'").ObjectId
     $azUser + " existe deja dans le tenant " + $tenantName
     }
     
    }

    catch
    {
     "Erreur dans le script scriptInviteUser"
    }

}

#Script qui verifie si le groupe existe ou non, s'il n'existe pas, il est ajoute
$scriptAjoutGroupe = {
   
    try
    {

     $checkGroup  = Get-AzureADGroup -filter "Displayname eq '$azGroup'"

     if(!$checkGroup)
      {
       New-AzureADGroup -Description $azGroup -DisplayName $azGroup -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet"
       $azGroup + " n'existe pas nous l'ajoutons a l'instant"
       Start-Sleep -Seconds 20
      }

     else
      {
       $azGroupObjectId = (Get-AzureADGroup -filter "Displayname eq '$azGroup'").ObjectId
       $azGroup + " existe deja dans le tenant " + $tenantName
      }
    }
    catch
    {
     "Erreur dans le script scriptAjoutGroupe"
    }

}

#Script qui verifie si l'utilisateur est dans le groupe ou non, s'il ne l'ai pas, il est ajoute
$scriptAjoutUserAuGroupe = {
    try
    {
     $checkUserInGroup = (Get-AzureADUser -filter "ObjectId eq '$azUserObjectId'" | Get-AzureADUserMembership | Select-Object DisplayName | Where-Object { $_.DisplayName -eq $azGroup })

     if(!$checkUserInGroup)
     {
       Add-AzureADGroupMember -ObjectId $azGroupObjectId -RefObjectId $azUserObjectId
       $azUser + " est maintenant ajoute a " + $azGroup
     }

     else
     {
      $azUser + " est deja membre de " + $azGroup
     }
    }

    catch
    {
     "Erreur dans le script scriptAjoutUserAuGroupe"
    }
}


################## Fin Fonctions ##################

$credential = Get-Credential
Connect-MsolService

write-host "!!!!!!!!Prendre note que ce programme invite l'utilisateur aux tenants choisis mais AUSSI aussi il l'ajoute au groupe nommé plus haut (et cree le groupe s'il n'existe pas)!!!!!!!!"
Start-Sleep -Seconds 5

$tenantList = (Get-MsolPartnerContract).TenantId

    Do
    {

     $azUser = Read-Host "Entrez le courriel de l'employé a inviter"

    }

    While(($azUser -notmatch "^([\w-\.]+)@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.)|(([\w-]+\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$") -and ($reponseEmail.length -lt 112))



    foreach ($tenant in $tenantList)
    {

     $tenantName = (Get-MsolPartnerContract | Where-Object{$_.tenantId -match $tenant}).DefaultDomainName
     $reponseTenant = ""

     Do
     {
      $reponseTenant = Read-Host "Voulez vous ajouter l'utilisateur au tenant '$tenantName' (o / n)?"
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

       & $scriptInviteUser
       $azUserObjectId = (Get-AzureADUser -Filter "mail eq '$azUser'").ObjectId

       & $scriptAjoutGroupe
       $azGroupObjectId = (Get-AzureADGroup -filter "Displayname eq '$azGroup'").ObjectId

       & $scriptAjoutUserAuGroupe
           
      }

      else
      {
       
      }

    }


Write-Host "Fin de la liste... Merci et bonne journee!"

Start-Sleep -Seconds 10

Exit
 
