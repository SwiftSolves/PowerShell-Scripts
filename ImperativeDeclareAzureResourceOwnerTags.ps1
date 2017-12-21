<#
    .DESCRIPTION
        An runbook which finds the deploym,ent owner of a Azure resource and applies an owner Tag to the Azure resource gets all the ARM resources using the Run As Account (Service Principal)

    .NOTES
        AUTHOR: Nathan Swift
        LASTEDIT: Dec 21, 2017
#>

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


# Obtain resource objects
##Needs## Filter out existing Azure Resource objects that already have Owner Tag assigned
$azurerescs = Get-AzureRmResource # | Where-Object ResourceGroupName -contains rgMDTest2 ## < Filter to apply on a RG

# Execute through each resource object and apply a owner tag based on who deployed the resource
##Needs## Rewrite to use parallelization using either: PS WorkFlow OR Start-Job > https://github.com/Azure/azure-powershell/releases/tag/v4.4.0-September2017
foreach ($azureresc in $azurerescs){

#var for operation name to filter on
$azurerescop = $azureresc.ResourceType + "/write"

#find operations where resource was created in past 90 days # Activity Log only goes back 90 days unless stored in a db of some sort for historical \ archival purposes
$azurerescvalues = Get-AzureRmLog -StartTime (Get-Date).AddDays(-90) -ResourceId $azureresc.ResourceId -DetailedOutput  -Status Succeeded | Where-Object OperationName -contains $azurerescop

#sometimes the operations logs have multiple entries pick the latest record
$owner = $azurerescvalues[0].Caller

#Obtain existing tags and apply existing Tags
$tags = (Get-AzureRmResource -ResourceId $azureresc.ResourceId).Tags
$tags += @{Owner=$owner}
Set-AzureRmResource -ResourceId $azureresc.ResourceId -Tag $tags -Force

}