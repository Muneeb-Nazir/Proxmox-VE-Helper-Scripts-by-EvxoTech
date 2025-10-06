**full smart one-click n8n Proxmox LXC installer** that:

* 💬 Asks which OS you want (Debian 11, Debian 12, or Ubuntu 24.04)
* 🔑 Asks for root password for the container
* 🧠 Auto-detects storage and available CT ID
* 📦 Automatically downloads template if missing
* ⚙️ Creates and configures the container
* 🚀 Installs **Node.js**, **n8n**, and sets up a **systemd service**
* 🌐 Auto-starts n8n on port `5678`
* ✅ Displays connection info after install

---

### ⚡ Final Version 1: `n8n-proxmox-v1.sh`

```bash
#!/usr/bin/env bash
# ==============================================
# EvxoTech Smart n8n LXC Auto-Installer
# Supports: Debian 11 / Debian 12 / Ubuntu 24.04
# ==============================================

set -e

# ----- Colors -----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

function msg() { echo -e "${CYAN}$1${NC}"; }
function ok() { echo -e "${GREEN}$1${NC}"; }
function warn() { echo -e "${YELLOW}$1${NC}"; }
function err() { echo -e "${RED}$1${NC}" >&2; }

clear
echo "====================================="
echo " EvxoTech Smart n8n Proxmox Installer"
echo "====================================="
echo ""

# ----- OS Choice -----
echo "Select OS for LXC:"
echo "1) Debian 11"
echo "2) Debian 12"
echo "3) Ubuntu 24.04"
echo ""
read -rp "Enter choice [1-3]: " os_choice

case $os_choice in
  1)
    OS="debian-11"
    TEMPLATE_NAME="debian-11-standard_11.7-1_amd64.tar.zst"
    ;;
  2)
    OS="debian-12"
    TEMPLATE_NAME="debian-12-standard_12.7-1_amd64.tar.zst"
    ;;
  3)
    OS="ubuntu-24.04"
    TEMPLATE_NAME="ubuntu-24.04-standard_24.04-1_amd64.tar.zst"
    ;;
  *)
    err "Invalid choice. Exiting."
    exit 1
    ;;
esac

# ----- Password -----
read -rsp "Enter root password for inside LXC: " LXC_PASS
echo ""

# ----- Detect Storage -----
msg "🔍 Detecting available Proxmox storages..."
STORAGE=$(pvesm status | awk 'NR>1 {print $1; exit}')
if [ -z "$STORAGE" ]; then
  err "No valid storage found!"
  exit 1
fi
ok "✅ Using storage: $STORAGE"

# ----- Check Template -----
msg "📦 Checking LXC templates..."
TEMPLATE_PATH="/var/lib/vz/template/cache/$TEMPLATE_NAME"
if [ ! -f "$TEMPLATE_PATH" ]; then
  ok "Downloading $TEMPLATE_NAME ..."
  pveam update
  pveam download local "$TEMPLATE_NAME"
else
  ok "✅ Template already exists."
fi

# ----- Assign ID -----
NEXTID=$(pvesh get /cluster/nextid)
ok "🔢 Assigned Container ID: $NEXTID"

# ----- Create Container -----
msg "🚀 Creating LXC container..."
pct create "$NEXTID" "local:vztmpl/$TEMPLATE_NAME" \
  -hostname n8n \
  -password "$LXC_PASS" \
  -storage "$STORAGE" \
  -rootfs 8G \
  -cores 2 \
  -memory 2048 \
  -net0 name=eth0,bridge=vmbr0,ip=dhcp \
  -unprivileged 1

ok "✅ LXC created successfully."
pct start "$NEXTID"
sleep 5

# ----- Install n8n -----
msg "⚙️ Installing n8n inside container..."
pct exec "$NEXTID" -- bash -c "
  apt update -y && apt upgrade -y
  apt install -y curl sudo gnupg build-essential

  # Install Node.js 20 LTS
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt install -y nodejs

  # Install n8n globally
  npm install -g n8n

  # Create n8n systemd service
  cat <<EOF > /etc/systemd/system/n8n.service
[Unit]
Description=n8n Automation Tool
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/n8n
Restart=on-failure
User=root
Environment=PATH=/usr/bin:/usr/local/bin
Environment=HOME=/root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable n8n
  systemctl start n8n
"

# ----- Get IP -----
LXC_IP=$(pct exec "$NEXTID" ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}' || true)

# ----- Output Info -----
echo ""
ok "🎉 Installation complete!"
msg "========================================"
msg "  🆔 Container ID: $NEXTID"
msg "  🌐 IP Address: ${LXC_IP:-DHCP Pending}"
msg "  ⚙️  OS: $OS"
msg "  🔑 Username: root"
msg "  🔒 Password: (your entered password)"
msg "  🚀 Access n8n: http://${LXC_IP:-<your-lxc-ip>}:5678"
msg "  🔧 Enter shell: pct enter $NEXTID"
msg "========================================"
ok "✅ n8n is now running and enabled at boot."
```

---

### 🧩 To Use It

```bash
chmod +x n8n-proxmox.sh
./n8n-proxmox.sh
```

---

### 🌟 Features

✅ Smart OS selection (Debian 11 / 12 / Ubuntu 24.04)
✅ Auto-template download
✅ Auto-storage detection
✅ Password prompt
✅ Full Node.js + n8n setup
✅ Systemd autostart
✅ Prints IP + access info

---

