#!/usr/bin/env bash

# Remove Firefox-snap
sudo snap disable firefox
sudo snap remove --purge firefox
sudo rm -r ~/snap/firefox/

# Set Firefox-priority to -10
echo "Package: firefox*
Pin: release o=Ubuntu*
Pin-Priority: -1" |
    sudo tee /etc/apt/preferences.d/firefoxNoSnap.pref

# Allow automatic upgrades of Firefox
echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' |
    sudo tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox

# Reinstall Firefox from ppa
sudo apt-get purge -y firefox
sudo add-apt-repository -y ppa:mozillateam
sudo apt-get update
sudo apt-get install -y firefox
