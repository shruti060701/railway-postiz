FROM ghcr.io/gitroomhq/postiz-app:v2.22.1

# Railway volumes mount as root; this was found necessary via real testing
# on an earlier build attempt of this template (not a preemptive guess) -
# re-verify on first live deploy of this version in case upstream changed.
USER root

# Postiz's backend inherits the global PORT env var (5000) and tries to bind
# there, conflicting with the frontend/nginx process which also listens on
# 5000. Overriding the backend's own start script to force it onto internal
# port 3000 instead - matches BACKEND_INTERNAL_URL below and the official
# reference docker-compose's own internal port split.
COPY backend-package.json /app/apps/backend/package.json

# Real bug, confirmed via a live signup attempt: Postiz's own cookie-domain
# calculation (getCookieUrlFromDomain) uses tldts to guess an eTLD+1 from
# FRONTEND_URL and scopes the auth cookie to it. On Railway's default
# *.up.railway.app domain this computes Domain=.railway.app, which real
# browsers silently reject (it's on the actual Public Suffix List, even
# though tldts's bundled data doesn't know that) - so login/register
# succeed server-side but the session cookie never lands in the browser.
# Patching the compiled file to always use the exact hostname instead,
# which every browser accepts unconditionally.
COPY fixes/subdomain.management.js /app/apps/backend/dist/libraries/helpers/src/subdomain/subdomain.management.js

ENV PORT=5000
ENV NODE_ENV=production
ENV IS_GENERAL=true
ENV STORAGE_PROVIDER=local
ENV UPLOAD_DIRECTORY=/uploads
ENV BACKEND_INTERNAL_URL=http://localhost:3000
ENV RUN_CRON=true
ENV DISABLE_REGISTRATION=false

EXPOSE 5000
