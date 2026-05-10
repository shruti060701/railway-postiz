# Deploy and Host Postiz-self-hosted on Railway

Postiz is an open-source social media scheduling platform that lets you plan, publish, and analyze content across Twitter, LinkedIn, Reddit, Facebook, TikTok, and more. Think Buffer or Hootsuite, but you own the data and there are no per-channel fees. Teams can collaborate on a shared content calendar, get AI help with captions, and track performance — all from a single self-hosted dashboard.

## About Hosting Postiz-self-hosted

The math is simple: Buffer's Team plan costs $60/month for 10 channels. Postiz self-hosted on Railway? ~$5-10/month with unlimited channels and accounts. That's a ~$600/year saving before you factor in team seats. This template deploys Postiz with managed PostgreSQL and Redis, auto-generated JWT secrets, and a public HTTPS domain — all pre-wired. Railway handles SSL, container restarts, and private networking so you don't touch infrastructure. Your social tokens, post data, and analytics stay on your own instance. No third-party tracking. No usage caps. And because it's Railway, scaling up is a slider away if your audience grows.

## Common Use Cases

- **Social media agencies** — Manage 20+ client accounts across platforms from one dashboard. Schedule a month's worth of posts in an afternoon and let the approval workflow keep clients in the loop
- **Startup marketing teams** — Coordinate product launches across Twitter, LinkedIn, and Reddit without paying per-seat SaaS fees. One team of five saves $300/month vs Buffer
- **Creator personal brands** — Maintain consistent posting across all platforms with a visual calendar. Cross-post to Threads, Bluesky, and Mastodon with one click
- **Community managers** — Schedule announcements, event reminders, and engagement posts for Discord, Slack, and Reddit communities. Track which channels drive the most signups
- **Newsletter publishers** — Auto-post new articles to social channels when your RSS feed updates. Use AI caption generation to write platform-appropriate teasers

## Dependencies for Postiz-self-hosted Hosting

- **PostgreSQL** — Stores user accounts, connected social profiles, scheduled posts, and analytics data. Railway provisions this automatically with persistent storage and private networking
- **Redis** — Handles session storage and the job queue for scheduled post publishing. Railway provisions this automatically

### Deployment Dependencies

- [Postiz Official Website](https://postiz.com)
- [Postiz GitHub Repository](https://github.com/gitroomhq/postiz-app)
- [Postiz Docker Documentation](https://docs.postiz.com/installation/docker)
- [Postiz Environment Variables Reference](https://docs.postiz.com/configuration/reference)

### Implementation Details

This template runs the official `ghcr.io/gitroomhq/postiz-app:v2.11.3` image with PostgreSQL and Redis auto-wired through Railway's template variable references:

```
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
JWT_SECRET=${{secret(32)}}
MAIN_URL=https://${{postiz.RAILWAY_PUBLIC_DOMAIN}}
FRONTEND_URL=https://${{postiz.RAILWAY_PUBLIC_DOMAIN}}
NEXT_PUBLIC_BACKEND_URL=https://${{postiz.RAILWAY_PUBLIC_DOMAIN}}/api
```

The JWT secret gets auto-generated at deploy time via Railway's `secret()` function. Public URLs point to your Railway domain automatically, so OAuth callbacks work the moment you configure social apps.

## Why Deploy Postiz-self-hosted on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Postiz-self-hosted on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
