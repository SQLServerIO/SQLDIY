####################### 
function Get-Type 
{ 
    param($type) 
 
$types = @( 
'System.Boolean', 
'System.Byte[]', 
'System.Byte', 
'System.Char', 
'System.Datetime', 
'System.Decimal', 
'System.Double', 
'System.Guid', 
'System.Int16', 
'System.Int32', 
'System.Int64', 
'System.Single', 
'System.UInt16', 
'System.UInt32', 
'System.UInt64') 
 
    if ( $types -contains $type ) { 
        Write-Output "$type" 
    } 
    else { 
        Write-Output 'System.String' 
         
    } 
} #Get-Type 
 
####################### 
<#
.SYNOPSIS
    Creates a DataTable for an object
.DESCRIPTION
Creates a DataTable based on an objects properties.
.INPUTS
Object
    Any object can be piped to Out-DataTable
.OUTPUTS
   System.Data.DataTable
.EXAMPLE
    $DT = Get-psdrive| Out-DataTable
    This example creates a DataTable from the properties of Get-psdrive and assigns output to $dt variable
.NOTES
    Adapted from script by Marc van Orsouw see link
    Version History
    v1.0  - Chad Miller - Initial Release
    v1.1  - Chad Miller - Fixed Issue with Properties
    v1.2  - Chad Miller - Added setting column datatype by property as suggested by emp0
    v1.3  - Chad Miller - Corrected issue with setting datatype on empty properties
    v1.4  - Chad Miller - Corrected issue with DBNull
    v1.5  - Chad Miller - Updated example
    v1.6  - Chad Miller - Added column datatype logic with default to string
    v1.7 - Chad Miller - Fixed issue with IsArray
    v1.8 - Dan Burgess - Fixed issue with $NULL values, requiring DBNull instead
.LINK
    GitHub:   https://github.com/SQLServerIO/SQLDIY/blob/master/CATSQLServerDataGathering/Out-DataTable.psm1
    No longer working:  http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx
#>
Function Out-DataTable
{
    [CmdletBinding()]
    param([Parameter(Position=0, Mandatory=$true, ValueFromPipeline = $true)] [PSObject[]]$InputObject)

    Begin
    {
        $DT = New-Object Data.datatable
        $First = $true
    }
    Process
    {
        Foreach ($object in $InputObject)
        {
            $DR = $DT.NewRow()
            Foreach($property in $object.PsObject.get_properties())
            {
                If ($first)
                {
                    $Col =  new-object Data.DataColumn
                    $Col.ColumnName = $property.Name.ToString()
                    If ($property.value)
                    {
                        If ($property.value -isnot [System.DBNull])
                        {
                            $Col.DataType = [System.Type]::GetType("$(Get-Type $property.TypeNameOfValue)")
                        }
                    }
                    $DT.Columns.Add($Col)
                }
                If ($property.Gettype().IsArray)
                {
                    $DR.Item($property.Name) = $property.value | ConvertTo-XML -AS String -NoTypeInformation -Depth 1
                }
               Else
               {
                    $DR.Item($property.Name) = If ($property.value){$property.value} else { [DBNull]::Value }
               }
            }
            $DT.Rows.Add($DR)
            $First = $false
        }
    }

    End
    {
        Write-Output @(,($DT))
    }

} #Out-DataTable
