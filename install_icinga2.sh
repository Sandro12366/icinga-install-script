#!/bin/bash

# =============================================
# Icinga2 installation script (for Git repo)
#
# After pushing to a public repo, you can run this script as follows:
# bash <(curl -s https://raw.githubusercontent.com/<your-user>/<repo>/main/install_icinga2.sh)
# =============================================

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
    echo "Icinga2 Installation Credentials" > "$file"
    echo "================================" >> "$file"
    echo "Created on: $(date)" >> "$file"
    echo "" >> "$file"
    echo "Web Interface:" >> "$file"
    echo "Username: $1" >> "$file"
    echo "Password: $2" >> "$file"
    echo "" >> "$file"
    if [ ! -z "${3:-}" ]; then
        echo "Grafana:" >> "$file"
        echo "Username: admin" >> "$file"
        echo "Password: $3" >> "$file"
        echo "" >> "$file"
    fi
    echo "Database:" >> "$file"
    echo "Username: $4" >> "$file"
    echo "Password: $5" >> "$file"
    echo "" >> "$file"
    echo "Director API:" >> "$file"
    echo "Username: $6" >> "$file"
    echo "Password: $7" >> "$file"
    
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
    read -p "Do you really want to continue and possibly overwrite existing installations? (y/n): " CONTINUE_INSTALL
    if [ "$CONTINUE_INSTALL" != "y" ]; then
        echo -e "${RED}Installation aborted.${NC}"
        exit 1
    fi
fi

# OS detection
OS="unknown"
OS_VERSION=""
VERSION_CODENAME=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        debian)
            OS="debian"
            OS_VERSION="$VERSION_ID"
            VERSION_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
            ;;
        ubuntu)
            OS="ubuntu"
            OS_VERSION="$VERSION_ID"
            VERSION_CODENAME="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null || echo '')}"
            ;;
        rhel|centos|rocky|almalinux)
            OS="rhel"
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

# ---
# Extended Interactive Setup and Option Parsing

# FQDN/Hostname
read -p "Please enter the FQDN for Icinga2 (leave empty for IP-based access): " FQDN

# DNS check for FQDN
if [ -n "$FQDN" ]; then
    IP_RESOLVED=$(getent hosts "$FQDN" | awk '{ print $1 }')
    IP_LOCAL=$(hostname -I | awk '{print $1}')
    if [ "$IP_RESOLVED" != "$IP_LOCAL" ]; then
        echo -e "${YELLOW}Warning: FQDN $FQDN does not resolve to this server's IP ($IP_LOCAL). Let's Encrypt may fail!${NC}"
    fi
fi

# Proxy selection
echo "\nProxy/Reverse Proxy options:"
select PROXY_MODE in "No proxy" "Local nginx (integrated)" "Local Apache (integrated)" "External proxy (generate config)"; do
    case $REPLY in
        1)
            PROXY_SETUP="none"; break;;
        2)
            PROXY_SETUP="nginx"; break;;
        3)
            PROXY_SETUP="apache"; break;;
        4)
            PROXY_SETUP="external"; break;;
        *)
            echo "Please select 1, 2, 3 or 4.";;
    esac
done

# If external proxy, ask for type and generate config later
if [ "$PROXY_SETUP" = "external" ]; then
    echo "\nWhich external proxy do you want a config for?"
    select EXTERNAL_PROXY_TYPE in "nginx" "apache"; do
        case $REPLY in
            1) EXTERNAL_PROXY_TYPE="nginx"; break;;
            2) EXTERNAL_PROXY_TYPE="apache"; break;;
            *) echo "Please select 1 or 2.";;
        esac
done
fi

# SSL options for integrated proxy
LETSENCRYPT="n"
if [ "$PROXY_SETUP" = "nginx" ] || [ "$PROXY_SETUP" = "apache" ]; then
    read -p "Do you want to use Let's Encrypt for a real SSL certificate (requires valid FQDN)? (y/n): " LETSENCRYPT
fi

# Security hardening
read -p "Do you want to enable firewall and fail2ban hardening? (y/n): " ENABLE_HARDENING

# Notification integration
read -p "Do you want to configure email (SMTP) notifications? (y/n): " ENABLE_SMTP
read -p "Do you want to configure Slack/Teams notifications? (y/n): " ENABLE_CHAT

# Unattended mode (env/flags)
# (Stub: To be implemented. Example: if [ -n "${ICINGA_UNATTENDED:-}" ]; then ... fi)

# ---
# (The rest of the script will use these new variables to control the flow and features)

# Interactive selection

# WebUI selection
echo "\nWhich web interface should be installed?"
select WEBUI_VARIANT in "No WebUI" "Standard (WebUI only)" "WebUI with Grafana integration"; do
    case $REPLY in
        1)
            INSTALL_WEB="n"
            INSTALL_GRAFANA="n"
            INSTALL_REDIS="n"
            INSTALL_ICINGADB="n"
            break
            ;;
        2)
            INSTALL_WEB="y"
            INSTALL_GRAFANA="n"
            INSTALL_REDIS="n"
            INSTALL_ICINGADB="n"
            break
            ;;
        3)
            INSTALL_WEB="y"
            INSTALL_GRAFANA="y"
            INSTALL_REDIS="y"
            INSTALL_ICINGADB="y"
            break
            ;;
        *)
            echo "Please select 1, 2 or 3."
            ;;
    esac

done

# Director question
if [ "$INSTALL_WEB" = "y" ]; then
    read -p "Should Icinga Director be installed? (y/n): " INSTALL_DIRECTOR
else
    # Ask for Director even if no WebUI
    read -p "Should Icinga Director be installed? (y/n): " INSTALL_DIRECTOR
fi

# Generate random passwords
ICINGA_ADMIN_USER="icingaadmin"
ICINGA_ADMIN_PASS=$(generate_password)
GRAFANA_ADMIN_PASS=$(generate_password)
DB_USER="icinga2"
DB_PASS=$(generate_password)
DIRECTOR_API_USER="director"
DIRECTOR_API_PASS=$(generate_password)

# Install required repositories and packages
if [ "$OS" = "debian" ]; then
    echo -e "${GREEN}Debian version detected: $OS_VERSION${NC}"
    apt-get update
    # Different dependencies based on version
    for pkg in apt-transport-https wget gnupg lsb-release software-properties-common curl; do
        if ! is_installed "$pkg"; then
            apt-get install -y "$pkg"
        else
            echo -e "${YELLOW}Package $pkg is already installed.${NC}"
        fi
    done
    # Add Icinga repository
    if [ ! -f /etc/apt/sources.list.d/icinga.list ]; then
        wget -O - https://packages.icinga.com/icinga.key | gpg --dearmor -o /usr/share/keyrings/icinga-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/debian icinga-${VERSION_CODENAME} main" > /etc/apt/sources.list.d/icinga.list
    else
        echo -e "${YELLOW}Icinga repository is already added.${NC}"
    fi
    apt-get update
elif [ "$OS" = "ubuntu" ]; then
    echo -e "${GREEN}Ubuntu version detected: $OS_VERSION${NC}"
    apt-get update
    for pkg in wget gnupg lsb-release software-properties-common curl; do
        if ! is_installed "$pkg"; then
            apt-get install -y "$pkg"
        else
            echo -e "${YELLOW}Package $pkg is already installed.${NC}"
        fi
    done
    # Add Icinga repository
    if [ ! -f /etc/apt/sources.list.d/icinga.list ]; then
        wget -O - https://packages.icinga.com/icinga.key | gpg --dearmor -o /usr/share/keyrings/icinga-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-${VERSION_CODENAME} main" > /etc/apt/sources.list.d/icinga.list
    else
        echo -e "${YELLOW}Icinga repository is already added.${NC}"
    fi
    apt-get update
elif [ "$OS" = "rhel" ]; then
    echo -e "${GREEN}RHEL/CentOS version detected: $OS_VERSION${NC}"
    for pkg in epel-release wget curl gnupg2; do
        if ! is_installed "$pkg"; then
            yum install -y "$pkg"
        else
            echo -e "${YELLOW}Package $pkg is already installed.${NC}"
        fi
    done
    rpm --import https://packages.icinga.com/icinga.key
    if [ ! -f /etc/yum.repos.d/ICINGA-release.repo ]; then
        curl -o /etc/yum.repos.d/ICINGA-release.repo https://packages.icinga.com/epel/ICINGA-release.repo
    else
        echo -e "${YELLOW}Icinga repository is already added.${NC}"
    fi
    yum makecache
else
    echo -e "${RED}Unknown operating system, installation aborted.${NC}"
    exit 1
fi

# Install MySQL/MariaDB
if [ "$OS" = "debian" ]; then
    echo -e "${GREEN}Installing and configuring MySQL (Debian $OS_VERSION)...${NC}"
    if is_installed mysql-server; then
        echo -e "${YELLOW}MySQL server is already installed.${NC}"
    else
        apt-get install -y mysql-server mysql-client
    fi
elif [ "$OS" = "ubuntu" ]; then
    echo -e "${GREEN}Installing and configuring MySQL (Ubuntu $OS_VERSION)...${NC}"
    if is_installed mysql-server; then
        echo -e "${YELLOW}MySQL server is already installed.${NC}"
    else
        apt-get install -y mysql-server mysql-client
    fi
elif [ "$OS" = "rhel" ]; then
    echo -e "${GREEN}Installing and configuring MariaDB (RHEL/CentOS $OS_VERSION)...${NC}"
    if is_installed mariadb-server; then
        echo -e "${YELLOW}MariaDB server is already installed.${NC}"
    else
        yum install -y mariadb-server mariadb
        systemctl enable mariadb
        systemctl start mariadb
    fi
fi

# Secure MySQL/MariaDB installation
MYSQL_ROOT_AUTH=""
if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    # Try to detect if root uses auth_socket
    if mysql -u root -e "" 2>&1 | grep -q 'Access denied'; then
        echo -e "${YELLOW}MySQL root may require a password or use auth_socket. Please enter MySQL root password if prompted.${NC}"
        MYSQL_ROOT_AUTH="-u root -p"
    fi
    mysql $MYSQL_ROOT_AUTH -e "CREATE DATABASE IF NOT EXISTS icinga2;"
    mysql $MYSQL_ROOT_AUTH -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql $MYSQL_ROOT_AUTH -e "GRANT ALL PRIVILEGES ON icinga2.* TO '${DB_USER}'@'localhost';"
    mysql $MYSQL_ROOT_AUTH -e "FLUSH PRIVILEGES;"
elif [ "$OS" = "rhel" ]; then
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS icinga2;"
    mysql -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON icinga2.* TO '${DB_USER}'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
fi

# Include function files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_RAW_URL="https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main"
LIB_DIR="$SCRIPT_DIR/lib"
mkdir -p "$LIB_DIR"
for lib in icinga_install.sh grafana_install.sh ssl_setup.sh proxy_snippet.sh hardening.sh notifications.sh healthcheck.sh; do
    LIB_PATH="$LIB_DIR/$lib"
    if [ ! -f "$LIB_PATH" ]; then
        echo -e "${YELLOW}Downloading missing $lib...${NC}"
        curl -fsSL "$REPO_RAW_URL/lib/$lib" -o "$LIB_PATH" || { echo -e "${RED}Failed to download $lib from repo!${NC}"; exit 1; }
        chmod +x "$LIB_PATH"
    fi
    . "$LIB_PATH"
done

# Install Icinga components
install_icinga_core

# Install Grafana (if selected)
if [ "$INSTALL_GRAFANA" = "y" ]; then
    install_grafana
fi

# Check if proxy settings are needed
if [ "$PROXY_SETUP" = "y" ]; then
    read -p "Please enter the proxy URL (e.g. http://proxy.example.com:3128): " PROXY_URL
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    # Add proxy settings to apt
    cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
EOF
fi

# After main installation: set up nginx reverse proxy if desired
if [ "$INSTALL_NGINX" = "y" ]; then
    echo -e "${GREEN}Installing and configuring nginx as SSL proxy...${NC}"
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        apt-get install -y nginx openssl
    elif [ "$OS" = "rhel" ]; then
        yum install -y nginx openssl
    fi
    # Generate self-signed certificate
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/icinga.key \
        -out /etc/nginx/ssl/icinga.crt \
        -subj "/C=DE/ST=Icinga/L=Icinga/O=Icinga/OU=Icinga/CN=${FQDN:-localhost}"
    # nginx config for reverse proxy
    cat > /etc/nginx/sites-available/icinga2 << EOF
server {
    listen 443 ssl;
    server_name ${FQDN:-_};
    ssl_certificate /etc/nginx/ssl/icinga.crt;
    ssl_certificate_key /etc/nginx/ssl/icinga.key;
    location /icingaweb2/ {
        proxy_pass http://127.0.0.1/icingaweb2/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /grafana/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/icinga2 /etc/nginx/sites-enabled/icinga2
    # Disable default server
    if [ -f /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi
    systemctl enable nginx
    systemctl restart nginx
    echo -e "${GREEN}nginx SSL proxy active at https://${FQDN:-localhost}/icingaweb2/ and /grafana/${NC}"
fi

# Distributed Polling
read -p "Should distributed polling (satellites/agents) be configured? (y/n): " SETUP_DISTRIBUTED

if [ "$SETUP_DISTRIBUTED" = "y" ]; then
    # Automatic token generation for satellites/agents
    JOIN_TOKEN=$(openssl rand -hex 16)
    MASTER_IP=$(hostname -I | awk '{print $1}')
    echo "$JOIN_TOKEN" > /etc/icinga2/join.token
    chmod 600 /etc/icinga2/join.token
    echo -e "\n${GREEN}Distributed polling enabled!${NC}"
    echo -e "Master IP: ${YELLOW}$MASTER_IP${NC}"
    echo -e "Join token: ${YELLOW}$JOIN_TOKEN${NC}"
    echo -e "\nSatellites and agents can be connected automatically with the following one-liner:"
    echo -e "  bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_satellite.sh) $MASTER_IP $JOIN_TOKEN"
    echo -e "  bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_agent.sh) $MASTER_IP $JOIN_TOKEN"
    echo -e "\nThe required setup scripts are provided in the repo."
fi

# Proxy/SSL/Reverse Proxy logic
if [ "$PROXY_SETUP" = "nginx" ] || [ "$PROXY_SETUP" = "apache" ]; then
    setup_ssl_proxy "$PROXY_SETUP" "$FQDN" "$LETSENCRYPT"
    # (Add nginx/apache config logic here, using generated certs)
fi
if [ "$PROXY_SETUP" = "external" ]; then
    echo -e "\n${GREEN}External proxy config snippet for $EXTERNAL_PROXY_TYPE:${NC}"
    generate_proxy_snippet "$EXTERNAL_PROXY_TYPE" "$FQDN" "80"
fi

# Security hardening
if [ "$ENABLE_HARDENING" = "y" ]; then
    setup_hardening
fi

# Notification integration
if [ "$ENABLE_SMTP" = "y" ]; then
    setup_smtp
fi
if [ "$ENABLE_CHAT" = "y" ]; then
    setup_chat
fi

# Health check and summary at the end
run_healthcheck

# Save all credentials
save_credentials "$ICINGA_ADMIN_USER" "$ICINGA_ADMIN_PASS" "$GRAFANA_ADMIN_PASS" "$DB_USER" "$DB_PASS" "$DIRECTOR_API_USER" "$DIRECTOR_API_PASS"

# Restart services
systemctl restart icinga2
if [ "$INSTALL_WEB" = "y" ]; then
    if [ "$PROXY_SETUP" = "apache" ]; then
        systemctl restart apache2
    elif [ "$PROXY_SETUP" = "nginx" ]; then
        systemctl restart nginx
    fi
fi

echo -e "${GREEN}Installation completed!${NC}"
echo -e "Please check ${YELLOW}icinga2_credentials.txt${NC} for all credentials"
if [ -z "$FQDN" ]; then
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    echo -e "Access Icinga2 Web UI at: ${YELLOW}http://$IP_ADDRESS/icingaweb2/${NC}"
else
    echo -e "Access Icinga2 Web UI at: ${YELLOW}http://$FQDN/icingaweb2/${NC}"
fi
if [ "$INSTALL_GRAFANA" = "y" ]; then
    if [ -z "$FQDN" ]; then
        echo -e "Access Grafana at: ${YELLOW}http://$IP_ADDRESS:3000/${NC}"
    else
        echo -e "Access Grafana at: ${YELLOW}http://$FQDN:3000/${NC}"
    fi
fi

# Changelog and README update will be handled separately
