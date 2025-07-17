#!/bin/bash
# Health check and post-install summary
# Usage: source and call run_healthcheck

run_healthcheck() {
    echo "\n===== Icinga2 Health Check ====="
    systemctl is-active --quiet icinga2 && echo "Icinga2: RUNNING" || echo "Icinga2: NOT RUNNING"
    if systemctl is-active --quiet apache2; then echo "Apache: RUNNING"; fi
    if systemctl is-active --quiet nginx; then echo "nginx: RUNNING"; fi
    if systemctl is-active --quiet grafana-server; then echo "Grafana: RUNNING"; fi
    if systemctl is-active --quiet mariadb || systemctl is-active --quiet mysql; then echo "DB: RUNNING"; fi
    echo "Web2 URL: http://${FQDN:-$(hostname -I | awk '{print $1}')}/icingaweb2/"
    if [ "$INSTALL_GRAFANA" = "y" ]; then
        echo "Grafana URL: http://${FQDN:-$(hostname -I | awk '{print $1}')}:3000/"
    fi
    echo "Credentials: see icinga2_credentials.txt"
    echo "Distributed Polling: $( [ "$SETUP_DISTRIBUTED" = "y" ] && echo ENABLED || echo DISABLED )"
    echo "Firewall: $(systemctl is-active ufw 2>/dev/null || systemctl is-active firewalld 2>/dev/null)"
    echo "Fail2ban: $(systemctl is-active fail2ban 2>/dev/null)"
    echo "Notifications: SMTP $( [ -f /etc/icinga2/smtp.conf ] && echo ENABLED || echo DISABLED ), Chat $( [ -f /etc/icinga2/chat.conf ] && echo ENABLED || echo DISABLED )"
    echo "==================================="
}
