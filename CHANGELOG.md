# Changelog

## v1.2.0 (2025-07-17)
### Major Change: Release/Tag-Based Versioning
- **All script downloads (main and lib) now use release/tag-based versioning.**
  - The main script sets a `SCRIPT_VERSION` variable (e.g., `v1.2.0`).
  - All `lib/` scripts are always downloaded from the same release/tag as the main script, ensuring version consistency and atomic updates.
  - Users are encouraged to use the one-liner with a specific tag, e.g.:
    ```sh
    bash <(curl -s https://raw.githubusercontent.com/Sandro12366/icinga-install-script/v1.2.0/install_icinga2.sh)
    ```
- **Instructions for maintainers:**
  - After any change, bump `SCRIPT_VERSION`, commit, push, and create a new GitHub release/tag.
  - All users will then get the correct, matching versions of all scripts.
- **README and documentation updated** to reflect this new versioning approach.

## v1.1.1 (2025-07-17)
### Bug Fixes & Improvements
- **One-liner install robustness:**
  - The main script now automatically downloads all required `lib/` scripts from the GitHub repository if they are missing, ensuring the one-liner install works without a full repo clone.
- **Permissions:**
  - Downloaded `lib/` scripts are set as executable (`chmod +x`).
- **Error handling:**
  - If a `lib/` script cannot be downloaded, the script aborts with a clear error message.
- **Documentation:**
  - README updated to list all supported OS versions explicitly.
- **General:**
  - Minor quoting and logic improvements for robustness and maintainability.

## v1.1.0 (2025-07-17)
### Major Improvements
- **Robustness:**
  - Added `set -u` for unset variable detection.
  - Improved error trap to show the offending command and line number.
- **OS/Repo Handling:**
  - Explicitly set `VERSION_CODENAME` for Debian/Ubuntu repo URLs.
- **Package Checks:**
  - Hardened `is_installed` for dpkg-based systems (uses `dpkg-query`).
- **Database Setup:**
  - Added logic to handle MySQL root password and `auth_socket` edge cases.
  - SQL user creation now uses `IF NOT EXISTS` for idempotency.
- **Proxy Logic:**
  - Fixed proxy logic to match actual values of `PROXY_SETUP`.
- **Web Server Handling:**
  - Web root locations are now configurable.
  - Web server restarts only the one in use (nginx or apache).
- **Modularization:**
  - Sourced scripts in `lib/` are now checked for existence before sourcing (idempotent sourcing).
- **Unattended Mode:**
  - Added a stub for unattended mode (env/flags parsing, to be expanded).
- **Quoting:**
  - Improved variable quoting throughout for safety.
- **Health Check:**
  - Health check logic is now ready for further expansion in `lib/healthcheck.sh`.

### Documentation
- Updated README to reflect all new features, robustness, and modularity.
- Added this changelog for full transparency.

## v1.0.0 (2025-07-15)
### Initial Release
- Fully automated, modular Bash script for Icinga2 stack installation and configuration.
- Supports Debian, Ubuntu, RHEL, CentOS, Rocky, AlmaLinux.
- Interactive setup for FQDN, proxy, Web2, Director, nginx, distributed polling, and more.
- Automatic password generation and secure storage.
- Modularized advanced features into `lib/` scripts:
  - `lib/ssl_setup.sh` (Let's Encrypt/self-signed SSL for nginx/apache)
  - `lib/proxy_snippet.sh` (external proxy config generation)
  - `lib/hardening.sh` (firewall and fail2ban setup)
  - `lib/notifications.sh` (SMTP and Slack/Teams notification setup)
  - `lib/healthcheck.sh` (post-install health check and summary)
- Main script sources all modules and calls their functions at the appropriate places.
- README.md made visually appealing, international, and up-to-date with all features, including logo handling for light/dark mode and a credit note for GitHub Copilot.
- All user-facing output and documentation in English, with clear references to "Web2" (Icinga Web 2).
- Syntax and error check performed on the main script (no errors found).
