# Ubuntu Static IP Setup

A Bash script to configure static IPv4 addresses on Ubuntu/Debian systems using Netplan, with options to disable IPv6 and set hostnames.

## Features

- Automatically detects the primary network interface
- Prompts for static IP address, gateway, and DNS servers with validation
- Provides sensible defaults for network settings
- Option to set the system hostname
- Disables cloud-init network configuration to prevent conflicts
- Optional IPv6 disabling (user's choice)
- Creates backups of existing network configurations
- Sets proper file permissions on created configuration files
- Automatically applies the Netplan configuration
- Offers reboot option to complete the setup

## Requirements

- Ubuntu/Debian-based system using Netplan for network configuration
- Root privileges (sudo)

## Usage

1. Clone the repository:

```bash
git clone https://github.com/d3xt3r9/ubuntu-static-ip-setup.git
cd ubuntu-static-ip-setup
```

2. Make the script executable:

```bash
chmod +x setup_network.sh
```

3. Run the script with sudo:

```bash
sudo ./setup_network.sh
```

4. Follow the prompts to configure your network settings:
   - Network interface (default is automatically detected)
   - Static IP address with subnet mask (default: 192.168.1.200/24)
   - Gateway IP address (default: 192.168.1.1)
   - DNS servers, comma-separated (default: 8.8.8.8,8.8.4.4)
   - Hostname (optional)
   - IPv6 disabling (optional)
   - System reboot option after configuration

## What Happens

The script will:

1. Create or update the Netplan configuration at `/etc/netplan/01-netcfg.yaml`
2. Back up any existing configuration file before modifying it
3. Disable cloud-init network configuration if present
4. Optionally create an IPv6 disabling configuration at `/etc/sysctl.d/99-disable-ipv6.conf`
5. Apply the new network configuration
6. Optionally reboot to complete all changes

## Author

Athanasios Zannias - Version 1.1
