param(
[Parameter(Position=0, Mandatory, HelpMessage='What computer name would you like to target?')]
[string[]]$nodes

)

$pwd = "Voidmain@7907"
$Password = convertto-securestring $pwd -asplaintext -force
$Username = "lpu\amanasr"
    
$dummy = New-object -typename System.Management.Automation.PSCredential -ArgumentList $Username, $Password

foreach ($node in $nodes)
{
    Invoke-Command -ComputerName $node -Credential $dummy -ScriptBlock {
        $updates = Get-HotFix
        $updates | select Description, HotFixID, InstalledOn, PSComputerName | Format-Table
    }
} 