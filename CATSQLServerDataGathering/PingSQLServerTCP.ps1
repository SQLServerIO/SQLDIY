function PingSQLServerTCP {
<#[cmdletbinding(  
    DefaultParameterSetName = '',  
    ConfirmImpact = 'low'  
)]  
    Param(  
        [Parameter(  
            Mandatory = $True,  
            Position = 0,  
            ParameterSetName = '',  
            ValueFromPipeline = $True)]  
            [string]$computer,  
        [Parameter(  
            Position = 1,  
            Mandatory = $True,  
            ParameterSetName = '')]  
            [string]$port,  
        [Parameter(  
            Mandatory = $False,  
            ParameterSetName = '')]  
            [int]$TCPtimeout=1000
)#>
    #Begin {  
        $computer = "webserver"
        $port = 1433
        $TCPtimeout = 1000
        $ErrorActionPreference = "SilentlyContinue"  
        $report = @()  
    #}  
    #Process {  
    #Create temporary holder   
    $temp = "" | Select Server, Port, TypePort, Open, Notes  
    #Create object for connecting to port on computer  
    $tcpobject = new-Object system.Net.Sockets.TcpClient  
    #Connect to remote machine's port                
    $connect = $tcpobject.BeginConnect($computer,$port,$null,$null)  
    #Configure a timeout before quitting  
    $wait = $connect.AsyncWaitHandle.WaitOne($TCPtimeout,$false)  
    #If timeout  
    If(!$wait) {  
        #Close connection  
        $tcpobject.Close()  
        Write-Verbose "Connection Timeout"  
        #Build report  
        $temp.Server = $computer
        $temp.Port = $port
        $temp.TypePort = "TCP"  
        $temp.Open = "False"  
        $temp.Notes = "Connection to Port Timed Out"  
    } Else {  
        $error.Clear()  
        $tcpobject.EndConnect($connect) | out-Null  
        #If error  
        If($error[0]){  
            #Begin making error more readable in report  
            [string]$string = ($error[0].exception).message  
            $message = (($string.split(":")[1]).replace('"',"")).TrimStart()  
            $failed = $true  
        }  
        #Close connection      
        $tcpobject.Close()  
        #If unable to query port to due failure  
        If($failed){  
            #Build report  
            $temp.Server = $computer
            $temp.Port = $port
            $temp.TypePort = "TCP"  
            $temp.Open = "False"  
            $temp.Notes = "$message"  
        } Else{  
            #Build report  
            $temp.Server = $computer
            $temp.Port = $port
            $temp.TypePort = "TCP"  
            $temp.Open = "True"    
            $temp.Notes = ""  
        }  
    }     
    #Reset failed value  
    $failed = $Null      
    #Merge temp array with report              
    $report += $temp  

#    End {  
        #Generate Report  
        $report 
 #   }
#}
}
PingSQLServerTCP