# Azure Account verbinden
# Connect-AzAccount

# Abo anzeigen
# Get-AZSubscription | Sort-Object Name | Select-Object Name

# Subscription festlegen
$subscrName="Nutzungsbasierte Bezahlung"
Select-AzSubscription -SubscriptionName $subscrName

# Resourcegroup erstellen
# Locations lassen sich so anzeigen
# Get-AzLocation | Select-Object Location
$rgName="TestSQLAGRG"
$locName="germanywestcentral"
New-AZResourceGroup -Name $rgName -Location $locName

# Neuen Storage Account erstellen
$saName="TestSQLAGSA"
New-AZStorageAccount -Name $saName -ResourceGroupName $rgName -Type Standard_LRS -Location $locName

# Neues Netzwerk für die Testumgebung erstellen
$testSubnet=New-AZVirtualNetworkSubnetConfig -Name SQLSrvrSubnet -AddressPrefix 10.0.0.0/24
New-AZVirtualNetwork -Name SQLSrvrVnet -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $testSubnet -DNSServer 10.0.0.4
$rule1 = New-AZNetworkSecurityRuleConfig -Name "RDPTraffic" -Description "Allow RDP to all VMs on the subnet" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
New-AZNetworkSecurityGroup -Name SQLSrvrSubnet -ResourceGroupName $rgName -Location $locName -SecurityRules $rule1
$vnet=Get-AZVirtualNetwork -ResourceGroupName $rgName -Name SQLSrvrVnet
$nsg=Get-AZNetworkSecurityGroup -Name SQLSrvrSubnet -ResourceGroupName $rgName
Set-AZVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name SQLSrvrSubnet -AddressPrefix "10.0.0.0/24" -NetworkSecurityGroup $nsg
$vnet | Set-AzVirtualNetwork

# Active Directory Windows Server erstellen
# Create an availability set for domain controller virtual machines
New-AZAvailabilitySet -ResourceGroupName $rgName -Name dcAvailabilitySet -Location $locName -Sku Aligned -PlatformUpdateDomainCount 5 -PlatformFaultDomainCount 2
# Create the domain controller virtual machine
$vnet=Get-AZVirtualNetwork -Name SQLSrvrVnet -ResourceGroupName $rgName
$pip = New-AZPublicIpAddress -Name adVM-NIC -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
$nic = New-AZNetworkInterface -Name adVM-NIC -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress 10.0.0.4
$avSet=Get-AZAvailabilitySet -Name dcAvailabilitySet -ResourceGroupName $rgName
$vm=New-AZVMConfig -VMName adVM -VMSize Standard_D1_v2 -AvailabilitySetId $avSet.Id
$vm=Set-AZVMOSDisk -VM $vm -Name adVM-OS -DiskSizeInGB 128 -CreateOption FromImage -StorageAccountType "Standard_LRS"
$diskConfig=New-AZDiskConfig -AccountType "Standard_LRS" -Location $locName -CreateOption Empty -DiskSizeGB 20
$dataDisk1=New-AZDisk -DiskName adVM-DataDisk1 -Disk $diskConfig -ResourceGroupName $rgName
$vm=Add-AZVMDataDisk -VM $vm -Name adVM-DataDisk1 -CreateOption Attach -ManagedDiskId $dataDisk1.Id -Lun 1
$cred=Get-Credential -Message "Type the name and password of the local administrator account for adVM."
$vm=Set-AZVMOperatingSystem -VM $vm -Windows -ComputerName adVM -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vm=Set-AZVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
$vm=Add-AZVMNetworkInterface -VM $vm -Id $nic.Id
New-AZVM -ResourceGroupName $rgName -Location $locName -VM $vm

# Jetzt sollte auf dem neuen Windows Server zunächst die Rolle für den Domain Controller installiert werden und anschließend dcpromo ausgeführt werden
# -> Dazu kann das Skript createActiveDirectory.ps1 benutzt werden

