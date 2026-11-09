#!/usr/bin/env bash
# Creates deploy/vps/.env with fresh secrets. Secrets are generated on the VPS
# and never leave it. Safe to re-run: it refuses to overwrite an existing .env.
set -euo pipefail
cd "$(dirname "$0")"

if [ -f .env ]; then
  echo ".env already exists, not touching it. Edit it with: nano $(pwd)/.env"
  exit 0
fi

IP=$(curl -4 -s --max-time 5 ifconfig.me || true)
DEFAULT_DOMAIN=${IP:+${IP//./-}.sslip.io}

umask 077
cat > .env <<EOF
# Public hostname, no https://. Either a subdomain pointed at this VPS
# (e.g. reply.kelascinta.com) or the free sslip.io name below.
DOMAIN=${DEFAULT_DOMAIN:-CHANGE_ME}

# Generated secrets. Keep ENCRYPTION_KEY forever: changing it disconnects accounts.
NEXTAUTH_SECRET=$(openssl rand -base64 32)
CRON_SECRET=$(openssl rand -base64 32)
ENCRYPTION_KEY=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -hex 24)

# Login email (magic links). Fill these in.
RESEND_API_KEY=
EMAIL_FROM=OpenReply <login@your-verified-domain>
# Or use your own SMTP instead of Resend:
# EMAIL_SERVER=smtps://user%40example.com:password@mail.example.com:465

# Only these addresses can sign in.
ALLOWED_EMAILS=
EOF

echo "Created $(pwd)/.env (domain: ${DEFAULT_DOMAIN:-CHANGE_ME})"
echo "Next: nano $(pwd)/.env  -> fill RESEND_API_KEY, EMAIL_FROM, ALLOWED_EMAILS"
echo "Then: docker compose up -d --build"
