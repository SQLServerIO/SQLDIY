<#
.SYNOPSIS
    Pulls details about all databases on the list of servers pulled from the management database
.DESCRIPTION
    A detailed description of the module.
#>

function Get-Database-Information {
    [CmdletBinding()]
    param(
		[Parameter(Position=0, Mandatory=$true)]
		[System.String]$rserver,
		[Parameter(Position=0, Mandatory=$true)]		
		[System.String]$rdatabase,
		[Parameter(Position=0, Mandatory=$true)]		
		[System.Boolean]$isTrusted,
		[Parameter(Position=0, Mandatory=$false)]		
		[System.String]$ruserName,
		[Parameter(Position=0, Mandatory=$false)]		
		[System.String]$rpassword
    )
    begin {
    }
    process {
		#---------------------------------------------------------------
		#load SMO 
		[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo"); 
		[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum"); 
		[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo"); 
		$smo = "Microsoft.SqlServer.Management.Smo." 
		
		$table = "";
		$server = "CATAUSLR9PV8P2";
		$rserver = "CATAUSLR9PV8P2";
		$database = "master";
		$rdatabase = "Management";
		
		#---------------------------------------------------------------
		$rconn = New-Object System.Data.SqlClient.SqlConnection;
		if (!$rconn) {
			Throw "SqlConnection could not be created!";
			return;
		}
		
		#---------------------------------------------------------------
		if (!$rserver) {
			$rserver = "(local)";
		}
		$rconnString = "Server = $($rserver);";
		
		#---------------------------------------------------------------
		if ($rdatabase) {
			$rconnString = $rconnString + " Database = $($rdatabase);";
		}
		#---------------------------------------------------------------
		# repository connection string trusted auth only!
		$rconnString = $rconnString + " Integrated Security = True";
		
		#---------------------------------------------------------------
		# set our repository connection string
		$rconn.ConnectionString = $rconnString;
		$rconn.Open()
		#---------------------------------------------------------------
		# fetch SQL Server instances to loop through
		$command = "select distinct case ReturnedServer when '' then QueriedServer else ReturnedServer end as ServerName from ServerList where version <> ''"
		$cmd = New-Object System.Data.SqlClient.SqlCommand $command, $rconn;
		try {
			if ($cmd) {
				$data = New-Object System.Data.SqlClient.SqlDataAdapter;
				if ($data) {
					$ds = New-Object System.Data.DataSet;
					if ($ds) {
						$data.SelectCommand = $cmd;
						$data.Fill($ds) | Out-Null;
					}
				}
			}
		}
		catch [Exeption] {
			thow;
		}
		
		foreach ($Instance in $ds.Tables[0].Rows) {
			$server = $Instance.ItemArray.GetValue(0);
			$objServer = new-object ($smo + 'server') "$Server" 
			$rcmd = New-Object System.Data.SqlClient.SqlCommand;
			$rcmd.connection = $rconn;
			$insdate = (Get-Date -format "yyyy/MM/dd HH:mm:ss")
			foreach($sqlDatabase in $objServer.databases) { 
				try	{
					$database = $objServer.databases[$sqlDatabase.name]
					$rcmd.commandtext="";
					$rcmd.commandtext =	"INSERT INTO ["+$rdatabase+"].[dbo].[DBProperties] ([DBName],[CreateDate],[DBVersion],[Collation],[CompatibilityLevel],[RecoveryModel],[PageVerify],[CurrentStatus],[AutoCreateStatisticsEnabled],[AutoUpdateStatisticsEnabled],[AutoShrink],[IsDatabaseSnapshot],[IsParameterizationForced],[IsReadCommittedSnapshotOn],[IsMirroringEnabled],[BrokerEnabled],[ChangeTrackingEnabled],[IsFullTextEnabled])"+"VALUES"+"('"+$database.Name+"','"+$database.CreateDate+"','"+$database.Version+"','"+$database.Collation+"','"+$database.CompatibilityLevel+"','"+$database.RecoveryModel+"','"+$database.PageVerify+"','"+$database.Status+"','"+$database.AutoCreateStatisticsEnabled+"','"+$database.AutoUpdateStatisticsEnabled+"','"+$database.AutoShrink+"','"+$database.IsDatabaseSnapshot+"','"+$database.IsParameterizationForced+"','"+$database.IsReadCommittedSnapshotOn+"','"+$database.IsMirroringEnabled+"','"+$database.BrokerEnabled+"','"+$database.ChangeTrackingEnabled+"','"+$database.IsFullTextEnabled+"')"
					$rcmd.executenonquery() | Out-Null;
		
					foreach($log in $sqlDatabase.get_logfiles()) {
						$rcmd.commandtext="";
						$rcmd.commandtext = "INSERT INTO ["+$rdatabase+"].[dbo].[DBFile] ([DBFileName],[DBName],[ServerName],[DriveName],[CreateDate],[LastActiveDate],[DBFileGroup],[FileSizeKB],[SpaceUsedKB],[FileType],[RecordedDateTime]) VALUES('"+$log.FileName+"','"+$sqlDatabase.name+"','"+$server+"','"+$log.FileName.Substring(0,1)+"','"+$insdate+"','"+$insdate+"','NA',"+$log.Size/1KB+","+$log.UsedSpace/1KB+",'log','"+$insdate+"')"
						$rcmd.executenonquery() | Out-Null;
					}
					
					$database = $objServer.databases[$sqldatabase.name]
					foreach ($g in $database.get_Filegroups()) { 
						foreach ($fn in $g.Files) {
							$rcmd.commandtext="";
							$rcmd.commandtext =  "INSERT INTO ["+$rdatabase+"].[dbo].[DBFile] ([DBFileName],[DBName],[ServerName],[DriveName],[CreateDate],[LastActiveDate],[DBFileGroup],[FileSizeKB],[SpaceUsedKB],[FileType],[RecordedDateTime]) VALUES('"+$fn.FileName+"','"+$sqlDatabase.name+"','"+$server+"','"+$fn.FileName.Substring(0,1)+"','"+$insdate+"','"+$insdate+"','"+$g.name+"',"+$fn.Size/1KB+","+$fn.UsedSpace/1KB+",'data','"+$insdate+"')"
							$rcmd.executenonquery()  | Out-Null;
						}
					} 
				}
				catch {}
			}		
			$objServer = $null
		}
    }
    end {
    }
Export-ModuleMember -Function Get-Database-Information
}
