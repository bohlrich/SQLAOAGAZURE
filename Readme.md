# Create SQL Server Availability Test Environment in Azure

## Links

[Exchange dev/test environments in Azure](https://docs.microsoft.com/en-us/exchange/plan-and-deploy/deploy-new-installations/create-azure-test-environments?view=exchserver-2019)

[Tutorial: Manually configure an availability group](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/availability-group-manually-configure-tutorial-single-subnet)

## Requirements

### Create Azure Account

[Create Free Azure Account](https://azure.microsoft.com/de-de/free/)

### Install Azure Az Powershell Module

[Install the Azure Az PowerShell module](https://docs.microsoft.com/de-de/powershell/azure/install-az-ps?view=azps-7.0.0)

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

## How to

### Clone this repository

```powershell
git clone https://github.com/bohlrich/SQLAOAGAZURE.git
```

### Connect to your Azure Account

```powershell
Connect-AzAccount
```

### Set your Variables in Powershell Scripts

Set $subscrName, $rgName, $locName and $saName in 01 and 03

### Execute the first Script

```powershell
.\01_createEnvironment.ps1
```

### Connect to the adVM and Execute the second Script there

- Connect with mstsc to the Azure Virtual Machine with the given Account
- Open PowerShell
- Execute the contents of 02_createActiveDirectory.ps1
- Restart Machine

### Execute the third Script

```powershell
.\03_createSQLMachines.ps1
```
