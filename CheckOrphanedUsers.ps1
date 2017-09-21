if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) { 
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
cls
 
# Menu de configuracao de formatacao do CSV
Write-Host "Entre com a configuração de Output do CSV (para melhor formatação no Excel)"
Write-Host
$csvOptions = [System.Management.Automation.Host.ChoiceDescription[]] @("&EN-US", "&PT-BR")
[int]$csvDefaultchoice = 1
$csvOpt =  $host.UI.PromptForChoice($Title , $Info , $csvOptions, $csvDefaultchoice)
switch($csvOpt){
    0 { 
        Write-Host "O conteúdo do CSV gerado será formatado em padrão EN-US" -ForegroundColor White
        $separator = ","
    }
    1 { 
        Write-Host "O conteúdo do CSV gerado será formatado em padrão PT-BR" -ForegroundColor White
        $separator = ";"
    }
}
Write-Host
Write-Host "Entre com o modo de execução"
Write-Host
$execOptions = [System.Management.Automation.Host.ChoiceDescription[]] @("&Análise", "&Remoção")
[int]$execDefaultchoice = 0
$execOpt =  $host.UI.PromptForChoice($Title , $Info , $execOptions, $execDefaultchoice)
switch($execOpt){
    0 { 
        Write-Host "Serão apenas analisadas as contas de usuário do site" -ForegroundColor White
        $removeUsr = $false
    }
    1 { 
        Write-Host "Os usuários não identificados serão removidos!" -ForegroundColor Yellow
        $removeUsr = $true
    }
}
Write-Host
 
# Configuracoes Gerais
$domainPrefix = $env:userdomain + "\"
$inicio = Date
$global:resultsarray =@()
$global:usersNotFound = $true
 
# Funcao para montar o array que sera exportado no final e gerar um CSV
function exportGenerator($exUser,$exUrl,$exReason,$exAction){
    $ItemPropertiesObject = new-object PSObject
    $ItemPropertiesObject | add-member -membertype NoteProperty -name "Login" -Value $exUser.UserLogin
    $ItemPropertiesObject | add-member -membertype NoteProperty -name "Usuario" -Value $exUser.DisplayName
    $ItemPropertiesObject | add-member -membertype NoteProperty -name "Site" -Value $exUrl.Url
    $ItemPropertiesObject | add-member -membertype NoteProperty -name "Motivo" -Value $exReason
    $ItemPropertiesObject | add-member -membertype NoteProperty -name "Acao" -Value $exAction
    $global:resultsarray += $ItemPropertiesObject
}
 
# Funcao para analisar todos os usuarios de cada web
function analyzeWeb($anWeb){
    Write-Host
    Write-Host " - Analisando o site $($anWeb.Url)" -ForegroundColor Green
    foreach ($user in $anWeb.AllUsers | where {($_.UserLogin.ToLower() -ne "sharepoint\system") -and ($_.UserLogin.ToLower() -ne "nt authority\authenticated users") -and ($_.UserLogin.ToLower() -ne "nt authority\local service") -and ($_.UserLogin.ToLower() -notmatch "iusr")}){                                           
        $ds = New-Object System.DirectoryServices.DirectorySearcher
        $ds.Filter = "(&(objectCategory=User)(sAMAccountname=" + ($user.UserLogin).Split("\")[1] + "))"
        $de = $ds.FindOne()
        if ($de){
            $de = $de.GetDirectoryEntry()
            if ($de.accountdisabled) {
                $reason = "Desabilitado no AD"
                $action = "Deverá ser removido do site SharePoint"
                Write-Host " -- Login $($user.UserLogin) | $($reason)" -ForegroundColor Yellow
                $global:usersNotFound = $false
                if($anWeb.IsRootWeb -or $anWeb.HasUniquePerm){
                    if($removeUsr){
                        Remove-SPUser ($user.UserLogin) -Web $anWeb -Confirm:$false
                        if ($?){
                            Write-Host " -- Login $($user.UserLogin) | $($action) - $($anWeb.Url)!" -ForegroundColor Yellow
                            $action = "Usuário removido do site SharePoint"
                        } else {
                            $action = "Erro ao remover usuário do site SharePoint. Motivo: $($error[0])"
                            Write-Host " -- Login $($user.UserLogin) | Não foi possível removê-lo! - $($anWeb.Url)!" -ForegroundColor Red
                            Write-Host                 
                        }
                    }
                    exportGenerator $user $anWeb $reason $action
                } else {
                    $reason = "Não será possível retirar as permissões do usuário pois ele herda permissões do site root."
                    $action =  "Será necessário remover as permissões do usuário no site root ou quebrar a herança de permissões no subsite $($anWeb.Url)"
                    exportGenerator $user $anWeb $reason $action
                }
            }           
        } else {
            $reason = "Não existe no AD"
            $action = "Deverá ser removido do site SharePoint"
            Write-Host " -- Login $($user.UserLogin) | $($reason)" -ForegroundColor Yellow
            if($removeUsr){
                Remove-SPUser ($user.UserLogin) -Web $anWeb -Confirm:$false
                if ($?){
                    Write-Host " -- Login $($user.UserLogin) | $($action) - $($anWeb.Url)!" -ForegroundColor Yellow
                    $action = "Usuário removido do site SharePoint"
                } else {
                    $action = "Erro ao remover usuário do site SharePoint. Motivo: $($error[0])"
                    Write-Host " -- Login $($user.UserLogin) | Não foi possível removê-lo! - $($anWeb.Url)!" -ForegroundColor Red
                    Write-Host                 
                }
            }
            exportGenerator $user $anWeb $reason $action
        }
    }
    $anWeb.Dispose()
}
 
# Menu de definicao de escopo do site
Write-Host
$scopeOptions = [System.Management.Automation.Host.ChoiceDescription[]] @("Site &Específico","&Todos os Site Collections")
[int]$scopeDefaultchoice = 1
$scopeOpt =  $host.UI.PromptForChoice($Title , $Info , $scopeOptions, $scopeDefaultchoice)
switch($scopeOpt){
    0 {
        Write-Host "Será analisadao um site específico" -ForegroundColor White
        Write-Host
        $mainWeb = Read-Host "Entre com o endereço do site desejado (ex.: http://meu-site-collection/)"
        analyzeWeb(Get-SPWeb $mainWeb)
    }
    1 { 
        Write-Host "Analisando todos os sites collections e seus respectivos subsites" -ForegroundColor White
        $sites = Get-SPSite -Limit All
        foreach ($site in $sites){
            $webs = $site | Get-SPWeb -Limit All
            foreach ($web in $webs){
                analyzeWeb($web)
            }
            $web.Dispose()
        }
        $site.Dispose()
    }
}
Write-Host
 
if(!$removeUsr){
    $filePrefix = "CheckOrphanedUsers"
}else{
    $filePrefix = "RemovedOrphanedUsers"
}
 
# Criando o CSV!
if (!$global:usersNotFound){
    Write-Host "Gerando arquivo CSV..." -ForegroundColor Green
    $resultsarray | Export-CSV "$($filePrefix)_$((Date).ToString('yyyyMMdd_hhmmss')).csv" -NoTypeInformation -Delimiter $separator -Encoding utf8
    Write-Host "Pronto!" -ForegroundColor Green
} else {
    Write-Host "---------------------------------------------------------------------"
    Write-Host "PARABÉNS!" -ForegroundColor Green
    Write-Host "Não foram encontrados usuário desabilitados ou não encontrados no AD!" -ForegroundColor White
    Write-Host "Por este motivo não será gerado relatório de usuários em formato CSV." -ForegroundColor White
    Write-Host "---------------------------------------------------------------------"
}
Write-Host
Write-Host "Script iniciado em $(($inicio).ToString('dd/MM/yyyy hh:mm:ss')) e finalizado em $((Date).ToString('dd/MM/yyyy hh:mm:ss'))" -ForegroundColor Yellow