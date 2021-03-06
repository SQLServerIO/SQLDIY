$mInfo = $MyInvocation.MyCommand.ScriptBlock.Module
$mInfo.OnRemove = {
     if ($Script:oracle_conn.state -eq 'open')
     {
        Write-Host -BackgroundColor Black -ForegroundColor Yellow "Connection $($Script:oracle_conn.database) closed"
        $Script:oracle_conn.Close()
     }
    Write-Host -BackgroundColor Black -ForegroundColor Yellow "$($MyInvocation.MyCommand.ScriptBlock.Module.name) removed on $(Get-Date)"
    Remove-IseMenu OracleIse
}

# Write-Host "$($MyInvocation.MyCommand.ScriptBlock.Module.name) imported on $(Get-Date)"

import-module ISECreamBasic
import-module OracleClient
import-module WPK

. $psScriptRoot\Get-ConnectionInfo.ps1
. $psScriptRoot\Set-Options.ps1
. $psScriptRoot\Switch-CommentOrText.ps1
. $psScriptRoot\Switch-SelectedCommentOrText.ps1
. $psScriptRoot\ConvertTo-StringData.ps1
. $psScriptRoot\Library-UserStore.ps1
. $psScriptRoot\ConvertFrom-Xml.ps1

Set-Alias Expand-String $psScriptRoot\Expand-String.ps1

$Script:oracle_conn=new-object Oracle.DataAccess.Client.OracleConnection

#Load saved options into hashtable
Initialize-UserStore  -fileName "options.txt" -dirName "OracleIse" -defaultFile "$psScriptRoot\defaultopts.ps1"
$oracle_options = Read-UserStore -fileName "options.txt" -dirName "OracleIse" -typeName "Hashtable"

#$Script:DatabaseList = New-Object System.Collections.ArrayList

$bitmap = new-object System.Windows.Media.Imaging.BitmapImage
$bitmap.BeginInit()
$bitmap.UriSource = "$psScriptRoot\SQLPSX.PNG"
$bitmap.EndInit()


#######################
function Connect-Oracle
{
    param(
        $tns,
        $user,
        $password
    )
    if (! $tns)
    {
        $script:connInfo = Get-ConnectionInfo $bitmap
        if ($connInfo)
        { 
            $tns = $connInfo.tns
            $user = $connInfo.UserName
            $password = $connInfo.Password
        }
    }

    if ($tns -and $user -and $password)
    { 
        $Script:oracle_conn = new-oracle_connection -tns $tns -user $User -password $Password
#         if ($Script:oracle_conn.State -eq 'Open')
#         { invoke-oracle_query -sql:'sp_databases' -connection:$Script:oracle_conn | foreach { [void]$Script:DatabaseList.Add($_.DATABASE_NAME) } }
    }

} #Connect-Sql


#######################
function Disconnect-Oracle
{
    param()

    $Script:oracle_conn.Close()
    #$Script:DatabaseList.Clear()

} #Disconnect-Sql

#######################
if ((gmo SQLise))
{
    function Prompt
    {
        param()
        $basePrompt = $(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + $(Get-Location)
        $sqlPrompt = ' #[SQL]' + $(if ($Script:conn.State -eq 'Open') { $($Script:conn.DataSource) + '.' + $($Script:conn.Database) } else { '---'})
        $oraclePrompt = ' #[Oracle]' + $(if ($oracle_conn.State -eq 'Open') { $($oracle_conn.DataSource) } else { '---'})
        $basePrompt + $sqlPrompt + $oraclePrompt +$(if ($nestedpromptlevel -ge 1) { ' >>' }) + ' > '

    } #Prompt
}
else
{
    function Prompt
    {
        param()
        $basePrompt = $(if (test-path variable:/PSDebugContext) { '[DBG]: ' } else { '' }) + 'PS ' + $(Get-Location)
        $oraclePrompt = '#' + $(if ($Script:oracle_conn.State -eq 'Open') {'[CONNECTED][' + $($Script:oracle_conn.DataSource) + '.' + $($Script:oracle_conn.Database) + ']: '} else { '[DISCONNECTED]: '}) + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '> '
        $basePrompt + $oraclePrompt

    } #Prompt
}
#######################
function Get-FileName
{
    param($ext,$extDescription)
    $sfd = New-SaveFileDialog -AddExtension -DefaultExt "$ext" -Filter "$extDescription (.$ext)|*.$ext|All files(*.*)|*.*" -Title "Save Results" -InitialDirectory $pwd.path
    [void]$sfd.ShowDialog()
    return $sfd.FileName

} #Get-FileName

#######################
function Invoke-ExecuteOracle
{
    param(
        $inputScript,
        $displaymode = $null,
        $OutputVariable = $null
        )

    if ($inputScript -eq $null)
    {
        if (-not $psise.CurrentFile)
        {
            Write-Error 'You must have an open script file'
            return
        }
        
        $selectedRunspace = $psise.CurrentFile
        $selectedEditor=$selectedRunspace.Editor

        if (-not $selectedEditor.SelectedText)
        {
            $inputScript = $selectedEditor.Text 
        }
        else
        {
            $inputScript = $selectedEditor.SelectedText
        }
    }
    
    if ($oracle_conn.State -eq 'Closed')
    { Connect-Oracle }
    
    if ($displaymode -eq $null)
    {
        $displaymode = $env:SQLPsx_QueryOutputformat
        # Write-Host "Set `$env:SQLPsx_QueryOutputformat to $displaymode"
        [Environment]::SetEnvironmentVariable("SQLPsx_QueryOutputformat", $displaymode, "User")

        if ($displaymode -eq $null)
        {
            $displaymode = 'auto' 
        } 
    }

    if ($options.PoshMode)
    {
        Invoke-PoshCode $inputScript
        $inputScript = Remove-PoshCode $inputScript
        $inputScript = Expand-String $inputScript
    }

    # Write-host "Using mode: $displaymode"   
    switch($displaymode)
    {
            'grid' {$res = invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn 
                     if ($res.Tables)
                     {
                            Write-host 'multi'
                        $res.tables | %{ $_ |  Out-GridView -Title $psise.CurrentFile.DisplayName}
                     }
                     else
                     {
                      $res |  Out-GridView -Title $psise.CurrentFile.DisplayName
                     }
                   }
            'auto'  {    $res = invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn
                         if ($res.Tables)
                         {
                            Write-host 'multi'
                            # This doesn#t work, only 1st Resultset displayed
                            $res.tables | %{ $_  | out-host}
                         }
                         else
                         {
                            $res
                         }
                   }
            'table' {$res = invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn
                     if ($res.Tables)
                     {
                            Write-host 'multi'
                        $res.tables | %{ $_ | ft -auto }
                     }
                     else
                     {
                      $res | ft -auto
                     }
                   }
            'list' {$res = invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn
                     if ($res.Tables)
                     {
                            Write-host 'multi'
                        $res.tables | %{ $_ | fl }
                     }
                     else
                     {
                      $res | fl
                     }
                   }
            
        'file' {
                    $filePath = Get-FileName 'txt' 'Text'
                    if ($filePath)
                    {invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn | Out-File -FilePath $filePath -Force
                     Write-Host ""}
                  }
        'csv' {
                  $filePath = Get-FileName 'csv' 'CSV'
                  if ($filePath)
                  {invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn | Export-Csv -Path $filepath -NoTypeInformation -Force
                   Write-Host ""}
                 }
        'variable' {
                        $OutputVariable = Read-Host 'Variable (no "$" needed)'
                        Set-Variable -Name $OutputVariable -Value (invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn) -Scope Global
                    }
        'isetab'   {
                     $res = invoke-oracle_query -sql $inputScript -connection $Script:oracle_conn 
                     $text = ($res | ft -auto | Out-string -width 10000 -stream ) -replace " *$", ""-replace "\.\.\.$", "" -join "`r`n" 
                     $count = $psise.CurrentPowerShellTab.Files.count
                     $psIse.CurrentPowerShellTab.Files.Add()
                     $Newfile = $psIse.CurrentPowerShellTab.Files[$count]
                     $Newfile.Editor.Text = $text

                }        
    }
        
} #Invoke-ExecuteSql

#######################
function Write-OracleOptions
{
    param()
    Write-UserStore -fileName "options.txt" -dirName "OracleIse" -object $oracle_options

} #Write-Options

#######################
# this does not apply to Oracle
# function Switch-Database
# {
#     param()
# 
#     $Action = {
#         $this.Parent.Tag = $this.SelectedItem
#         $window.Close() }
#                 
#     $database = New-ComboBox -Name Database -Width 200 -Height 20 {$DatabaseList} -SelectedItem $conn.Database -On_SelectionChanged $Action -Show
# 
#     if ($database)
#     { $Script:oracle_conn.ChangeDatabase($database) } 
# 
# } #Switch-Database

#######################
function Edit-Uppercase
{
    param()
    if (-not $psise.CurrentFile)
    {
        Write-Error 'You must have an open script file'
        return
    }
    
    $selectedRunspace = $psise.CurrentFile
    $selectedEditor=$selectedRunspace.Editor

    if (-not $selectedEditor.SelectedText)
    {
        $output = $($selectedEditor.Text).ToUpper()
        if ($output)
        { $selectedEditor.Text = $output }

    }
    else
    {
        $output = $($selectedEditor.SelectedText).ToUpper()
        if ($output)
        { $selectedEditor.InsertText($output) }

    }

} #Edit-Uppercase

#######################
function Edit-Lowercase
{
    param()
    if (-not $psise.CurrentFile)
    {
        Write-Error 'You must have an open script file'
        return
    }
    
    $selectedRunspace = $psise.CurrentFile
    $selectedEditor=$selectedRunspace.Editor

    if (-not $selectedEditor.SelectedText)
    {
        $output = $($selectedEditor.Text).ToLower()
        if ($output)
        { $selectedEditor.Text = $output }

    }
    else
    {
        $output = $($selectedEditor.SelectedText).ToLower()
        if ($output)
        { $selectedEditor.InsertText($output) }

    }

} #Edit-Lowercase

#######################
function Set-PoshVariable
{
    param($name,$value)

    Set-Variable -Name $name -Value $value -Scope Global

} #Set-PoshVariable

#######################
function Invoke-PoshCode
{
    param($text)

    foreach ( $line in $text -split [System.Environment]::NewLine )
    {
        if ( $line.length -gt 0) {
            if ( $line -match "^\s*!!" ) {
                $line = $line -replace "^\s*!!", ""
                invoke-expression $line
            }
        }
    }

} #Invoke-PoshCode

#######################
function Remove-PoshCode
{
    param($text)

    $returnedText = ""
    foreach ( $line in $text -split [System.Environment]::NewLine )
    {
        if ( $line.length -gt 0) {
            if ( $line -notmatch "^\s*!!" ) {
                $returnText += "{0}{1}" -f $line,[System.Environment]::NewLine
            }
        }
    }
    $returnText

} #Remove-PoshCode


#######################
function Set-Outputformat
{   
    New-StackPanel {            
        New-RadioButton -Content "auto"     -GroupName Results -IsChecked $("auto" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "auto" }            
        New-RadioButton -Content "list"     -GroupName Results -IsChecked $("list" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "list" }            
        New-RadioButton -Content "table"    -GroupName Results -IsChecked $("table" -eq $env:SQLPsx_QueryOutputformat) -On_Click { $env:SQLPsx_QueryOutputformat = "table" }
        New-RadioButton -Content "grid"     -GroupName Results -IsChecked $("grid" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "grid" }
        New-RadioButton -Content "variable" -GroupName Results -IsChecked $("variable" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "variable" }
        New-RadioButton -Content "csv"      -GroupName Results -IsChecked $("csv" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "csv" }
        New-RadioButton -Content "file"     -GroupName Results -IsChecked $("file" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "file" }
        New-RadioButton -Content "isetab"   -GroupName Results -IsChecked $("isetab" -eq $env:SQLPsx_QueryOutputformat)  -On_Click { $env:SQLPsx_QueryOutputformat = "isetab" }
        # New-label ($env:SQLPsx_QueryOutputformat) ## Never try Write-Host when running as job
                    
    } -asjob           
}           
#######################
Add-IseMenu -name OracleIse @{
    "Connection" =@{
                    "Connect..." = {Connect-Oracle}
                    "Disconnect" = {Disconnect-Oracle}
    }
    "Execute" = {Invoke-ExecuteOracle} | Add-Member NoteProperty ShortcutKey "Alt+F7" -PassThru
    #"Change Database..." = {Switch-Database}
    "Options..." = {Set-OracleOptions; Write-OracleOptions}
    "Edit" =@{
                    "Make Uppercase         CTRL+SHIFT+U" = {Edit-Uppercase}
                    "Make Lowercase         CTRL+U" = {Edit-Lowercase}
                    "Toggle Comments" = {Switch-SelectedCommentOrText} | Add-Member NoteProperty ShortcutKey "CTRL+ALT+K" -PassThru
            }
    "Output Format..." = {Set-Outputformat}
} 

Export-ModuleMember -function * -Variable oracle_options, bitmap, oracle_conn #, DatabaseList
