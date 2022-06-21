#!/bin/sh
clear

echo spoof MAC address at boot and disable WLAN on sleep
# Source: https://sunknudsen.com/privacy-guides/how-to-spoof-mac-address-and-hostname-automatically-at-boot-on-macos

sudo mkdir -p /usr/local/sbin
sudo chown ${USER}:admin /usr/local/sbin

echo 'export PATH=$PATH:/usr/local/sbin' >> ~/.zshrc
source ~/.zshrc

cp mac-address-prefixes.txt /usr/local/sbin/mac-address-prefixes.txt

cat << "EOF" > /usr/local/sbin/spoof.sh
#! /bin/sh

set -e
set -o pipefail

export LC_CTYPE=C

basedir=$(dirname "$0")

# Spoof MAC address of Wi-Fi interface
mac_address_prefix=$(sed "$(jot -r 1 1 768)q;d" $basedir/mac-address-prefixes.txt | sed -e 's/[^A-F0-9:]//g')
mac_address_suffix=$(openssl rand -hex 3 | sed 's/\(..\)/\1:/g; s/.$//')
mac_address=$(echo "$mac_address_prefix:$mac_address_suffix" | awk '{print toupper($0)}')
networksetup -setairportpower en0 on
sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport --disassociate
sudo ifconfig en0 ether "$mac_address"
printf "%s\n" "Spoofed MAC address of en0 interface to $mac_address"
EOF

chmod +x /usr/local/sbin/spoof.sh

cat << "EOF" | sudo tee /Library/LaunchDaemons/local.spoof.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>spoof</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/sbin/spoof.sh</string>
    </array>

    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOF

cat << "EOF" > /usr/local/sbin/spoof-hook.sh
#! /bin/sh

# Turn off Wi-Fi interface
networksetup -setairportpower en0 off
EOF

chmod +x /usr/local/sbin/spoof-hook.sh

sudo defaults write com.apple.loginwindow LogoutHook "/usr/local/sbin/spoof-hook.sh"

clear

echo Install Homebrew, neofetch, cask and htop
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew analytics off
brew install neofetch htop cask figlet pandoc wget ipcalc 

clear

echo Install Apps
export HOMEBREW_CASK_OPTS="--appdir=/Applications"
brew install --cask firefox tor-browser iterm2 rectangle textmate appcleaner spotify whatsapp discord vscodium exifcleaner microsoft-word mactex-no-gui coconutbattery veracrypt syncthing wire altserver
clear

echo Cleaning up...
brew cleanup

clear

echo Finished!
