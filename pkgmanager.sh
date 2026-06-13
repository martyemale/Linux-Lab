#!/bin/bash
echo "=============================="
echo "  Package Management Reference"
echo "  Linux+ XK0-006 Study Guide"
echo "  Date: $(date)"
echo "=============================="

cat << 'GUIDE'

--- RED HAT FAMILY (RHEL, Fedora, Rocky, AlmaLinux) ---
Package Manager: dnf (replaces yum)
Package Format: .rpm

  Install:        dnf install nginx
  Remove:         dnf remove nginx
  Upgrade one:    dnf upgrade zsh
  Upgrade all:    dnf upgrade
  Search:         dnf search nginx
  Info:           dnf info nginx
  List installed: dnf list installed
  Check updates:  dnf check-update
  Clean cache:    dnf clean all
  Group install:  dnf groupinstall "Development Tools"
  Repo list:      dnf repolist

--- DEBIAN FAMILY (Ubuntu, Debian, Mint) ---
Package Manager: apt (wraps dpkg)
Package Format: .deb

  Install:        apt install nginx
  Remove:         apt remove nginx
  Purge (+ conf): apt purge nginx
  Upgrade one:    apt install --only-upgrade zsh
  Upgrade all:    apt upgrade
  Update repos:   apt update
  Search:         apt search nginx
  Info:           apt show nginx
  List installed: apt list --installed
  Autoremove:     apt autoremove
  Low-level:      dpkg -i package.deb
  List files:     dpkg -L nginx

--- SUSE FAMILY (openSUSE, SLES) ---
Package Manager: zypper
Package Format: .rpm

  Install:        zypper install nginx
  Remove:         zypper remove nginx
  Upgrade one:    zypper update zsh
  Upgrade all:    zypper update
  Search:         zypper search nginx
  Info:           zypper info nginx
  Refresh repos:  zypper refresh
  List repos:     zypper repos

--- KEY DIFFERENCES TO REMEMBER ---

  Upgrade vs Update:
    dnf upgrade = update packages (Red Hat)
    apt update  = refresh repo metadata (Debian)
    apt upgrade = update packages (Debian)
    * "update" means different things on different distros!

  Remove vs Purge:
    apt remove  = remove package, keep config files
    apt purge   = remove package AND config files
    dnf remove  = removes package and configs

  Your Mac uses: brew (Homebrew)
    brew install    = install
    brew upgrade    = upgrade
    brew uninstall  = remove
    brew search     = search
    brew list       = list installed

GUIDE

echo ""
echo "--- DEMO: Homebrew on this Mac ---"
echo "Installed packages: $(brew list | wc -l | tr -d ' ')"
echo ""
echo "Recently installed:"
brew list --versions | tail -5
echo ""
echo "Reference complete."
