<#
    .DESCRIPTION
        An runbook which starts or stops the Azure Firewall

    .NOTES
        AUTHOR: Nathan Swift
        LASTEDIT: Novemeber 6, 2018
#>

Param
(
  [Parameter (Mandatory= $true)]
  [String] $process = "",
  
  [Parameter (Mandatory= $true)]
  [String] $azfwname = "",

  [Parameter (Mandatory= $true)]
  [String] $azfwrg = "",

  [Parameter (Mandatory= $false)]
  [String] $vnetname = "",

  [Parameter (Mandatory= $false)]
  [String] $vnetrg = "",

  [Parameter (Mandatory= $false)]
  [String] $pipname = "",

  [Parameter (Mandatory= $false)]
  [String] $piprg = ""

)

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

Set-AzureRMContext -Subscription 

# Azure FW Object
$azfw = Get-AzureRmFirewall -Name $azfwname -ResourceGroupName $azfwrg

# Deallocate
if ($process -match "stop"){

    # Deallocate
    $azfw.Deallocate()
    Set-AzureRmFirewall -AzureFirewall $azfw
    Write-Output ("Azure Firewal $azfw.name Stopped")

}

#Reallocate
Elseif ($process -match "start"){

    $vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetrg
    $publicip = Get-AzureRmPublicIpAddress -Name $pipname -ResourceGroupName $piprg
    $azfw.Allocate($vnet,$publicip)
    Set-AzureRmFirewall
    Write-Output ("Azure Firewal $azfw.name Started")
}

Else {

    Write-Output ("Azure Firewal $azfw.name incorrect process parameter")

}