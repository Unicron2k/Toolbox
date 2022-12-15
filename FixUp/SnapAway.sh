#!/usr/bin/env bash

#Remove Kubuntu standard-snaps
sudo snap disable firefox
sudo snap remove --purge firefox
sudo snap remove --purge gtk-common-themes
sudo snap remove --purge bare
sudo snap remove --purge gnome-3-38-2004
sudo snap remove --purge core20
sudo snap remove --purge snapd
sudo rm -r ~/snap
sudo apt-get purge -y snapd
sudo rm -r /snap

# Set Snap-priority to -10
echo "Package: snapd
Pin: release a=*
Pin-Priority: -10" |
    sudo tee /etc/apt/preferences.d/NoSnaps.pref
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
