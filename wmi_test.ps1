$runpath = $myinvocation.mycommand.path.substring(0,($myinvocation.mycommand.path.length - $MyInvocation.mycommand.name.length))
$lm1 = $runpath+"CATSQLServerDataGathering\Out-DataTable.psm1"
$lm2 = $runpath+"CATSQLServerDataGathering\Write-DataTable.psm1"
$lm3 = $runpath+"CATSQLServerDataGathering\Add-SqlTable.psm1"
$lm4 = $runpath+"CATSQLServerDataGathering\GetServerInformation.psm1"
$lm5 = $runpath+"CATSQLServerDataGathering\GetDatabaseInformation.psm1"
$lm6 = $runpath+"CATSQLServerDataGathering\QuerySQLListener.psm1"
$lm7 = $runpath+"CATSQLServerDataGathering\GetAgentDetails.psm1"
Import-Module $lm1
Import-Module $lm2
Import-Module $lm3
Import-Module $lm4
Import-Module $lm5
Import-Module $lm6
Import-Module $lm7


#$res = @()
#$res = QuerySQLListener "webserver"
#GetServerInformation "ironman" "warmachine" "SQLDIY"
#foreach($r in $res){$r}
#GetDatabaseInformation  "warmachine" "Management" $true
$rserver = "warmachine"
$rdatabase = "SQLDIY"
GetAgentDetails $rserver $rdatabase $rserver


