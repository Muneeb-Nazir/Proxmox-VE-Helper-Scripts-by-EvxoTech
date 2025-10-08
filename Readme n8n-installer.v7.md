 **clean and professional `README.md`** 

---

````markdown
# 🚀 Smart n8n Proxmox Installer (v2)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Proxmox](https://img.shields.io/badge/Proxmox-8.1%2B-orange.svg)
![n8n](https://img.shields.io/badge/n8n-Automation-red.svg)
![AI](https://img.shields.io/badge/AI-ready-green.svg)

> Developed by **EvxoTech (Muneeb Nazir)** — a smart, flexible, and AI-integrated automation setup for **n8n** running inside a Proxmox LXC.

---

🧠 EvxoTech — n8n + Laravel LXC Auto Installer for Proxmox 8.x

This script automates the full setup of a n8n automation platform with optional Laravel Admin Panel + NGINX + MariaDB + PHP-FPM inside a single Proxmox LXC container — all in one command.

It’s built on tteck’s Proxmox Helper Framework
 and updated for Proxmox VE 8.1 → 8.5+.

🚀 Features

✅ Auto-detects storage and bridge
✅ Supports Proxmox VE 8.1 → 8.5+ (bypass built-in restrictions)
✅ Installs n8n via Node.js + npm
✅ Optional Laravel + NGINX stack
✅ MariaDB + PHP + Composer preinstalled
✅ Automatic systemd service for n8n
✅ Optional HTTPS via Let’s Encrypt (future extension)
✅ No spinner or unbound variable errors
✅ Clean colorized installer output

🧩 Stack Components
Component	Purpose	Notes
n8n	Workflow automation & AI integration platform	Installed globally via npm install -g n8n
Laravel	PHP admin panel or API backend	Optional (installed in /var/www/laravel-app)
NGINX	Web server for Laravel	Auto-configured
MariaDB	Database for Laravel / n8n	Local service
PHP-FPM	FastCGI for Laravel	Installed & enabled
Node.js / npm	Core runtime for n8n	Installed via apt or NodeSource
Systemd Service	Persistent n8n daemon	/etc/systemd/system/n8n.service
⚙️ Usage
1️⃣ Clone the repo or download script
cd /root/scripts
wget https://raw.githubusercontent.com/Muneeb-Nazir/Proxmox-VE-Helper-Scripts-by-EvxoTech/main/n8n-installer-v7.sh
chmod +x n8n-installer-v7.sh

2️⃣ Run the script as root in the Proxmox shell
./n8n-proxmox-v7.sh

3️⃣ Follow the prompts

The installer will ask for:

Storage (auto-detected from your Proxmox pools)

Bridge (default vmbr0)

Container ID (next available by default)

Disk size (e.g. 20G)

Root password for the container

Option to install Laravel + Nginx

Optional AI provider integration (future-ready)

🖥️ Example Output
⚙️  Compatible Proxmox VE version 8.4 detected (bypass active)
🔄 Loading installer environment...
✅ Creating LXC Container ID 102
🧩 Installing packages inside container...
✅ n8n service installed and started
✅ Laravel installed in /var/www/laravel-app

🌐 Access URLs
Service	URL	Notes
n8n	http://<container-ip>:5678	Web automation UI
Laravel App	http://<container-ip>/	PHP admin dashboard
MariaDB	localhost:3306	Accessible internally
SSH / Shell	pct enter <ctid>	Manage directly
🧠 Example: Systemd Service (inside container)
[Unit]
Description=n8n daemon
After=network.target

[Service]
ExecStart=/usr/bin/n8n
Restart=always
User=root
WorkingDirectory=/root
Environment=GENERIC_TIMEZONE=Asia/Karachi

[Install]
WantedBy=multi-user.target

🛠️ Maintenance
Update n8n
pct exec <ctid> -- bash -c "npm update -g n8n && systemctl restart n8n"

Update Laravel
pct exec <ctid> -- bash -c "cd /var/www/laravel-app && git pull && composer update"

Backup Container
vzdump <ctid> --compress zstd

🔒 Optional SSL via Let’s Encrypt (future)

You can easily extend your install script to include:

apt install certbot python3-certbot-nginx -y
certbot --nginx


This will auto-provision HTTPS for both Laravel and n8n.

🧩 Credits

EvxoTech — Installer logic, Laravel integration, and AI backend hooks

tteck — Original Proxmox LXC Helper Framework

n8n.io — Open Source Automation Platform

Laravel — PHP framework powering the backend

🧾 License

This script is released under the MIT License — feel free to use, modify, and distribute with attribution.

💬 Support

For issues or feature requests:

Open a GitHub issue on EvxoTech’s Proxmox Helper Scripts Repo

Or ping in your DevOps team’s internal Slack/Discord

