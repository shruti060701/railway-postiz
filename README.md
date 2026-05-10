# Postiz — Social Media Scheduling on Railway

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/new/template/TEMPLATE_CODE)

Deploy [Postiz](https://postiz.com), the open-source social media scheduling platform, on Railway with one click. Schedule posts, manage multiple accounts, and analyze performance across Twitter, LinkedIn, Reddit, and more. A self-hosted alternative to Buffer and Hootsuite.

## What's Included

| Service | Image | Purpose |
|---|---|---|
| **Postiz** | `ghcr.io/gitroomhq/postiz-app:v2.11.3` | Social media scheduling app + API |
| **PostgreSQL** | Railway Managed | App data, user accounts, posts |
| **Redis** | Railway Managed | Session store, job queue |

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
| `DATABASE_URL` | PostgreSQL connection | Auto-configured |
| `REDIS_URL` | Redis connection | Auto-configured |
| `JWT_SECRET` | Secret for signing sessions | Auto-generated |
| `MAIN_URL` | Public URL | Auto-configured |
| `FRONTEND_URL` | Frontend URL | Auto-configured |
| `NEXT_PUBLIC_BACKEND_URL` | API URL | Auto-configured |
| `BACKEND_INTERNAL_URL` | Internal API URL | `http://localhost:3000` |
| `IS_GENERAL` | Multi-user mode | `true` |
| `STORAGE_PROVIDER` | File storage | `local` |
| `UPLOAD_DIRECTORY` | Upload path | `/uploads` |
| `DISABLE_REGISTRATION` | Lock public signups | `false` |

## Estimated Cost

~$5-10/month on Railway (Postiz + PostgreSQL + Redis). Stays flat regardless of social account count.

## Notes

- **Version**: This template uses Postiz v2.11.3, the last stable version that runs without Temporal. Newer versions require a Temporal workflow engine.
- **Disable Registration**: After creating your admin account, set `DISABLE_REGISTRATION=true` to prevent unauthorized signups
- **Social OAuth**: To connect social accounts, you'll need to configure OAuth apps for each platform (X, LinkedIn, etc.)
- **Email**: Configure `RESEND_API_KEY` and `EMAIL_FROM_ADDRESS` to enable email notifications
- **Upgrades**: Update the image tag in the Dockerfile to upgrade Postiz

## License

Postiz is licensed under [AGPL-3.0](https://github.com/gitroomhq/postiz-app/blob/main/LICENSE).
