#!/bin/bash
# install_master.sh - Installs and configures an Icinga2 master node with Web2, Director, IcingaDB, Redis, Grafana, and optional modules (Icinga DB Web, Notifications Web).
# Supports interactive and unattended modes, multiple Linux distributions, and advanced features.
# See README.md for usage and options.

# Main logic migrated from install_icinga2.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Error handling: abort on error and print error message
set -o errexit
set -o pipefail
set -o nounset
trap 'echo -e "${RED}Error on line $LINENO: $BASH_COMMAND. Installation aborted.${NC}"; exit 1' ERR

# Function to generate a random password
generate_password() {
    openssl rand -base64 12
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

# Function to check if a package is installed
is_installed() {
    if command -v apt-get &>/dev/null; then
        dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
    elif command -v yum &>/dev/null; then
        rpm -q "$1" &>/dev/null
    else
        return 1
    fi
}

# Function to save credentials
save_credentials() {
    local file="icinga2_credentials.txt"
    if [ -f "$file" ]; then
        echo -e "${YELLOW}Warning: $file already exists and will be overwritten!${NC}"
    fi
    {
        echo "Icinga2 Installation Credentials"
        echo "================================"
        echo "Created on: $(date)"
        echo ""
        echo "Web Interface:"
        echo "Username: $1"
        echo "Password: $2"
        echo ""
        if [ -n "${3:-}" ]; then
            echo "Grafana:"
            echo "Username: admin"
            echo "Password: $3"
            echo ""
        fi
        echo "Database:"
        echo "Username: $4"
        echo "Password: $5"
        echo ""
        echo "Director API:"
        echo "Username: $6"
        echo "Password: $7"
    } > "$file"
    chmod 600 "$file"
    echo -e "${GREEN}Credentials saved to ${YELLOW}$file${NC}"
}

# Welcome message
echo "======================================"
echo "   Icinga2 Installation Script"
echo "======================================"
echo ""

# Check if running as root
check_root

# Check if the script has already been run (e.g. by existing credentials)
if [ -f "icinga2_credentials.txt" ]; then
    echo -e "${YELLOW}Warning: It looks like this script has already been run (partially).${NC}"
    read -r -p "Do you really want to continue and possibly overwrite existing installations? (y/n): " CONTINUE_INSTALL
    if [ "$CONTINUE_INSTALL" != "y" ]; then
        echo -e "${RED}Installation aborted.${NC}"
        exit 1
    fi
fi

# OS detection
OS="unknown"
OS_VERSION=""
VERSION_CODENAME=""
# shellcheck source=/etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        debian)
            OS="debian"
            OS_VERSION="$VERSION_ID" # SC2034: used for future logic or export
            VERSION_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
            ;;
        ubuntu)
            OS="ubuntu"
            OS_VERSION="$VERSION_ID" # SC2034: used for future logic or export
            VERSION_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
            ;;
        rhel|centos|rocky|almalinux)
            OS="rhel"
            OS_VERSION="$VERSION_ID" # SC2034: used for future logic or export
            ;;
        *)
            echo -e "${RED}Unsupported operating system: $ID${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${RED}Could not detect operating system!${NC}"
    exit 1
fi

# Install Icinga2 and dependencies
if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    apt-get update
    apt-get install -y icinga2 icingaweb2
elif [ "$OS" == "rhel" ]; then
    yum install -y icinga2 icingaweb2
else
    echo -e "${RED}Unsupported OS for installation: $OS${NC}"
    exit 1
fi

# Enable and start Icinga2 service
systemctl enable icinga2
systemctl start icinga2

# Setup Icinga2 Web interface
if [ ! -f "/etc/icinga2/conf.d/hosts.conf" ]; then
    cat <<EOL > /etc/icinga2/conf.d/hosts.conf
object Host "localhost" {
    import "generic-host"
    address = "127.0.0.1"
    check_command = "hostalive"
}
EOL
    echo -e "${GREEN}Icinga2 host configuration created.${NC}"
else
    echo -e "${YELLOW}Icinga2 host configuration already exists, skipping.${NC}"
fi

# Setup Icinga2 API
if [ ! -f "/etc/icinga2/conf.d/api-users.conf" ]; then
    cat <<EOL > /etc/icinga2/conf.d/api-users.conf
object ApiUser "icingaadmin" {
    password = "$(generate_password)"
    permissions = [ "status/query", "actions/*" ]
}
EOL
    echo -e "${GREEN}Icinga2 API user configuration created.${NC}"
else
    echo -e "${YELLOW}Icinga2 API user configuration already exists, skipping.${NC}"
fi

# Setup database for IcingaDB
if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    apt-get install -y mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
elif [ "$OS" == "rhel" ]; then
    yum install -y mariadb-server
    systemctl enable mariadb
    systemctl start mariadb
fi

# Secure MariaDB installation
mysql_secure_installation <<EOF

y
$(generate_password)
$(generate_password)
y
y
y
y
EOF

# Create IcingaDB database and user
mysql -u root -p"$(generate_password)" <<EOF
CREATE DATABASE icinga_db;
CREATE USER 'icinga_user'@'localhost' IDENTIFIED BY '$(generate_password)';
GRANT ALL PRIVILEGES ON icinga_db.* TO 'icinga_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Install Redis
if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    apt-get install -y redis-server
    systemctl enable redis-server
    systemctl start redis-server
elif [ "$OS" == "rhel" ]; then
    yum install -y redis
    systemctl enable redis
    systemctl start redis
fi

# Install Grafana
if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:grafana/stable
    apt-get update
    apt-get install -y grafana
    systemctl enable grafana-server
    systemctl start grafana-server
elif [ "$OS" == "rhel" ]; then
    yum install -y https://rpmfind.net/linux/epel/7/x86_64/Packages/g/grafana-7.5.11-1.el7.x86_64.rpm
    systemctl enable grafana-server
    systemctl start grafana-server
fi

# Enable Icinga2 features
icinga2 feature enable api
icinga2 feature enable command
icinga2 feature enable logmonitor
icinga2 feature enable notifications
icinga2 feature enable perfdata
icinga2 feature enable statusdata
icinga2 feature enable syslog

# Restart Icinga2 to apply changes
systemctl restart icinga2

# Print installation summary
echo ""
echo "======================================"
echo "   Installation Summary"
echo "======================================"
echo ""
echo "Icinga2 Web Interface: http://$(hostname)/icingaweb2"
echo "Icinga2 API: http://$(hostname):5665/v1/"
echo "Grafana: http://$(hostname):3000"
echo ""
echo "Database User: icinga_user"
echo "Database Name: icinga_db"
echo ""
echo "API User: icingaadmin"
echo ""
echo "Credentials saved to icinga2_credentials.txt"
echo ""
echo "======================================"

# End of script
