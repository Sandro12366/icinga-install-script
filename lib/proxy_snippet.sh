#!/bin/bash
# Generate config snippet for external proxy
# Usage: generate_proxy_snippet <type> <fqdn> <backend_port>

generate_proxy_snippet() {
    local TYPE="$1"
    local FQDN="$2"
    local PORT="$3"
    if [ "$TYPE" = "nginx" ]; then
        cat <<EOF
# NGINX reverse proxy config for Icinga Web2
server {
    listen 443 ssl;
    server_name $FQDN;
    ssl_certificate /path/to/your/fullchain.pem;
    ssl_certificate_key /path/to/your/privkey.pem;
    location /icingaweb2/ {
        proxy_pass http://YOUR_ICINGA_SERVER:$PORT/icingaweb2/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /grafana/ {
        proxy_pass http://YOUR_ICINGA_SERVER:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF
    elif [ "$TYPE" = "apache" ]; then
        cat <<EOF
# Apache reverse proxy config for Icinga Web2
<VirtualHost *:443>
    ServerName $FQDN
    SSLEngine on
    SSLCertificateFile /path/to/your/fullchain.pem
    SSLCertificateKeyFile /path/to/your/privkey.pem
    ProxyPreserveHost On
    ProxyPass /icingaweb2/ http://YOUR_ICINGA_SERVER:$PORT/icingaweb2/
    ProxyPassReverse /icingaweb2/ http://YOUR_ICINGA_SERVER:$PORT/icingaweb2/
    ProxyPass /grafana/ http://YOUR_ICINGA_SERVER:3000/
    ProxyPassReverse /grafana/ http://YOUR_ICINGA_SERVER:3000/
</VirtualHost>
EOF
    fi
}
