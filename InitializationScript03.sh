#!/usr/bin/env bash

set -Eeuxo pipefail

echo '>>> Setup general variables'
export SERVER_SSH_KEYS=(
    'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCn7F4GaMHycYXRoHSIXQYwHsOlhQXjl2wHZnFbdkTioELBPFTLUitPOPKEnST+gFDKOuXtdTzWk3jlBUFoQ+Nu++Kak+TvViZKfDLszg7jpBJrLfhEwxO72hCLH0H5mXOy5dPgp0YI0NREGx0UwMUsz9RFbGGudIrWXf88IMSd82ZoBpKP8gkMY/KgSElB0CLWxDjgisGKVbJPBHAmZ6rbuaDep25IGzQM/M6GVkJhccJMdgM/6fczir3DPaSjJEh9VP42xgLyULRabG/VDJRlU7Jb/Bab2I/C3H/sBy8g14kilKA5Gs0YQJTbZTyz1YMJ8ip9LD/+yS8baOxKHJlsqlpEkQ5FaaLWBJ9ocn7xmHGhjpfrg2k6bH6e8x5oI49eulGhXBiPFOS+Y+1LMIFPW5z5rKiIQrmR51rl/tog0Uy2OTRu3t6cdG+iNAgjLZhOFGeaaBgEnOSApHe+eo4lDPIDKJfiaAcx/WdL3JmPlcnPe7bp9FWCoDBVwgTDOThtv0EFLLAjqzSvpR/Xq/sxVYfTYacSiFayF+zmw+lHvmlapzEEZDUAjA/4K4Nnm+vNWBiCjw1p41EJmD2FLq2TYdTLjqOZh4UGbqv1KQDpBvRrzQUREe4OA1Zd/HLx/MDz1ZAd9ljUfVpfbGMldOpHOyBLmxZE6HtIOpOX/x0DHw== pavel.balashov1@gmail.com'
)

echo '>>> Setup logging'
export BASH_XTRACEFD=100
export SERVER_INIT_LOG='/root/server_init.log'

if [ -e "$SERVER_INIT_LOG" ]; then
    rm --recursive --force "$SERVER_INIT_LOG"
fi
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


{
cat << "EOF"

# Set default SSH public keys
export SERVER_SSH_KEYS="$SERVER_SSH_KEYS"

EOF
} >> "${SYSTEM_CUSTOM_PROFILE_PATH}"

echo '>>> Update and upgrade system'
#apt-get update --assume-yes
#apt-get upgrade --assume-yes

# Global close brace
} 100>&1 | tee ${SERVER_INIT_LOG}
