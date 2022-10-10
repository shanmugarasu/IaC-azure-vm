provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

resource "azurerm_resource_group" "adp" {
  name     = "adp-resources"
  location = "centralindia"
}

# Virtual Machine Resources

resource "azurerm_virtual_network" "adp" {
  name                = "adp-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.adp.location
  resource_group_name = azurerm_resource_group.adp.name
}

resource "azurerm_subnet" "adp" {
  name                 = "adp-subnet"
  resource_group_name  = azurerm_resource_group.adp.name
  virtual_network_name = azurerm_virtual_network.adp.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "adp" {
  name                = "adp-nic"
  location            = azurerm_resource_group.adp.location
  resource_group_name = azurerm_resource_group.adp.name

  ip_configuration {
    name                          = "adp-ip"
    subnet_id                     = azurerm_subnet.adp.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "adp" {
  name                = "adp-vm"
  resource_group_name = azurerm_resource_group.adp.name
  location            = azurerm_resource_group.adp.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.adp.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "adp" {
  name                       = "github_runner_1"
  virtual_machine_id         = azurerm_windows_virtual_machine.adp.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  auto_upgrade_minor_version = true
  type_handler_version       = "2.0.0"

  protectedSettings = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/shanmugarasu/coin-payment/master/src/scripts/github-runner-install.ps1"],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file github-runner-install.ps1"
    }
SETTINGS
}
