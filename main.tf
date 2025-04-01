
resource "azurerm_resource_group" "rg_hub" {
  name     = "${var.rsc_prefix}-hub"
  location = var.rsc_location
}

resource "azurerm_virtual_network" "vnet_hub" {
  name                = "${var.rsc_prefix}-vnet-hub"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
  address_space       = [var.vnet_address_space]
}

resource "azurerm_subnet" "subnet_hub_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 10, 0)]
}

resource "azurerm_subnet" "subnet_hub_jumpbox" {
  name                 = "subnet-jumpbox"
  resource_group_name  = azurerm_resource_group.rg_hub.name
  virtual_network_name = azurerm_virtual_network.vnet_hub.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 10, 1)]
}

resource "azurerm_public_ip" "ergw_pip" {
  name                = "${var.rsc_prefix}-ergw-pip"
  resource_group_name = azurerm_resource_group.rg_hub.name
  location            = azurerm_resource_group.rg_hub.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "ergw" {
  name                        = "${var.rsc_prefix}-ergw"
  location                    = azurerm_resource_group.rg_hub.location
  resource_group_name         = azurerm_resource_group.rg_hub.name
  type                        = "ExpressRoute"
  sku                         = "Standard"
  remote_vnet_traffic_enabled = true
  ip_configuration {
    name                 = "GatewayIpConfig"
    public_ip_address_id = azurerm_public_ip.ergw_pip.id
    subnet_id            = azurerm_subnet.subnet_hub_gateway.id
  }
}

resource "azurerm_virtual_network_gateway_connection" "ercct_cnt" {
  name                       = "${var.rsc_prefix}-ercct-cnt"
  location                   = azurerm_resource_group.rg_hub.location
  resource_group_name        = azurerm_resource_group.rg_hub.name
  type                       = "ExpressRoute"
  express_route_circuit_id   = var.cnt_info.ercct_id
  virtual_network_gateway_id = azurerm_virtual_network_gateway.ergw.id
  authorization_key          = var.cnt_info.cnt_key
}

resource "azurerm_network_security_group" "nsg_hub" {
  name                = "${var.rsc_prefix}-nsg-hub"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_hub_jumpbox" {
  network_security_group_id = azurerm_network_security_group.nsg_hub.id
  subnet_id                 = azurerm_subnet.subnet_hub_jumpbox.id
}

resource "azurerm_network_interface" "nic_jumpbox" {
  name                = "${var.rsc_prefix}-jumpbox-nic"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_hub_jumpbox.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "jumpbox_linux" {
  name                  = "${var.rsc_prefix}-jumpbox-linux"
  location              = azurerm_resource_group.rg_hub.location
  resource_group_name   = azurerm_resource_group.rg_hub.name
  network_interface_ids = [azurerm_network_interface.nic_jumpbox.id]
  size                  = "Standard_D2s_v5"

  admin_username = var.admin_info.user_name
  admin_password = var.admin_info.password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  disable_password_authentication = false
}

resource "azurerm_bastion_host" "bastion_dev" {
  name                = "${var.rsc_prefix}-bastion-dev"
  location            = azurerm_resource_group.rg_hub.location
  resource_group_name = azurerm_resource_group.rg_hub.name
  sku                 = "Developer"
  virtual_network_id  = azurerm_virtual_network.vnet_hub.id
}
