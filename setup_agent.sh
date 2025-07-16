#!/bin/bash
# Icinga2 Agent Auto-Setup Script
# Ausführbar per 1-Zeiler aus dem Git-Repo

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

MASTER_IP="$1"
JOIN_TOKEN="$2"

if [ -z "$MASTER_IP" ] || [ -z "$JOIN_TOKEN" ]; then
    echo -e "${RED}Usage: $0 <MASTER_IP> <JOIN_TOKEN>${NC}"
    exit 1
fi

# Root-Check
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Bitte als root ausführen!${NC}"
    exit 1
fi

# OS-Erkennung
OS="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        debian|ubuntu)
            OS="debian"
            ;;
        rhel|centos|rocky|almalinux)
            OS="rhel"
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

# Pakete installieren
if [ "$OS" = "debian" ]; then
    apt-get update
    apt-get install -y icinga2
elif [ "$OS" = "rhel" ]; then
    yum install -y icinga2
fi

# Node Wizard automatisiert ausführen
echo -e "${YELLOW}Starte automatisiertes Icinga2 Node Wizard Setup für Agent...${NC}"
echo -e "agent\n$MASTER_IP\n$JOIN_TOKEN\ny\ny\n" | icinga2 node wizard

# Zertifikate automatisch holen
icinga2 node setup --ticket $JOIN_TOKEN --endpoint $MASTER_IP

systemctl restart icinga2

echo -e "${GREEN}Agent-Setup abgeschlossen!${NC}"
