#!/usr/bin/env bash
#
# deploy — b5hunt (EA FC Tactical Intelligence)
# ----------------------------------------------------------------------------
# Recurring deployment script. Run this on the server (over SSH) after every
# release. It pulls the latest code and runs all the release steps in order.
#
#   Usage:   ./deploy                 # deploy the default branch
#            ./deploy main            # deploy a specific branch
#            BRANCH=main ./deploy     # same, via env var
#
# Safe to re-run. Stops on the first error (set -e). Always tries to bring the
# app back UP even if a step fails (trap).
# ----------------------------------------------------------------------------

set -Eeuo pipefail

# ============================ Config (edit me) ==============================
APP_DIR="${APP_DIR:-$(cd "$(dirname "$0")" && pwd)}"   # repo root (this folder)
BRANCH="${1:-${BRANCH:-main}}"
PHP="${PHP:-php}"
COMPOSER="${COMPOSER:-composer}"

# Feature flags — turn things off if you don't use them yet.
BUILD_ASSETS="${BUILD_ASSETS:-true}"   # npm ci && npm run build (Vite)
USE_HORIZON="${USE_HORIZON:-true}"     # restart Horizon workers after deploy
USE_REVERB="${USE_REVERB:-true}"       # gracefully restart Reverb (websockets)
RUN_MIGRATIONS="${RUN_MIGRATIONS:-true}"
MAINTENANCE_MODE="${MAINTENANCE_MODE:-true}"  # php artisan down during deploy
# ===========================================================================

# --------------------------- pretty logging --------------------------------
c_reset="\033[0m"; c_blue="\033[1;34m"; c_green="\033[1;32m"; c_red="\033[1;31m"; c_yellow="\033[1;33m"
step() { echo -e "\n${c_blue}▶ $*${c_reset}"; }
ok()   { echo -e "${c_green}✔ $*${c_reset}"; }
warn() { echo -e "${c_yellow}⚠ $*${c_reset}"; }
die()  { echo -e "${c_red}✘ $*${c_reset}" >&2; exit 1; }

bring_up() {
  if [ "$MAINTENANCE_MODE" = "true" ]; then
    "$PHP" artisan up >/dev/null 2>&1 || true
  fi
}
trap 'echo; warn "Deploy failed — bringing app back up."; bring_up' ERR

cd "$APP_DIR" || die "APP_DIR not found: $APP_DIR"
[ -f artisan ] && [ -d .git ] || die "This does not look like a Laravel repo: $APP_DIR"

# First-time guard: .env must already exist and be configured.
# On a brand-new server run ./setup.sh ONCE (it creates .env, then you edit
# DB/Redis/Reverb/APP_URL), then use ./deploy.sh for every release after that.
[ -f .env ] || die ".env not found — run ./setup.sh first, fill in DB/Redis/Reverb, then re-run ./deploy.sh"

echo -e "${c_blue}=============================================${c_reset}"
echo -e "${c_blue}  b5hunt deploy — branch: ${BRANCH}${c_reset}"
echo -e "${c_blue}  $(date)${c_reset}"
echo -e "${c_blue}=============================================${c_reset}"

# 1) Maintenance mode -------------------------------------------------------
if [ "$MAINTENANCE_MODE" = "true" ]; then
  step "Enabling maintenance mode"
  "$PHP" artisan down --retry=15 --render="errors::503" >/dev/null 2>&1 || "$PHP" artisan down || true
  ok "App is down"
fi

# 2) Pull latest code -------------------------------------------------------
step "Pulling latest code ($BRANCH)"
git fetch --all --prune
git checkout "$BRANCH"
git reset --hard "origin/$BRANCH"      # server tree is disposable; origin is the source of truth
ok "Code updated to $(git rev-parse --short HEAD)"

# 3) PHP dependencies -------------------------------------------------------
step "Installing PHP dependencies"
$COMPOSER install --no-dev --prefer-dist --optimize-autoloader --no-interaction --no-progress
ok "Composer done"

# 4) Frontend assets --------------------------------------------------------
if [ "$BUILD_ASSETS" = "true" ]; then
  step "Building frontend assets (Vite)"
  # --include=dev so the build tools (vite/tailwind) install even if NODE_ENV=production
  if [ -f package-lock.json ]; then npm ci --include=dev; else npm install; fi
  npm run build
  ok "Assets built"
else
  warn "Skipping asset build (BUILD_ASSETS=false)"
fi

# 5) Database migrations ----------------------------------------------------
if [ "$RUN_MIGRATIONS" = "true" ]; then
  step "Running migrations"
  "$PHP" artisan migrate --force
  ok "Migrations done"
else
  warn "Skipping migrations (RUN_MIGRATIONS=false)"
fi

# 6) Rebuild caches (clear then warm) --------------------------------------
step "Rebuilding caches"
"$PHP" artisan optimize:clear
"$PHP" artisan config:cache
"$PHP" artisan route:cache
"$PHP" artisan view:cache
"$PHP" artisan event:cache
# Filament assets + icon cache (no-ops if Filament isn't installed yet)
"$PHP" artisan filament:cache-components >/dev/null 2>&1 || true
"$PHP" artisan icons:cache              >/dev/null 2>&1 || true
ok "Caches warmed"

# 7) Storage symlink (idempotent) ------------------------------------------
step "Ensuring storage symlink"
"$PHP" artisan storage:link >/dev/null 2>&1 || true
ok "Storage linked"

# 8) Restart background workers --------------------------------------------
step "Restarting workers"
if [ "$USE_HORIZON" = "true" ]; then
  "$PHP" artisan horizon:terminate >/dev/null 2>&1 || warn "Horizon not running (supervisor will respawn it)"
else
  "$PHP" artisan queue:restart >/dev/null 2>&1 || true
fi
if [ "$USE_REVERB" = "true" ]; then
  "$PHP" artisan reverb:restart >/dev/null 2>&1 || warn "Reverb not running"
fi
ok "Workers signalled to restart"

# 9) Back online ------------------------------------------------------------
bring_up
trap - ERR
ok "App is UP — deploy finished ✅  ($(git rev-parse --short HEAD))"
