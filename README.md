# n8n Deployment for CORDE (Secure, High Availability, On-Prem)

This repo contains everything needed to deploy a secure, production-ready, high-availability instance of [n8n](https://n8n.io/) inside CORDE’s infrastructure.

## 🌐 Public Access: https://n8n.corde.nz

This setup supports:
- Azure AD Single Sign-On (SSO)
- TLS (HTTPS) via Let's Encrypt
- Redis-based queue mode for HA
- PostgreSQL for data storage
- Microsoft 365 SMTP for email
- Docker-based stack

---

## 🔧 Setup Instructions

### 1. Requirements
- Ubuntu 20.04 or later (root access required)
- Docker and Docker Compose (installed automatically)
- DNS entry for `n8n.corde.nz` pointing to your public IP
- Ports 80 and 443 open in firewall

---

### 2. Deploy via Bootstrap Script

**Run these commands on your server:**

```bash
cd /opt && git clone https://github.com/Balerman2/N8NDeploymentCORDE.git n8n && cd n8n
sudo bash bootstrap-n8n.sh
```

This will:
- Install Docker and Compose
- Create folder structure
- Drop in `.env.template`, `docker-compose.yml`, and Traefik config

---

### 3. Fill in Secrets

```bash
cd /opt/n8n
cp .env.template .env
nano .env
```

Fill in all `REPLACE_*` values:
- Azure AD tenant/client info
- Encryption key (`openssl rand -hex 32`)
- PostgreSQL password
- SMTP password (App Password from Microsoft 365)

---

### 4. Start the Stack

```bash
docker compose up -d
```

Wait ~1 minute, then visit:
```
https://n8n.corde.nz
```
You’ll be redirected to Microsoft login.

---

## 📦 Files

| File                | Purpose                                  |
|---------------------|------------------------------------------|
| `.env.template`     | Config template with all needed settings |
| `bootstrap-n8n.sh`  | Full install and setup script            |
| `docker-compose.yml`| Runs n8n, Redis, Postgres, Traefik       |
| `traefik/acme.json` | Stores TLS certs (auto-created)          |
| `backup.sh`         | Daily PostgreSQL backup (30-day retention) |
| `healthcheck.sh`    | Lightweight HTTP healthcheck endpoint    |
| `.gitignore`        | Prevents secrets/backups from being committed |

---

## 🔐 Security Notes

- Traefik handles HTTPS using Let’s Encrypt (HTTP challenge)
- n8n secured behind Azure AD login
- Credentials and env variables encrypted with `N8N_ENCRYPTION_KEY`
- PostgreSQL and Redis are internal-only

---

## 🛠 Maintenance Tips

### Restart n8n:
```bash
cd /opt/n8n && docker compose restart
```

### View Logs:
```bash
docker compose logs -f
```

### Backup DB:
```bash
/opt/n8n/backup.sh
```

Backups are stored in `/opt/n8n/backups/` and auto-cleaned after 30 days.

---

## 🩺 Healthcheck Endpoint (optional)

If you want uptime monitoring:
- Create a new workflow in n8n with a **Webhook** node at `/healthz`
- Add a simple Set node returning `{ "status": "ok" }`
- Use this URL in your monitoring tool:

```
https://n8n.corde.nz/webhook/healthz
```

---

## 📬 Email Setup (Microsoft 365)

Use a mailbox like `noreply@corde.nz`. Set up an **App Password** (if MFA is enabled) and paste it into `.env`.

SMTP Settings:
```
Host: smtp.office365.com
Port: 587
TLS: Yes
```

---

## ✅ Done!

You now have a secure, production-grade, HA n8n instance running with minimal effort. For support, raise a GitHub issue or contact the IT team.

Thanks!

Originally developed by Jack Gillians for internal CORDE use.
Maintained by the CORDE IT team.