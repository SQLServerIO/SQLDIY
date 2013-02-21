#---------------------------------------------------------------
# This script will execute a sql command and returns a formatted
# table of the result.  The first parm can either be a query string 
# or a path to a file that contains the query.
#
#---------------------------------------------------------------
param(
    [string]$serverfilelist, #Optional text file with a list of server names
	[string]$sqlFile,# = $(Throw "SQL command (or the full path/Filename to a .sql file) is required!"),
	[string]$server,   #Optional parm to specify the server.  Otherwise local is used.
	[string]$database, #Optional parm to specify the database to use in the connection
	[string]$userName, #Optional parm to specify the UserName/Password for the connection
	[string]$password, #Optional parm to specify the UserName/Password for the connection
    [string]$rserver,  #Optional parm to specifiy the repository server. Otherwise local is used.
    [string]$rdatabase #Optional parm to specify the repository database to use in the connection. Otherwise Management is used.
	)

#---------------------------------------------------------------
# Determine if a sql command is given or the path to a file.
#
$table = "";
$sqlFile = "C:\projects\source\opensource\SQLDIY\Management.GatherServernameps.sql"
$server = "WARMACHINE";
$database = "master";
$rdatabase = "SQLDIY";
#$userName, #Optional parm to specify the UserName/Password for the connection
#$password  #Optional parm to specify the UserName/Password for the connection

$command = $sqlFile.Trim();
if (Test-Path $command -pathType leaf)
{
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
if (!$conn)
{
	Throw "SqlConnection could not be created!";
	return;
}
$File = "C:\projects\source\opensource\SQLDIY\NetworkMachines.txt"
Get-Content $File | foreach-Object {
    $server = $_;
    #---------------------------------------------------------------
    # Default the server to local if one was not provided
    #
    if (!$server)
    {
	    $server = "(local)";
    }
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

    $conn.Open();
    $rconn.Open();
    #if ($conn.State -eq 1)
    #{
    #    Write-Host 'conn open';
    #}
    if ($conn.State -eq 1)
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
                         $rcmd.commandtext = "INSERT INTO "+$rdatabase+".dbo.ServerList (QueriedServer,ReturnedServer,Version) VALUES('"+$server+"','"+$row.ItemArray.GetValue(0)+"','"+$row.ItemArray.GetValue(1)+"')"
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
	    Write-Host "Connection could not be opened!";
    }
    $conn.Dispose();
    $rconn.Dispose();
}