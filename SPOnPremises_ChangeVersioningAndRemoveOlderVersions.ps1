cls

Write-Host "** Atencao **" -BackgroundColor Blue -ForegroundColor White
Write-Host "Este script ira alterar a configuracao do versionamento de listas e bibliotecas dos sites SharePoint!" -ForegroundColor Yellow
Write-Host

$major = Read-Host "Qual o numero de major versions que serao mantidas?"
$minor = Read-Host "Qual o numero de minor versions que serao mantidas?"

$url = Read-Host "Entre com a URL do Site Collection (deixe em branco para rodar em todos os site collections)" 

if (![string]::IsNullOrEmpty($url)){
	$SPSites = Get-SPSite $url
} else {
	$SPSites = Get-SPSite -Limit All
}

if ($SPSites){
	foreach ($SPSite in $SPSites){
		$SPWebs = $SPSite | Get-SPWeb -Limit All
		foreach ($web in $SPWebs){
			Write-Host "--------------------------------------------------------------------------------"
			Write-Host "Configurando listas do site $($web.Url)" -ForegroundColor Yellow
			
			$lists = $web.Lists | where {($_.EnableVersioning) -and ($_.RootFolder.Url -notmatch "_catalogs") -and ($_.Title -ne "Workflows")}
			if ($lists){
				foreach ($list in $lists){
					Write-Host "Alterando configuracoes de versionamento da lista $($list.Title) - $($list.Url)" -ForegroundColor Green
					$list.MajorVersionLimit = $major
					if ($list.EnableMinorVersions){
						$list.MajorWithMinorVersionsLimit = $minor
					}
					$list.Update()
					Write-Host "Removendo versoes antigas de itens da lista $($list.Title)"
					foreach($item in $list.Items){
						$item.SystemUpdate($false)
					}
				}
			}
		}
		$web.Dispose()
	}
	$SPSites.Dispose()
}