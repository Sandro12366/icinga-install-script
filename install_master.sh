#!/bin/bash
# install_master.sh - Installs and configures an Icinga2 master node with Web2, Director, IcingaDB, Redis, Grafana, and optional modules (Icinga DB Web, Notifications Web).
# Supports interactive and unattended modes, multiple Linux distributions, and advanced features.
# See README.md for usage and options.


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

# Interactive setup menu for choosing components to install
install_master=false
install_satellite=false
install_agent=false
install_grafana=false
install_redis=false
install_director=false
install_db=false
install_ssl=false
install_proxy=false
install_notifications=false
install_healthcheck=false
install_distributed_polling=false

if [ -z "${UNATTENDED_MODE:-}" ]; then
    echo "Select components to install (y/n):"
    read -p "Install Icinga2 Master? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_master=true
    read -p "Install Satellite Node? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_satellite=true
    read -p "Install Agent Node? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_agent=true
    read -p "Install Grafana? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_grafana=true
    read -p "Install Redis? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_redis=true
    read -p "Install Director? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_director=true
    read -p "Install Database? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_db=true
    read -p "Setup SSL? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_ssl=true
    read -p "Setup Proxy? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_proxy=true
    read -p "Setup Notifications? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_notifications=true
    read -p "Setup Healthcheck? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_healthcheck=true
    read -p "Setup Distributed Polling? [y/N]: " ans && [[ $ans =~ ^[Yy]$ ]] && install_distributed_polling=true
    echo "Selected components:"
    $install_master && echo "- Icinga2 Master"
    $install_satellite && echo "- Satellite Node"
    $install_agent && echo "- Agent Node"
    $install_grafana && echo "- Grafana"
    $install_redis && echo "- Redis"
    $install_director && echo "- Director"
    $install_db && echo "- Database"
    $install_ssl && echo "- SSL"
    $install_proxy && echo "- Proxy"
    $install_notifications && echo "- Notifications"
    $install_healthcheck && echo "- Healthcheck"
    $install_distributed_polling && echo "- Distributed Polling"
fi

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
# shellcheck disable=SC1091
# shellcheck source=/etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        debian)
            OS="debian"
            # shellcheck disable=SC2034
            OS_VERSION="$VERSION_ID"
            VERSION_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
            ;;
        ubuntu)
            OS="ubuntu"
            # shellcheck disable=SC2034
            OS_VERSION="$VERSION_ID"
            VERSION_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
            ;;
        rhel|centos|rocky|almalinux)
            OS="rhel"
            # shellcheck disable=SC2034
            OS_VERSION="$VERSION_ID"
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

# Check if database exists
if mysql -u root -p"$(generate_password)" -e "USE icinga_db;" 2>/dev/null; then
    echo -e "${YELLOW}Database 'icinga_db' already exists.${NC}"
    read -p "Do you want to overwrite it? [y/N]: " overwrite_db
    if [[ "$overwrite_db" =~ ^[Yy]$ ]]; then
        mysql -u root -p"$(generate_password)" -e "DROP DATABASE icinga_db;"
        echo -e "${YELLOW}Database 'icinga_db' dropped. Proceeding with creation.${NC}"
    else
        echo -e "${YELLOW}Skipping database creation.${NC}"
    fi
fi

# Create IcingaDB database and user (idempotent)
mysql -u root -p"$(generate_password)" <<EOF
CREATE DATABASE IF NOT EXISTS icinga_db;
CREATE USER IF NOT EXISTS 'icinga_user'@'localhost' IDENTIFIED BY '$(generate_password)';
GRANT ALL PRIVILEGES ON icinga_db.* TO 'icinga_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# Install Redis
if $install_redis; then
    echo -e "${GREEN}Installing Redis...${NC}"
    if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
        apt-get install -y redis-server
        systemctl enable redis-server
        systemctl start redis-server
    elif [ "$OS" == "rhel" ]; then
        yum install -y redis
        systemctl enable redis
        systemctl start redis
    fi
else
    echo -e "${YELLOW}Redis installation skipped.${NC}"
fi

# Install Grafana
if $install_grafana; then
    echo -e "${GREEN}Installing Grafana...${NC}"
    if [ "$OS" == "debian" ] || [ "$OS" == "ubuntu" ]; then
        apt-get install -y apt-transport-https wget gnupg
        wget -q -O - https://apt.grafana.com/gpg.key | apt-key add -
        echo "deb https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
        apt-get update
        apt-get install -y grafana
        systemctl enable grafana-server
        systemctl start grafana-server
    elif [ "$OS" == "rhel" ]; then
        yum install -y https://rpmfind.net/linux/epel/7/x86_64/Packages/g/grafana-7.5.11-1.el7.x86_64.rpm
        systemctl enable grafana-server
        systemctl start grafana-server
    fi
else
    echo -e "${YELLOW}Grafana installation skipped.${NC}"
fi

# Enable Icinga2 features
export PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin
if ! command -v icinga2 &>/dev/null; then
    if [ -x "/usr/sbin/icinga2" ]; then
        ICINGA2_BIN="/usr/sbin/icinga2"
    elif [ -x "/sbin/icinga2" ]; then
        ICINGA2_BIN="/sbin/icinga2"
    else
        echo -e "${RED}Icinga2 binary not found after installation!${NC}"
        echo -e "${YELLOW}Please check that the Icinga2 package installed successfully and is in your PATH.${NC}"
        exit 1
    fi
else
    ICINGA2_BIN="icinga2"
fi

for feature in api command logmonitor notifications perfdata statusdata syslog; do
    conf_file="/etc/icinga2/features-available/${feature}.conf"
    if [ "$feature" = "api" ]; then
        crt_file="/var/lib/icinga2/certs/$(hostname).crt"
        key_file="/var/lib/icinga2/certs/$(hostname).key"
        ca_crt_file="/var/lib/icinga2/certs/ca.crt"
        ca_key_file="/var/lib/icinga2/certs/ca.key"
        csr_file="/var/lib/icinga2/certs/$(hostname).csr"

        # Generate CA if missing
        if [ ! -f "$ca_crt_file" ] || [ ! -f "$ca_key_file" ]; then
            echo -e "${YELLOW}API feature requires CA certs. Generating CA...${NC}"
            $ICINGA2_BIN pki new-ca
        fi
        # Ensure certs directory exists
        if [ ! -d "/var/lib/icinga2/certs" ]; then
            mkdir -p /var/lib/icinga2/certs
            chown nagios:nagios /var/lib/icinga2/certs
        fi
        # Generate host key/csr if missing
        if [ ! -f "$key_file" ] || [ ! -f "$csr_file" ]; then
            echo -e "${YELLOW}Generating host key and CSR for $(hostname)...${NC}"
            $ICINGA2_BIN pki new-cert --cn "$(hostname)" --key "$key_file" --csr "$csr_file"
        fi
        # Sign host cert if missing
        if [ ! -f "$crt_file" ]; then
            echo -e "${YELLOW}Signing host certificate for $(hostname)...${NC}"
            $ICINGA2_BIN pki sign-csr --csr "$csr_file" --cert "$crt_file"
        fi
        ln -s /var/lib/icinga2/ca/ca.crt /var/lib/icinga2/certs/ca.crt
        ln -s /var/lib/icinga2/ca/ca.key /var/lib/icinga2/certs/ca.key
    
    fi
    if [ -f "$conf_file" ]; then
        $ICINGA2_BIN feature enable "$feature"
    else
        echo -e "${YELLOW}Feature '$feature' not available (missing $conf_file), skipping.${NC}"
    fi

done

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

# Save credentials to file
save_credentials "icingaadmin" "$ICINGAWEB_PASS" "$GRAFANA_PASS" "icinga_user" "$DB_PASS" "icingaadmin" "$API_PASS"

echo "Credentials saved to icinga2_credentials.txt"
echo ""
cat icinga2_credentials.txt
echo ""
echo "======================================"

# End of script