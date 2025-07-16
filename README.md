# 🚀 Icinga2 Automated Installation & Configuration Script

<p align="center">
  <picture>
    <source srcset="media/icinga-logo-invert-screen-export-small.png" media="(prefers-color-scheme: dark)">
    <img alt="Icinga2 Logo" src="media/icinga-logo-screen-export-small.png" width="320">
  </picture>
</p>

---

**Easily set up a full-featured Icinga2 monitoring stack (WebUI, Director, IcingaDB, Redis, Grafana, distributed polling, and optional nginx SSL proxy) on any major Linux distribution – fully automated and ready to use!**

---

## ✨ Features

- **Automatic OS detection:** Debian, Ubuntu, RHEL, CentOS, Rocky, AlmaLinux
- **Smart dependency & repository management** per distribution
- **Interactive setup:** FQDN, proxy, WebUI, Director, nginx, distributed polling
- **Secure password generation** and storage (`icinga2_credentials.txt`)
- **One-command install** for Icinga2, WebUI, Director, IcingaDB, Redis, Grafana
- **All components pre-configured** and integrated
- **Optional nginx SSL proxy** with self-signed certificate
- **Distributed polling:** automatic token generation, one-liner for satellites/agents
- **Modular codebase:** function files for Icinga & Grafana setup
- **Auto-setup scripts** for satellites and agents
- **All credentials and tokens stored securely**

---

## 🚦 Quick Start

1. **Clone or fork this repo, or use directly from GitHub.**
2. **Run as root on your server:**

```sh
bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/install_icinga2.sh)
```

---

## 🌐 Distributed Polling (Satellites/Agents)

Connect a satellite or agent with a single command (replace `<MASTER_IP>` and `<JOIN_TOKEN>`):

```sh
bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_satellite.sh) <MASTER_IP> <JOIN_TOKEN>
bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/main/setup_agent.sh) <MASTER_IP> <JOIN_TOKEN>
```

---

## 🔒 Security

- All passwords are randomly generated and stored in `icinga2_credentials.txt` (`chmod 600`)
- The script checks for existing installations and warns before overwriting

---

## 📝 Notes & Contribution

- For details, see comments in the script files.
- This project is **open source** – contributions, issues, and PRs are welcome!
- [Icinga2 Documentation](https://icinga.com/docs/)

---

## 📦 Repository

[github.com/Sandro12366/icinga-install-script](https://github.com/Sandro12366/icinga-install-script)
