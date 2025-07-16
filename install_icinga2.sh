#!/bin/bash

# =============================================
# Icinga2 Installationsscript (für Git-Repo)
#
# Nach dem Push in ein öffentliches Repo kann das Script so ausgeführt werden:
# bash <(curl -s https://raw.githubusercontent.com/<dein-user>/<repo>/main/install_icinga2.sh)
# =============================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to generate random password
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

# Function to save credentials
save_credentials() {
    local file="icinga2_credentials.txt"
    echo "Icinga2 Installation Credentials" > "$file"
    echo "================================" >> "$file"
    echo "Generated on: $(date)" >> "$file"
    echo "" >> "$file"
    echo "Web Interface:" >> "$file"
    echo "Username: $1" >> "$file"
    echo "Password: $2" >> "$file"
    echo "" >> "$file"
    if [ ! -z "$3" ]; then
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

# Betriebssystem-Erkennung
OS="unknown"
OS_VERSION=""
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        debian)
            OS="debian"
            OS_VERSION="$VERSION_ID"
            ;;
        ubuntu)
            OS="ubuntu"
            OS_VERSION="$VERSION_ID"
            ;;
        rhel|centos|rocky|almalinux)
            OS="rhel"
            OS_VERSION="$VERSION_ID"
            ;;
        *)
            echo -e "${RED}Nicht unterstütztes Betriebssystem: $ID${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${RED}Konnte Betriebssystem nicht erkennen!${NC}"
    exit 1
fi

# Interaktive Auswahl

# FQDN/Hostname
read -p "Bitte gib den FQDN für Icinga2 ein (leer lassen für IP-basierten Zugriff): " FQDN

# Hinweis zu Proxy und nginx
cat <<EOF

Hinweis: Ein lokaler SSL-Proxy (nginx) kann später im Setup ausgewählt werden, um WebUI und Grafana per HTTPS bereitzustellen.
EOF

# Proxy-Frage
read -p "Wird dieser Server hinter einem Proxy betrieben? (y/n): " PROXY_SETUP

# WebUI-Auswahl
echo "\nWelche Web-Oberfläche soll installiert werden?"
select WEBUI_VARIANT in "Keine WebUI" "Standard (nur WebUI)" "WebUI mit Grafana-Integration"; do
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
            echo "Bitte 1, 2 oder 3 wählen."
            ;;
    esac
done

# Director-Frage
if [ "$INSTALL_WEB" = "y" ]; then
    read -p "Soll Icinga Director installiert werden? (y/n): " INSTALL_DIRECTOR
else
    # Wenn keine WebUI, dann trotzdem nach Director fragen
    read -p "Soll Icinga Director installiert werden? (y/n): " INSTALL_DIRECTOR
fi

# nginx Reverse Proxy
read -p "Möchtest du einen lokalen SSL-Proxy (nginx) als Reverse Proxy für WebUI/Grafana einrichten? (y/n): " INSTALL_NGINX

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
    echo -e "${GREEN}Detected Debian Version: $OS_VERSION${NC}"
    apt-get update
    # Unterschiedliche Abhängigkeiten je nach Version
    if [ "$OS_VERSION" = "11" ]; then
        apt-get install -y apt-transport-https wget gnupg lsb-release software-properties-common curl
    elif [ "$OS_VERSION" = "12" ] || [ "$OS_VERSION" = "13" ]; then
        apt-get install -y wget gnupg lsb-release software-properties-common curl
    else
        apt-get install -y wget gnupg lsb-release software-properties-common curl
    fi
    # Add Icinga repository
    if [ ! -f /etc/apt/sources.list.d/icinga.list ]; then
        wget -O - https://packages.icinga.com/icinga.key | gpg --dearmor -o /usr/share/keyrings/icinga-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/debian icinga-${VERSION_CODENAME} main" > /etc/apt/sources.list.d/icinga.list
    fi
    apt-get update
elif [ "$OS" = "ubuntu" ]; then
    echo -e "${GREEN}Detected Ubuntu Version: $OS_VERSION${NC}"
    apt-get update
    apt-get install -y wget gnupg lsb-release software-properties-common curl
    # Add Icinga repository
    if [ ! -f /etc/apt/sources.list.d/icinga.list ]; then
        wget -O - https://packages.icinga.com/icinga.key | gpg --dearmor -o /usr/share/keyrings/icinga-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/icinga-archive-keyring.gpg] https://packages.icinga.com/ubuntu icinga-${VERSION_CODENAME} main" > /etc/apt/sources.list.d/icinga.list
    fi
    apt-get update
elif [ "$OS" = "rhel" ]; then
    echo -e "${GREEN}Detected RHEL/CentOS Version: $OS_VERSION${NC}"
    yum install -y epel-release wget curl gnupg2
    rpm --import https://packages.icinga.com/icinga.key
    if [ ! -f /etc/yum.repos.d/ICINGA-release.repo ]; then
        curl -o /etc/yum.repos.d/ICINGA-release.repo https://packages.icinga.com/epel/ICINGA-release.repo
    fi
    yum makecache
else
    echo -e "${RED}Unbekanntes OS, Installation abgebrochen.${NC}"
    exit 1
fi

# Install MySQL/MariaDB
if [ "$OS" = "debian" ]; then
    echo -e "${GREEN}Installing and configuring MySQL (Debian $OS_VERSION)...${NC}"
    if [ "$OS_VERSION" = "11" ]; then
        apt-get install -y mysql-server mysql-client
    elif [ "$OS_VERSION" = "12" ] || [ "$OS_VERSION" = "13" ]; then
        apt-get install -y mariadb-server mariadb-client
    else
        apt-get install -y mariadb-server mariadb-client
    fi
elif [ "$OS" = "ubuntu" ]; then
    echo -e "${GREEN}Installing and configuring MySQL (Ubuntu $OS_VERSION)...${NC}"
    apt-get install -y mysql-server mysql-client
elif [ "$OS" = "rhel" ]; then
    echo -e "${GREEN}Installing and configuring MariaDB (RHEL/CentOS $OS_VERSION)...${NC}"
    yum install -y mariadb-server mariadb
    systemctl enable mariadb
    systemctl start mariadb
fi

# Secure MySQL/MariaDB installation
if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
    mysql -e "CREATE DATABASE IF NOT EXISTS icinga2;"
    mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -e "GRANT ALL PRIVILEGES ON icinga2.* TO '${DB_USER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
elif [ "$OS" = "rhel" ]; then
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS icinga2;"
    mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mysql -u root -e "GRANT ALL PRIVILEGES ON icinga2.* TO '${DB_USER}'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
fi

# Funktionsdateien einbinden
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/icinga_install.sh"
. "$SCRIPT_DIR/lib/grafana_install.sh"

# Icinga-Komponenten installieren
install_icinga_core

# Grafana installieren (falls gewählt)
if [ "$INSTALL_GRAFANA" = "y" ]; then
    install_grafana
fi

# Configure proxy settings if needed
if [ "$PROXY_SETUP" = "y" ]; then
    read -p "Enter proxy URL (e.g., http://proxy.example.com:3128): " PROXY_URL
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    
    # Add proxy settings to apt
    cat > /etc/apt/apt.conf.d/proxy.conf << EOF
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
EOF
fi

# Nach der Hauptinstallation: nginx Reverse Proxy einrichten, falls gewünscht
if [ "$INSTALL_NGINX" = "y" ]; then
    echo -e "${GREEN}Installiere und konfiguriere nginx als SSL-Proxy...${NC}"
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
        apt-get install -y nginx openssl
    elif [ "$OS" = "rhel" ]; then
        yum install -y nginx openssl
    fi
    # Self-signed Zertifikat erzeugen
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/icinga.key \
        -out /etc/nginx/ssl/icinga.crt \
        -subj "/C=DE/ST=Icinga/L=Icinga/O=Icinga/OU=Icinga/CN=${FQDN:-localhost}"
    # nginx Konfiguration für Reverse Proxy
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
    # Default-Server deaktivieren
    if [ -f /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi
    systemctl enable nginx
    systemctl restart nginx
    echo -e "${GREEN}nginx SSL-Proxy aktiv unter https://${FQDN:-localhost}/icingaweb2/ und /grafana/${NC}"
fi

# Distributed Polling
read -p "Soll Distributed Polling (Satelliten/Agenten) konfiguriert werden? (y/n): " SETUP_DISTRIBUTED

if [ "$SETUP_DISTRIBUTED" = "y" ]; then
    # Automatische Token-Generierung für Satelliten/Agenten
    JOIN_TOKEN=$(openssl rand -hex 16)
    MASTER_IP=$(hostname -I | awk '{print $1}')
    echo "$JOIN_TOKEN" > /etc/icinga2/join.token
    chmod 600 /etc/icinga2/join.token
    echo -e "\n${GREEN}Distributed Polling aktiviert!${NC}"
    echo -e "Master-IP: ${YELLOW}$MASTER_IP${NC}"
    echo -e "Join-Token: ${YELLOW}$JOIN_TOKEN${NC}"
    echo -e "\nSatelliten und Agenten können mit folgendem 1-Zeiler automatisch angebunden werden:"
    echo -e "  bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_satellite.sh) $MASTER_IP $JOIN_TOKEN"
    echo -e "  bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_agent.sh) $MASTER_IP $JOIN_TOKEN"
    echo -e "\nDie nötigen Setup-Skripte werden im Repo erzeugt."
fi

# Save all credentials
save_credentials "$ICINGA_ADMIN_USER" "$ICINGA_ADMIN_PASS" "$GRAFANA_ADMIN_PASS" "$DB_USER" "$DB_PASS" "$DIRECTOR_API_USER" "$DIRECTOR_API_PASS"

# Restart services
systemctl restart icinga2
if [ "$INSTALL_WEB" = "y" ]; then
    systemctl restart apache2
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
