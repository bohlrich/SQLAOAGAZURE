# Festlegen der Namen für die zu erstellenden Maschinen
$servers = @("sql01","sql02")


foreach($server in $servers)
{
    # Festlegen des Names für den ersten SQL Server Knoten
    $vmDNSName="$server"
    # Resourcegruppe aus dem 01_createEnvironment.ps1
    $rgName="TestSQLAGRG"
    $locName=(Get-AZResourceGroup -Name $rgName).Location
    Test-AZDnsAvailability -DomainQualifiedName $vmDNSName -Location $locName
    
    # Set up key variables
    $subscrName="Nutzungsbasierte Bezahlung"
    $vmDNSName="$server"
    # Set the Azure subscription
    Select-AzSubscription -SubscriptionName $subscrName
    # Get the Azure location and storage account names
    $locName=(Get-AZResourceGroup -Name $rgName).Location
    $saName=(Get-AZStorageaccount | Where {$_.ResourceGroupName -eq $rgName}).StorageAccountName
    # Create an availability set for SQL Server virtual machines
    New-AZAvailabilitySet -ResourceGroupName $rgName -Name sqlAvailabilitySet -Location $locName -Sku Aligned  -PlatformUpdateDomainCount 5 -PlatformFaultDomainCount 2
    # Specify the virtual machine name and size
    $vmName="$server"
    $vmSize="Standard_D3_v2"
    $vnet=Get-AZVirtualNetwork -Name "SQLSrvrVnet" -ResourceGroupName $rgName
    $avSet=Get-AZAvailabilitySet -Name sqlAvailabilitySet -ResourceGroupName $rgName
    $vm=New-AZVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $avSet.Id
    # Create the NIC for the virtual machine
    $nicName=$vmName + "-NIC"
    $pipName=$vmName + "-PublicIP"
    $pip=New-AZPublicIpAddress -Name $pipName -ResourceGroupName $rgName -DomainNameLabel $vmDNSName -Location $locName -AllocationMethod Dynamic
    $nic=New-AZNetworkInterface -Name $nicName -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -PrivateIpAddress "10.0.0.5"
    # Create and configure the virtual machine
    $cred=Get-Credential -Message "Type the name and password of the local administrator account for sqlVM."
    $vm=Set-AZVMOSDisk -VM $vm -Name ($vmName +"-OS") -DiskSizeInGB 128 -CreateOption FromImage -StorageAccountType "Standard_LRS"
    $vm=Set-AZVMOperatingSystem -VM $vm -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
    $vm=Set-AZVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2019-Datacenter -Version "latest"
    $vm=Add-AZVMNetworkInterface -VM $vm -Id $nic.Id
    New-AZVM -ResourceGroupName $rgName -Location $locName -VM $vm
}