#!/usr/bin/env bash

set -Eeuxo pipefail

echo '>>> Setup logging'
export BASH_XTRACEFD=100
export SERVER_INIT_LOG='/root/server_init.log'
touch "${SERVER_INIT_LOG}"

# Global open brace
{

cd /root

echo '>>> Setup environment variables'
export SYSTEM_CUSTOM_PROFILE_PATH='/etc/profile.d/server_profile.sh'
{
cat << 'EOF'

# Set server-specific variables
export SERVER_USER='nodex'
#export SERVER_USER_HOME="$(eval echo ~${SERVER_USER})"
export SERVER_USER_HOME="/home/${SERVER_USER}"
export SERVER_USER_EMAIL='pavel.balashov1@gmail.com'
export SERVER_INIT_LOG='/root/server_init.log'
export SYSTEM_CUSTOM_PROFILE_PATH='/etc/profile.d/server_profile.sh'

# Set default SSH public keys
export SERVER_SSH_KEYS=(
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCn7F4GaMHycYXRoHSIXQYwHsOlhQXjl2wHZnFbdkTioELBPFTLUitPOPKEnST+gFDKOuXtdTzWk3jlBUFoQ+Nu++Kak+TvViZKfDLszg7jpBJrLfhEwxO72hCLH0H5mXOy5dPgp0YI0NREGx0UwMUsz9RFbGGudIrWXf88IMSd82ZoBpKP8gkMY/KgSElB0CLWxDjgisGKVbJPBHAmZ6rbuaDep25IGzQM/M6GVkJhccJMdgM/6fczir3DPaSjJEh9VP42xgLyULRabG/VDJRlU7Jb/Bab2I/C3H/sBy8g14kilKA5Gs0YQJTbZTyz1YMJ8ip9LD/+yS8baOxKHJlsqlpEkQ5FaaLWBJ9ocn7xmHGhjpfrg2k6bH6e8x5oI49eulGhXBiPFOS+Y+1LMIFPW5z5rKiIQrmR51rl/tog0Uy2OTRu3t6cdG+iNAgjLZhOFGeaaBgEnOSApHe+eo4lDPIDKJfiaAcx/WdL3JmPlcnPe7bp9FWCoDBVwgTDOThtv0EFLLAjqzSvpR/Xq/sxVYfTYacSiFayF+zmw+lHvmlapzEEZDUAjA/4K4Nnm+vNWBiCjw1p41EJmD2FLq2TYdTLjqOZh4UGbqv1KQDpBvRrzQUREe4OA1Zd/HLx/MDz1ZAd9ljUfVpfbGMldOpHOyBLmxZE6HtIOpOX/x0DHw== pavel.balashov1@gmail.com'
)

# Set Debian frontend settings
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true

# Set locale settings
export LANG=en_US.UTF-8
export LANGUAGE=en
export LC_ALL=en_US.UTF-8
export LC_ADDRESS=en_US.UTF-8
export LC_IDENTIFICATION=en_US.UTF-8
export LC_MONETARY=en_US.UTF-8
export LC_NUMERIC=en_US.UTF-8
export LC_TELEPHONE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_MEASUREMENT=en_US.UTF-8
export LC_NAME=en_US.UTF-8
export LC_PAPER=en_US.UTF-8

# Setup Bash history
shopt -s histappend
PROMPT_COMMAND="${PROMPT_COMMAND:-:} ; history -a"
HISTFILESIZE=400000000
HISTSIZE=10000

# Setup Bash prompt
export PS1='\n[\D{%Y.%m.%d} \t] \u@\h (${?}) \w\n\\$ '

EOF
} >> "${SYSTEM_CUSTOM_PROFILE_PATH}"
source "${SYSTEM_CUSTOM_PROFILE_PATH}"

echo '>>> Update and upgrade system'
apt-get update --assume-yes --fix-missing
apt-get upgrade --assume-yes

echo '>>> Install essential packages'
apt-get remove --assume-yes \
    openssh-server \
    docker \
    docker-engine \
    docker.io \
    containerd \
    runc
apt-get install --assume-yes --no-install-recommends --fix-missing --fix-broken \
    build-essential \
    gcc \
    binutils \
    man \
    bzip2 \
    unzip \
    sudo \
    less \
    vim \
    nano \
    re2c \
    locate \
    sed \
    gawk \
    git \
    make \
    curl \
    wget \
    unzip \
    expect \
    dialog \
    ntp \
    bash-completion \
    shellcheck \
    apt-utils \
    aptitude \
    python2.7 \
    python2.7-dev \
    python-pip \
    python3 \
    python3-dev \
    python3-pip \
    python3-apt \
    python3-docker \
    lm-sensors \
    wireless-tools \
    alien \
    pkgconf \
    libaio1 \
    libaio-dev \
    gdebi \
    locales \
    gnupg \
    supervisor \
    tmux \
    default-mysql-client \
    gdb \
    strace \
    libsqlite3-dev \
    sqlite3 \
    openssl \
    openssh-client \
    openssh-server \
    iputils-ping \
    netstat-nat \
    net-tools \
    iproute2 \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    software-properties-common \
    libterm-readline-gnu-perl \
    ufw

# # Other possible packages
# linux-headers-$(uname --kernel-release) \

if id "${SERVER_USER}" &>/dev/null; then
    echo ">>> Create user: ${SERVER_USER}"
    useradd --create-home --shell /bin/bash "${SERVER_USER}"
    usermod --append --groups sudo "${SERVER_USER}"
    usermod --password '*' "${SERVER_USER}"
fi

echo '>>> Edit sudo privileges for members of the sudo group'
sed --in-place 's/^[ #]*%sudo.*/%sudo   ALL=(ALL) NOPASSWD:ALL/g' /etc/sudoers

echo '>>> Clear .bashrc of the user'
echo '' > "${SERVER_USER_HOME}/.bashrc"

echo '>>> Setup public and private keys'
su - ${SERVER_USER} -c 'ssh-keygen -t rsa -b 4096 -C "${SERVER_USER_EMAIL}" -f "${HOME}"/.ssh/id_rsa -N ""'
su - ${SERVER_USER} -c 'eval "$(ssh-agent -s)" && ssh-add "${HOME}"/.ssh/id_rsa'

echo '>>> Generate locale'
locale-gen en_US.UTF-8

echo '>>> Setup timezone'
timedatectl set-timezone Europe/Bratislava

# echo '>>> Setup Docker and docker-compose'
# curl \
#     --fail \
#     --verbose \
#     --location \
#         https://download.docker.com/linux/ubuntu/gpg \
#     | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
# echo \
#   "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
#   | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# apt-get update --assume-yes
# apt-get install --assume-yes --no-install-recommends --fix-missing --fix-broken \
#     docker-ce \
#     docker-ce-cli \
#     containerd.io \
#     lib32z1 \
#     zlib1g
# curl \
#     --verbose \
#     --output \
#         /usr/local/bin/docker-compose \
#     --location \
#         "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
# chmod a+x /usr/local/bin/docker-compose
# groupadd --force docker
# usermod --append --groups docker "${SERVER_USER}"

echo '>>> Setup git'
su - ${SERVER_USER} -c "git config --global user.name 'Pavel Balashov'"
su - ${SERVER_USER} -c "git config --global user.email 'pavel.balashov1@gmail.com'"
su - ${SERVER_USER} -c "git config --global push.recurseSubmodules check"
su - ${SERVER_USER} -c "git config --global submodule.recurse true"
su - ${SERVER_USER} -c "git config --global diff.submodule log"
su - ${SERVER_USER} -c "git config --global status.submodulesummary 1"

echo '>>> Cleaning up'
apt-get clean --yes
apt-get autoclean --yes
apt-get autoremove --yes
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

echo '>>> Setup additional interactive shell features'
{
cat << 'EOF'

# Setup window resizing
shopt -s checkwinsize

# Setup glob patterns
shopt -s globstar

# Enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

EOF
} >> "${SYSTEM_CUSTOM_PROFILE_PATH}"

echo '>>> Testing'
cd /root
type python
python --version
which python3
python3 --version
sqlite3 --version
docker-compose --version && sleep 5
docker --version

echo '>>> Rebooting'
shutdown -r now

# Global close brace
} 100>&1 | tee ${SERVER_INIT_LOG}
