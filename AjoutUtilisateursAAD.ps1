Install-Module AzureAD
Update-Module -Name AzureAD
Connect-AzureAD -TenantId TenantID #Changer pour le numéro du tenantID

################## Debut Parametres ##################

$questionPrenom = "Entrez le prenom du nouvel employé“
$userPrenom = ""

$questionNomFamille = "Entrez le nom de famille du nouvel employé“
$userNomFamille = ""

$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$questionMotPasse = "Entrez un mot de passe pour lutilisateur“
$PasswordProfile.Password = ""

$questionTelephone = "Entrez le numero de telephone du nouvel employé (format 514-555-5555)“
$userTelephone = ""

$questionDepartment = "
1. Direction
2. Comptabilite
3. Marketing
4. SCDO
5. Infrastructure
6. Dev
7. Recherche et developpement
8. Ventes
9. Ressources Humaines

Entrez numero correspondant au departement de la personne“
$userDepartement = ""

$azGroup = "groupeAajouter"

$CompanyName  = "NomCompany"

################## Fin Parametres ##################


################## Debut Fonctions ##################

#Script validant le prenom
$scriptPrenom = {
    try
    {
        $reponsePrenom = Read-Host $questionPrenom

        if (($reponsePrenom -match "^[a-zA-Z\-]+$") -and ($reponsePrenom.length -lt 32)) {
        $reponsePrenom
        }
        else {
        Write-Host "Votre reponse doit contenir un nom valide"
        & $scriptPrenom
        }
    }
    catch
    {
        Write-Host "Votre reponse doit contenir un nom valide"
        & $scriptPrenom
    }
}

#Script validant le nom de famille
$scriptNomFamille = {
    try
    {
        $reponseNomFamille = Read-Host $questionNomFamille

        if (($reponseNomFamille -match "^[a-zA-Z\-]+$") -and ($reponseNomFamille.length -lt 32)) {
        $reponseNomFamille
        }
        else {
        Write-Host "Votre reponse doit contenir un nom valide"
        & $scriptNomFamille
        }
    }
    catch
    {
        Write-Host "Votre reponse doit contenir un nom valide"
        & $scriptNomFamille
    }
}

#Script validant le mot de passe
$scriptMotPasse = {
    try
    {
        $reponseMotPasse = Read-Host $questionMotPasse

        if ($reponseMotPasse -cmatch @”
^((?=.*[^A-Za-z0-9]))([A-Za-z0-9\d@#$%^&amp;amp;£*\-_+=[\]{}|\\:’,?/`~”();!]|\.(?!@)){8,20}$
“@)
        {
        $reponseMotPasse
        }
        else {
        Write-Host "Votre mot de passe doit contenir entre 8 et 20 caractere avec au moin une majuscule et un caractere special"
        & $scriptMotPasse
        }
    }
    catch
    {
        Write-Host "VVotre mot de passe doit contenir entre 8 et 20 caractere avec au moin une majuscule et un caractere special"
        & $scriptMotPasse
    }
}

#Script validant le telephone
$scriptTelephone = {
    try
    {
        $reponseTelephonee = Read-Host $questionTelephone

        if ($reponseTelephonee -match "\d\d\d-\d\d\d-\d\d\d\d") {
        $reponseTelephonee
        }
        else {
        Write-Host "Votre reponse doit contenir un numero de telephone valide"
        & $scriptTelephone
        }
    }
    catch
    {
        Write-Host "Votre reponse doit contenir un numero de telephone valide"
        & $scriptTelephone
    }
}

#Script validant le departement
$scriptDepartement = {
    try
    {
        $reponseDepartment = Read-Host $questionDepartment

        if ($reponseDepartment -eq 1) {
        "Direction"
        }
        elseif ($reponseDepartment -eq 2) {
        "Comptabilite"
        }
        elseif ($reponseDepartment -eq 3) {
        "Marketing"
        }
        elseif ($reponseDepartment -eq 4) {
        "SCDO"
        }
        elseif ($reponseDepartment -eq 5) {
        "Infrastructure"
        }
        elseif ($reponseDepartment -eq 6) {
        "Dev"
        }
        elseif ($reponseDepartment -eq 7) {
        "Recherche et developpement"
        }
        elseif ($reponseDepartment -eq 8) {
        "Ventes"
        }
        elseif ($reponseDepartment -eq 9) {
        "Ressources Humaines"
        }
        else {
        Write-Host "Votre reponse doit etre un nombre dans les choix de reponse"
        & $scriptDepartement
        }
    }
    catch
    {
        Write-Host "Votre reponse doit etre un nombre dans les choix de reponse"
        & $scriptDepartement
    }
}

################## Fin Fonctions ##################

#Clear-Host
$userPrenom = & $scriptPrenom

#Clear-Host
$userNomFamille = & $scriptNomFamille

#Clear-Host
$PasswordProfile.Password = & $scriptMotPasse

#Clear-Host
$userTelephone = & $scriptTelephone

#Clear-Host
$userDepartement = & $scriptDepartement

$DisplayName = $userPrenom + " " + $userNomFamille

$MailNickName = $userPrenom + "." + $userNomFamille

$UserPrincipalName = $userPrenom + "." + $userNomFamille + "@" + $CompanyName + ".com"

#Ajout de l'utilisateur au tenant
New-AzureADUser -AccountEnabled $true -PasswordProfile $PasswordProfile -DisplayName $DisplayName -UserPrincipalName $UserPrincipalName -Department $userDepartement -CompanyName $CompanyName -ShowInAddressList $true -TelephoneNumber $userTelephone -MailNickName $MailNickName

Write-Host "L'utilisateur a ete ajoute"

Start-Sleep -Seconds 10

Exit
