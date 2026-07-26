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

ENV PORT=5000
ENV NODE_ENV=production
ENV IS_GENERAL=true
ENV STORAGE_PROVIDER=local
ENV UPLOAD_DIRECTORY=/uploads
ENV BACKEND_INTERNAL_URL=http://localhost:3000
ENV RUN_CRON=true
ENV DISABLE_REGISTRATION=false

EXPOSE 5000
