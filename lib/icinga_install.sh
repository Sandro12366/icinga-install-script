#!/bin/bash
# icinga_install.sh - Functions for installing and configuring Icinga2 core, IcingaDB, Director, Web2, Icinga DB Web, and Icinga Notifications Web modules.
# Used by install_master.sh for modular, robust, and production-ready stack setup.

# Contains functions for the installation and configuration of Icinga2, Icinga DB, Director, WebUI, Icinga DB Web, Icinga Notifications Web

install_icinga_core() {
    local INSTALL_WEB="$1"
    local INSTALL_DIRECTOR="$2"
    local INSTALL_ICINGADB="$3"
    local INSTALL_ICINGADB_WEB="$4"
    local INSTALL_NOTIFICATIONS_WEB="$5"
    local DB_USER="$6"
    local DB_PASS="$7"
    # Example: install_icinga_core "$INSTALL_WEB" "$INSTALL_DIRECTOR" "$INSTALL_ICINGADB" "$INSTALL_ICINGADB_WEB" "$INSTALL_NOTIFICATIONS_WEB" "$DB_USER" "$DB_PASS"

    # Install Icinga2 core
    if ! is_installed icinga2; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y icinga2
        elif command -v yum &>/dev/null; then
            yum install -y icinga2
        fi
    fi
    systemctl enable icinga2
    systemctl start icinga2

    # Install Web2 if requested
    if [ "$INSTALL_WEB" = "y" ]; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y icingaweb2 icingacli
        elif command -v yum &>/dev/null; then
            yum install -y icingaweb2 icingacli
        fi
        systemctl enable apache2 || systemctl enable httpd
        systemctl restart apache2 || systemctl restart httpd
    fi

    # Install Icinga Director if requested
    if [ "$INSTALL_DIRECTOR" = "y" ]; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y icingaweb2-module-director
        elif command -v yum &>/dev/null; then
            yum install -y icingaweb2-module-director
        fi
    fi

    # Install IcingaDB and Redis if requested
    if [ "$INSTALL_ICINGADB" = "y" ]; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y icingadb icingadb-redis
        elif command -v yum &>/dev/null; then
            yum install -y icingadb icingadb-redis
        fi
        systemctl enable icingadb
        systemctl start icingadb
        systemctl enable redis-server || systemctl enable redis
        systemctl start redis-server || systemctl start redis
    fi

    # Install Icinga DB Web if requested
    if [ "$INSTALL_ICINGADB_WEB" = "y" ]; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y icingaweb2-module-icingadb
        elif command -v yum &>/dev/null; then
            yum install -y icingaweb2-module-icingadb
        fi
    fi

    # Install Icinga Notifications Web if requested
    if [ "$INSTALL_NOTIFICATIONS_WEB" = "y" ]; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y icingaweb2-module-notifications
        elif command -v yum &>/dev/null; then
            yum install -y icingaweb2-module-notifications
        fi
    fi

    # Configure DB credentials for Web2/Director (if needed)
    # ...additional configuration logic can be added here...
}
