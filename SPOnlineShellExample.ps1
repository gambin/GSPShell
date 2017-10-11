#### At first you must download SPOnline SDK at https://www.microsoft.com/en-us/download/details.aspx?id=35585 ####
#### And them SPOnline Shell Management - https://www.microsoft.com/en-us/download/details.aspx?id=35588 ####

#### Add the path for SharePoint Client DLL's ####
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 
#### You might need some other references (depending on what your script does) for example: ####
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll" 

$username = "<username>@<my-domain>.com" 
$password = "MyAccountPasword321" 
$url = "https://<my-url>.sharepoint.com/teams/MySite"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url) 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword) 
$clientContext.Credentials = $credentials 
# $web = $context.Web
# $context.Load($web)


#### Get list Remote Event Recivers example: ####

$listName = "Enter the list title here"
Write-Host "Attempting to iterate event receivers on list '$listName'"

$list = $context.Web.Lists.GetByTitle($listName); 
$context.Load($list)
$eventReceivers = $list.EventReceivers
$context.Load($eventReceivers)
$context.ExecuteQuery()

Write-Host "Found" $eventReceivers.Count "receiver(s) on this list"

foreach ($er in $eventReceivers)
{
	Write-Host ("Found ER: " + $er.ReceiverName)
	Write-Host ("   ReceiverClass: " + $er.ReceiverClass)
	Write-Host ("   ReceiverAssembly: " + $er.ReceiverAssembly)
	Write-Host ("   EventType: " + $er.EventType)
	Write-Host ("   ReceiverUrl: " + $er.ReceiverUrl)
	Write-Host ("   Synchronization: " + $er.Synchronization)
}