#!/usr/bin/env bash
# ==============================================================================
# BusSense AI - Production-Like Staging Deployment Script
# Target: Ubuntu 22.04 LTS / Debian 12
# Project: BusSense AI (Greater Kochi Transit Intelligence Platform)
# ==============================================================================

set -euo pipefail

DEPLOY_DIR="/opt/bussense"
REPO_URL="https://github.com/Antony0610/BusSense-AI.git"
BRANCH="${1:-master}"
LOG_FILE="/var/log/bussense/deploy_$(date +%Y%m%d_%H%M%S).log"

mkdir -p /var/log/bussense
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "=============================================================================="
echo " Starting BusSense AI Staging Deployment: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo " Target Directory: ${DEPLOY_DIR} | Branch: ${BRANCH}"
echo "=============================================================================="

# 1. Prerequisite Verification
echo "[1/8] Verifying system prerequisites..."
for cmd in git python3 node npm systemctl nginx curl; do
    if ! command -v "${cmd}" &> /dev/null; then
        echo "ERROR: Required command '${cmd}' is not installed."
        exit 1
    fi
done
echo "  [OK] System packages verified."

# 2. Source Code Sync
echo "[2/8] Synchronizing repository code..."
if [ ! -d "${DEPLOY_DIR}/.git" ]; then
    echo "  Cloning repository..."
    mkdir -p "${DEPLOY_DIR}"
    git clone "${REPO_URL}" "${DEPLOY_DIR}"
fi

cd "${DEPLOY_DIR}"
git fetch origin "${BRANCH}"
git checkout "${BRANCH}"
git pull origin "${BRANCH}"
DEPLOYED_COMMIT=$(git rev-parse HEAD)
echo "  [OK] Checked out commit: ${DEPLOYED_COMMIT}"

# 3. Backend Python Environment & Dependencies
echo "[3/8] Setting up backend virtualenv..."
cd "${DEPLOY_DIR}/backend"
if [ ! -d ".venv" ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
echo "  [OK] Backend virtualenv updated."

# 4. Frontend Node.js Dependencies & Production Build
echo "[4/8] Building Next.js Authority Frontend..."
cd "${DEPLOY_DIR}/frontend"
npm ci --prefer-offline --no-audit
npm run build
echo "  [OK] Next.js compilation completed."

# 5. Service Files & Permissions
echo "[5/8] Configuring systemd services and permissions..."
id -u bussense &>/dev/null || useradd -r -s /bin/false bussense
chown -R bussense:bussense "${DEPLOY_DIR}"

cp "${DEPLOY_DIR}/deploy/systemd/bussense-backend.service" /etc/systemd/system/
cp "${DEPLOY_DIR}/deploy/systemd/bussense-frontend.service" /etc/systemd/system/
systemctl daemon-reload

# 6. Service Restarts
echo "[6/8] Restarting application services..."
systemctl enable bussense-backend
systemctl enable bussense-frontend
systemctl restart bussense-backend
systemctl restart bussense-frontend

# 7. Reverse Proxy Configuration
echo "[7/8] Verifying Nginx reverse proxy..."
if [ -f "${DEPLOY_DIR}/deploy/nginx/bussense.conf" ]; then
    cp "${DEPLOY_DIR}/deploy/nginx/bussense.conf" /etc/nginx/sites-available/bussense.conf
    ln -sf /etc/nginx/sites-available/bussense.conf /etc/nginx/sites-enabled/
    nginx -t
    systemctl reload nginx
    echo "  [OK] Nginx reloaded successfully."
fi

# 8. Post-Deployment Smoke Verification
echo "[8/8] Executing live staging smoke checks..."
sleep 3

BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/health || echo "FAIL")
FRONTEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000 || echo "FAIL")

echo "  Backend /health HTTP status: ${BACKEND_HEALTH}"
echo "  Frontend / HTTP status: ${FRONTEND_STATUS}"

if [ "${BACKEND_HEALTH}" = "200" ] && [ "${FRONTEND_STATUS}" = "200" ]; then
    echo "=============================================================================="
    echo " DEPLOYMENT SUCCESSFUL: Staging operational at $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo " Deployed Commit: ${DEPLOYED_COMMIT}"
    echo " Log File: ${LOG_FILE}"
    echo "=============================================================================="
    exit 0
else
    echo "ERROR: Post-deployment smoke check failed. Inspect logs with journalctl -u bussense-backend."
    exit 1
fi

