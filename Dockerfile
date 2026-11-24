# Stage 1: Build Flutter Web release bundle
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Build-time configuration injected via --dart-define
ARG BASE_HREF=/
ARG APP_NAME=SpendWise
ARG APP_ENV=production
ARG API_BASE_URL=
ARG STORAGE_BACKEND=local
ARG DEFAULT_CURRENCY=EUR
ARG DEFAULT_MONTHLY_BUDGET=0

# Copy dependency manifests first for better Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy application source
COPY . .

# Compile release web bundle
RUN flutter build web --release \
    --base-href="${BASE_HREF}" \
    --dart-define=APP_NAME="${APP_NAME}" \
    --dart-define=APP_ENV="${APP_ENV}" \
    --dart-define=API_BASE_URL="${API_BASE_URL}" \
    --dart-define=STORAGE_BACKEND="${STORAGE_BACKEND}" \
    --dart-define=DEFAULT_CURRENCY="${DEFAULT_CURRENCY}" \
    --dart-define=DEFAULT_MONTHLY_BUDGET="${DEFAULT_MONTHLY_BUDGET}"

# Stage 2: Serve static bundle via lightweight nginx
FROM nginx:alpine AS runtime

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1/ > /dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
