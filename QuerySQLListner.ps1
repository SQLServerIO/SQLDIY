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
        $ConnectionTimeout = 10000
    } 
    Process { 
        $FormattedResults = "" | Select ServerName, InstanceName, IsClustered, Version, TCP,NamedPipe
        $UDPClient = new-Object system.Net.Sockets.Udpclient
        $UDPClient.client.ReceiveTimeout = $ConnectionTimeout 
        $UDPClient.Connect("$Computer",$Port)
        Write-Host $Computer
        Write-Host $Port
        $ToASCII = new-object system.text.asciiencoding 
        $UDPPacket = 0x02
        [void]$UDPClient.Send($UDPPacket,$UDPPacket.length) 
        $UDPEndpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0) 
        Try { 
            $BytesRecived = $UDPClient.Receive([ref]$UDPEndpoint) 
            [string]$Response = $ToASCII.GetString($BytesRecived)
            $res = ""
            If ($Response) {
                $Response = $Response.Substring(3,$Response.Length-5)
                $i = 0;
                $Response.Split(";") | ForEach {
                if ($i % 2 -eq 0) {
                    Write-Host "col:"$_
                }
                else {
                    Write-Host "val:"$_
                }
                $i+=1
            }
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
    }
}

QuerySQLListner UH-ORSUPPLYT-01