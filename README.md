# Icinga2 Interactive Installation Script

This script provides an automated way to install and configure Icinga2 with optional components including:
- Icinga Web UI
- Icinga Director
- Grafana

## Features

- Interactive installation process
- Automatic dependency installation
- Support for proxy environments
- Automatic password generation
- Optional FQDN or IP-based setup
- Secure credential storage
- Preconfigured components integration

## Prerequisites

- Debian-based Linux distribution (Debian/Ubuntu)
- Root access
- Internet connection

## Usage

1. Make the script executable:
```bash
chmod +x install_icinga2.sh
```

2. Run the script as root:
```bash
sudo ./install_icinga2.sh
```

3. Follow the interactive prompts to configure your installation:
   - Enter FQDN (optional)
   - Configure proxy settings (if needed)
   - Choose components to install
   - The script will handle the rest

## Post-Installation

- All credentials are saved in `icinga2_credentials.txt`
- Access URLs will be displayed at the end of installation
- For security, make sure to change the default passwords after first login

## Components

### Icinga2 Core
- Monitoring engine
- Command and notification features enabled

### Icinga Web UI (Optional)
- Web interface for Icinga2
- IDO MySQL backend
- Automated configuration

### Icinga Director (Optional)
- Configuration management tool
- Automated API user setup
- Database configuration

### Grafana (Optional)
- Visualization platform
- Automated installation and basic setup
- Preconfigured admin password

## Security Notes

- All generated passwords are random and secure
- Credentials file is created with restricted permissions (600)
- Database users are created with limited privileges
- API users are configured with appropriate permissions

## Troubleshooting

If you encounter any issues:
1. Check the credentials file exists and is readable
2. Verify all services are running: `systemctl status icinga2`
3. Check logs: `journalctl -u icinga2`
4. Ensure all ports are accessible (80/443 for web, 3000 for Grafana)
