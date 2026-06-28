#!/usr/bin/env bash
#
# setup — b5hunt (EA FC Tactical Intelligence)
# ----------------------------------------------------------------------------
# First-time provisioning for a fresh checkout on the server. Run this ONCE
# after cloning the repo (or after a server rebuild). It prepares the app:
# env file, dependencies, app key, database, storage, caches, workers.
#
#   Usage:   ./setup
#
# It is mostly idempotent — re-running it will not wipe your .env or DB.
# For day-to-day releases use ./deploy instead.
# ----------------------------------------------------------------------------

set -Eeuo pipefail

# ============================ Config (edit me) ==============================
APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")" && pwd)}"
PHP="${PHP:-php}"
COMPOSER="${COMPOSER:-composer}"
APP_ENV="${APP_ENV:-production}"          # production | local
SEED_DATABASE="${SEED_DATABASE:-false}"   # run db:seed after migrate
BUILD_ASSETS="${BUILD_ASSETS:-true}"
# ===========================================================================

c_reset="\033[0m"; c_blue="\033[1;34m"; c_green="\033[1;32m"; c_red="\033[1;31m"; c_yellow="\033[1;33m"
step() { echo -e "\n${c_blue}▶ $*${c_reset}"; }
ok()   { echo -e "${c_green}✔ $*${c_reset}"; }
warn() { echo -e "${c_yellow}⚠ $*${c_reset}"; }
die()  { echo -e "${c_red}✘ $*${c_reset}" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

cd "$APP_DIR" || die "APP_DIR not found: $APP_DIR"

echo -e "${c_blue}=============================================${c_reset}"
echo -e "${c_blue}  b5hunt setup — env: ${APP_ENV}${c_reset}"
echo -e "${c_blue}=============================================${c_reset}"

# 0) Prerequisite check -----------------------------------------------------
step "Checking prerequisites"
MISSING=0
check_bin() { if have "$1"; then ok "$1 found ($(command -v "$1"))"; else warn "$1 NOT found"; MISSING=1; fi; }
check_bin "$PHP"
check_bin "$COMPOSER"
check_bin git
[ "$BUILD_ASSETS" = "true" ] && { check_bin node; check_bin npm; }
# PHP version + required extensions (Laravel 12 needs PHP >= 8.2)
if have "$PHP"; then
  "$PHP" -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);' \
    && ok "PHP version OK ($($PHP -r 'echo PHP_VERSION;'))" \
    || die "PHP >= 8.2 required"
  for ext in pdo_mysql mbstring openssl tokenizer xml ctype json bcmath curl fileinfo redis; do
    "$PHP" -m | grep -iq "^$ext$" && ok "ext: $ext" || warn "ext MISSING: $ext"
  done
fi
[ "$MISSING" = "1" ] && warn "Some tools are missing — install them before continuing."

# 1) Environment file -------------------------------------------------------
step "Preparing .env"
if [ ! -f .env ]; then
  [ -f .env.example ] || die ".env.example not found — is the Laravel app scaffolded?"
  cp .env.example .env
  ok "Created .env from .env.example  →  EDIT IT NOW (DB, Redis, APP_URL, mail, Reverb, Stripe/Paddle)"
else
  ok ".env already exists (left untouched)"
fi

# 2) PHP dependencies -------------------------------------------------------
step "Installing PHP dependencies"
if [ "$APP_ENV" = "production" ]; then
  $COMPOSER install --no-dev --prefer-dist --optimize-autoloader --no-interaction
else
  $COMPOSER install --no-interaction
fi
ok "Composer done"

# 3) App key ----------------------------------------------------------------
step "Application key"
if grep -q "^APP_KEY=base64:" .env 2>/dev/null; then
  ok "APP_KEY already set"
else
  "$PHP" artisan key:generate --force
  ok "APP_KEY generated"
fi

# 4) Frontend assets --------------------------------------------------------
if [ "$BUILD_ASSETS" = "true" ]; then
  step "Installing & building frontend"
  if [ -f package-lock.json ]; then npm ci; else npm install; fi
  npm run build
  ok "Assets built"
fi

# 5) Storage + permissions --------------------------------------------------
step "Storage & permissions"
"$PHP" artisan storage:link >/dev/null 2>&1 || true
chmod -R ug+rw storage bootstrap/cache 2>/dev/null || true
ok "Storage linked & writable"

# 6) Database ---------------------------------------------------------------
step "Database migrations"
warn "Make sure DB credentials in .env are correct and the database exists."
"$PHP" artisan migrate --force
if [ "$SEED_DATABASE" = "true" ]; then
  "$PHP" artisan db:seed --force
  ok "Database seeded"
fi
ok "Migrations done"

# 7) Caches -----------------------------------------------------------------
step "Warming caches"
"$PHP" artisan optimize >/dev/null 2>&1 || { "$PHP" artisan config:cache; "$PHP" artisan route:cache; "$PHP" artisan view:cache; }
"$PHP" artisan filament:cache-components >/dev/null 2>&1 || true
"$PHP" artisan icons:cache >/dev/null 2>&1 || true
ok "Caches warmed"

# 8) Worker hint ------------------------------------------------------------
step "Background workers"
cat <<'EOF'
  Register these as services (systemd or supervisor) so they survive reboots:

    • Queue/Horizon :  php artisan horizon
    • Websockets    :  php artisan reverb:start
    • Scheduler     :  add to crontab →  * * * * * cd /path/to/app && php artisan schedule:run >> /dev/null 2>&1

  systemd example for Horizon (/etc/systemd/system/b5hunt-horizon.service):

    [Unit]
    Description=b5hunt Horizon
    After=network.target redis.service mysql.service
    [Service]
    User=www-data
    Restart=always
    ExecStart=/usr/bin/php /path/to/app/artisan horizon
    [Install]
    WantedBy=multi-user.target

  Then:  sudo systemctl enable --now b5hunt-horizon
EOF

echo
ok "Setup finished ✅  — from now on use ./deploy.sh for releases."
