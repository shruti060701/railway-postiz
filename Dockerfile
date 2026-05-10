FROM ghcr.io/gitroomhq/postiz-app:v2.11.3

# Railway volumes mount as root — run as root to avoid permission issues
USER root

ENV PORT=5000
ENV NODE_ENV=production
ENV IS_GENERAL=true
ENV STORAGE_PROVIDER=local
ENV UPLOAD_DIRECTORY=/uploads
ENV BACKEND_INTERNAL_URL=http://localhost:3000

EXPOSE 5000
