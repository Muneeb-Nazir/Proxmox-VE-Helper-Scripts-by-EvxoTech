#!/usr/bin/env bash
# Proxmox Helper Script - Nginx Proxy Manager (Docker + MariaDB)
# Author: patched for Docker install with MariaDB

source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)

function header_info {
  clear
  cat <<"EOF"
    _   __      _               ____                           __  ___                                 
   / | / /___ _(_)___  _  __   / __ \_________ __  ____  __   /  |/  /___ _____  ____ _____ ____  _____
  /  |/ / __  / / __ \| |/_/  / /_/ / ___/ __ \| |/_/ / / /  / /|_/ / __  / __ \/ __  / __  / _ \/ ___/
 / /|  / /_/ / / / / />  <   / ____/ /  / /_/ />  </ /_/ /  / /  / / /_/ / / / / /_/ / /_/ /  __/ /    
/_/ |_/\__, /_/_/ /_/_/|_|  /_/   /_/   \____/_/|_|\__, /  /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/     
      /____/                                      /____/                            /____/             
EOF
}
header_info
echo -e "Loading..."

APP="Nginx Proxy Manager"
var_disk="8"
var_cpu="2"
var_ram="2048"
var_os="ubuntu"
var_version="24.04"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"             # Privileged
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function post_install() {
  header_info
  msg_info "Updating container OS"
  apt-get update -y && apt-get upgrade -y &>/dev/null
  msg_ok "Updated container OS"

  msg_info "Installing Docker"
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release &>/dev/null
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -y &>/dev/null
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin &>/dev/null
  msg_ok "Installed Docker"

  msg_info "Deploying Nginx Proxy Manager + MariaDB"
  mkdir -p /opt/npm
  cd /opt/npm

  cat <<EOF > docker-compose.yml
version: "3"
services:
  db:
    image: jc21/mariadb-aria:latest
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: npm
      MYSQL_DATABASE: npm
      MYSQL_USER: npm
      MYSQL_PASSWORD: npm
    volumes:
      - ./data/mysql:/var/lib/mysql

  app:
    image: jc21/nginx-proxy-manager:latest
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    environment:
      DB_MYSQL_HOST: db
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: npm
      DB_MYSQL_PASSWORD: npm
      DB_MYSQL_NAME: npm
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF

  docker compose up -d &>/dev/null
  msg_ok "Deployed Nginx Proxy Manager + MariaDB"

  msg_info "Enabling Docker autostart"
  systemctl enable docker &>/dev/null
  msg_ok "Enabled Docker"

  msg_ok "Completed Successfully!"
  echo -e "You can now access Nginx Proxy Manager at:
  ${BL}http://${IP}:81${CL}
  Default Login → Email: admin@example.com | Password: changeme"
}

start
build_container
post_install
