#IMPORT MODULE
import-module Az.DesktopVirtualization
import-module Az.Compute
import-module Az.Accounts

#Connect to azure
try
{
    "Logging in to Azure..."
    Connect-AzAccount -Identity
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}

### VARIABLES ####
#$subscriptionID = "YOUR-SUBSCRIPTION-ID" 
#$tenantID = "YOUR-TENANT-ID"
$hostpoolname = "Personal-Hostpool-ZF" 
$rgname = "RG-ZF-AVD"
$tempo = 120 #TIME IN SECONDS TO WAIT BETWEEN MESSAGE AND USER LOGOFF ACTION
$msgtitle = "Warning! Session is going to be disconnected." #message title
$msgbody = "All virtual machines are going to shutdown in 120 seconds, please log-off your computers." #message body

#GET WVD SESSION HOST VM LIST
$sessionhost = Get-AzWvdSessionHost -HostPoolName $hostpoolname -ResourceGroupName $rgname

#FOR EACH SESSION HOST, GET USER SESSIONS AND TAKE ACTION
foreach ($server in $sessionhost){
    $temp = $server.name
    $array = $temp.Split("/") #SPLIT VM NAME
    #LIST USER SESSIONS FROM ONE SESSION HOST VM
    $session = Get-AzWvdUserSession -HostPoolName $hostpoolname -ResourceGroupName $rgname -SessionHostName $array[1]
    #TEST IF SESSION HOST VM HAS USER SESSION CONNECTED
    if ($session -eq $nul)
        {
            #IF IT HAS NO USER SESSION, THEN SHUTDOWN THE VM
            $vmname = $array[1].Split(".")
            Write-Host $vmname[0] "is shutdown"
            Stop-AzVM -Name $vmname[0] -ResourceGroupName $rgname -Force
        }
    else
        {
            #IF IT HAS USER SESSION, FOR EACH USER SESSION SEND A LOGOFF MESSAGE TO THE USER, WAIT SOME TIME, DISCONNECT USER AND THEN SHUTDOWN THE VM
            foreach ($userid in $session) {
                write-host $userid
                #SPLIT USER ID 
                $temps = $userid.Name
                $xid = $temps.Split("/")
                write-host "Session ID" $xid[2]
                #SEND MESSAGE TO THE USER WARNING ABOUT SESSION LOGOFF IN X SECONDS 
                Send-AzWvdUserSessionMessage -HostPoolName $hostpoolname -ResourceGroupName $rgname -SessionHostName $array[1] -UserSessionId $xid[2] -MessageTitle $msgtitle -MessageBody $msgbody
                #WAIT X SECONDS BEFORE DISCONNECT THE USER SESSION
                sleep $tempo
                #DISCONNECT USER SESSION
                Remove-AzWvdUserSession -HostPoolName $hostpoolname -ResourceGroupName $rgname -SessionHostName $array[1] -Id $xid[2] -Force
            }
            #SHUTDOWN THE VIRTUAL MACHINE AFTER ALL USER SESSION WERE DISCONNECTED
            $vmname = $array[1].Split(".")
            Write-Host $vmname[0] "is shutdown"
            Stop-AzVM -Name $vmname[0] -ResourceGroupName $rgname -Force
        }
}
