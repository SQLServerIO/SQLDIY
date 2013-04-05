<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

Import-Module C:\projects\source\OpenSource\SQLDIY\CATSQLServerDataGathering\GetDatabaseInformation.psm1
Import-Module C:\projects\source\OpenSource\SQLDIY\CATSQLServerDataGathering\QuerySQLListener.psm1
$res = @()
$res = QuerySQLListener "webserver"
foreach($r in $res){$r}
GetDatabaseInformation  "warmachine" "Management" $true
