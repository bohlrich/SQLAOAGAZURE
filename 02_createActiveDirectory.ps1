# Zusätzliche Disk für die AD Ressourcen hinzufügen
$disk=Get-Disk | where {$_.PartitionStyle -eq "RAW"}
$diskNumber=$disk.Number
Initialize-Disk -Number $diskNumber
New-Partition -DiskNumber $diskNumber -UseMaximumSize -AssignDriveLetter
Format-Volume -DriveLetter F

# Windows Feature installieren und Domain erstellen
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName testsqlag.local -DatabasePath "F:\NTDS" -SysvolPath "F:\SYSVOL" -LogPath "F:\Logs"

# Nach dem erfolgtem Neustart noch die Tools installieren
Add-WindowsFeature RSAT-ADDS-Tools