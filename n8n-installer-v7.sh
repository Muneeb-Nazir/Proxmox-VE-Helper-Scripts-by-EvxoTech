#!/usr/bin/env bash
# ===========================================================
# EvxoTech n8n + Laravel Installer for Proxmox 8.x (8.1â€“8.5+)
# Based on tteck build.func helper, with safe 8.4 bypass
# ===========================================================

APP="n8n"
source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)

# --- Override the strict Proxmox version check (supports 8.1â€“8.5+) ---
pve_check() {
  if command -v pveversion >/dev/null 2>&1; then
    PVE_VER=$(pveversion | grep -oP 'pve-manager/\K[0-9]+\.[0-9]+')
    echo "âš™ï¸  Compatible Proxmox VE version $PVE_VER detected (bypass active)."
  else
    echo "âš ï¸  Not running inside Proxmox VE, proceeding anyway."
  fi
}

# --- Spinner safety patch ---
if [ -z "${SPINNER_PID+x}" ]; then
  SPINNER_PID=""
fi
stop_spinner() {
  if [[ -n "$SPINNER_PID" ]] && kill -0 "$SPINNER_PID" 2>/dev/null; then
    kill "$SPINNER_PID" >/dev/null 2>&1 || true
    wait "$SPINNER_PID" 2>/dev/null || true
  fi
  echo -ne "\r\033[K"
}

# --- Header banner ---
function header_info() {
  clear
  cat <<"EOF"
 _   _     _      
| \ | |   (_)     
|  \| |___ _ _ __ 
| . ` / _ \ | '_ \
| |\  |  __/ | | | |
|_| \_|\___|_|_| |_|
------------------------------------------
      EvxoTech n8n + Laravel Installer
------------------------------------------
EOF
}
header_info
echo -e "ðŸ”„ Loading installer environment..."

# ---------------- BASE VARIABLES ----------------
var_disk="8"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"

variables
color
catch_errors

# ---------------- DEFAULT SETTINGS ----------------
function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG=$(grep -m1 "vmbr" /etc/network/interfaces | awk '{print $2}' | cut -d'/' -f1)
  BRG=${BRG:-vmbr0}
  NET="dhcp"
  GATE=""
  SSH="no"
  VERB="no"
  echo_default
}

# ---------------- UPDATE HANDLER ----------------
function update_script() {
  header_info
  if [[ ! -f /etc/systemd/system/n8n.service ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi
  if ! command -v npm >/dev/null 2>&1; then
    msg_info "Installing NPM..."
    apt-get install -y npm >/dev/null 2>&1
    msg_ok "Installed NPM"
  fi
  msg_info "Updating ${APP} inside LXC..."
  npm update -g n8n &>/dev/null
  systemctl restart n8n
  msg_ok "n8n updated successfully!"
  exit
}

# ---------------- MAIN INSTALL FLOW ----------------
start
build_container

msg_info "Configuring services inside container..."
pct exec "$CTID" -- bash -c "apt-get update && apt-get install -y nginx mariadb-server php php-fpm php-mysql unzip curl git"

# --- Install n8n ---
pct exec "$CTID" -- bash -c "npm install -g n8n"
pct exec "$CTID" -- bash -c "cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n daemon
After=network.target

[Service]
ExecStart=/usr/bin/n8n
Restart=always
User=root
Environment=GENERIC_TIMEZONE=$(cat /etc/timezone)
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable n8n && systemctl start n8n"
msg_ok "n8n service installed and started."

# --- Optional Laravel installation ---
if whiptail --backtitle "EvxoTech Installer" --yesno "Install Laravel + Nginx inside same container?" 10 60; then
  msg_info "Installing Laravel stack..."
  pct exec "$CTID" -- bash -c "cd /var/www && git clone https://github.com/laravel/laravel.git laravel-app \
    && cd laravel-app && composer install && php artisan key:generate"
  msg_ok "Laravel installed in /var/www/laravel-app"
else
  msg_info "Skipping Laravel installation."
fi

description

msg_ok "âœ… Installation completed successfully!"
IP=$(pct exec "$CTID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
echo -e "\n${APP} reachable at: ${BL}http://${IP}:5678${CL}\n"
echo -e "Laravel (if installed) reachable at: ${BL}http://${IP}${CL}\n"
