#!/bin/bash
# ssl_setup.sh - Functions for SSL and Let's Encrypt setup for nginx/apache proxies in Icinga2 stack.
# Used by install_master.sh for secure web access.

# SSL and Let's Encrypt logic for nginx/apache
# Usage: source this file and call setup_ssl_proxy <webserver> <fqdn> <letsencrypt>

setup_ssl_proxy() {
    local WEBSERVER="$1"
    local FQDN="$2"
    local LETSENCRYPT="$3"
    if [ "$WEBSERVER" = "nginx" ]; then
        if [ "$LETSENCRYPT" = "y" ] && [ -n "$FQDN" ]; then
            echo -e "${GREEN}Setting up Let's Encrypt SSL for nginx...${NC}"
            if ! is_installed certbot; then
                apt-get install -y certbot python3-certbot-nginx || yum install -y certbot python3-certbot-nginx
            fi
            certbot --nginx -d "$FQDN" --non-interactive --agree-tos -m admin@$FQDN || {
                echo -e "${YELLOW}Let's Encrypt failed, falling back to self-signed certificate.${NC}"
                setup_selfsigned_nginx "$FQDN"
            }
        else
            setup_selfsigned_nginx "$FQDN"
        fi
    elif [ "$WEBSERVER" = "apache" ]; then
        if [ "$LETSENCRYPT" = "y" ] && [ -n "$FQDN" ]; then
            echo -e "${GREEN}Setting up Let's Encrypt SSL for apache...${NC}"
            if ! is_installed certbot; then
                apt-get install -y certbot python3-certbot-apache || yum install -y certbot python3-certbot-apache
            fi
            certbot --apache -d "$FQDN" --non-interactive --agree-tos -m admin@$FQDN || {
                echo -e "${YELLOW}Let's Encrypt failed, falling back to self-signed certificate.${NC}"
                setup_selfsigned_apache "$FQDN"
            }
        else
            setup_selfsigned_apache "$FQDN"
        fi
    fi
}

setup_selfsigned_nginx() {
    local FQDN="$1"
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/icinga.key \
        -out /etc/nginx/ssl/icinga.crt \
        -subj "/C=DE/ST=Icinga/L=Icinga/O=Icinga/OU=Icinga/CN=${FQDN:-localhost}"
}

setup_selfsigned_apache() {
    local FQDN="$1"
    mkdir -p /etc/apache2/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/apache2/ssl/icinga.key \
        -out /etc/apache2/ssl/icinga.crt \
        -subj "/C=DE/ST=Icinga/L=Icinga/O=Icinga/OU=Icinga/CN=${FQDN:-localhost}"
}
