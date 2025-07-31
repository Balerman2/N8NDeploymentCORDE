#!/bin/bash

set -e

# Define base directory
BASE_DIR="/opt/n8n"

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Install Docker & Compose
apt update && apt install -y docker.io docker-compose
systemctl enable docker && systemctl start docker

# Create folders
mkdir -p "$BASE_DIR/traefik"
cd "$BASE_DIR"

# Create .env.template
cat <<EOF > .env.template
# --- n8n Core ---
N8N_PORT=5678
N8N_PROTOCOL=https
N8N_HOST=n8n.corde.nz
N8N_EDITOR_BASE_URL=https://n8n.corde.nz
GENERIC_TIMEZONE=Pacific/Auckland

# --- Postgres DB ---
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=n8n-db
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=REPLACE_DB_PASSWORD

# --- Redis Queue ---
QUEUE_MODE=redis
QUEUE_REDIS_HOST=n8n-redis
QUEUE_REDIS_PORT=6379

# --- Azure AD OIDC ---
N8N_AUTH_ENABLE=true
N8N_AUTH_TYPE=oauth2
N8N_AUTH_OAUTH2_CLIENT_ID=REPLACE_CLIENT_ID
N8N_AUTH_OAUTH2_CLIENT_SECRET=REPLACE_CLIENT_SECRET
N8N_AUTH_OAUTH2_AUTHORIZE_URL=https://login.microsoftonline.com/REPLACE_TENANT_ID/oauth2/v2.0/authorize
N8N_AUTH_OAUTH2_TOKEN_URL=https://login.microsoftonline.com/REPLACE_TENANT_ID/oauth2/v2.0/token
N8N_AUTH_OAUTH2_CALLBACK_URL=https://n8n.corde.nz/rest/login
N8N_AUTH_OAUTH2_SCOPE=openid profile email

# --- Encryption ---
N8N_ENCRYPTION_KEY=REPLACE_32_BYTE_HEX
N8N_DIAGNOSTICS_ENABLED=false
N8N_DISABLE_PRODUCTION_MAIN_MENU=true

# --- SMTP (Office 365) ---
N8N_SMTP_HOST=smtp.office365.com
N8N_SMTP_PORT=587
N8N_SMTP_USER=noreply@corde.nz
N8N_SMTP_PASS=REPLACE_SMTP_PASSWORD
N8N_SMTP_SENDER=noreply@corde.nz
EOF

# Create docker-compose.yml
cat <<EOF > docker-compose.yml
version: '3.8'
services:

  traefik:
    image: traefik:v2.11
    command:
      - --providers.docker=true
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.le.acme.httpchallenge=true
      - --certificatesresolvers.le.acme.httpchallenge.entrypoint=web
      - --certificatesresolvers.le.acme.email=it-admin@corde.nz
      - --certificatesresolvers.le.acme.storage=/acme.json
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/acme.json:/acme.json
    restart: unless-stopped

  n8n:
    image: docker.n8n.io/n8nio/n8n
    env_file:
      - .env
    volumes:
      - n8n_data:/home/node/.n8n
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.n8n.rule=Host(\`n8n.corde.nz\`)"
      - "traefik.http.routers.n8n.entrypoints=websecure"
      - "traefik.http.routers.n8n.tls.certresolver=le"
    depends_on:
      - n8n-db
      - n8n-redis
    restart: unless-stopped

  n8n-db:
    image: postgres:15
    environment:
      POSTGRES_USER: \${DB_POSTGRESDB_USER}
      POSTGRES_PASSWORD: \${DB_POSTGRESDB_PASSWORD}
      POSTGRES_DB: \${DB_POSTGRESDB_DATABASE}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  n8n-redis:
    image: redis:6-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  n8n_data:
  postgres_data:
  redis_data:
EOF

# Create Traefik ACME storage
touch "$BASE_DIR/traefik/acme.json"
chmod 600 "$BASE_DIR/traefik/acme.json"

# Output
cat <<NOTE

Bootstrap complete.

1. Navigate to $BASE_DIR
2. Copy .env.template to .env and fill in all REPLACE_* values
3. Run: docker compose up -d
4. Access n8n at: https://n8n.corde.nz

NOTE
