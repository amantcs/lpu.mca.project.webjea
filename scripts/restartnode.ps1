param(
[Parameter(Position=0, Mandatory, HelpMessage='What computer name would you like to target?')]
[string[]]$nodes

)

Restart-Computer -ComputerName $nodes -Force

Write-Host "$nodes Reboot Done" 