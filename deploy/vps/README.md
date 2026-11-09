# OpenReply on your own VPS

Runs everything on one Ubuntu server with Docker: Postgres, Redis, the web app,
the worker, the cron scheduler and Caddy for automatic HTTPS. No Vercel or
Railway. Instagram connects through Zernio (saved later in Settings), so no
Meta variables are needed.

## Requirements

- Ubuntu with Docker and the compose plugin (`docker compose version`)
- Ports 80 and 443 free and open in the cloud firewall (Tencent Cloud security group)
- About 2 GB of free RAM for the first build (add swap if short, see below)
- A verified sender in Resend, or your own SMTP server, for login emails

## First start

```bash
git clone https://github.com/jetveetlev/openreplyfork.git ~/openreply
cd ~/openreply/deploy/vps
bash setup.sh            # creates .env with fresh secrets and a sslip.io domain
nano .env                # fill RESEND_API_KEY, EMAIL_FROM, ALLOWED_EMAILS (and DOMAIN if you use a subdomain)
docker compose up -d --build
```

The first build takes several minutes. Then open `https://<DOMAIN>/api/health`
and look for `status: ok` and `worker.healthy: true`.

## Connect Instagram (Zernio)

Sign in at `https://<DOMAIN>`, open Settings, save your Zernio API key
(unrestricted, read/write, Inbox access), select your profile and import the
Instagram account. Create campaigns in OpenReply only, never in Zernio.

## Everyday commands

```bash
cd ~/openreply/deploy/vps
docker compose ps                     # status
docker compose logs -f worker         # watch DM sending
docker compose logs -f web caddy      # web app and HTTPS
docker compose restart worker
```

## Update

```bash
cd ~/openreply && git pull
cd deploy/vps && docker compose up -d --build
```

Migrations run automatically when the web container starts.

## Backup

```bash
cd ~/openreply/deploy/vps
docker compose exec -T postgres pg_dump -U openreply openreply | gzip > ~/openreply-$(date +%F).sql.gz
```

Keep a copy of `.env` somewhere safe too. Losing `ENCRYPTION_KEY` means
reconnecting every account.

## Changing the domain

Edit `DOMAIN` in `.env`, run `docker compose up -d`, then reconfigure the
Zernio connection in Settings so its webhook points at the new URL.

## Low on RAM

```bash
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```
