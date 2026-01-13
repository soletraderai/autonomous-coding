# Teachy Deployment Strategy Plan

## Summary

Deploy Teachy to DigitalOcean Droplets with:
- **Auth**: Supabase Auth (Email/Password + Google OAuth) - **COMPLETE**
- **Hosting**: DigitalOcean Droplet with Docker + Nginx - **READY**
- **Database**: Supabase PostgreSQL (managed) - **CONFIGURED**
- **CI/CD**: GitHub Actions for automated deployments - **COMPLETE**
- **Domain**: To be registered

**Status:** All code implementation complete. Ready for infrastructure provisioning.

---

## Recommended Droplet Configuration

### Primary Recommendation: Basic Droplet

| Specification | Recommendation | Reasoning |
|---------------|----------------|-----------|
| **Plan** | Basic (Regular Intel) | Cost-effective for starting |
| **Size** | 2 GB RAM / 1 vCPU / 50 GB SSD | Minimum for Node.js + Docker |
| **Region** | `sfo3` (San Francisco) or `nyc3` (New York) | Low latency for US users |
| **Image** | Ubuntu 24.04 LTS | Latest LTS, good Docker support |
| **Backups** | Enabled ($4.80/mo extra) | Essential for disaster recovery |
| **Monitoring** | Enabled (free) | Built-in CPU/memory/disk alerts |
| **IPv6** | Enabled (free) | Future-proofing |

**Estimated Cost:** $18/month ($12 droplet + $4.80 backups + ~$1 domain)

### Scaling Path

| Stage | Droplet | RAM | vCPU | When to Upgrade |
|-------|---------|-----|------|-----------------|
| **Launch** | Basic | 2 GB | 1 | Starting out |
| **Growth** | Basic | 4 GB | 2 | >1000 daily users or API latency >500ms |
| **Scale** | General Purpose | 8 GB | 2 | >5000 daily users or need more reliability |

### Alternative: Premium AMD ($14/mo for 1GB)
- Better single-thread performance
- Consider if API response time is critical
- Upgrade path: $28/mo for 2GB Premium

---

## Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     DigitalOcean Droplet                        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Docker Compose                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │   │
│  │  │   Nginx     │  │   API       │  │     Redis       │  │   │
│  │  │  (SSL/Proxy)│──│  (Express)  │──│    (Cache)      │  │   │
│  │  │   :80/:443  │  │   :3001     │  │    :6379        │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘  │   │
│  │         │                │                               │   │
│  │         │                │                               │   │
│  │  ┌─────────────┐        │                               │   │
│  │  │  Frontend   │        │                               │   │
│  │  │  (Static)   │        │                               │   │
│  │  └─────────────┘        │                               │   │
│  └─────────────────────────│───────────────────────────────┘   │
│                            │                                    │
└────────────────────────────│────────────────────────────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │    Supabase (External)       │
              │  ┌────────────────────────┐  │
              │  │   PostgreSQL Database  │  │
              │  │   (Managed, Backups)   │  │
              │  └────────────────────────┘  │
              │  ┌────────────────────────┐  │
              │  │   Auth Service         │  │
              │  │   (OAuth, JWT)         │  │
              │  └────────────────────────┘  │
              └──────────────────────────────┘
```

---

## Step-by-Step Deployment Guide

### Step 1: Create DigitalOcean Droplet

1. **Log in** to [cloud.digitalocean.com](https://cloud.digitalocean.com)

2. **Create Droplet** with these settings:
   ```
   Region:        San Francisco 3 (sfo3) or New York 3 (nyc3)
   Image:         Ubuntu 24.04 (LTS) x64
   Size:          Basic → Regular → $12/mo (2 GB / 1 vCPU / 50 GB SSD)

   Authentication: SSH Key (recommended) or Password

   Options:
   ☑ Backups ($4.80/mo)
   ☑ IPv6
   ☑ Monitoring

   Hostname:      teachy-prod
   Tags:          production, teachy
   ```

3. **Note the Droplet IP** (e.g., `164.90.xxx.xxx`)

### Step 2: Initial Server Setup

SSH into your droplet and run the setup script:

```bash
# Connect to droplet
ssh root@YOUR_DROPLET_IP

# Download and run setup script
curl -fsSL https://raw.githubusercontent.com/YOUR_REPO/main/scripts/setup-server.sh | bash
```

Or manually:

```bash
# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | bash

# Install Docker Compose
apt install -y docker-compose-plugin

# Create deploy user
useradd -m -s /bin/bash deploy
usermod -aG docker deploy

# Configure firewall
ufw allow ssh
ufw allow http
ufw allow https
ufw enable

# Install monitoring agent
curl -sSL https://repos.insights.digitalocean.com/install.sh | bash
```

### Step 3: Configure SSH for Deployment

```bash
# On your local machine, generate a deploy key
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/teachy_deploy

# Copy public key to droplet
ssh-copy-id -i ~/.ssh/teachy_deploy.pub deploy@YOUR_DROPLET_IP

# Test connection
ssh -i ~/.ssh/teachy_deploy deploy@YOUR_DROPLET_IP
```

### Step 4: Clone Repository on Server

```bash
# As deploy user on server
sudo -u deploy -i

# Clone repository
git clone https://github.com/YOUR_USERNAME/teachy.git /home/deploy/teachy
cd /home/deploy/teachy

# Create production environment file
cp .env.production.example .env
nano .env  # Fill in all production values
```

### Step 5: Configure GitHub Secrets

In your GitHub repository, go to **Settings → Secrets and variables → Actions** and add:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DEPLOY_SSH_KEY` | (private key content) | Content of `~/.ssh/teachy_deploy` |
| `SERVER_HOST` | `164.90.xxx.xxx` | Your Droplet IP |
| `SERVER_USER` | `deploy` | SSH user |
| `DEPLOY_PATH` | `/home/deploy/teachy` | Repository path on server |
| `SITE_URL` | `https://yourdomain.com` | Production URL |
| `API_URL` | `https://yourdomain.com/api` | API URL |
| `VITE_SUPABASE_URL` | `https://xxx.supabase.co` | Supabase URL |
| `VITE_SUPABASE_ANON_KEY` | `eyJ...` | Supabase anon key |
| `VITE_API_URL` | `https://yourdomain.com` | API URL for frontend |

### Step 6: Initial Deployment

```bash
# On the server as deploy user
cd /home/deploy/teachy

# Pull images and start services
docker compose -f docker-compose.prod.yml up -d

# Check status
docker compose -f docker-compose.prod.yml ps

# View logs
docker compose -f docker-compose.prod.yml logs -f
```

### Step 7: Configure Domain & SSL

1. **Register domain** (Namecheap, Cloudflare, Google Domains)

2. **Configure DNS** - Add A records:
   ```
   Type: A    Host: @      Points to: YOUR_DROPLET_IP
   Type: A    Host: www    Points to: YOUR_DROPLET_IP
   ```

3. **Wait for DNS propagation** (5-30 minutes)

4. **Run SSL setup**:
   ```bash
   cd /home/deploy/teachy
   ./scripts/setup-ssl.sh yourdomain.com admin@yourdomain.com
   ```

5. **Update Nginx config** for SSL (uncomment HTTPS block in `nginx/conf.d/default.conf`)

6. **Restart services**:
   ```bash
   docker compose -f docker-compose.prod.yml up -d
   ```

---

## GitHub Secrets Full Reference

### Required Secrets

```yaml
# Server Access
DEPLOY_SSH_KEY:           # Private SSH key for deploy user
SERVER_HOST:              # Droplet IP address
SERVER_USER:              # deploy
DEPLOY_PATH:              # /home/deploy/teachy

# URLs (for smoke tests)
SITE_URL:                 # https://yourdomain.com
API_URL:                  # https://yourdomain.com/api

# Frontend Build Args
VITE_SUPABASE_URL:        # https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY:   # eyJhbGc...
VITE_API_URL:             # https://yourdomain.com
```

### Server Environment (.env file on server)

```bash
# These go in /home/deploy/teachy/.env on the server
NODE_ENV=production
PORT=3001

# Database
DATABASE_URL=postgresql://...
DIRECT_URL=postgresql://...

# Auth
JWT_SECRET=<openssl rand -hex 32>
JWT_REFRESH_SECRET=<openssl rand -hex 32>
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Services
GEMINI_API_KEY=...
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRICE_MONTHLY=price_...
STRIPE_PRICE_YEARLY=price_...
RESEND_API_KEY=re_...
EMAIL_FROM=Teachy <noreply@yourdomain.com>

# URLs
FRONTEND_URL=https://yourdomain.com
```

---

## Monitoring & Alerts Configuration

### DigitalOcean Monitoring (Built-in)

1. Go to **Droplet → Monitoring tab**
2. Create alerts:

| Alert | Threshold | Duration | Action |
|-------|-----------|----------|--------|
| CPU | > 80% | 5 minutes | Email notification |
| Memory | > 85% | 5 minutes | Email notification |
| Disk | > 90% | 5 minutes | Email notification |
| Bandwidth In | > 1 GB/hour | 1 hour | Email notification |

### Health Check Endpoints

| Endpoint | Purpose | Expected Response |
|----------|---------|-------------------|
| `GET /health` | Nginx liveness | `200 OK` |
| `GET /api/health` | API + DB + Redis | `{"status": "healthy"}` |

### Recommended: UptimeRobot (Free)

1. Create account at [uptimerobot.com](https://uptimerobot.com)
2. Add monitors:
   - **HTTP(s)**: `https://yourdomain.com` (5 min interval)
   - **HTTP(s)**: `https://yourdomain.com/api/health` (5 min interval)
3. Configure alerts: Email + Slack/Discord webhook

---

## Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|-------------|-------|
| DigitalOcean Droplet (2GB) | $12.00 | Basic plan |
| Droplet Backups | $4.80 | 20% of droplet cost |
| Supabase | $0.00 | Free tier (500MB DB, 50K auth users) |
| Domain | ~$1.00 | $12/year averaged |
| Resend Email | $0.00 | Free tier (3K emails/month) |
| UptimeRobot | $0.00 | Free tier (50 monitors) |
| **Total** | **~$18/month** | |

### Scaling Costs

| Stage | Monthly Cost | Trigger |
|-------|-------------|---------|
| Launch | $18 | - |
| Growth | $32 | Upgrade to 4GB droplet |
| Scale | $75 | 8GB droplet + Supabase Pro ($25) |

---

## Implementation Checklist

### Completed (Phase 9)

- [x] Supabase Auth migration (Phase 0)
- [x] Production Dockerfile (API + Frontend)
- [x] Docker Compose production configuration
- [x] Nginx configuration (SSL-ready)
- [x] GitHub Actions CI/CD workflow
- [x] Smoke test script
- [x] Rollback mechanism
- [x] Server setup script
- [x] SSL setup script
- [x] Environment template

### Remaining (Infrastructure)

- [ ] Create DigitalOcean account/Droplet
- [ ] Register domain name
- [ ] Configure DNS
- [ ] Run server setup script
- [ ] Clone repository to server
- [ ] Configure GitHub secrets
- [ ] First deployment
- [ ] SSL certificate setup
- [ ] Configure Stripe production webhook
- [ ] Configure monitoring alerts
- [ ] End-to-end testing

---

## Files Reference

### Created Files (Phase 9)

| File | Purpose |
|------|---------|
| `api/Dockerfile.prod` | Multi-stage API production build |
| `Dockerfile` | Multi-stage frontend production build |
| `docker-compose.prod.yml` | Production orchestration |
| `nginx/nginx.conf` | Main Nginx configuration |
| `nginx/conf.d/default.conf` | Site config with SSL support |
| `nginx/conf.d/frontend.conf` | Standalone frontend config |
| `.github/workflows/deploy.yml` | CI/CD pipeline |
| `scripts/setup-server.sh` | Server initialization |
| `scripts/setup-ssl.sh` | SSL certificate setup |
| `scripts/smoke-test.sh` | Deployment verification |
| `scripts/rollback.sh` | Rollback mechanism |
| `.env.production.example` | Environment template |

---

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Docker permission denied | `sudo usermod -aG docker deploy && newgrp docker` |
| Port 80 in use | `sudo lsof -i :80` and stop conflicting service |
| SSL certificate fails | Check DNS propagation: `dig yourdomain.com` |
| API not responding | Check logs: `docker compose logs api` |
| Memory issues | Upgrade droplet or add swap: `fallocate -l 2G /swapfile` |

### Useful Commands

```bash
# View all container logs
docker compose -f docker-compose.prod.yml logs -f

# Restart specific service
docker compose -f docker-compose.prod.yml restart api

# Check container resource usage
docker stats

# View deployment history
cat /home/deploy/teachy/deployments.log

# Manual rollback
./scripts/rollback.sh 1
```

---

## Security Checklist

- [x] SSH key authentication (no password)
- [x] UFW firewall (only 22, 80, 443)
- [x] Non-root Docker containers
- [x] Environment variables (not in code)
- [x] Rate limiting on API endpoints
- [x] Security headers in Nginx
- [x] Fail2ban for SSH protection (24h ban, 3 max retries)
- [x] Automatic security updates (unattended-upgrades)
- [x] SSH hardening (root login disabled, password auth disabled)
- [x] Swap file for memory management (2GB)

---

## Support Resources

- **DigitalOcean Docs**: [docs.digitalocean.com](https://docs.digitalocean.com)
- **Docker Docs**: [docs.docker.com](https://docs.docker.com)
- **Supabase Docs**: [supabase.com/docs](https://supabase.com/docs)
- **Let's Encrypt**: [letsencrypt.org/docs](https://letsencrypt.org/docs)
