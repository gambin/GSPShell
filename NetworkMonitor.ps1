$currentIp = Test-Connection -ComputerName $env:computername -Count 1 | Select IPV4Address
$logFile = "$((Get-Location).path)\NetworkConnectionsLog-$($env:computername)_$($currentIp.IPV4Address.IPAddressToString ).csv"

$intervalBetweenCapturesInSeconds = 15
$howManyCollects = 5

while ($i -lt $howManyCollects) {
    
    $i++

    Write-Output "Starting the collection: $i of $howManyCollects"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # More details here: https://maxnilz.com/docs/004-network/003-tcp-connection-state/
    $connections = Get-NetTCPConnection -State Listen, Established, TimeWait -ErrorAction SilentlyContinue | Where-Object LocalAddress -NotMatch ':' | 
        Select LocalAddress, LocalPort, RemoteAddress, RemotePort, OwningProcess, State
    
    $dnsResolverExcludedIPs = @("0.0.0.0","127.0.0.1")
    
    foreach ($item in $connections){
        Write-Output "Getting extra info - $([array]::IndexOf($connections, $item)) of $($connections.Length)"
        if(!([string]::IsNullOrEmpty($item.RemoteAddress)) -and ($item.RemoteAddress -notin $dnsResolverExcludedIPs)){
            $dnsName = (Get-DnsClientCache | Where-Object { $_.data -eq $item.RemoteAddress }).Entry
            if (-not $dnsName) {
                ### May slow down...
                # $dnsName = (Resolve-DnsName -ErrorAction SilentlyContinue -Name $item.RemoteAddress).NameHost
                # if (-not $dnsName) {
                    $dnsName = "DNS name not found"
                # }
            } else {
                if ($dnsName.Length -gt 1){
                    $dnsName = $dnsName -join ","
                }
            }
        } else {
            $dnsName = "Not Applicable"
        }
        Write-Output "[x] DNS extended info done!"

        $processName = (Get-Process -Id $item.OwningProcess -ErrorAction SilentlyContinue).Name
        if (-not $processName) {
            $processName = "Process name not found"
        }
        Write-Output "[x] Process extended info done!"
       
        $item | Add-Member -MemberType NoteProperty -Name RemoteAddress_DNS -Value $dnsName
        $item | Add-Member -MemberType NoteProperty -Name Timestamp -Value $timestamp
        $item | Add-Member -MemberType NoteProperty -Name ProcessName -Value $processName
    }

    $connections | 
        Select Timestamp, LocalAddress, LocalPort, RemoteAddress, RemoteAddress_DNS, RemotePort, State, OwningProcess, ProcessName | 
        Sort-Object -Property State -Descending |
        Export-Csv -Path $logFile -NoTypeInformation -Append

    Write-Output "Waiting some time for the next run!"
    Start-Sleep -Seconds $intervalBetweenCapturesInSeconds
}

Write-Output "`nDiscovery completed. Results saved to ${logFile}."
