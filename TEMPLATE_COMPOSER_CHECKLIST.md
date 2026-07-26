# Railway Template Composer Checklist — Postiz

Apply these settings in the Railway template composer when generating the template from the project. Rewritten 2026-07-26 — the previous version of this template (repo pushed 2026-05-10) was built against Postiz `v2.11.3` as a single container with no Temporal at all. **Postiz v2.12+ requires Temporal as a hard dependency**, confirmed against Postiz's own official `gitroomhq/postiz-docker-compose` repo, not guessed. This is a ground-up rebuild matching the real, current, 8-service architecture.

**Real services this template deploys:** `postiz` (the app), `Postgres` (Postiz's own metadata DB), `Redis`, `elasticsearch`, `temporal-postgres` (a second, separate Postgres — Temporal's own DB, not shared with Postiz), `temporal` (the Temporal server), `temporal-ui`, `temporal-admin-tools` (optional, see note below).

---

## 1. Healthcheck Settings

### `postiz` (app)
- **Healthcheck Path:** `/`
- **Healthcheck Timeout:** `180` seconds — Postiz's own official healthcheck (in the reference docker-compose) uses a `start_period: 120s`, meaning the vendor itself expects up to 2 minutes before the app is ready. Don't use a shorter timeout.

### `temporal-ui`
- **Healthcheck Path:** `/healthz` — confirmed real endpoint from the official docker-compose healthcheck definition.
- **Healthcheck Timeout:** `120` seconds

### `Postgres`, `Redis`, `elasticsearch`, `temporal-postgres`, `temporal`, `temporal-admin-tools`
- **No healthcheck path** — leave blank (TCP-only check). None of these expose an HTTP endpoint suitable for Railway's healthcheck mechanism. In particular, **do not** set an HTTP healthcheck on `temporal` — the official compose file's own healthcheck for it is a `temporal operator cluster health` CLI command (gRPC-based), not HTTP, and setting an HTTP path here will fail forever exactly like the bug already found and fixed on this project's Umami/Valkey pairing.

---

## 2. Variable Descriptions (Add to EVERY variable)

### `postiz` (App) Variables

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `PORT` | `5000` | No | **Must be set as an explicit Railway variable, not just a Dockerfile default** — Railway's own edge routing needs this visible at the platform level to know where to send traffic. Confirmed the hard way on this project's Metabase template: a Dockerfile-only `ENV PORT` is invisible to Railway's routing and causes every request to hit Railway's own fallback response instead of the app. |
| `MAIN_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | No | Public URL of the Postiz instance. |
| `FRONTEND_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | No | Same as `MAIN_URL` — used by the frontend build. |
| `NEXT_PUBLIC_BACKEND_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}/api` | No | Public API base URL the frontend calls. |
| `JWT_SECRET` | `${{secret(32)}}` | No | Signs authentication tokens. Auto-generated per deployment. |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | No | Postiz's own metadata database (posts, integrations, users). Uses a standard `postgres://` URL — no special format quirk here, unlike some other templates in this project. |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | No | Required (not optional, unlike some other templates' Redis) — Postiz uses Redis for queueing and caching core functionality. |
| `TEMPORAL_ADDRESS` | `${{temporal.RAILWAY_PRIVATE_DOMAIN}}:7233` | No | Address of the Temporal server. Required — Postiz v2.12+ cannot run without Temporal reachable. |
| `NEXT_PUBLIC_UPLOAD_DIRECTORY` | `/uploads` | No | Public-facing path for uploaded media, matches `UPLOAD_DIRECTORY` (already baked into the Dockerfile). |

**Baked into the Dockerfile already (not composer variables, don't duplicate):** `NODE_ENV=production`, `IS_GENERAL=true`, `STORAGE_PROVIDER=local`, `UPLOAD_DIRECTORY=/uploads`, `BACKEND_INTERNAL_URL=http://localhost:3000`, `RUN_CRON=true`, `DISABLE_REGISTRATION=false`.

**Social media platform API credentials (X, LinkedIn, Reddit, GitHub, Facebook, YouTube, TikTok, Pinterest, Discord, Slack, Mastodon, etc.):** the official compose file lists ~15 platform integrations, all blank by default. **Mark every one of these Optional** — a deployer only fills in credentials for the platforms they actually want to post to, and Postiz runs fine with none configured (you just can't connect that specific platform until you add its keys later). Don't require any of them.

### `Postgres` Variables (managed plugin — `railwayapp-templates/postgres-ssl`)

Same standard pattern as every other template in this project — `PGHOST`/`PGPORT`/`PGUSER`/`PGDATABASE`/`PGPASSWORD` all reference the plugin's own auto-injected values, `POSTGRES_USER`/`POSTGRES_DB`/`PGDATA`/`SSL_CERT_DAYS`/`RAILWAY_DEPLOYMENT_DRAINING_SECONDS` marked Optional with Railway's defaults, `POSTGRES_PASSWORD` verified live against the actual composer screenshot (don't assume a `secret()` length — this has been wrong on multiple prior templates in this project).

### `Redis` Variables (managed plugin via `railway add --database redis`)

Standard auto-injected `REDIS_URL`/`REDIS_PUBLIC_URL` — leave as-is, no custom configuration needed.

### `elasticsearch` Variables

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `discovery.type` | `single-node` | No | Runs Elasticsearch as a single-node cluster — appropriate for this use case (Temporal's internal visibility store), not a real multi-node search deployment. |
| `xpack.security.enabled` | `false` | No | Disables Elasticsearch's own auth layer — acceptable since this service has no public port and is only reachable from `temporal` over Railway's private network. |
| `ES_JAVA_OPTS` | `-Xms256m -Xmx256m` | No | Caps JVM heap size. Matches the official reference exactly — don't increase without reason, Elasticsearch here only serves Temporal's internal visibility queries, not real search traffic. |
| `cluster.routing.allocation.disk.threshold_enabled` | `true` | **Yes** | Enables disk-based shard allocation limits. |
| `cluster.routing.allocation.disk.watermark.low` | `512mb` | **Yes** | Disk watermark thresholds, matches official reference defaults. |
| `cluster.routing.allocation.disk.watermark.high` | `256mb` | **Yes** | |
| `cluster.routing.allocation.disk.watermark.flood_stage` | `128mb` | **Yes** | |

No public domain needed — internal only.

### `temporal-postgres` Variables (raw `postgres:16` image — deliberately NOT the managed Railway plugin, to match the official reference exactly and avoid any SSL-mode mismatch with Temporal's own DB driver config, which doesn't specify SSL params)

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `POSTGRES_USER` | `temporal` | No | Matches what `temporal`'s own `POSTGRES_USER` variable must reference. |
| `POSTGRES_PASSWORD` | `${{secret(32)}}` | No | Auto-generated. Must match what's referenced on the `temporal` service — set as a cross-service reference there, not independently generated (same class of desync bug already caught on this project's Typebot template). |

No public domain needed — internal only. Mount a Railway Volume at `/var/lib/postgresql/data` for persistence.

### `temporal` Variables (custom Dockerfile — `Dockerfile.temporal`, bakes in the `dynamicconfig` file the official compose mounts locally)

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `DB` | `postgres12` | No | Tells Temporal's auto-setup which DB driver dialect to use. |
| `DB_PORT` | `5432` | No | |
| `POSTGRES_USER` | `${{temporal-postgres.POSTGRES_USER}}` | No | Cross-service reference — must match `temporal-postgres` exactly. |
| `POSTGRES_PWD` | `${{temporal-postgres.POSTGRES_PASSWORD}}` | No | Cross-service reference — same reasoning. |
| `POSTGRES_SEEDS` | `${{temporal-postgres.RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname of Temporal's own Postgres. |
| `DYNAMIC_CONFIG_FILE_PATH` | `config/dynamicconfig/development-sql.yaml` | No | Path (relative to the image's own working directory, `/etc/temporal`) to the config file baked into the custom Dockerfile. |
| `ENABLE_ES` | `true` | No | Enables the Elasticsearch-backed visibility store. |
| `ES_SEEDS` | `${{elasticsearch.RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname of the Elasticsearch service. |
| `ES_VERSION` | `v7` | No | Matches the pinned `elasticsearch:7.17.27` image. |
| `TEMPORAL_NAMESPACE` | `default` | No | |

No public domain needed — `postiz` connects to it internally via `TEMPORAL_ADDRESS`.

### `temporal-ui` Variables (raw `temporalio/ui:2.34.0` image)

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `TEMPORAL_ADDRESS` | `${{temporal.RAILWAY_PRIVATE_DOMAIN}}:7233` | No | |
| `TEMPORAL_CORS_ORIGINS` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | No | Only relevant if you generate a public domain for this service — see note below. |

**Whether to expose this publicly is a judgment call, not a hard requirement.** `temporal-ui` is an internal admin/observability dashboard for inspecting workflow runs — not something Postiz's actual end users interact with. Generating a public domain makes it convenient to check on, but also exposes an unauthenticated admin panel to the internet unless you separately gate it. Consider leaving it without a public domain (private-network-only) unless you specifically want to check on Temporal workflow health from outside Railway.

### `temporal-admin-tools` — optional, flagged as likely non-functional as a real "service"

The official compose file runs this with `stdin_open: true` and `tty: true` — it's a pure CLI container meant for `docker exec -it` style interactive admin commands (inspecting/replaying workflows manually), not a long-running service with independent function. On Railway, there's no equivalent of an attached interactive TTY session the way Docker Compose provides one locally. **Recommendation: include it in the composer for architectural completeness (matching the reference exactly), but expect it to just sit idle with no real functionality** — `railway ssh` into it if you ever need actual admin CLI access, don't expect it to do anything on its own. Not a blocker for Postiz's core functionality either way.

---

## 3. Secrets That Must Use `${{secret()}}`

| Variable | Template Syntax |
|----------|-----------------|
| `JWT_SECRET` (on `postiz`) | `${{secret(32)}}` |
| `POSTGRES_PASSWORD` (on `temporal-postgres`) | `${{secret(32)}}` |
| `POSTGRES_PWD` (on `temporal`) | `${{temporal-postgres.POSTGRES_PASSWORD}}` — cross-reference, NOT an independent `secret()` call |
| `POSTGRES_PASSWORD` (on `Postgres`, main app DB) | Whatever Railway's plugin already prefilled — verify live, don't assume a length |

---

## 4. Volumes

| Service | Mount Path | Notes |
|---------|-----------|-------|
| `postiz` | `/uploads` | Persists uploaded media. **Known gap:** the official compose also persists `/config` as a separate volume (likely holding encryption-related state) — Railway's per-service volume model doesn't obviously support two independent mount paths on one service the way Docker Compose does. This template mounts only `/uploads` as the higher-priority path; verify on first real deploy whether `/config` not persisting causes any real issue (e.g., re-encryption prompts on redeploy) and revisit if so. |
| `temporal-postgres` | `/var/lib/postgresql/data` | Standard Postgres data directory. |
| `elasticsearch` | `/usr/share/elasticsearch/data` | Persists Elasticsearch's index data — without this, Temporal's workflow visibility history resets on every redeploy. |
| `Postgres` (main) | Managed automatically by the Railway plugin | No manual setup needed. |

---

## 5. Known Troubleshooting

- **`postiz` crash-loops or can't reach Temporal:** confirm `TEMPORAL_ADDRESS` resolves to `temporal`'s real private domain with `:7233` appended — Postiz v2.12+ genuinely cannot start without this working, unlike Redis which some other templates treat as optional.
- **`temporal` service fails to start:** check `POSTGRES_SEEDS`/`POSTGRES_USER`/`POSTGRES_PWD` match `temporal-postgres` exactly, and that `ES_SEEDS` points at a reachable `elasticsearch` instance — `temporal`'s auto-setup process depends on both being up before it can complete its own bootstrap.
- **Elasticsearch fails to start / crashes:** check the service has enough memory allocated (256MB heap via `ES_JAVA_OPTS`, but the container needs meaningfully more than that to run at all — budget at least 512MB-1GB for this specific service, more than a typical lightweight template service in this project).
- **Backend/frontend port conflict inside the `postiz` container:** already fixed via the `backend-package.json` override baked into the Dockerfile (forces the backend onto internal port 3000 instead of colliding with the frontend on 5000) — inherited from a real fix found during an earlier build attempt of this exact template. If this breaks again on a future Postiz version bump, re-verify the internal file path `/app/apps/backend/package.json` is still correct for that version.
- **This is by far the most expensive template in this project to run** — 8 services including a full Temporal cluster and Elasticsearch. Budget accordingly when advising deployers on expected monthly cost; this is not a $5/month template.

---

## 6. Post-Deploy Steps

After the template is published, test-deploy from a fresh Railway account (incognito window) and verify:

1. No "needs configuration" prompts appear for Postgres's auto-injected variables (either Postgres instance).
2. All services come online — this will take noticeably longer than any other template in this project, since `postiz` depends on `temporal` depending on both `temporal-postgres` and `elasticsearch` all being healthy first. Give it real time before assuming something's broken.
3. The app responds with a real `200` at `/`.
4. Open the actual Railway domain in a browser and complete real account creation — don't just curl the root path.
5. **Actually test the core scheduling flow**, not just that the app loads: connect a test social platform (or at minimum, create a draft post) and confirm it saves correctly, since that's the functionality that depends on Temporal actually working end-to-end, not just being "online."
