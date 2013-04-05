function QuerySQLListner{ 
    [cmdletbinding( 
        DefaultParameterSetName = '', 
        ConfirmImpact = "low"
    )] 
    Param( 
        [Parameter( 
            Mandatory = $True, 
            Position = 0, 
            ParameterSetName = '', 
            ValueFromPipeline = $True)] 
        [string]$Computer
    ) 
    Begin { 
        $ErrorActionPreference = "SilentlyContinue" 
        $Port = 1434
        $ConnectionTimeout = 1000
        $Responses  = @();
    } 
    Process { 
        $UDPClient = new-Object system.Net.Sockets.Udpclient
        $UDPClient.client.ReceiveTimeout = $ConnectionTimeout
        $IPAddress = [System.Net.Dns]::GetHostEntry($Computer).AddressList[0].IPAddressToString
        $UDPClient.Connect($IPAddress,$Port)
        $ToASCII = new-object system.text.asciiencoding 
        $UDPPacket = 0x03,0x00,0x00
        Try { 
            $UDPEndpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0)
            $UDPClient.Client.Blocking = $True
            [void]$UDPClient.Send($UDPPacket,3)#$UDPPacket.length
            $BytesRecived = $UDPClient.Receive([ref]$UDPEndpoint) 
            [string]$Response = $ToASCII.GetString($BytesRecived)
            $res = ""
            If ($Response) {
                $Response = $Response.Substring(3,$Response.Length-3).Replace(";;","~")
                #$i = 0;
                $Response.Split("~") | ForEach {
                $Responses += $_
            }
            $socket = $null;
            $UDPClient.close() 
        }
        }
        Catch { 
            $Error[0].ToString()
            if(!(Test-Connection -Cn $Computer -BufferSize 16 -Count 1 -ea 0 -quiet))
            {"Problem still exists in connecting to $s"}
            $UDPClient.Close()
        } 
    } 
    End { 
        return ,$Responses
    }
}

try {    
    Import-Module FailoverClusters;
    $isfcavail = "TRUE";
}
catch [Exeption] {
    $isfcavail = "FALSE";
}
#---------------------------------------------------------------
# Determine if a sql command is given or the path to a file.
#
$table = "";
$sqlFile = (Resolve-Path .\Management.GatherServernameps.sql).Path 
$server = "CATAUSLR9PV8P2";
$rserver = "CATAUSLR9PV8P2";
$database = "master";
$rdatabase = "Management";
$loginfailed = 0;
$pingfailed = 0;

$command = $sqlFile.Trim();
if (Test-Path $command -pathType leaf) {
	#---------------------------------------------------------------
	# Since a file path was given, pull the content as the sql command.
	#
	$command = Get-Content $command;
}

#---------------------------------------------------------------
# Create a connection object, if this cannot be create we must fail
#
$conn = New-Object System.Data.SqlClient.SqlConnection;
$rconn = New-Object System.Data.SqlClient.SqlConnection;
if (!$conn) {
	Throw "SqlConnection could not be created!";
	return;
}
$i = 0;
$File = (Resolve-Path .\NetworkMachines.txt).Path 
$serverList = @();
Get-Content $File | foreach-Object {
    $i = $i + 1;
    $server = $_;
    $pingfailed  = 0;
    $loginfailed = 0;
    Write-Host "Count              :"$i;
    Write-Host "Server             :"$server
    if(!(Test-Connection -Cn $server -BufferSize 16 -Count 1 -ea 0 -quiet))
    {
	    $pingfailed = 1;
    }

    $serverList += $server;    
    try{
        QuerySQLListner $server | foreach-Object{
            foreach($str in $_) {
                $str = $str.Replace("ServerName;","").Replace("InstanceName;","")
                if($str.Trim().Length -gt 0)
                {   $str
                    $svr = $str.Substring(0,$str.IndexOf(";"))
                    $inst = $str.ToString().Substring($str.IndexOf(";")+1,$str.IndexOf(";",$str.IndexOf(";",$str.IndexOf(";")+1))-$str.IndexOf(";")-1)
                    if(!$inst.Contains("MSSQLSERVER"))
                    {
                        $svr = $svr+"\"+$inst
                    }
                    $serverList += $svr
                }
            }
        }
    }
    catch
    {}
    if ($isfcavail) {
        try {
            Get-ClusterResource -Cluster $server -ea "0" | ForEach-Object {
                if ($_.Name -match "SQL Network Name") {
                    Write-Host "cluster            :" $_.Name.Replace("SQL Network Name (","").Replace(")","")
                    $serverList += $_.Name.Replace("SQL Network Name (","").Replace(")","").Trim()
                }
            }
        }
        catch {
            Write-Host "not a cluster"
        }
    }
   
     try {
        Get-Service MSSQLServer -ComputerName $server -ea "0" | ForEach-Object {
            if ($_.Status -eq "Running") {
                Write-Host "default instance   :" $server
            }
        }
    }
    catch {
        if(!(Test-Connection -Cn $server -BufferSize 16 -Count 1 -ea 0 -quiet)) {
            $pingfailed = 1;
        }
    }
            
    try {
        Get-Service MSSQL$* -ComputerName $server -ea "0" | ForEach-Object {
            if ($_.Status -eq "Running") {
                Write-Host "named instance     :"$_.Name.Replace("MSSQL",$server).Replace("$", "\")
               $serverList += $_.Name.Replace("MSSQL",$server).Replace("$", "\").Trim()
                Write-Host "named instance added"
            }
        }
    }
    catch {
        if(!(Test-Connection -Cn $server -BufferSize 16 -Count 1 -ea 0 -quiet))
        {
            $pingfailed = 1;
        }
    }
}  

$serverList.Count;
$serverList = $serverList | select -uniq
$serverList.Count;

foreach ($s in $serverList){
    $pingfailed  = 0;
    $loginfailed = 0;

    $server = $s;

    Write-Host "Test Server        :"$server
    $connString = "Server = $($server);";

    #---------------------------------------------------------------
    # Include the database in our connection string if one is given.
    #
    if ($database)
    {
    	    $connString = $connString + " Database = $($database);";
    }

    #---------------------------------------------------------------
    # Base security on the existence of a username/password
    #
    if ($userName -and $password)
    {
    	    $connString = $connString + " User Id = $($userName); Password = $($password)";
    }
    else
    {
    	    $connString = $connString + " Integrated Security = True";
    }

    #---------------------------------------------------------------
    # Default the repository server to local if one was not provided
    #
    if (!$rserver)
    {
    	    $rserver = "(local)";
    }

    $rconnString = "Server = $($rserver);";
    #---------------------------------------------------------------
    # Include the repository  database in our connection string if one is given.
    #
    if ($rdatabase)
    {
    	    $rconnString = $rconnString + " Database = $($rdatabase);";
    }
    #---------------------------------------------------------------
    # repository connection string trusted auth only!
    $rconnString = $rconnString + " Integrated Security = True";

    #---------------------------------------------------------------
    # Now that we have built our connection string, attempt the connection.
    #
    $conn.ConnectionString = $connString;
    $rconn.ConnectionString = $rconnString;
    $error.clear();
    try {
        $conn.Open();
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        if($error[0].Exception -match "Login failed"){
        $loginfailed = 1
        }
    }
    $rconn.Open();
    if (($conn.State -eq 1) -and ($rconn.State -eq 1))
    {
    	    $cmd = New-Object System.Data.SqlClient.SqlCommand $command, $conn;
    	    if ($cmd)
    	    {
    		    $data = New-Object System.Data.SqlClient.SqlDataAdapter;
    		    if ($data)
    		    {
    			    $ds = New-Object System.Data.DataSet;
    			    if ($ds)
    			    {
    				    $data.SelectCommand = $cmd;
    				    $data.Fill($ds) | Out-Null;
                    
    				    foreach ($table in $ds.Tables)
    				    {
    					    foreach ($row in $table)
                        {
                         $rcmd = New-Object System.Data.SqlClient.SqlCommand;
                         $rcmd.connection = $rconn;
                         $rcmd.commandtext = "INSERT INTO "+$rdatabase+".dbo.ServerList (QueriedServer,ReturnedServer,Version,PingFailed,LoginFailed) VALUES('"+$server+"','"+$row.ItemArray.GetValue(0)+"','"+$row.ItemArray.GetValue(1)+"',"+$pingfailed+","+$loginfailed+")"
                         $rcmd.executenonquery()  | Out-Null;
                        }
                    }
    				    $ds.Dispose();
    			    }
    			    else
    			    {
    				    Write-Host "Failed creating the data set object!";
    			    }
    			    $data.Dispose();
    		    }
    		    else
    		    {
    			    Write-Host "Failed creating the data adapter object!";
    		    }
    		    $cmd.Dispose();
    	    }	
    	    else
    	    {
    		    Write-Host "Failed creating the command object!";
    	    }
    	    $conn.Close();
        $rconn.close();

    }
    else
    {
         $rcmd = New-Object System.Data.SqlClient.SqlCommand;
         $rcmd.connection = $rconn;
         $rcmd.commandtext = "INSERT INTO "+$rdatabase+".dbo.ServerList (QueriedServer,ReturnedServer,Version,PingFailed,LoginFailed) VALUES('"+$server+"','','',"+$pingfailed+","+$loginfailed+")"
         $rcmd.executenonquery()  | Out-Null;
    }
    $conn.Dispose();
    $rconn.Dispose();
}
