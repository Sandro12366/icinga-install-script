# Contributing to Icinga2 Install Script

Thank you for considering contributing to this project! Here are some guidelines to help you get started:

## How to Contribute

- **Bug Reports & Feature Requests:**
  - Please use [GitHub Issues](https://github.com/Sandro12366/icinga-install-script/issues) to report bugs or request features.
- **Pull Requests:**
  - Fork the repository and create your branch from `main`.
  - Make sure your code is clean, well-commented, and tested.
  - Bump the `SCRIPT_VERSION` in `install_icinga2.sh` if your change affects the install or lib scripts.
  - Submit a pull request with a clear description of your changes.
- **Coding Style:**
  - Use shellcheck to lint your Bash scripts.
  - Keep user-facing output in English and use consistent formatting.
- **Documentation:**
  - Update the README and CHANGELOG for any user-facing or breaking changes.

## Maintainers
- After merging, create a new GitHub release/tag for every version bump.
- Ensure all scripts in `lib/` are present and up-to-date in the release.

## Community
- Be respectful and constructive in all interactions.
- All contributions are welcome!

---

<sub>Inspired by best practices from the open source community.</sub>
