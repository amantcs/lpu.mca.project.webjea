param(
[Parameter(Position=0, Mandatory, HelpMessage='What computer name would you like to target?')]
[string[]]$nodes

)


#$cred = Get-Credential
$pwd = "*************"
    $Password = convertto-securestring $pwd -asplaintext -force
    $Username = "lpu\amanasr"
    
    $dummy = New-object -typename System.Management.Automation.PSCredential -ArgumentList $Username, $Password

<#
Try{
$nodes = Get-Content D:\PowerShell\servers.txt

}

Catch{
    Write-Error "Text File Path Error. Please Correct and Try Again"
    Write-Error $_.Exception
    Exit -1
} #>
$report = @()

$count = 1
$array = @()
$arrayDay = @()
#Write-Host "Collecting Data..."
foreach( $node in $nodes) {
    
    $serverObject = "" | Select-Object ServerCount, ServerName, ServerIp, State, CTotalSpace, CFreeGB, CUtil, ETotalSpace, EFreeGB, EUtil, CPU, Memory, AutomaticServices, LastRebootedOn, Days, Hours, Minutes, Seconds


    $serverObject.ServerCount = $count
    $serverObject.ServerName = $node

    if (test-connection $node -count 1 -quiet)
    {
        $serverObject.State = "Running"

        Try{
        $temp = nslookup $node
        $temp1 = $temp.split(":")
        $temp1 = $temp1.trim(" ")
        $ip = $temp1[10]
        $serverObject.ServerIp = $ip}

        Catch{
            $serverObject.ServerIp = "NA"
        }

        Try{
        $cdisk = Invoke-Command -ComputerName $node -Credential $dummy -ScriptBlock { Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object FreeSpace, Size } -ErrorAction SilentlyContinue
        $ctotal = [math]::Round($cdisk.Size/1gb,2)
        $serverObject.CTotalSpace =  "$ctotal GB"
        $cfree = [math]::Round($cdisk.FreeSpace/1gb,2)
        $serverObject.CFreeGB = "$cfree GB"
        $util = [math]::Round(100-(($cfree*100)/$ctotal),2)
        $serverObject.CUtil = "$util%"
        }
        Catch{
        $serverObject.CTotalSpace = "WinRM-Issue"
        $serverObject.CFreeGB = "WinRM-Issue"
        $serverObject.CUtil = "WinRM-Issue"
        }
        
        Try{
        $edisk = Invoke-Command -ComputerName $node -Credential $dummy -ScriptBlock { Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='D:'" | Select-Object FreeSpace, Size } -ErrorAction SilentlyContinue 
        $etotal = [math]::Round($edisk.Size/1gb,2)
        $serverObject.ETotalSpace =  "$etotal GB"
        $efree = [math]::Round($edisk.FreeSpace/1gb,2)
        $serverObject.EFreeGB = "$efree GB"
        $eutil = [math]::Round(100-(($efree*100)/$etotal),2)
        $serverObject.EUtil = "$eutil%"
        }

        Catch{
        $serverObject.ETotalSpace = "WinRM-Issue"
        $serverObject.EFreeGB = "WinRM-Issue"
        $serverObject.EUtil = "WinRM-Issue"
        }

        Try{
        
        $cpu = (Invoke-Command -ComputerName $node -Credential $dummy -ScriptBlock {Get-WMIObject win32_processor | Measure-Object -Property LoadPercentage -Average | Select Average} -ErrorAction SilentlyContinue).Average
        $serverObject.CPU = "$cpu%"
        }
        Catch{
        $serverObject.CPU = "WinRM-Issue"
        }
        
        Try{
        $memory = (Invoke-Command -ComputerName $node -Credential $dummy  -ScriptBlock { gwmi win32_operatingsystem |Select-Object @{Name = "MemoryUsage"; Expression = {“{0:N2}” -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) }}} -ErrorAction SilentlyContinue).MemoryUsage
        $serverObject.Memory = "$memory%"

        if($serverObject.Memory -gt 95)
        {
            Invoke-Command -ComputerName satlrccdlin561 -Credential $dummy  -ScriptBlock { gps |  sort -Property ws -Descending | select name, path, ws -first 5 | Format-Table}
        }


        }
        Catch{
        $serverObject.Memory = "WinRM-Issue"
        }

        Try{
        $stopped  = Invoke-Command -ComputerName $node -Credential $dummy -ScriptBlock { Get-Service | Where-Object {$_.StartType -eq "Automatic" -and $_.Status -eq "Stopped"} } -ErrorAction SilentlyContinue
        $no = $stopped.Count
        if($no -gt 0)
        {
            $serverObject.AutomaticServices = "$no Not Running"
          
        }
        else
        {
            $serverObject.AutomaticServices = "All Running"
        }}

        Catch{
        $serverObject.AutomaticServices = "WinRM-Issue"
        }

        Try{
        $time = Invoke-Command -ComputerName $node -Credential $dummy -ScriptBlock { (Get-WmiObject win32_operatingsystem | select @{Label = 'LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}}).LastBootUpTime } -ErrorAction SilentlyContinue
        $serverObject.LastRebootedOn = $time

        $days = ((Get-Date)-$time).Days
        $serverObject.Days = "$days Days"
            
        
        $hours = ((Get-Date)-$time).Hours
        $serverObject.Hours = "$hours Hours"

    
        $minutes = ((Get-Date)-$time).Minutes
        $serverObject.Minutes = "$minutes Minutes"

    
        $seconds = ((Get-Date)-$time).Seconds
        $serverObject.Seconds = "$seconds Seconds"
        }
        Catch{
        $serverObject.LastRebootedOn = "WinRM-Issue"
        $serverObject.Days = "WinRM-Issue"
        $serverObject.Minutes = "WinRM-Issue"
        $serverObject.Seconds = "WinRM-Issue"
        }
    }
    else
    {
        $serverObject.State = "Stopped"
        $serverObject.ServerIp = "NA"

        $serverObject.CTotalSpace = "NA"
        $serverObject.CFreeGB = "NA"
        $serverObject.CUtil = "NA"

        $serverObject.ETotalSpace = "NA"
        $serverObject.EFreeGB = "NA"
        $serverObject.EUtil = "NA"
        $serverObject.AutomaticServices = "NA"

        $serverObject.LastRebootedOn = "NA"
        $serverObject.Days = "NA"
        $serverObject.Hours = "NA"
        $serverObject.Minutes = "NA"
        $serverObject.Seconds = "NA"
    }

     $report += $serverObject 
     #Write-Host "Server $count done."
     $count++
}
#Consolidated data from all servers has been saved in report variable
#$report | Select ServerName, State, CUtil, EUtil, LastRebootedOn | Format-Table -Wrap
#Write-Host "Data Collection Completed. Generating HTML Report..."
$Header = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TH {border-width: 1px; padding: 3px; border-style: solid; border-color: black; background-color: #BFBFBF;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$body = @"
<a href="https://lpuwebjea.lpu.com/WebJEA/?cmdid=serverhealth"> Back</a>
"@
$htmlData
$htmlData = $report | ConvertTo-Html -PreContent "<h1>Server Report</h1>" -Head $Header -Body $body

$FormattedHTML =  $htmlData | ForEach {

   $_ -replace "<td>Running</td>","<td bgcolor='#40B070'>Running</td>"  -replace "<td>Stopped</td>","<td bgcolor='#FF6666'>Stopped</td>"  -replace "<td>All Running</td>","<td bgcolor='#40B070'>All Running</td>"  -replace "<td>WinRM-Issue</td>","<td bgcolor='#FADB52'>WinRM-Issue</td>"

}

Function format-html{
    $columns = @("ServerName", "State", "CUtil", "EUtil", "CPU", "Memory", "AutomaticServices")

$html = "[[span|table|"

$html = $html + "[[span|table-caption|Server Report]]"

$html = $html + "[[span|table-header|"

# add header columns
foreach ($column in $columns) {
    $html = $html + "[[span|table-header-cell|" + $column + "]]"
}

# close header
$html = $html + "]]"

# add body
$html = $html + "[[span|table-body|"

# add rows
foreach ($row in $report) {
    $html = $html + "[[span|table-row|"

    # add cells
    foreach ($column in $columns) {
        $html = $html + "[[span|table-body-cell|" + $row.psobject.Properties[$column].Value + "]]"
    }

    # close row
    $html = $html + "]]"
}

# close body
$html = $html + "]]"

# close table
$html = $html + "]]"

# Output the formatted string:
$html
}

$FormattedHTML | Out-File report.html
Copy-Item .\report.html "C:\inetpub\wwwroot\webjea"

format-html


Write-Host "[[a|report.html|Ctrl+Click To View The Detailed Report]]"


<#
Write-Host "HTML Report Generated. Sending Email..."
[string]$body = $htmlData
$smtp = ""
$to = ""
$from = ""
$cc = ""
$subject = "Server Health Report $(Get-Date)"
Send-MailMessage -SmtpServer $smtp -To $to -Cc $cc -From $from -Subject $subject -Body $body -BodyAsHtml

Write-Host "Mail Sent with No Errors"
#>

<#
$columns = @("ServerName", "State", "CUtil", "EUtil", "CPU", "Memory", "AutomaticServices")

$html = "[[span|table|"

$html = $html + "[[span|table-caption|Server Report]]"

$html = $html + "[[span|table-header|"

# add header columns
foreach ($column in $columns) {
    $html = $html + "[[span|table-header-cell|" + $column + "]]"
}

# close header
$html = $html + "]]"

# add body
$html = $html + "[[span|table-body|"

# add rows
foreach ($row in $report) {
    $html = $html + "[[span|table-row|"

    # add cells
    foreach ($column in $columns) {
        $html = $html + "[[span|table-body-cell|" + $row.psobject.Properties[$column].Value + "]]"
    }

    # close row
    $html = $html + "]]"
}

# close body
$html = $html + "]]"

# close table
$html = $html + "]]"

# Output the formatted string:
$html

#>
