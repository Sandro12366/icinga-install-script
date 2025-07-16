# Icinga2 installation script
# ===========================
# This script installs and configures Icinga2, WebUI, Director, IcingaDB, Redis, Grafana, distributed polling (satellites/agents), and optionally nginx SSL proxy. It supports multiple Linux distributions and is fully automated.

## Usage

After pushing to your public GitHub repo, run the script on your server as root:

```sh
bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/install_icinga2.sh)
```

## Features
- Automatic OS detection (Debian, Ubuntu, RHEL, CentOS, Rocky, AlmaLinux)
- Dependency and repository management per distribution
- Interactive selection (FQDN, proxy, WebUI, Director, nginx, distributed polling)
- Automatic password generation and secure storage in `icinga2_credentials.txt`
- Installs and configures Icinga2, WebUI, Director, IcingaDB, Redis, Grafana
- Activates and configures all features (including IcingaDB, Redis, Grafana module in WebUI)
- Optional local nginx SSL proxy with self-signed certificate
- Distributed polling: automatic token generation, one-liner for satellites/agents with correct repo URL
- Modularized: function files for Icinga and Grafana setup (`lib/icinga_install.sh`, `lib/grafana_install.sh`)
- Auto-setup scripts for satellites and agents (`setup_satellite.sh`, `setup_agent.sh`)
- All credentials and tokens are saved securely

## Distributed Polling (Satellites/Agents)

To connect a satellite or agent, run the following one-liner on the remote system:

```sh
bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_satellite.sh) <MASTER_IP> <JOIN_TOKEN>
bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_agent.sh) <MASTER_IP> <JOIN_TOKEN>
```

## Security
- All passwords are randomly generated and stored in `icinga2_credentials.txt` (chmod 600)
- The script checks for existing installations and warns before overwriting

## Notes
- For more details, see the comments in the script files.
- This project is open source and contributions are welcome!

## Repository
https://github.com/Sandro12366/icinga-install-script
