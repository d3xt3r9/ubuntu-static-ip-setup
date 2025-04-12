#!/bin/bash
# =============================================================================
# Ubuntu Static IP Setup Script
# 
# This script configures a static IP address on Ubuntu/Debian systems
# that use Netplan for network configuration. It includes:
#   - Detection of the primary network interface
#   - Setting static IP, gateway, and DNS servers
#   - Optional hostname configuration
#   - Optional IPv6 disabling
#   - Handling of cloud-init network conflicts
# 
# Author: Athanasios Zannias
# Version: 1.1
# =============================================================================


# Exit on any error
set -e

# Default configuration values
DEFAULT_STATIC_IP="192.168.1.200/24"
DEFAULT_GATEWAY="192.168.1.1"
DEFAULT_DNS_SERVERS="8.8.8.8,8.8.4.4"

# Basic IP validation function
validate_ip() {
  if [[ ! $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(\/[0-9]+)?$ ]]; then
    echo "Invalid IP format: $1"
    return 1
  fi
  return 0
}

# Detect primary network interface
PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' 2>/dev/null || echo "eth0")
read -p "Enter network interface name (default: $PRIMARY_INTERFACE): " INTERFACE
INTERFACE="${INTERFACE:-$PRIMARY_INTERFACE}"
echo "Using network interface: $INTERFACE"

# Prompt the user for the static IP address
read -p "Enter the static IP address with subnet mask (default: $DEFAULT_STATIC_IP): " STATIC_IP
STATIC_IP="${STATIC_IP:-$DEFAULT_STATIC_IP}"
if ! validate_ip "$STATIC_IP"; then
  echo "Invalid IP format. Using default instead: $DEFAULT_STATIC_IP"
  STATIC_IP="$DEFAULT_STATIC_IP"
fi

# Prompt the user for the gateway
read -p "Enter the gateway IP address (default: $DEFAULT_GATEWAY): " GATEWAY
GATEWAY="${GATEWAY:-$DEFAULT_GATEWAY}"
if ! validate_ip "$GATEWAY"; then
  echo "Invalid gateway format. Using default instead: $DEFAULT_GATEWAY"
  GATEWAY="$DEFAULT_GATEWAY"
fi

# Prompt the user for the DNS servers
read -p "Enter DNS servers, comma-separated (default: $DEFAULT_DNS_SERVERS): " DNS_SERVERS
DNS_SERVERS="${DNS_SERVERS:-$DEFAULT_DNS_SERVERS}"

# Path to the Netplan configuration file
NETPLAN_CONFIG="/etc/netplan/01-netcfg.yaml"
CLOUD_INIT_CFG="/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
CLOUD_INIT_NETPLAN="/etc/netplan/50-cloud-init.yaml"
IPv6_CONFIG_FILE="/etc/sysctl.d/99-disable-ipv6.conf"

# Optional: Set hostname
read -p "Enter hostname (leave blank to skip): " HOSTNAME
if [ -n "$HOSTNAME" ]; then
    sudo hostnamectl set-hostname "$HOSTNAME"
    # Check if entry already exists before adding
    if ! grep -q "127.0.0.1 $HOSTNAME" /etc/hosts; then
        echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
        echo "Hostname set to $HOSTNAME and added to /etc/hosts."
    else
        echo "Hostname set to $HOSTNAME. Entry already exists in /etc/hosts."
    fi
fi

# Disable cloud-init network configuration
echo "network: {config: disabled}" | sudo tee "$CLOUD_INIT_CFG" > /dev/null
echo "Disabled cloud-init network configuration."

# Make IPv6 disabling optional
read -p "Disable IPv6? (y/N): " DISABLE_IPV6
if [[ "$DISABLE_IPV6" =~ ^[Yy]$ ]]; then
    if [ -f "$IPv6_CONFIG_FILE" ]; then
        echo "IPv6 disable configuration file already exists at $IPv6_CONFIG_FILE"
    else
        # Create the configuration file with IPv6 disable settings
        echo "Creating IPv6 disable configuration file at $IPv6_CONFIG_FILE"

        # Add IPv6 disable settings
        sudo tee "$IPv6_CONFIG_FILE" > /dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

        echo "IPv6 disable configuration added to $IPv6_CONFIG_FILE"

        # Apply the changes
        sudo sysctl --system
        echo "Applied IPv6 disable settings."
    fi
else
    echo "IPv6 will remain enabled."
fi

# Backup existing Netplan configuration if it exists
if [ -f "$NETPLAN_CONFIG" ]; then
    sudo cp "$NETPLAN_CONFIG" "${NETPLAN_CONFIG}.bak_$(date +%F_%T)"
    echo "Backup of the original Netplan config created at ${NETPLAN_CONFIG}.bak_$(date +%F_%T)"
fi

# Create or overwrite Netplan configuration for static IP
sudo tee "$NETPLAN_CONFIG" > /dev/null <<EOF
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      dhcp6: no
      accept-ra: no
      link-local: []
      addresses:
        - $STATIC_IP
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
          addresses: [${DNS_SERVERS}]
EOF

# Set appropriate permissions for the Netplan file
sudo chmod 600 "$NETPLAN_CONFIG"
sudo chown root:root "$NETPLAN_CONFIG"
echo "Set permissions for Netplan configuration to 600."

# Disable cloud-init network configuration if cloud-init is present
if [ -d "/etc/cloud" ]; then
    # Make sure the cloud.cfg.d directory exists
    sudo mkdir -p /etc/cloud/cloud.cfg.d/
    
    # Create the config file
    echo "network: {config: disabled}" | sudo tee "$CLOUD_INIT_CFG" > /dev/null
    echo "Disabled cloud-init network configuration."
else
    echo "Cloud-init not detected on this system, skipping cloud-init configuration."
fi

echo "Netplan configuration updated with static IP: $STATIC_IP and gateway via $GATEWAY."

# Apply the Netplan configuration
sudo netplan apply
echo "Netplan configuration applied successfully."

# Optional: Reboot prompt to finalize hostname changes
read -p "Reboot required to apply hostname changes. Reboot now? (y/n): " REBOOT_CHOICE
if [[ "$REBOOT_CHOICE" =~ ^[Yy]$ ]]; then
    sudo reboot
else
    echo "Reboot skipped. Please reboot manually to complete the setup."
fi