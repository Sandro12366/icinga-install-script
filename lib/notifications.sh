#!/bin/bash
# Notification integration: SMTP and Slack/Teams
# Usage: source and call setup_smtp, setup_chat

setup_smtp() {
    echo "--- SMTP Notification Setup ---"
    read -p "SMTP server: " SMTP_SERVER
    read -p "SMTP port: " SMTP_PORT
    read -p "SMTP username: " SMTP_USER
    read -s -p "SMTP password: " SMTP_PASS; echo
    read -p "Notification email recipient: " SMTP_RCPT
    # Save config for later use (e.g. for Icinga2 notification scripts)
    cat > /etc/icinga2/smtp.conf <<EOF
SMTP_SERVER=$SMTP_SERVER
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASS=$SMTP_PASS
SMTP_RCPT=$SMTP_RCPT
EOF
    chmod 600 /etc/icinga2/smtp.conf
    echo "SMTP config saved to /etc/icinga2/smtp.conf"
}

setup_chat() {
    echo "--- Chat Notification Setup (Slack/Teams) ---"
    read -p "Webhook URL: " CHAT_WEBHOOK
    read -p "Channel/User: " CHAT_CHANNEL
    cat > /etc/icinga2/chat.conf <<EOF
CHAT_WEBHOOK=$CHAT_WEBHOOK
CHAT_CHANNEL=$CHAT_CHANNEL
EOF
    chmod 600 /etc/icinga2/chat.conf
    echo "Chat config saved to /etc/icinga2/chat.conf"
}
