param
(
    [Parameter (Mandatory=$false)]
    [object] $fscredobj,

    [string] $fsurl
)

Remove-PSDrive -Name S -Force

start-sleep -Seconds 60

New-PSDrive -Name S -PSProvider FileSystem -Root "\\$($fsurl)\samplefileshare" -Credential $fscredobj -Persist