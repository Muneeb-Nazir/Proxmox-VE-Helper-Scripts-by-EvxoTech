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

## ✨ Features

✅ **Works on Proxmox VE 8.1 to 8.5+**  
✅ **Supports Debian 11, Debian 12, and Ubuntu 24.04**  
✅ **Automatic password setup for root user**  
✅ **Installs and configures n8n automatically**  
✅ **AI Agent-ready (Hugging Face, OpenAI, Anthropic, Ollama)**  
✅ **Optional SSL setup**  
✅ **Multi-user ready structure (future admin panel)**  
✅ **Simple and clean interface — no external dependencies**

---

## 🧩 Prerequisites

- Proxmox VE **v8.1 or higher**
- Internet connection for downloading templates
- Storage pool (e.g., `local-lvm`) available
- Root shell access to Proxmox host

---

## ⚙️ Installation

1. **Download the script:**
   ```bash
   wget https://raw.githubusercontent.com/Muneeb-Nazir/Proxmox-VE-Helper-Scripts-by-EvxoTech/main/n8n-proxmox-v2.sh
   chmod +x n8n-proxmox-v2.sh
````

2. **Run the installer:**

   ```bash
   ./n8n-proxmox-v2.sh
   ```

3. **Follow the prompts:**

   * Enter your **LXC root password**
   * Select your preferred **base OS**
   * Choose an **AI backend** (optional)
   * Decide whether to **enable SSL setup**

---

## 🧠 AI Integration Options

During setup, you’ll be prompted to choose an AI backend:

| Option                     | Description                     |
| -------------------------- | ------------------------------- |
| **1️⃣ Hugging Face**       | Default and free-friendly       |
| **2️⃣ OpenAI / Anthropic** | Cloud-hosted premium LLM APIs   |
| **3️⃣ Ollama**             | Self-hosted local LLM engine    |
| **4️⃣ Skip**               | Continue without AI integration |

---

## 🔒 SSL Setup (Optional)

If you enable SSL:

* The script installs **Certbot**
* You’ll be prompted to set DNS/domain configuration manually
  *(ideal for Cloudflare + NGINX Reverse Proxy setups)*

If skipped, n8n will remain accessible via HTTP.

---

## 🌍 Access Information

After installation completes:

| Item              | Description                  |
| ----------------- | ---------------------------- |
| **Web Access**    | `http://<container_ip>:5678` |
| **Root Password** | As entered during setup      |
| **AI Backend**    | As selected                  |
| **Container ID**  | Auto-assigned by Proxmox     |
| **OS Version**    | Debian/Ubuntu as chosen      |

---

## 💡 Example Usage

### View running container

```bash
pct list
```

### Restart n8n service

```bash
pct exec <CTID> -- systemctl restart n8n
```

### Update n8n

```bash
pct exec <CTID> -- npm update -g n8n
```

---

## 🧩 Future Roadmap

* [ ] Web Admin UI for n8n flow management
* [ ] Built-in reverse proxy (NGINX Manager)
* [ ] Auto SSL via Let’s Encrypt
* [ ] Full AI Agent integration (Lindy-style orchestration)

---

## 🧑‍💻 Developer Notes

* Written in **Bash**
* Follows **Proxmox LXC best practices**
* Lightweight, stateless, and modular
* Can be extended for **Nextcloud**, **LLM WebUI**, or **license management systems**

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

### 💬 Author

**EvxoTech (Muneeb Nazir)**
💻 GitHub: [Muneeb-Nazir](https://github.com/Muneeb-Nazir)
🌐 Website: *Coming soon...*
🚀 “Automation meets Intelligence — the EvxoTech way.”

```

---


