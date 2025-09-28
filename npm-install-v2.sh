#!/usr/bin/env bash
# Patched Proxmox Helper Script - Nginx Proxy Manager (Docker + MariaDB)
# Copyright (c) 2025 Evxo Technologies.com
# Author: Evxo Tech
# License: MIT

# Source original helper functions (keeps UI & LXC creation logic)
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)

# --- PATCH: Override the pve_check function to allow 8.1 and newer ---
pve_check() {
  if ! pveversion | grep -Eq "pve-manager/8\.[1-9]|pve-manager/8\.[1-9][0-9]"; then
    msg_error "This version of Proxmox Virtual Environment is not supported"
    echo -e "Requires Proxmox Virtual Environment Version 8.1 or later."
    echo -e "Exiting..."
    sleep 2
    exit
  fi
}

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
var_disk="16"
var_cpu="2"
var_ram="2048"
var_os="ubuntu"
var_version="24.04"

# initialize variables, colors, error handling from build.func
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"             # Privileged container by default for Docker
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

# Keep existing update_script if needed (unchanged)
function update_script() {
  header_info
  if [[ ! -f /lib/systemd/system/npm.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox --title "SET RESOURCES" "Please set the resources in your ${APP} LXC to ${var_cpu}vCPU and ${var_ram}RAM for the build process before continuing" 10 75
  if ! command -v pnpm &> /dev/null; then  
    msg_info "Installing pnpm"
    npm install -g pnpm@8.15 &>/dev/null
    msg_ok "Installed pnpm"
  fi
  RELEASE=$(curl -s https://api.github.com/repos/NginxProxyManager/nginx-proxy-manager/releases/latest |
    grep "tag_name" |
    awk '{print substr($2, 3, length($2)-4) }')
  msg_info "Stopping Services"
  systemctl stop openresty || true
  systemctl stop npm || true
  msg_ok "Stopped Services"

  msg_info "Cleaning Old Files"
  rm -rf /app \
    /var/www/html \
    /etc/nginx \
    /var/log/nginx \
    /var/lib/nginx \
    /var/cache/nginx &>/dev/null || true
  msg_ok "Cleaned Old Files"

  msg_info "Downloading NPM v${RELEASE}"
  wget -q https://codeload.github.com/NginxProxyManager/nginx-proxy-manager/tar.gz/v${RELEASE} -O - | tar -xz &>/dev/null || true
  cd nginx-proxy-manager-${RELEASE} 2>/dev/null || true
  msg_ok "Downloaded NPM v${RELEASE}"

  # note: the original update flow modifies openresty bits; we keep it for compatibility
  msg_info "Setting up Enviroment"
  ln -sf /usr/bin/python3 /usr/bin/python || true
  ln -sf /usr/bin/certbot /opt/certbot/bin/certbot || true
  ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx || true
  ln -sf /usr/local/openresty/nginx/ /etc/nginx || true
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" backend/package.json 2>/dev/null || true
  sed -i "s|\"version\": \"0.0.0\"|\"version\": \"$RELEASE\"|" frontend/package.json 2>/dev/null || true
  sed -i 's|"fork-me": ".*"|"fork-me": "Proxmox VE Helper-Scripts"|' frontend/js/i18n/messages.json 2>/dev/null || true
  sed -i "s|https://github.com.*source=nginx-proxy-manager|https://helper-scripts.com|g" frontend/js/app/ui/footer/main.ejs 2>/dev/null || true
  sed -i 's+^daemon+#daemon+g' docker/rootfs/etc/nginx/nginx.conf 2>/dev/null || true
  NGINX_CONFS=$(find "$(pwd)" -type f -name "*.conf" 2>/dev/null || true)
  for NGINX_CONF in $NGINX_CONFS; do
    sed -i 's+include conf.d+include /etc/nginx/conf.d+g' "$NGINX_CONF" 2>/dev/null || true
  done
  mkdir -p /var/www/html /etc/nginx/logs 2>/dev/null || true
  cp -r docker/rootfs/var/www/html/* /var/www/html/ 2>/dev/null || true
  cp -r docker/rootfs/etc/nginx/* /etc/nginx/ 2>/dev/null || true
  cp docker/rootfs/etc/letsencrypt.ini /etc/letsencrypt.ini 2>/dev/null || true
  cp docker/rootfs/etc/logrotate.d/nginx-proxy-manager /etc/logrotate.d/nginx-proxy-manager 2>/dev/null || true
  ln -sf /etc/nginx/nginx.conf /etc/nginx/conf/nginx.conf 2>/dev/null || true
  rm -f /etc/nginx/conf.d/dev.conf 2>/dev/null || true
  mkdir -p /tmp/nginx/body \
    /run/nginx \
    /data/nginx \
    /data/custom_ssl \
    /data/logs \
    /data/access \
    /data/nginx/default_host \
    /data/nginx/default_www \
    /data/nginx/proxy_host \
    /data/nginx/redirection_host \
    /data/nginx/stream \
    /data/nginx/dead_host \
    /data/nginx/temp \
    /var/lib/nginx/cache/public \
    /var/lib/nginx/cache/private \
    /var/cache/nginx/proxy_temp 2>/dev/null || true
  chmod -R 777 /var/cache/nginx 2>/dev/null || true
  chown root /tmp/nginx 2>/dev/null || true
  echo resolver "$(awk 'BEGIN{ORS=" "} $1=="nameserver" {print ($2 ~ ":")? "["$2"]": $2}' /etc/resolv.conf);" >/etc/nginx/conf.d/include/resolvers.conf 2>/dev/null || true
  if [ ! -f /data/nginx/dummycert.pem ] || [ ! -f /data/nginx/dummykey.pem ]; then
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj "/O=Nginx Proxy Manager/OU=Dummy Certificate/CN=localhost" -keyout /data/nginx/dummykey.pem -out /data/nginx/dummycert.pem &>/dev/null || true
  fi
  mkdir -p /app/global /app/frontend/images 2>/dev/null || true
  cp -r backend/* /app 2>/dev/null || true
  cp -r global/* /app/global 2>/dev/null || true
  python3 -m pip install --no-cache-dir certbot-dns-cloudflare &>/dev/null || true
  msg_ok "Setup Enviroment"

  # build frontend if present
  if [ -d "./frontend" ]; then
    msg_info "Building Frontend"
    cd ./frontend
    pnpm install &>/dev/null || true
    pnpm upgrade &>/dev/null || true
    pnpm run build &>/dev/null || true
    cp -r dist/* /app/frontend 2>/dev/null || true
    cp -r app-images/* /app/frontend/images 2>/dev/null || true
    msg_ok "Built Frontend"
  fi

  msg_info "Initializing Backend"
  rm -rf /app/config/default.json &>/dev/null || true
  if [ ! -f /app/config/production.json ]; then
    cat <<'EOF' >/app/config/production.json
{
  "database": {
    "engine": "knex-native",
    "knex": {
      "client": "sqlite3",
      "connection": {
        "filename": "/data/database.sqlite"
      }
    }
  }
}
EOF
  fi
  cd /app 2>/dev/null || true
  pnpm install &>/dev/null || true
  msg_ok "Initialized Backend"

  msg_info "Starting Services (openresty/npm if present)"
  systemctl enable -q --now openresty 2>/dev/null || true
  systemctl enable -q --now npm 2>/dev/null || true
  msg_ok "Started Services (if available)"

  msg_info "Cleaning up"
  rm -rf ~/nginx-proxy-manager-* 2>/dev/null || true
  msg_ok "Cleaned"

  msg_ok "Updated Successfully"
  exit
}

# build_container from build.func will create and start the LXC
start
build_container
description

# --------------------------
# POST-INSTALL: run inside the LXC to install Docker & deploy NPM + MariaDB
# --------------------------
msg_info "Preparing post-install script for inside LXC"
# Create the installer script content and write it inside the container using pct exec and here-doc
cat <<'INTERNAL' | pct exec "$CTID" -- bash -c 'cat > /root/npm-install-inside.sh && chmod +x /root/npm-install-inside.sh'
#!/usr/bin/env bash
set -euo pipefail

# Run inside the container as root
export DEBIAN_FRONTEND=noninteractive

echo "===== Updating OS ====="
apt-get update -y
apt-get upgrade -y

echo "===== Installing prerequisites ====="
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

echo "===== Adding Docker APT repository ====="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y

echo "===== Installing Docker CE and compose plugin ====="
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Ensure Docker systemd service is enabled and started
systemctl enable --now docker

# Create directories for persistent data
mkdir -p /opt/npm/data /opt/npm/letsencrypt

cat > /opt/npm/docker-compose.yml <<'YML'
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
YML

echo "===== Starting Nginx Proxy Manager stack ====="
cd /opt/npm
# Use the docker-compose plugin (docker compose)
docker compose up -d

echo "===== Completed NPM install inside container ====="
echo "Access URL: http://${IP}:81 (replace ${IP} with container IP if needed)"
INTERNAL

msg_ok "Wrote post-install script to container"

# Execute the post install inside the container
msg_info "Executing post-install inside container (this may take several minutes)"
pct exec "$CTID" -- bash -c "/root/npm-install-inside.sh" || {
  msg_error "Post-install script failed inside container. Check container logs and /root/npm-install-inside.sh"
  exit 1
}
msg_ok "Post-install complete"

# Set container to normal resources after building
msg_info "Setting Container to Normal Resources"
pct set $CTID -cores 1 -memory $var_ram &>/dev/null || true
msg_ok "Set Container to Normal Resources"

msg_ok "Completed Successfully!\n"
# Attempt to obtain IP for user feedback
IP=$(pct exec "$CTID" -- bash -c "ip -4 addr show eth0 | awk '/inet / {print \$2}' | cut -d/ -f1" 2>/dev/null || echo "UNKNOWN")
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:81${CL}\n"
