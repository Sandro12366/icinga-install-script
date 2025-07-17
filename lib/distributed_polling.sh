#!/bin/bash
# distributed_polling.sh - Functions for setting up distributed polling (satellites/agents) in Icinga2.
# Used by install_master.sh and install_satellite.sh for robust distributed monitoring.

# Distributed polling (satellites/agents) setup
# Usage: source and call setup_distributed_polling <master_ip>

setup_distributed_polling() {
    local MASTER_IP="$1"
    local JOIN_TOKEN
    JOIN_TOKEN=$(openssl rand -hex 16)
    echo "$JOIN_TOKEN" > /etc/icinga2/join.token
    chmod 600 /etc/icinga2/join.token
    echo -e "\n${GREEN}Distributed polling enabled!${NC}"
    echo -e "Master IP: ${YELLOW}$MASTER_IP${NC}"
    echo -e "Join token: ${YELLOW}$JOIN_TOKEN${NC}"
    echo -e "\nSatellites and agents can be connected automatically with the following one-liner:"
    echo -e "  bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_satellite.sh) $MASTER_IP $JOIN_TOKEN"
    echo -e "  bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_agent.sh) $MASTER_IP $JOIN_TOKEN"
    echo -e "\nThe required setup scripts are provided in the repo."
}
