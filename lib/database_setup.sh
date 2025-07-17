#!/bin/bash
# database_setup.sh - Functions for installing and configuring MySQL/MariaDB for Icinga2 stack.
# Used by install_master.sh for modular DB setup and credential management.
# Usage: source and call setup_database <os> <db_user> <db_pass>

setup_database() {
    local OS="$1"
    local DB_USER="$2"
    local DB_PASS="$3"
    if [ "$OS" = "debian" ]; then
        echo -e "${GREEN}Installing and configuring MySQL (Debian)...${NC}"
        if is_installed mysql-server; then
            echo -e "${YELLOW}MySQL server is already installed.${NC}"
        else
            apt-get install -y mysql-server mysql-client
        fi
    elif [ "$OS" = "ubuntu" ]; then
        echo -e "${GREEN}Installing and configuring MySQL (Ubuntu)...${NC}"
        if is_installed mysql-server; then
            echo -e "${YELLOW}MySQL server is already installed.${NC}"
        else
            apt-get install -y mysql-server mysql-client
        fi
    elif [ "$OS" = "rhel" ]; then
        echo -e "${GREEN}Installing and configuring MariaDB (RHEL/CentOS)...${NC}"
        if is_installed mariadb-server; then
            echo -e "${YELLOW}MariaDB server is already installed.${NC}"
        else
            yum install -y mariadb-server mariadb
            systemctl enable mariadb
            systemctl start mariadb
        fi
    fi

    # Secure MySQL/MariaDB installation and create DB/user
    MYSQL_ROOT_AUTH=""
    if [ "$OS" = "debian" ] || [ "$OS" = "ubuntu" ]; then
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
}
