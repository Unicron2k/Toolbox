#!/usr/bin/env bash

# Set net6 PMC-repo to high priority
echo 'Package: *
Pin: origin "packages.microsoft.com"
Pin-Priority: 1001' | sudo tee /etc/apt/preferences.d/net6pmc.pref

# Get microsoft GPG-key for ppa-verification
curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

# Add microsoft PPAs
RELEASE=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $RELEASE main
deb [arch=amd64] https://packages.microsoft.com/ubuntu/21.04/prod hirsute main
deb [arch=amd64] https://packages.microsoft.com/ubuntu/21.10/prod impish main
deb [arch=amd64] https://packages.microsoft.com/ubuntu/22.04/prod jammy main" |
    sudo tee -a /etc/apt/sources.list.d/microsoft-prod.list

# Add mono GPG-ley for PPA-verification
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
# Add mono PPA
echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" |
    sudo tee /etc/apt/sources.list.d/mono-official-stable.list

# Install
sudo apt-get update
sudo apt-get install -y azure-cli dotnet-sdk-6.0 dotnet-sdk-7.0 mono-complete
sudo dotnet tool install --global dotnet-ef dotnet-aspnet-codegenerator
