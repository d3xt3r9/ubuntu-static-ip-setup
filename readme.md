# Ubuntu Static IP Setup

A Bash script to configure a static IPv4 address using Netplan and disable IPv6 on Ubuntu Server.

## Features

- Prompts for static IP address, gateway, and DNS servers.
- Option to set the hostname.
- Disables cloud-init network configuration.
- Creates a configuration file to disable IPv6.
- Applies the Netplan configuration.

## Usage

1. Clone the repository:

```bash
   git clone https://github.com/d3xt3r9/ubuntu-static-ip-setup.git
```

```bash
   cd ubuntu-static-ip-setup
```

2. Make the script executable:

```bash
chmod +x setup_network.sh
```

3. Run the script:

```bash
sudo ./setup_network.sh
```

4. Follow the prompts to configure your network settings.
