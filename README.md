# Postiz — Social Media Scheduling on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template/TEMPLATE_CODE)

Deploy [Postiz](https://postiz.com), the open-source social media scheduling platform, on Railway with one click. Schedule posts, manage multiple accounts, and analyze performance across Twitter, LinkedIn, Reddit, and more. A self-hosted alternative to Buffer and Hootsuite.

## What's Included

Postiz v2.12+ requires [Temporal](https://temporal.io) (a workflow orchestration engine) as a hard dependency — this is a real architecture change from earlier Postiz versions, not an optional extra. This template deploys the full stack Postiz's own official reference (`gitroomhq/postiz-docker-compose`) uses:

| Service | Image | Purpose |
|---|---|---|
| **Postiz** | `ghcr.io/gitroomhq/postiz-app:v2.22.1` | Social media scheduling app + API |
| **PostgreSQL** (main) | Railway Managed | Postiz's own app data — users, posts, connected accounts |
| **Redis** | Railway Managed | Session store, job queue |
| **Elasticsearch** | `elasticsearch:7.17.27` | Temporal's internal workflow visibility store |
| **PostgreSQL** (Temporal) | `postgres:16` | A second, separate database — Temporal's own storage, not shared with Postiz |
| **Temporal Server** | `temporalio/auto-setup:1.28.1` | Workflow orchestration engine that actually runs scheduled posts |
| **Temporal UI** | `temporalio/ui:2.34.0` | Optional admin dashboard for inspecting workflow runs |
| **Temporal Admin Tools** | `temporalio/admin-tools:1.28.1-tctl-1.18.4-cli-1.4.1` | Optional CLI container for manual workflow inspection — see notes below |

This is a genuinely heavier template than most self-hosted tools — 8 services instead of the usual 2-3 — because that's what Postiz itself now requires to function, not a design choice made here.

## Features

- **Multi-Platform Posting** — Schedule to Twitter/X, LinkedIn, Reddit, Facebook, Instagram, TikTok, YouTube, Threads, Pinterest, and more
- **Content Calendar** — Visual drag-and-drop calendar for planning posts across all channels
- **Team Collaboration** — Invite team members with role-based permissions and approval workflows
- **AI-Powered Captions** — Generate post captions with OpenAI integration
- **Analytics Dashboard** — Track engagement, reach, and growth across all connected accounts
- **Self-Hosted** — Full data ownership, no per-account limits, no vendor lock-in

## How to Deploy

### One-Click Deploy

Click the "Deploy on Railway" button above.

### Manual Deploy via CLI

```bash
brew install railway
railway login
railway init --name postiz
railway add --database postgres
railway add --database redis
railway up -d
railway domain
```

### After Deployment

1. Open the generated URL
2. Create your admin account
3. Connect your social media accounts
4. Set `DISABLE_REGISTRATION=true` after creating your account to prevent public signups

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `PORT` | Port Railway routes external traffic to | `5000` |
| `DATABASE_URL` | PostgreSQL connection (Postiz's own app DB) | Auto-configured |
| `REDIS_URL` | Redis connection | Auto-configured |
| `TEMPORAL_ADDRESS` | Address of the Temporal server — required, not optional | Auto-configured |
| `JWT_SECRET` | Secret for signing sessions | Auto-generated |
| `MAIN_URL` | Public URL | Auto-configured |
| `FRONTEND_URL` | Frontend URL | Auto-configured |
| `NEXT_PUBLIC_BACKEND_URL` | API URL | Auto-configured |
| `NEXT_PUBLIC_UPLOAD_DIRECTORY` | Public path for uploaded media | `/uploads` |
| `BACKEND_INTERNAL_URL` | Internal API URL | `http://localhost:3000` |
| `IS_GENERAL` | Multi-user mode | `true` |
| `STORAGE_PROVIDER` | File storage | `local` |
| `UPLOAD_DIRECTORY` | Upload path | `/uploads` |
| `DISABLE_REGISTRATION` | Lock public signups | `false` |

## Estimated Cost

$20-35/month on Railway — significantly more than most templates in this collection, since Elasticsearch and the Temporal cluster add real compute cost on top of the app itself. Stays flat regardless of social account count, but budget for 8 running services, not 2-3.

## Notes

- **Version**: This template uses Postiz v2.22.1, the newest verified stable release at build time, with the full Temporal stack it now requires.
- **Why Temporal?** Postiz v2.12+ moved scheduled-post execution to Temporal workflows. This isn't optional — the app cannot start without a reachable Temporal server.
- **Disable Registration**: After creating your admin account, set `DISABLE_REGISTRATION=true` to prevent unauthorized signups
- **Social OAuth**: To connect social accounts, you'll need to configure OAuth apps for each platform (X, LinkedIn, etc.)
- **Email**: Configure `RESEND_API_KEY` and `EMAIL_FROM_ADDRESS` to enable email notifications
- **Temporal Admin Tools**: this service has no real function on Railway by itself (it's a CLI container meant for interactive `docker exec`-style access) — use `railway ssh` into it if you ever need manual workflow inspection
- **Upgrades**: Update the image tag in the Dockerfile to upgrade Postiz — verify Temporal compatibility before bumping major versions

## License

Postiz is licensed under [AGPL-3.0](https://github.com/gitroomhq/postiz-app/blob/main/LICENSE).
