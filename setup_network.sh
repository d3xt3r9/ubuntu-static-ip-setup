#!/bin/bash

# Exit on any error
set -e

# Default configuration values
DEFAULT_STATIC_IP="192.168.1.200/24"
DEFAULT_GATEWAY="192.168.1.1"
DEFAULT_DNS_SERVERS="8.8.8.8,8.8.4.4"

# Prompt the user for the static IP address
read -p "Enter the static IP address with subnet mask (default: $DEFAULT_STATIC_IP): " STATIC_IP
STATIC_IP="${STATIC_IP:-$DEFAULT_STATIC_IP}"

# Prompt the user for the gateway
read -p "Enter the gateway IP address (default: $DEFAULT_GATEWAY): " GATEWAY
GATEWAY="${GATEWAY:-$DEFAULT_GATEWAY}"

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
    echo "127.0.0.1 $HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
    echo "Hostname set to $HOSTNAME and added to /etc/hosts."
fi

# Disable cloud-init network configuration
echo "network: {config: disabled}" | sudo tee "$CLOUD_INIT_CFG" > /dev/null
echo "Disabled cloud-init network configuration."

# Disable IPv6 system-wide by adding settings to sysctl.conf
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
    eth0:
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
echo "Set permissions for Netplan configuration to 644."

# Delete any existing cloud-init network file to prevent conflicts
if [ -f "$CLOUD_INIT_NETPLAN" ]; then
    sudo rm "$CLOUD_INIT_NETPLAN"
    echo "Removed conflicting cloud-init Netplan file: $CLOUD_INIT_NETPLAN"
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