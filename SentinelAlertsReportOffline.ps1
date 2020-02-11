#########################################################################################
## Author:      Nathan Swift
## Date:        02.11.2020
## Description: Downloads Sentinel Rules and generates a report
## Needs PS Core 6 or 7 and Module powershell-yaml 
# Install-Module -Name powershell-yaml
#########################################################################################

# download the Azure Sentinel Github zip
Invoke-WebRequest -Uri "https://github.com/Azure/Azure-Sentinel/archive/master.zip" -OutFile C:\temp\sentinel.zip

# Extract the Sentinel Github .zip
Expand-Archive -Path C:\temp\sentinel.zip -DestinationPath c:\temp\sentinel

# New Report
$filename = "SentinelAlertsReport.csv"

# base path variable
$basepath = "C:\temp\sentinel\Azure-Sentinel-master\Detections"

# Get all the detection .ayml rules
$files = Get-ChildItem -Path C:\temp\sentinel\Azure-Sentinel-master\Detections -Recurse -File -Include "*.yaml"

# For each yaml rule get unique field from the rule and import them into the csv file.
foreach ($file in $files){
    $pathfile = $basepath + "\" + $file.Directory.Name + "\" + $file.Name
    $linkpath = "https://github.com/Azure/Azure-Sentinel/tree/master/Detections/" + $file.Directory.Name + "/" + $file.Name

    $rule = [pscustomobject](Get-Content $pathfile -Raw | ConvertFrom-Yaml)

    $reportObj = New-Object PSCustomObject

    $reportObj | add-member -NotePropertyName Name -NotePropertyValue $rule.Name
    $reportObj | add-member -NotePropertyName Severity -NotePropertyValue $rule.Severity

    ## Solve for multiple objects
    $reportObj | add-member -NotePropertyName Tactics -NotePropertyValue $rule.tactics
    $reportObj | add-member -NotePropertyName Connectors -NotePropertyValue $rule.requiredDataConnectors.connectorId
    $reportObj | add-member -NotePropertyName Logs -NotePropertyValue $rule.requiredDataConnectors.dataTypes
    $reportObj | add-member -NotePropertyName Techniques -NotePropertyValue $rule.relevantTechniques    
    
    $reportObj | add-member -NotePropertyName Description -NotePropertyValue $rule.description
    $reportObj | add-member -NotePropertyName Link -NotePropertyValue $linkpath


    $reportObj | Export-Csv C:\temp\$filename -NoTypeInformation -Delimiter "," -append

}
