### How many workflows are running on my SharePoint Farm?

$sites = Get-SPSite -Limit All
$total = 0
foreach ($site in $sites){
    $webs = $site | Get-SPWeb -Limit All
	foreach ($web in $webs){
		foreach ($list in $web.lists){
			foreach ($item in $list.workflowassociations | where {$_.runninginstances -gt 0}){
				if ("$($web.Url)"){
					Write-Host "Site URL: $($web.Url)"
					Write-Host "- List: $($list.Title) ($($list.ItemCount))"
					Write-Host "- List URL: $($web.Url)/$($list.RootFolder.Url)"
					Write-Host "- Running: $($item.RunningInstances)"
					Write-Host
					$total++
				}
			}
		}
	}
	$site.dispose()
}
Write-Host "$($total) workflows instances are running on this Farm!"