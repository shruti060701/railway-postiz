# Railway Template Composer Checklist — Postiz

Apply these settings in the Railway template composer when generating the template from the project. Rewritten 2026-07-26 — the previous version of this template (repo pushed 2026-05-10) was built against Postiz `v2.11.3` as a single container with no Temporal at all. **Postiz v2.12+ requires Temporal as a hard dependency**, confirmed against Postiz's own official `gitroomhq/postiz-docker-compose` repo, not guessed. This is a ground-up rebuild matching the real, current, 8-service architecture.

**Real, live service names in this project (auto-generated names for GitHub-connected/image-based services — use these exact names in the composer, not generic labels):**

| Real Service Name | What It Actually Is |
|---|---|
| `railway-postiz` | The Postiz app itself (GitHub-connected, `Dockerfile`) |
| `Postgres` | Postiz's own metadata DB (managed plugin) |
| `Redis` | Session/queue store (managed plugin) |
| `selfless-dedication` | Elasticsearch (GitHub-connected, `Dockerfile.elasticsearch`) |
| `temporal-postgres` | Temporal's own, separate Postgres (raw `postgres:16` image) |
| `remarkable-patience` | The Temporal server (GitHub-connected, `Dockerfile.temporal`) |
| `temporal-ui` | Temporal's admin dashboard (raw `temporalio/ui:2.34.0` image) |
| `temporal-admin-tools` | Temporal CLI container, mostly non-functional as a standing service (raw image) |

---

## 1. Healthcheck Settings

### `railway-postiz` (app)
- **Healthcheck Path:** `/`
- **Healthcheck Timeout:** `180` seconds — Postiz's own official healthcheck (in the reference docker-compose) uses a `start_period: 120s`, meaning the vendor itself expects up to 2 minutes before the app is ready. Don't use a shorter timeout.

### `temporal-ui`
- **Healthcheck Path:** `/healthz` — confirmed real endpoint from the official docker-compose healthcheck definition.
- **Healthcheck Timeout:** `120` seconds

### `Postgres`, `Redis`, `selfless-dedication`, `temporal-postgres`, `remarkable-patience`, `temporal-admin-tools`
- **No healthcheck path** — leave blank (TCP-only check). None of these expose an HTTP endpoint suitable for Railway's healthcheck mechanism. In particular, **do not** set an HTTP healthcheck on `remarkable-patience` — the official compose file's own healthcheck for it is a `temporal operator cluster health` CLI command (gRPC-based), not HTTP, and setting an HTTP path here will fail forever exactly like the bug already found and fixed on this project's Umami/Valkey pairing (and like `selfless-dedication` genuinely did fail this way once, for a different reason, during this template's build — see Troubleshooting).

---

## 2. Variable Descriptions (Add to EVERY variable)

### `railway-postiz` (App) Variables — 10 total

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `PORT` | `5000` | No | **Must be set as an explicit Railway variable, not just a Dockerfile default** — Railway's own edge routing needs this visible at the platform level to know where to send traffic. Confirmed the hard way on this project's Metabase template: a Dockerfile-only `ENV PORT` is invisible to Railway's routing and causes every request to hit Railway's own fallback response instead of the app. |
| `MAIN_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | No | Public URL of the Postiz instance. |
| `FRONTEND_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | No | Same as `MAIN_URL` — used by the frontend build. |
| `NEXT_PUBLIC_BACKEND_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}/api` | No | Public API base URL the frontend calls. |
| `JWT_SECRET` | `${{secret(32)}}` | No | Signs authentication tokens. Auto-generated per deployment. |
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | No | Postiz's own metadata database (posts, integrations, users). Uses a standard `postgres://` URL — no special format quirk here, unlike some other templates in this project. |
| `REDIS_URL` | `${{Redis.REDIS_URL}}` | No | Required (not optional, unlike some other templates' Redis) — Postiz uses Redis for queueing and caching core functionality. |
| `TEMPORAL_ADDRESS` | `${{remarkable-patience.RAILWAY_PRIVATE_DOMAIN}}:7233` | No | Address of the Temporal server. Required — Postiz v2.12+ cannot run without Temporal reachable. **Use the real service name `remarkable-patience` here, not a generic `temporal` placeholder.** |
| `NEXT_PUBLIC_UPLOAD_DIRECTORY` | `/uploads` | No | Public-facing path for uploaded media, matches `UPLOAD_DIRECTORY` (already baked into the Dockerfile). |

**Baked into the Dockerfile already (not composer variables, don't duplicate):** `NODE_ENV=production`, `IS_GENERAL=true`, `STORAGE_PROVIDER=local`, `UPLOAD_DIRECTORY=/uploads`, `BACKEND_INTERNAL_URL=http://localhost:3000`, `RUN_CRON=true`, `DISABLE_REGISTRATION=false`. Also baked in via file `COPY` (not env vars, just noted for context): a `backend-package.json` override fixing a real backend/frontend port-5000 conflict, and a patched `subdomain.management.js` fixing a real cookie-domain bug (see Troubleshooting below) — neither needs any composer action, they're already in the repo's `Dockerfile`.

**Social media platform API credentials (X, LinkedIn, Reddit, GitHub, Facebook, YouTube, TikTok, Pinterest, Discord, Slack, Mastodon, etc.):** the official compose file lists ~15 platform integrations, all blank by default. **Mark every one of these Optional** — a deployer only fills in credentials for the platforms they actually want to post to, and Postiz runs fine with none configured (you just can't connect that specific platform until you add its keys later). Don't require any of them. **Google OAuth (`GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET`, if listed) is the same category** — no template (this one or the official reference) can ship working Google login for every deployer, since OAuth redirect URIs must match each deployer's own unique domain. Mark Optional, and document in `README.md`/`TEMPLATE_DESCRIPTION.md` that it requires manual setup — don't leave deployers to discover the "Access blocked" error unexplained.

### `Postgres` Variables (managed plugin — `railwayapp-templates/postgres-ssl`) — 19 total, same standard pattern as every other template in this project

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `DATABASE_URL` | Auto-set by Railway's plugin — leave as is | No | Postiz's primary connection string, referenced by `railway-postiz`. |
| `DATABASE_PUBLIC_URL` | Auto-set by Railway's plugin — leave as is | No | Public/external connection string for reaching this database from outside Railway's network. |
| `PGHOST` | `${{RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname. |
| `PGPORT` | `5432` | No | Port Postgres listens on internally. Verify this is actually filled in, not left as an empty "to be filled by the user" placeholder — this exact composer glitch has recurred on this project's Umami/NocoDB/Metabase templates. |
| `PGUSER` | `${{POSTGRES_USER}}` | No | Database username. |
| `PGDATABASE` | `${{POSTGRES_DB}}` | No | Database name. |
| `PGPASSWORD` | `${{POSTGRES_PASSWORD}}` | No | Database password. |
| `POSTGRES_USER` | `postgres` | **Yes** | Username for the Postgres superuser account. |
| `POSTGRES_PASSWORD` | Whatever Railway's plugin actually prefills — **verify live via the composer screenshot, don't assume a specific `secret()` length.** This exact wrong guess has already happened on multiple other templates in this project (Evolution API, Typebot). | No | Auto-generated superuser password. |
| `POSTGRES_DB` | `railway` (Railway's own default) | **Yes** | Default database name created on startup. |
| `PGDATA` | `/var/lib/postgresql/data/pgdata` | **Yes** | Directory where Postgres stores its data files. |
| `SSL_CERT_DAYS` | `820` | **Yes** | SSL certificate validity period. |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60` | **Yes** | Seconds Railway waits for active connections before a redeploy. Verify this is actually filled in, same empty-placeholder caveat as `PGPORT`. |

### `Redis` Variables (managed plugin via `railway add --database redis`) — full list, verified live

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `REDIS_URL` | Auto-set by Railway's plugin — leave as is | No | Primary connection string, referenced by `railway-postiz`. |
| `REDIS_PUBLIC_URL` | Auto-set by Railway's plugin — leave as is | No | Public/external connection string for reaching Redis from outside Railway's network. |
| `REDISHOST` | `${{RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname. |
| `REDISPORT` | `6379` | No | Port Redis listens on internally. |
| `REDISUSER` | `default` | No | Default Redis username. |
| `REDISPASSWORD` | Auto-generated by Railway's plugin — verify live, don't assume | No | Redis auth password. |
| `REDIS_PASSWORD` | Same value as `REDISPASSWORD` — some tools read this name instead | No | Duplicate of `REDISPASSWORD` under a different variable name. |

### `selfless-dedication` (Elasticsearch) Variables — 7 total

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `discovery.type` | `single-node` | No | **Required — confirmed via a real crash, not a preemptive guess.** Without this, Elasticsearch refuses to start with `"the default discovery settings are unsuitable for production use..."`, since it assumes it's joining a multi-node production cluster. Runs as a single-node cluster here, appropriate for this use case (Temporal's internal visibility store), not a real multi-node search deployment. |
| `xpack.security.enabled` | `false` | No | Disables Elasticsearch's own auth layer — acceptable since this service has no public port and is only reachable from `remarkable-patience` over Railway's private network. |
| `ES_JAVA_OPTS` | `-Xms256m -Xmx256m` | No | Caps JVM heap size. Matches the official reference exactly — don't increase without reason, Elasticsearch here only serves Temporal's internal visibility queries, not real search traffic. |
| `cluster.routing.allocation.disk.threshold_enabled` | `true` | **Yes** | Enables disk-based shard allocation limits. |
| `cluster.routing.allocation.disk.watermark.low` | `512mb` | **Yes** | Disk watermark thresholds, matches official reference defaults. |
| `cluster.routing.allocation.disk.watermark.high` | `256mb` | **Yes** | Disk watermark threshold. |
| `cluster.routing.allocation.disk.watermark.flood_stage` | `128mb` | **Yes** | Disk watermark threshold. |

No public domain needed — internal only. Mount a Railway Volume at `/usr/share/elasticsearch/data` (persists Temporal's workflow visibility index — without it, that history resets on every redeploy).

**Important lesson baked into this row set:** if this service is ever deleted and recreated for any reason, all 7 of these variables must be manually re-applied — they do NOT carry over automatically, and this exact mistake happened once during this template's own build (see Troubleshooting).

### `temporal-postgres` Variables (raw `postgres:16` image — deliberately NOT the managed Railway plugin, to match the official reference exactly and avoid any SSL-mode mismatch with Temporal's own DB driver config, which doesn't specify SSL params) — 3 total

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `POSTGRES_USER` | `temporal` | No | Matches what `remarkable-patience`'s own `POSTGRES_USER` variable must reference. |
| `POSTGRES_PASSWORD` | `${{secret(32)}}` | No | Auto-generated. Must match what's referenced on `remarkable-patience` — set as a cross-service reference there, not independently generated (same class of desync bug already caught on this project's Typebot template). |
| `PGDATA` | `/var/lib/postgresql/data/pgdata` | **Yes** | **Required, confirmed via a real crash, not a preemptive guess.** Mounting the volume directly at `/var/lib/postgresql/data` leaves a `lost+found` directory there (standard on a freshly formatted volume filesystem), which breaks Postgres's own `initdb` — it expects a genuinely empty directory. Setting `PGDATA` to a subdirectory of the mount point fixes it, same pattern Railway's own managed Postgres plugin already uses everywhere else in this project. |

No public domain needed — internal only. Mount a Railway Volume at `/var/lib/postgresql/data` for persistence.

### `remarkable-patience` (Temporal server) Variables — custom Dockerfile (`Dockerfile.temporal`, bakes in the `dynamicconfig` file the official compose mounts locally) — 9 total

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `DB` | `postgres12` | No | Tells Temporal's auto-setup which DB driver dialect to use. |
| `DB_PORT` | `5432` | No | Port for `temporal-postgres`. |
| `POSTGRES_USER` | `${{temporal-postgres.POSTGRES_USER}}` | No | Cross-service reference — must match `temporal-postgres` exactly. |
| `POSTGRES_PWD` | `${{temporal-postgres.POSTGRES_PASSWORD}}` | No | Cross-service reference — same reasoning. |
| `POSTGRES_SEEDS` | `${{temporal-postgres.RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname of Temporal's own Postgres. |
| `DYNAMIC_CONFIG_FILE_PATH` | `config/dynamicconfig/development-sql.yaml` | No | Path (relative to the image's own working directory, `/etc/temporal`) to the config file baked into the custom Dockerfile. |
| `ENABLE_ES` | `true` | No | Enables the Elasticsearch-backed visibility store. |
| `ES_SEEDS` | `${{selfless-dedication.RAILWAY_PRIVATE_DOMAIN}}` | No | Internal hostname of the Elasticsearch service. **Use the real service name `selfless-dedication`, not a generic `elasticsearch` placeholder.** |
| `ES_VERSION` | `v7` | No | Matches the pinned `elasticsearch:7.17.27` image. |
| `TEMPORAL_NAMESPACE` | `default` | No | Default Temporal namespace. |

No public domain needed — `railway-postiz` connects to it internally via `TEMPORAL_ADDRESS`.

### `temporal-ui` Variables (raw `temporalio/ui:2.34.0` image) — 2 total

| Variable | Value | Mark Optional? | Description |
|----------|-------|-----------------|-------------|
| `TEMPORAL_ADDRESS` | `${{remarkable-patience.RAILWAY_PRIVATE_DOMAIN}}:7233` | No | Points at the real Temporal server service name. |
| `TEMPORAL_CORS_ORIGINS` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | **Yes** | Only relevant if you generate a public domain for this service — see note below. Mark Optional since a public domain isn't required. |

**Whether to expose this publicly is a judgment call, not a hard requirement.** `temporal-ui` is an internal admin/observability dashboard for inspecting workflow runs — not something Postiz's actual end users interact with. Generating a public domain makes it convenient to check on, but also exposes an unauthenticated admin panel to the internet unless you separately gate it. Consider leaving it without a public domain (private-network-only) unless you specifically want to check on Temporal workflow health from outside Railway.

### `temporal-admin-tools` Variables — no variables needed

The official compose file runs this with `stdin_open: true` and `tty: true` — it's a pure CLI container meant for `docker exec -it` style interactive admin commands (inspecting/replaying workflows manually), not a long-running service with independent function or any config of its own. On Railway, there's no equivalent of an attached interactive TTY session the way Docker Compose provides one locally. **Recommendation: include it in the composer for architectural completeness (matching the reference exactly), but expect it to just sit idle with no real functionality** — `railway ssh` into it if you ever need actual admin CLI access, don't expect it to do anything on its own. Not a blocker for Postiz's core functionality either way.

---

## 3. Secrets That Must Use `${{secret()}}`

| Variable | Template Syntax |
|----------|-----------------|
| `JWT_SECRET` (on `railway-postiz`) | `${{secret(32)}}` |
| `POSTGRES_PASSWORD` (on `temporal-postgres`) | `${{secret(32)}}` |
| `POSTGRES_PWD` (on `remarkable-patience`) | `${{temporal-postgres.POSTGRES_PASSWORD}}` — cross-reference, NOT an independent `secret()` call |
| `POSTGRES_PASSWORD` (on `Postgres`, main app DB) | Whatever Railway's plugin already prefilled — verify live, don't assume a length |
| `REDISPASSWORD`/`REDIS_PASSWORD` (on `Redis`) | Auto-generated by Railway's plugin — verify live, don't assume |

---

## 4. Volumes

| Service | Mount Path | Notes |
|---------|-----------|-------|
| `railway-postiz` | `/uploads` | Persists uploaded media. **Known gap:** the official compose also persists `/config` as a separate volume (likely holding encryption-related state) — Railway's per-service volume model doesn't obviously support two independent mount paths on one service the way Docker Compose does. This template mounts only `/uploads` as the higher-priority path; verify on first real deploy whether `/config` not persisting causes any real issue (e.g., re-encryption prompts on redeploy) and revisit if so. |
| `temporal-postgres` | `/var/lib/postgresql/data` | Standard Postgres data directory. Requires `PGDATA` set to a subdirectory, see above. |
| `selfless-dedication` | `/usr/share/elasticsearch/data` | Persists Elasticsearch's index data — without this, Temporal's workflow visibility history resets on every redeploy. |
| `Postgres` (main) | Managed automatically by the Railway plugin | No manual setup needed. |
| `Redis` | Managed automatically by the Railway plugin | No manual setup needed. |

---

## 5. Known Troubleshooting

- **`railway-postiz` crash-loops or can't reach Temporal:** confirm `TEMPORAL_ADDRESS` resolves to `remarkable-patience`'s real private domain with `:7233` appended — Postiz v2.12+ genuinely cannot start without this working, unlike Redis which some other templates treat as optional.
- **`remarkable-patience` (Temporal server) fails to start:** check `POSTGRES_SEEDS`/`POSTGRES_USER`/`POSTGRES_PWD` match `temporal-postgres` exactly, and that `ES_SEEDS` points at a reachable `selfless-dedication` instance — Temporal's auto-setup process depends on both being up before it can complete its own bootstrap.
- **Elasticsearch (`selfless-dedication`) fails to start / crashes:** check the service has enough memory allocated (256MB heap via `ES_JAVA_OPTS`, but the container needs meaningfully more than that to run at all — budget at least 512MB-1GB for this specific service, more than a typical lightweight template service in this project).
- **Elasticsearch bootstrap check failure — `"the default discovery settings are unsuitable for production use..."`:** means `discovery.type=single-node` is missing. Confirmed via a real crash during this template's own build: when the service was deleted and recreated (to fix an unrelated `USER root` volume-permission issue), all 7 Elasticsearch variables were lost and had to be manually re-applied — they do NOT carry over automatically when a service is recreated.
- **Backend genuinely up, but registration/login redirects back to the login screen instead of the real app:** a real bug found and fixed during this template's build — Postiz's own `getCookieUrlFromDomain()` function computes the auth cookie's `Domain` attribute from `FRONTEND_URL` using the `tldts` library, which on Railway's default `*.up.railway.app` domain resolves to `Domain=.railway.app`. Real browsers reject this outright (`up.railway.app` is on the actual Public Suffix List, protecting against exactly this kind of cross-tenant cookie scope, even though `tldts`'s bundled data doesn't reflect that) — so registration succeeds server-side (`POST /api/auth/register` returns a real `200`), but the session cookie never lands in the browser. **Already fixed in this template's `Dockerfile`** via a patched `fixes/subdomain.management.js` copied over the compiled output, forcing it to always use the exact hostname instead of a guessed parent domain — no composer action needed, just documented here so the fix isn't accidentally reverted or misunderstood later.
- **Backend/frontend port conflict inside the `railway-postiz` container:** already fixed via the `backend-package.json` override baked into the Dockerfile (forces the backend onto internal port 3000 instead of colliding with the frontend on 5000) — inherited from a real fix found during an earlier build attempt of this exact template. If this breaks again on a future Postiz version bump, re-verify the internal file path `/app/apps/backend/package.json` is still correct for that version.
- **Google (or any OAuth) login shows "Access blocked" / "not allowed":** expected without manual setup — no template can ship working OAuth for every deployer, since redirect URIs must match each deployer's own domain. Document this plainly rather than leaving it unexplained; email/password registration works independently and is the supported default path.
- **This is by far the most expensive template in this project to run** — 8 services including a full Temporal cluster and Elasticsearch. Budget accordingly when advising deployers on expected monthly cost; this is not a $5/month template.

---

## 6. Post-Deploy Steps

After the template is published, test-deploy from a fresh Railway account (incognito window) and verify:

1. No "needs configuration" prompts appear for Postgres's or Redis's auto-injected variables.
2. All 8 services come online — this will take noticeably longer than any other template in this project, since `railway-postiz` depends on `remarkable-patience` depending on both `temporal-postgres` and `selfless-dedication` all being healthy first. Give it real time before assuming something's broken.
3. The app responds with a real `200`/`307` at `/`.
4. Open the actual Railway domain in a browser and complete real account creation — then **actually refresh and confirm the session persists** (don't just trust a `200` on the register call itself — verified during this template's build that registration can succeed server-side while the session cookie still fails to persist in the browser for an unrelated reason).
5. **Actually test the core scheduling flow**, not just that the app loads: connect a test social platform (or at minimum, create a draft post) and confirm it saves correctly, since that's the functionality that depends on Temporal actually working end-to-end, not just being "online."
