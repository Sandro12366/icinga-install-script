# 🚀 Icinga2 Automated Installation & Configuration Script

<p align="center">
  <picture style="display:inline-block; vertical-align:middle;">
    <source srcset="media/icinga-logo-invert-screen-export-small.png" media="(prefers-color-scheme: dark)">
    <img alt="Icinga2 Logo" src="media/icinga-logo-screen-export-small.png" height="160" style="display:inline-block; vertical-align:middle; margin-right:24px;">
  </picture>
  <img alt="Your Logo" src="media/logo-nobackround_orig.png" height="160" style="display:inline-block; vertical-align:middle;">
</p>

---

**Easily set up a full-featured Icinga2 monitoring stack (Web2, Director, IcingaDB, Redis, Grafana, distributed polling, and optional nginx SSL proxy) on any major Linux distribution – fully automated and ready to use!**

---

## ✨ Features

- **Automatic OS detection:** Debian (11, 12, 13), Ubuntu (20.04, 22.04, 24.04), RHEL (8, 9), CentOS (7, 8), Rocky Linux (8, 9), AlmaLinux (8, 9)
- **Smart dependency & repository management** per distribution
- **Interactive setup:** FQDN, proxy, Web2, Director, nginx, distributed polling
- **Unattended mode stub:** Ready for full automation via environment variables/flags
- **Secure password generation** and storage (`icinga2_credentials.txt`)
- **One-command install** for Icinga2, Web2, Director, IcingaDB, Redis, Grafana
- **All components pre-configured** and integrated
- **Optional nginx SSL proxy** with self-signed certificate or Let's Encrypt
- **Distributed polling:** automatic token generation, one-liner for satellites/agents
- **Modular codebase:** function files for Icinga & Grafana setup, advanced features in `lib/`
- **Auto-setup scripts** for satellites and agents
- **All credentials and tokens stored securely**
- **Robust error handling:** aborts on error, shows offending command and line
- **Idempotent sourcing:** all `lib/` scripts are checked before sourcing
- **Web server detection:** only restarts the web server in use
- **Health check:** post-install health check and summary

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
- Hardened package checks and improved quoting for safety
- Handles MySQL/MariaDB root password and `auth_socket` edge cases

---

## 🛠️ Advanced & Robustness Features

- **set -u**: aborts on unset variables
- **Improved error trap**: shows offending command and line
- **Explicit repo codename detection** for Debian/Ubuntu
- **Idempotent sourcing** of all `lib/` scripts
- **Web server detection** for restart logic
- **Stub for unattended mode** (expandable for CI/CD)

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a full list of changes and improvements.

---

## 📝 Notes & Contribution

- For details, see comments in the script files.
- This project is **open source** – contributions, issues, and PRs are welcome!
- [Icinga2 Documentation](https://icinga.com/docs/)

---

## 📦 Repository

[github.com/Sandro12366/icinga-install-script](https://github.com/Sandro12366/icinga-install-script)

---

<sub><sup>GitHub Copilot (GPT-4.1) helped with this project.</sup></sub>
