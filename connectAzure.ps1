param (
  [Parameter(Mandatory=$true)][String]$spName,
  [Parameter(Mandatory=$true)][String]$spPass,
  [Parameter(Mandatory=$true)][String]$SubscriptionId,
  [Parameter(Mandatory=$true)][String]$TenantId
)

if (-not(Get-Module -Name Az.Accounts -ListAvailable)){
  Write-Warning "Module 'Az.Accounts' is missing or out of date. Installing module now."
  Install-Module -Name Az.Accounts, Az.Resources -Scope CurrentUser -Force -AllowClobber
}

$spPassword = ConvertTo-SecureString -AsPlainText -Force -String $spPass
$creds = New-Object System.Management.Automation.PSCredential ($spName,$spPassword)
Connect-AzAccount -ServicePrincipal -Credential $creds -Tenant $tenantId -Subscription $SubscriptionId