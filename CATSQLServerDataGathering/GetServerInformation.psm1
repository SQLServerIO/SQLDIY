<#
.SYNOPSIS
    Pulls details about target server via WMI
.DESCRIPTION
    A detailed description of the module.
#>

function GetServerInformation {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
		[string]$server,
		[Parameter(Position=1, Mandatory=$true)]
		[string]$rserver,
		[Parameter(Position=2, Mandatory=$true)]		
		[string]$rdatabase
    )
    begin {
        $ErrorActionPreference = "SilentlyContinue" 
        #if we are using posh 3.0 set the connection type back to DCOM
        $opt = New-CimSessionOption -Protocol DCOM 
        $sd = New-CimSession -ComputerName $server -SessionOption $opt
        #capture our instance id so we can tear it down later
        $cmsessionid = $sd.InstanceId
    }
    process {
        $dt = Get-CimInstance -CimSession $sd -Query "select * from Win32_LogicalDisk where DriveType = 3 or DriveType = 4" | select SystemName, DeviceID, VolumeName, @{n='Size';e={$([math]::round(($_.Size/1MB),2))}}, @{n='FreeSpace';e={$([math]::round(($_.FreeSpace/1MB),2))}}, Compressed, VolumeDirty,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        try{
            Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName LogicalDisk -DataTable $dt
        }
        catch{}
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "LogicalDisk" -Data $dt

        $dt = Get-CimInstance -CimSession $sd -Query "select * from Win32_ComputerSystem" | select Name, Model, Manufacturer, Description, DNSHostName, Domain, DomainRole, PartOfDomain, NumberOfProcessors, SystemType, TotalPhysicalMemory, UserName, Workgroup, @{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        try{
            Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName ComputerSystem -DataTable $dt
        }
        catch{}
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "ComputerSystem" -Data $dt
   
        $dt = Get-CimInstance -CimSession $sd -Query "select * from Win32_OperatingSystem" | select PSComputerName, Name, Version, FreePhysicalMemory, OSLanguage, OSProductSuite, OSType, ServicePackMajorVersion, ServicePackMinorVersion ,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        try{
            Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName OperatingSystem -DataTable $dt    
        }
        catch{}
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "OperatingSystem" -Data $dt

        $dt = Get-CimInstance -CimSession $sd -Query "select * from Win32_DiskDriveToDiskPartition" | select PSComputerName, Antecedent, Dependent, @{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        try{
            Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName DiskDriveToDiskPartition -DataTable $dt
        }
        catch{}
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "DiskDriveToDiskPartition" -Data $dt

        $dt = Get-CimInstance -CimSession $sd -Query "select * from Win32_DiskDrive" | select PSComputerName ,Index, BytesPerSector, Name, @{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable #PSComputerName, ConfigManagerErrorCode,LastErrorCode,Status,DeviceID,StatusInfo,Partitions,BytesPerSector,ConfigManagerUserConfig,InterfaceType,Size,CapabilityDescriptions,CompressionMethod,ErrorCleared,ErrorDescription,ErrorMethodology,MediaType,Model,Site,Container
        try{
            Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName DiskDrive -DataTable $dt    
        }
        catch{}
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "DiskDrive" -Data $dt

        $dt = Get-CimInstance -CimSession $sd -Query "select * from Win32_DiskPartition" | select PSComputerName ,Index, BlockSize, StartingOffset, Name, @{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        try{
            Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName DiskPartition -DataTable $dt    
        }
        catch{}
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "DiskPartition" -Data $dt
    }
    end {
        Remove-CimSession -InstanceId $cmsessionid
        $opt.Dispose()
        $sd.Dispose()
    }
}
Export-ModuleMember -Function GetServerInformation
