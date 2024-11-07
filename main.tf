provider "azurerm" {
  features {}
 
  subscription_id = "784262c0-253b-469e-96a9-def4349c9c23"
}

resource "azurerm_resource_group" "webapp_rg" {
  name     = "webapp-resource-group"
  location = "West us 2"
}

resource "azurerm_virtual_network" "webapp_vnet" {
  name                = "webapp-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "frontend-subnet"
  resource_group_name  = azurerm_resource_group.webapp_rg.name
  virtual_network_name = azurerm_virtual_network.webapp_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend_subnet" {
  name                 = "backend-subnet"
  resource_group_name  = azurerm_resource_group.webapp_rg.name
  virtual_network_name = azurerm_virtual_network.webapp_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "frontend-nsg"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-https"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name

  security_rule {
    name                       = "allow-internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# Front-end VM
resource "azurerm_network_interface" "frontend_nic" {
  name                = "frontend-nic"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name

  ip_configuration {
    name                          = "frontend-ip-config"
    subnet_id                     = azurerm_subnet.frontend_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend_public_ip.id
  }
}

resource "azurerm_public_ip" "frontend_public_ip" {
  name                = "frontend-public-ip"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  allocation_method   = "Static"  # Change this line from "Dynamic" to "Static"
  sku                  = "Standard"  # Specify Standard SKU for public IP
}


resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                = "frontend-vm"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  # استخدام المفتاح SSH بدلاً من كلمة المرور
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/Hossam/Documents/my_custom_key.pub")  # مسار المفتاح العام
  }

  # تعطيل المصادقة عبر كلمة المرور
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.frontend_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Back-end VM
resource "azurerm_network_interface" "backend_nic" {
  name                = "backend-nic"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name

  ip_configuration {
    name                          = "backend-ip-config"
    subnet_id                     = azurerm_subnet.backend_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                = "backend-vm"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  # استخدام المفتاح SSH بدلاً من كلمة المرور
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("C:/Users/Hossam/Documents/my_custom_key.pub")  # مسار المفتاح العام
  }

  # تعطيل المصادقة عبر كلمة المرور
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.backend_nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "webappstorageacctacccc"
  resource_group_name      = azurerm_resource_group.webapp_rg.name
  location                 = azurerm_resource_group.webapp_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

output "frontend_public_ip" {
  value = azurerm_public_ip.frontend_public_ip.ip_address
}
