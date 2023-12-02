#Install-Module WebJEAConfig

#Config.Json location and other inputs will depend on your specific configuration.
Import-Module WebJEAConfig
Open-WebJEAFile -Path "c:\scripts\config.json" 
New-WebJEACommand -CommandId 'getupdate' -DisplayName 'Update History' -Script 'get-update.ps1' -PermittedGroups @('*')
Save-WebJEAFile