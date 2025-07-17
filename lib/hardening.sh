#!/bin/bash
# hardening.sh - Functions for security hardening (firewall, fail2ban) for Icinga2 stack.
# Used by install_master.sh for production-grade security.

# Security hardening: firewall and fail2ban
# Usage: source and call setup_hardening

setup_hardening() {
    # Firewall
    if command -v ufw &>/dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
        echo "UFW firewall enabled."
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
        echo "firewalld enabled."
    fi
    # Fail2ban
    if ! is_installed fail2ban; then
        if command -v apt-get &>/dev/null; then
            apt-get install -y fail2ban
        elif command -v yum &>/dev/null; then
            yum install -y fail2ban
        fi
    fi
    systemctl enable fail2ban
    systemctl restart fail2ban
    echo "Fail2ban enabled."
}
