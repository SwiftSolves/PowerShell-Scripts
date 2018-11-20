<#
.SYNOPSIS


.DESCRIPTION


DEPENDENCIES
- The runbook must be called from an Azure Log Analytics alert via a webhook.

REQUIRED AUTOMATION ASSETS
- An Automation connection asset called "AzureRunAsConnection" that is of type AzureRunAsConnection.
- An Automation certificate asset called "AzureRunAsCertificate".

.PARAMETER WebhookData
Optional. (The user doesn't need to enter anything, but the service always passes an object.)
This is the data that's sent in the webhook that's triggered from the alert.

.NOTES
AUTHOR: Nathan Swift
LASTEDIT: 201*-11-18
#>

[OutputType("PSAzureOperationResponse")]

param
(
    [Parameter (Mandatory=$false)]
    [object] $WebhookData
)

$ErrorActionPreference = "stop"

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


##Manual Testing
#$WebhookData = Get-Content 'C:\temp\alertip8.json' | Out-String | ConvertFrom-Json

#Static Variables
$NSGname = "YOUR NSG NAME"
$NSGrg = "YOUR NSG RESOURCE GROUP NAME"

#Take Webhook Data and taketody of Data in alert and convert JSON into PS Object
$WebhookRequestBody = $WebhookData.RequestBody | ConvertFrom-Json

#store the Rows results of alert data into a variable
$rows = $WebhookRequestBody.data.SearchResult.tables.rows | select -Unique

#Run through each instance of variable data
foreach ($row in $rows[0]){
    
    #REGEX Match for a Public IP Address in the row of data
    $pips = $row -match "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    
    #If a PIP is found stop script
    If ($pips) {

        #Set $PIP variable to the row with public ip address found in Regex match 
        $pip = $row
        break
    }

}

#Another logic, some alerts rows contains multiple entries with rows of data, in this case finding the Public IP Address needs a differnt handling mechanism

#No Public IP Addrewas found with method one
if (!$pips){

    Write-Host "Null value detected"

    # Nested foreach loops help check into each individual row across multiple entries of the alert data
    foreach ($rowsingle in $rows){
        foreach ($rowunique in $rowsingle){
            Write-Host "Row Single is: $rowsingle"
            $pip = $rowunique -match "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
            If ($pip) {
                break
            }
        }
    }
    $pip = $rowunique
    Write-Host ($pip)

}

Write-Host ($pip)

#/32 CIDR to PIP for NSG rule
$pipcidr = $pip+"/32"

Write-Host ($pipcidr)

#obtain the NSG you want to add a rule to - Set you unique NSG anme and ResourceGroupName
$NSG = Get-AzureRmNetworkSecurityGroup -Name $NSGname -ResourceGroupName $NSGrg

#Check the custom rules count and add to the next priority so oes not overlap with existing priority rule
$priority = $NSG.SecurityRules.Priority.Count + 101

$rulename = New-Guid
Write-Host ($rulename)

#Construct the NSG Rule based of the pity found and the PIP CIDR found above and apply the new rule to the NSG - Set you unique NSG anme and ResourceGroupName
Get-AzureRmNetworkSecurityGroup -Name $NSGname -ResourceGroupName $NSGrg | Add-AzureRmNetworkSecurityRuleConfig -Name "logrb_$rulename" -Direction Inbound -Priority $priority -Access Deny -SourceAddressPrefix $pipcidr -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange '*' -Protocol '*' | Set-AzureRmNetworkSecurityGroup
