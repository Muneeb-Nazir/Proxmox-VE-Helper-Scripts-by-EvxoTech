#!/usr/bin/env bash
# Copyright (c) 2025 Evxo Technologies
# Author: Evxo Tech
# License: MIT

# --- PATCH: Allow PVE 4.1 → 8.x ---
pve_check() {
  if ! pveversion | grep -Eq "pve-manager/(4\.[1-9]|[5-8]\.)"; then
    msg_error "This version of Proxmox Virtual Environment is not supported"
    echo -e "Requires Proxmox Virtual Environment Version 4.1 or later."
    echo -e "Exiting..."
    sleep 2
    exit
  fi
}

# --- Header Banner ---
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

# --- Ask user for root password for the LXC ---
read -s -p "Enter root password for LXC: " LCX_PASS
echo ""
read -s -p "Re-enter root password for LXC: " LCX_PASS2
echo ""
if [ "$LCX_PASS" != "$LCX_PASS2" ]; then
  echo "Passwords do not match! Exiting..."
  exit 1
fi

# --- Ask for DB root password ---
read -s -p "Enter MariaDB root password (for persistence): " DB_PASS
echo ""
read -s -p "Re-enter MariaDB root password: " DB_PASS2
echo ""
if [ "$DB_PASS" != "$DB_PASS2" ]; then
  echo "DB Passwords do not match! Exiting..."
  exit 1
fi

# --- OS selection ---
echo "Select base OS for container:"
select os in "Debian 12 (Bookworm)" "Ubuntu 24.04 (Noble)"; do
  case $os in
    "Debian 12 (Bookworm)") var_os="debian"; var_version="12"; break ;;
    "Ubuntu 24.04 (Noble)") var_os="ubuntu"; var_version="24.04"; break ;;
  esac
done

variables
color
catch_errors

# --- Default settings ---
function default_settings() {
  CT_TYPE="1"
  PW="$LCX_PASS"
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  SSH="yes"
  VERB="no"
  echo_default
}

# --- Deployment (Docker + persistence) ---
function deploy_script() {
  header_info
  msg_info "Installing Docker and Docker Compose"
  apt-get update &>/dev/null
  apt-get install -y docker.io docker-compose-plugin mariadb-server sqlite3 &>/dev/null
  msg_ok "Installed Docker and MariaDB"

  msg_info "Setting up MariaDB root password"
  mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASS}';
FLUSH PRIVILEGES;
EOF
  msg_ok "MariaDB root password set"

  msg_info "Creating Docker Compose stack"
  mkdir -p /opt/npm
  cat > /opt/npm/docker-compose.yml <<EOF
version: "3"
services:
  app:
    image: jc21/nginx-proxy-manager:latest
    restart: always
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - /opt/npm/data:/data
      - /opt/npm/letsencrypt:/etc/letsencrypt
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "${DB_PASS}"
      DB_MYSQL_NAME: "npm"

  db:
    image: mariadb:10.6
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: "${DB_PASS}"
      MYSQL_DATABASE: "npm"
      MYSQL_USER: "npm"
      MYSQL_PASSWORD: "${DB_PASS}"
    volumes:
      - /opt/npm/mysql:/var/lib/mysql
EOF

  msg_ok "Docker Compose stack created"

  msg_info "Starting Nginx Proxy Manager"
  cd /opt/npm && docker compose up -d
  msg_ok "Nginx Proxy Manager started"
}

start
build_container
description
deploy_script

msg_info "Setting Container to Normal Resources"
pct set $CTID -cores 1
msg_ok "Set Container to Normal Resources"

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable at:
         ${BL}http://${IP}:81${CL}\n"
