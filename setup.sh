#!/bin/bash

if [ "$EUID" -eq 0 ] ; then
  echo "Do not run as root"
  exit
fi

main() {
  cd ~

  _dnf
  _power

  _tmux
  _vim

  _php

  _ssh
  _git

  _gterm
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

  # enable Chrome repo
  sudo dnf install fedora-workstation-repositories
  sudo dnf config-manager --set-enabled google-chrome

  sudo dnf install -y \
    code \
    dotnet-sdk-6.0 aspnetcore-runtime-6.0 \
    dotnet-sdk-7.0 aspnetcore-runtime-7.0 \
    file-roller file-roller-nautilus \
    gcc-c++ \
    gitk \
    gnome-extensions-app gnome-tweaks \
    golang \
    google-chrome-stable \
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
  fi
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
default-size-rows=25
font='Monospace, Bold 18'
use-system-font=false
EOT
}

main
