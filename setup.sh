#!/bin/bash

if [ "$EUID" -eq 0 ] ; then
  echo "Do not run as root"
  exit
fi

main() {
  cd ~

  _sudo

  _dnf
  _power

  _tmux
  _vim

  _php
  _aws

  _ssh
  _git

  _gnome
  _gterm
}

_sudo() {
  echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$USER" > /dev/null
}

_dnf() {
  # VSCode repo setup
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

  # MongoDB repo setup
  sudo rpm --import https://pgp.mongodb.com/server-6.0.asc
  sudo tee /etc/yum.repos.d/mongodb.repo > /dev/null << EOF
[Mongodb]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-6.0.asc
EOF

  # enable Chrome repo
  sudo dnf install fedora-workstation-repositories
  sudo dnf config-manager --set-enabled google-chrome

  sudo dnf install -y \
    code \
    dotnet-sdk-6.0 aspnetcore-runtime-6.0 \
    dotnet-sdk-7.0 aspnetcore-runtime-7.0 \
    file-roller file-roller-nautilus \
    gcc-c++ \
    gimp \
    gitk \
    gnome-extensions-app gnome-tweaks \
    golang \
    google-chrome-stable \
    mongodb-org \
    npm \
    java-latest-openjdk-devel \
    mariadb mariadb-server \
    php-cli composer php-pdo \
    podman-compose \
    postgresql postgresql-server \
    protobuf-compiler \
    qemu-kvm guestfs-tools libvirt virt-install virt-manager virt-viewer \
    rust cargo rust-src rustfmt \
    tmux \
    vim-enhanced

  # replace nano with vim
  sudo dnf install -y --allowerasing vim-default-editor
  
  # assume there's enough RAM to skip zram/swap
  sudo dnf remove -y zram-generator-defaults

  sudo dnf update -y
}

_power() {
  if [ -d /sys/class/power_supply/BAT* ]; then
    mkdir -p ~/.bashrc.d
    cat > ~/.bashrc.d/cpuGovernor << EOF
alias governor-get="cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
alias governor-set-powersave="echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
alias governor-set-schedutil="echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
EOF

    LOGIND="/etc/systemd/logind.conf"
    if ! grep -q '^HandleLidSwitch=' $LOGIND ; then 
      echo "HandleLidSwitch=ignore" | sudo tee -a $LOGIND > /dev/null
    fi
    if ! grep -q '^HandleLidSwitchExternalPower' $LOGIND ; then 
      echo "HandleLidSwitchExternalPower=ignore" | sudo tee -a $LOGIND > /dev/null
    fi
  fi

  # wait 15 minutes before turning off the screen
  gsettings set org.gnome.desktop.session idle-delay 900
}

_tmux() {
  cat > ~/.tmux.conf << EOF
set-option -g status-style bg=red,fg=white
EOF

  mkdir -p ~/.bashrc.d
  cat > ~/.bashrc.d/tm << EOF
alias tm="tmux attach -d -t tm || tmux new-session -s tm"
EOF

}

_vim() {
  # enabled with 'set runtimepath' in /etc/vimrc.local below
  sudo git clone --depth 1 \
    https://github.com/ctrlpvim/ctrlp.vim.git \
    /etc/systemSetup/vimPlugins/ctrlp

  # RHEL's /etc/vimrc looks to vimrc.local for global host settings
  sudo tee /etc/vimrc.local > /dev/null << EOF
filetype plugin on
filetype indent on

set hlsearch
set ignorecase
set incsearch
set number
set showmatch
set smartcase
set tabstop=4 softtabstop=0 expandtab shiftwidth=2 smarttab

au FileType php setl tabstop=8 shiftwidth=4

set runtimepath+=/etc/systemSetup/vimPlugins/ctrlp

let g:ctrlp_max_height = 20
let g:ctrlp_custom_ignore = 'node_modules\|^\.git'
EOF
}

_php() {
  composer global require "squizlabs/php_codesniffer=*" -q
}

_aws() {
  # toolkit requires docker, which isn't included in Fedora since RH went with podman et al
  sudo dnf config-manager --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
  sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo groupadd docker
  sudo usermod -aG docker $USER
  newgrp docker
  sudo systemctl enable --now containerd.service
  sudo systemctl enable --now docker

  wget -P /tmp/ https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
  unzip /tmp/aws-sam-cli-linux-x86_64.zip -d /tmp/sam-install
  sudo /tmp/sam-install/install
}

_ssh() {
  ssh-keygen -t ecdsa -b 521 -f ~/.ssh/id_ecdsa_schone-code

  sudo tee /etc/ssh/sshd_config.d/60-localnetwork.conf > /dev/null << EOF
Port 42000
AllowUsers $USER
PasswordAuthentication no
EOF
  sudo systemctl enable sshd
}

_git() {
  # set up ~/.gitconfig
  git config --global core.editor vim
  git config --global diff.tool vimdiff
  git config --global init.defaultBranch main
  git config --global user.name "Brandon Detty"
  git config --global user.email "113217431+brandon-detty@users.noreply.github.com"

  git config --global core.excludesfile ~/.gitignore
  cat > ~/.gitignore << EOF
*.swp
*.swo
EOF
}

_gnome() {
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark
  gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark

  gsettings set org.gnome.desktop.interface text-scaling-factor 1.25
}

_gterm() {
  gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ zoom-in '<Primary>equal'

  GTERM_PROF=`gsettings get org.gnome.Terminal.ProfilesList default`
  GTERM_PROF="${GTERM_PROF%\'}"
  GTERM_PROF="${GTERM_PROF#\'}"
  dconf load /org/gnome/terminal/legacy/profiles:/ << EOT
[/]
list=['$GTERM_PROF']

[:$GTERM_PROF]
audible-bell=false
default-size-columns=130
default-size-rows=24
font='Monospace, Bold 14'
use-system-font=false
EOT
}

main
