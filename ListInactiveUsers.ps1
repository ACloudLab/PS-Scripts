Set-ExecutionPolicy bypass
Install-Module ImportExcel -AllowClobber -Force
Get-Module ImportExcel -ListAvailable | Import-Module -Force -Verbose
Set-executionpolicy bypass
Install-Module AzureAD
Install-Module AzureADPreview -AllowClobber -Force
install-module msgraph
Install-Module Microsoft.Graph -Scope CurrentUser -Force
Import-Module Microsoft.Graph.Users
Connect-MgGraph

$inactiveDate = (Get-Date).AddDays(-30)
$users = Get-MgUser -All:$true -Property Id,DisplayName,UserPrincipalName,UserType, SigninActivity, AccountEnabled
$inactiveUsers = $users | Where-Object {
    $_.SignInActivity.LastSignInDateTime -lt $inactiveDate
} | Select-Object DisplayName, UserPrincipalName, UserType, AccountEnabled -ExpandProperty SignInActivity

$inactiveUsers | Export-Excel -Path C:\Temp\InactiveUsers.xlsx
