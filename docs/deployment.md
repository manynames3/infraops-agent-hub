# Low-Cost Deployment Guide

This guide describes low-cost deployment paths for the InfraOps Agent Hub portfolio MVP. Keep it simple: start with the hosted static demo, then use one small VPS only when you need the full Docker Compose/n8n runtime.

Do not put real credentials in this repository. Use placeholders in docs and store real values only on the server in `.env` or a secret manager.

## Cheapest Hosted Demo Path

Use this first when you do not need a custom domain or always-on n8n:

```text
Cloudflare Pages
  index.html
  demo.html
  functions/api/run-demo-incident.js

Standard Postgres later
  Neon for optional low-cost hosted demo persistence
  AWS RDS or AWS-native storage for production/governance
```

Why this is the current cheapest path:

- No domain is required; use the `*.pages.dev` URL.
- No VPS is required for the buyer-facing demo.
- The hosted demo can render a full mock incident packet from repository sample data.
- Server-side persistence can be added behind the same standard Postgres audit schema.
- Neon is optional when the hosted demo needs persistent audit or workflow data without always-on database cost.
- AWS RDS or AWS-native storage remains the production/governance path when private networking, IAM integration, compliance posture, and operational controls matter.

Use `docs/database-portability.md` before wiring hosted audit writes.

Hosted Neon setup summary:

1. Create a Neon project and database.
2. Apply `audit-schema/postgres.sql` with `psql "$DATABASE_URL" -f audit-schema/postgres.sql`.
3. In Cloudflare Pages, set `DATABASE_PROVIDER=neon`.
4. Set `DATABASE_URL` to Neon's pooled connection string with `sslmode=require`.
5. Set `DATABASE_SSL_MODE=require`.
6. Set `ENABLE_HOSTED_AUDIT_WRITES=true` only after the schema is initialized.

## Docker Compose Path

Use one small VPS:

- AWS Lightsail Linux instance, or
- Another low-cost VPS from a provider you already trust.

Recommended starting size:

- 1-2 vCPU.
- 1-2 GB RAM.
- 40 GB or more SSD.
- Ubuntu LTS or Debian.

Use this path when you need n8n running outside your laptop, local Postgres volumes, or a fuller operations demo. The MVP does not need RDS, a load balancer, Kubernetes, or a search cluster for this stage.

## Architecture

```text
Internet
  |
  | HTTPS 443
  v
Caddy or Nginx on VPS
  |
  | localhost or Docker network
  v
n8n + Postgres via Docker Compose
  |
  v
Docker volumes: postgres_data, n8n_data
```

Public entry point:

- `https://infraops.example.com`

Private-only services:

- Postgres port `5432`.
- n8n container port `5678` when fronted by reverse proxy.
- Adminer should stay disabled unless temporarily accessed through SSH tunnel.

## Lightsail Setup

1. Create a small Linux/Unix Lightsail instance.
2. Attach a static IP so DNS does not change after restart.
3. Create an A record for `infraops.example.com` pointing to the static IPv4 address.
4. Open only required inbound firewall ports.
5. SSH into the instance and install Docker Engine plus Docker Compose plugin.

Recommended Lightsail firewall:

| Purpose | Protocol | Port | Source |
| --- | --- | --- | --- |
| SSH | TCP | 22 | Your current IP only |
| HTTP certificate challenge and redirect | TCP | 80 | `0.0.0.0/0`, `::/0` if IPv6 enabled |
| HTTPS app access | TCP | 443 | `0.0.0.0/0`, `::/0` if IPv6 enabled |

Do not expose:

- `5432` Postgres.
- `5678` n8n directly.
- `8080` Adminer.
- Docker daemon ports.

## Server Bootstrap

On the server:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git ufw
```

Install Docker and the Compose plugin using Docker's official Linux instructions for your distro. Verify:

```bash
docker --version
docker compose version
```

Clone the repository:

```bash
sudo mkdir -p /opt/infraops-agent-hub
sudo chown "$USER":"$USER" /opt/infraops-agent-hub
git clone <repo-url> /opt/infraops-agent-hub
cd /opt/infraops-agent-hub
```

Create server config:

```bash
cp config.example.env .env
chmod 600 .env
```

Edit `.env` on the server:

```text
INFRAOPS_ENV=production-demo
INFRAOPS_INTEGRATION_MODE=mock
INFRAOPS_HUMAN_APPROVAL_REQUIRED=true
INFRAOPS_ALLOW_PRODUCTION_ACTIONS=false

POSTGRES_PASSWORD=<generate-a-long-random-local-password>
N8N_BASIC_AUTH_USER=<operator-username>
N8N_BASIC_AUTH_PASSWORD=<generate-a-long-random-local-password>
N8N_ENCRYPTION_KEY=<generate-a-long-random-32-plus-character-value>

ENABLE_REAL_AWS_CALLS=false
ENABLE_REAL_GITHUB_CALLS=false
ENABLE_REAL_SLACK_CALLS=false
ENABLE_REAL_LLM_CALLS=false
```

Keep all real values out of Git.

## Docker Compose Deployment

Validate the Compose file:

```bash
docker compose config >/dev/null
```

Start core services:

```bash
docker compose up -d postgres n8n
docker compose ps
```

Apply the local audit schema if needed:

```bash
docker exec -i infraops-postgres psql -U infraops -d infraops_hub < audit-schema/postgres.sql
```

Check logs:

```bash
docker compose logs --tail=100 postgres
docker compose logs --tail=100 n8n
```

Run the local demo:

```bash
./scripts/run-local-demo.sh
```

Recommended Compose adjustment for a VPS:

- Bind n8n to localhost only, or
- Put n8n on a private Docker network and expose it only through Caddy/Nginx.

The current scaffold maps `5678` for local convenience. For an internet-facing VPS, do not leave n8n directly reachable on public port `5678`.

Minimal `docker-compose.prod.yml` override:

```yaml
services:
  n8n:
    ports:
      - "127.0.0.1:${N8N_PORT:-5678}:5678"
    environment:
      N8N_HOST: infraops.example.com
      N8N_PROTOCOL: https
      N8N_SECURE_COOKIE: "true"
      WEBHOOK_URL: https://infraops.example.com/
```

Run with:

```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d postgres n8n
```

## HTTPS Option A: Caddy

Caddy is the simplest option because it can manage HTTPS automatically when DNS points to the server and ports `80` and `443` are open.

Install Caddy, then create `/etc/caddy/Caddyfile`:

```caddyfile
infraops.example.com {
  encode gzip
  reverse_proxy 127.0.0.1:5678
}
```

Reload:

```bash
sudo caddy fmt --overwrite /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Use Caddy for the portfolio MVP unless you already operate Nginx. It is less configuration for automatic TLS.

## HTTPS Option B: Nginx

Nginx is fine if you prefer a familiar reverse proxy. Use Certbot or your existing certificate process for TLS.

Example server block after certificates exist:

```nginx
server {
    listen 80;
    server_name infraops.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name infraops.example.com;

    ssl_certificate /etc/letsencrypt/live/infraops.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/infraops.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:5678;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Do not run both Caddy and Nginx on ports `80` and `443` at the same time.

## Domain and DNS

For Lightsail:

1. Attach a static IP to the instance.
2. Create or use a DNS zone.
3. Add an A record for `infraops.example.com` to the static IPv4 address.
4. Optional: add an AAAA record only if you are intentionally using IPv6 and can keep it current.
5. Wait for DNS propagation before expecting HTTPS certificate issuance to succeed.

For another VPS:

1. Use the provider's fixed public IP or reserved IP.
2. Add an A record at your DNS provider.
3. Keep TTL short during setup if your DNS provider allows it.

## Host Firewall

Use both the cloud provider firewall and the host firewall.

Example `ufw` setup:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from <your-ip-address> to any port 22 proto tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

Do not allow public inbound access to Postgres, Adminer, or Docker.

For temporary database inspection, use SSH tunneling instead of opening ports:

```bash
ssh -L 15432:127.0.0.1:5432 <server-user>@infraops.example.com
```

## Backup Strategy

Back up two things:

- Postgres logical data.
- Docker volumes for n8n state.

Create a backup directory:

```bash
sudo mkdir -p /opt/infraops-agent-hub-backups
sudo chown "$USER":"$USER" /opt/infraops-agent-hub-backups
chmod 700 /opt/infraops-agent-hub-backups
```

Postgres logical backup:

```bash
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
docker exec infraops-postgres pg_dump -U infraops -d infraops_hub \
  > "/opt/infraops-agent-hub-backups/postgres-${timestamp}.sql"
gzip "/opt/infraops-agent-hub-backups/postgres-${timestamp}.sql"
```

n8n volume backup:

```bash
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
N8N_VOLUME="$(docker volume ls --format '{{.Name}}' | grep '_n8n_data$' | head -n 1)"
if [ -z "$N8N_VOLUME" ]; then
  echo "Could not find n8n_data volume. Check docker volume ls." >&2
  exit 1
fi
docker run --rm \
  -v "${N8N_VOLUME}:/data:ro" \
  -v /opt/infraops-agent-hub-backups:/backup \
  alpine tar -czf "/backup/n8n-data-${timestamp}.tgz" -C /data .
```

The exact n8n volume name depends on the Compose project name. Check it with `docker volume ls` if the command above does not find the expected volume.

Postgres volume backup is optional if logical `pg_dump` works. Prefer logical backups first because they are easier to inspect and restore across Postgres patch versions.

Backup rules:

- Keep at least 7 daily backups for a demo.
- Test restore once before calling the deployment stable.
- Copy backups off the instance if the data matters.
- Do not store backups in a public bucket.
- Do not include `.env` in routine artifact bundles unless encrypted.

Restore sketch:

```bash
docker compose down
docker compose up -d postgres
gunzip -c /opt/infraops-agent-hub-backups/postgres-<timestamp>.sql.gz \
  | docker exec -i infraops-postgres psql -U infraops -d infraops_hub
docker compose up -d n8n
```

## Cost-Control Notes

Keep costs predictable:

- Use one small instance.
- Use the included Docker Postgres for the portfolio MVP.
- Avoid high-frequency polling.
- Prefer webhook-triggered workflows.
- Keep LLM calls disabled by default.
- Set provider-side LLM usage limits before enabling real model calls.
- Configure AWS Budgets before creating Lightsail resources.
- Review Lightsail billing weekly while the demo is public.
- Delete unattached static IPs, old snapshots, unused disks, and abandoned instances.
- Cap log retention and avoid storing large raw logs in Postgres.

Use Lightsail snapshots sparingly. They are useful before upgrades, but old snapshots can become quiet recurring cost.

## What Not To Use Yet

Avoid these for the portfolio MVP:

- RDS: useful later, but it adds monthly cost and operational surface.
- NAT Gateway: expensive for a small demo and not needed on a single public VPS.
- ALB: not needed until you have multiple app instances or stricter routing requirements.
- ECS/Fargate: good platform later, unnecessary orchestration cost now.
- OpenSearch: high cost and operational weight; use Postgres audit records and small log excerpts for now.

Add these only when the demo has real usage that justifies the cost.

## Production Hardening Checklist

Before treating this as anything beyond a portfolio MVP:

- Replace all placeholder passwords and encryption keys.
- Keep `.env` out of Git and restrict it to `0600`.
- Force HTTPS and verify certificate renewal.
- Put n8n behind the reverse proxy, not public port `5678`.
- Use strong n8n credentials and rotate them.
- Disable Adminer or expose it only through SSH tunnel.
- Restrict SSH to your IP or use a VPN.
- Enable unattended OS security updates.
- Keep Docker images patched with a planned update window.
- Configure host firewall and Lightsail firewall consistently.
- Add backup automation and restore testing.
- Monitor disk usage, memory, CPU, and Docker volume growth.
- Keep real integrations disabled until approval gates and audit writes are tested.
- Keep AWS, GitHub, Slack, and LLM permissions least-privilege.
- Add alerting for failed backups and high disk usage.
- Document rollback steps before changing workflow definitions.

## References

- [Docker Compose production guidance](https://docs.docker.com/compose/how-tos/production/)
- [Docker Compose installation](https://docs.docker.com/compose/install/)
- [Caddy automatic HTTPS](https://caddyserver.com/docs/automatic-https)
- [Caddy reverse proxy](https://caddyserver.com/docs/caddyfile/directives/reverse_proxy)
- [NGINX reverse proxy](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)
- [NGINX SSL termination](https://docs.nginx.com/nginx/admin-guide/security-controls/terminating-ssl-http/)
- [Lightsail pricing](https://aws.amazon.com/lightsail/pricing/)
- [Lightsail firewalls](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-firewall-and-port-mappings-in-amazon-lightsail.html)
- [Lightsail DNS zone setup](https://docs.aws.amazon.com/lightsail/latest/userguide/lightsail-how-to-create-dns-entry.html)
- [Lightsail static IPs](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-static-ip-addresses-in-amazon-lightsail.html)
- [Lightsail billing and usage](https://docs.aws.amazon.com/lightsail/latest/userguide/understanding-your-amazon-lightsail-bill.html)
- [AWS Budgets](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-create.html)
