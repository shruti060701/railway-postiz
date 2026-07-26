# Deploy and Host Postiz Self-Hosted on Railway

Postiz is the open-source social media scheduling platform that lets you plan, publish, and analyze posts across Twitter/X, LinkedIn, Reddit, Facebook, TikTok, and a dozen other platforms from one dashboard. Think Buffer or Hootsuite, but you own the data and pay no per-channel fees.

## About Hosting Postiz Self-Hosted

Buffer's Team plan costs $60/month for 10 channels. Hootsuite starts at $99/month. Postiz self-hosted on Railway costs a flat infrastructure fee regardless of how many accounts or channels you connect, so for a five-person marketing team managing a dozen social accounts, that gap is real money every single month, not a rounding error.

The bigger reason teams choose self-hosting here isn't just the price, though. It's what you're actually trusting a third party with. Buffer and Hootsuite hold your social media OAuth tokens on their own infrastructure, meaning a breach on their end is a breach of your accounts too. Self-hosting keeps those tokens, your scheduled content, and your analytics data on infrastructure you control. For agencies managing client accounts specifically, that's not a nice-to-have, it's often a real client-trust requirement.

## This Template Deploys the Real, Current Postiz Architecture

Here's something worth knowing before you deploy: Postiz v2.12 and later require [Temporal](https://temporal.io), a full workflow orchestration engine, to actually execute scheduled posts. This isn't an optional performance upgrade, it's a hard dependency the app cannot start without. We confirmed this directly against Postiz's own official deployment reference (`gitroomhq/postiz-docker-compose`) rather than assuming an older, simpler setup still works.

Temporal itself needs two more things to run: Elasticsearch (for its internal workflow visibility store) and its own dedicated PostgreSQL database, completely separate from Postiz's own app database. Add those up and this template deploys 8 services total: Postiz itself, its PostgreSQL, Redis, Elasticsearch, a second PostgreSQL for Temporal, the Temporal server, Temporal's UI, and an admin-tools container.

That's a heavier stack than almost anything else in a typical Railway template marketplace, and it means real cost. Budget $20-35/month here, not the $5-10 you'd expect from a simple app-plus-database template. We'd rather tell you that upfront than have you discover it on your first bill.

## Common Use Cases

- **Social media agencies**: Manage 20+ client accounts across platforms from one dashboard. Schedule a month's worth of posts in an afternoon, with approval workflows keeping clients in the loop.
- **Startup marketing teams**: Coordinate product launches across Twitter, LinkedIn, and Reddit without per-seat SaaS fees eating into a lean budget.
- **Creator personal brands**: Maintain consistent posting across every platform from one visual calendar, cross-posting to Threads, Bluesky, and Mastodon with a single click.
- **Community managers**: Schedule announcements, event reminders, and engagement posts for Discord, Slack, and Reddit communities from one place.
- **Newsletter publishers**: Auto-post new articles to social channels when your RSS feed updates, using AI caption generation for platform-appropriate teasers instead of hand-writing each one.

## Dependencies for Postiz Self-Hosted Hosting

Postiz needs PostgreSQL for its own app data (users, posts, connected profiles) and, as of v2.12+, a full Temporal stack to actually execute scheduled posts: Redis for queueing, Elasticsearch for Temporal's visibility store, and a second, separate PostgreSQL purely for Temporal's own state.

### Deployment Dependencies

This template provisions all of it together: Postiz's own PostgreSQL and Redis, plus Elasticsearch, Temporal's dedicated PostgreSQL, the Temporal server itself, Temporal's admin UI, and an admin-tools container, all wired over Railway's private network. Nothing needs manual connection setup between services.

### Reference Links

- [Postiz Official Website](https://postiz.com)
- [Postiz GitHub Repository](https://github.com/gitroomhq/postiz-app)
- [Postiz's Official Docker Compose Reference](https://github.com/gitroomhq/postiz-docker-compose)
- [Postiz Environment Variables Reference](https://docs.postiz.com/configuration/reference)

### Implementation Details

This template runs `ghcr.io/gitroomhq/postiz-app:v2.22.1`, verified as the newest actual release tag in the registry at build time, not a floating `latest` that could change under you. Services are wired through Railway's own variable-reference syntax:

```
DATABASE_URL=${{Postgres.DATABASE_URL}}
REDIS_URL=${{Redis.REDIS_URL}}
TEMPORAL_ADDRESS=${{temporal.RAILWAY_PRIVATE_DOMAIN}}:7233
JWT_SECRET=${{secret(32)}}
MAIN_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
FRONTEND_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}
NEXT_PUBLIC_BACKEND_URL=https://${{RAILWAY_PUBLIC_DOMAIN}}/api
```

The JWT secret auto-generates at deploy time. Public URLs point to your Railway domain automatically, so OAuth callbacks work the moment you configure social platform apps. `PORT` is set explicitly as a Railway variable, not just a Dockerfile default, a lesson learned the hard way on another template in this same collection, where relying on a Dockerfile-only port default caused Railway's own routing to never reach the container at all.

## How Postiz Compares to the Alternatives

**Vs. Buffer**: Buffer is polished and requires zero infrastructure knowledge, but charges per channel and holds your data on its own servers. Postiz trades some of that turnkey simplicity for full data ownership and no per-channel cost, which matters once you're managing more than a handful of accounts.

**Vs. Hootsuite**: Hootsuite adds social listening and enterprise features most teams don't use, at enterprise pricing to match. Postiz focuses specifically on scheduling and calendar management without the upsell bloat.

**Vs. Later**: Later is visually focused and strongest for Instagram-heavy workflows. Postiz handles text-heavy platforms like Reddit and LinkedIn natively and includes AI caption generation across all platforms rather than gating it behind a higher paid tier.

## Getting Started

After deploying, give it real time before assuming something's wrong. This stack has real startup dependencies (Postiz needs Temporal healthy, which needs both Elasticsearch and its own database healthy first), so the full chain coming online takes noticeably longer than a simple single-service template.

Once it's up, open your Railway domain and create your admin account. Immediately after, set `DISABLE_REGISTRATION=true` to stop anyone else from signing up on your instance, since Postiz doesn't lock this down by default. From there, connect your social platform accounts under Settings by configuring OAuth apps for whichever platforms you actually use (X, LinkedIn, Reddit, and so on); you only need to set up the ones you plan to post to, not all of them.

With at least one platform connected, use the content calendar to draft and schedule your first post. This is the point worth actually testing end to end, not just confirming the app loads, since Postiz v2.12+ routes scheduled-post execution through Temporal, and a working calendar UI doesn't by itself confirm the whole pipeline is wired correctly. Schedule something a few minutes out and confirm it actually publishes.

## Why Deploy Postiz Self-Hosted on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Postiz self-hosted on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.

## Frequently Asked Questions

### Why does this template need 8 services when other self-hosted tools only need 2-3?
Because Postiz v2.12+ genuinely requires it. Temporal, Elasticsearch, and a second database aren't optional additions, they're what the current version needs to run. An older, simpler template could pin to pre-Temporal Postiz to avoid this, but that means running a version the project has since moved past.

### Is Redis really required, or can I skip it to save cost?
Required here. Unlike some other self-hosted tools where Redis is a nice-to-have cache, Postiz uses it directly for session storage and its job queue. Skipping it isn't a supported configuration.

### What happens if Temporal goes down after everything's running?
Scheduled posts stop executing until it's back. Postiz's web UI itself may still load, since that doesn't depend on Temporal for every action, but the core scheduling pipeline does.

### Do I need to configure every social platform listed in the variables?
No, every platform's API credentials (X, LinkedIn, Reddit, Facebook, TikTok, and roughly a dozen others) are optional and blank by default. Only configure the ones you actually plan to post to.

### What does the Temporal Admin Tools service actually do?
Not much on its own. It's a CLI container meant for interactive manual workflow inspection (`docker exec`-style access locally), not a service with independent function. On Railway, you'd `railway ssh` into it if you ever needed to manually inspect a stuck workflow; most deployers will never need to touch it.

### Is my data safe if I stop paying for Railway hosting?
Your data lives across the Postgres volumes this template provisions (Postiz's own database plus Temporal's). As long as those volumes exist, your scheduled posts, connected accounts, and history are intact.

### Where can I download Postiz?
Source code is at `github.com/gitroomhq/postiz-app`, with Docker images published to `ghcr.io/gitroomhq/postiz-app`. This template pulls a specific verified version automatically.
