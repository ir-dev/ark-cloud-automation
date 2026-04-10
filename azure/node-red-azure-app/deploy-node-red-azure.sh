#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 <resource-group> <app-name> [location] [app-service-plan] [sku]

Examples:
  $0 my-rg my-node-red-app eastus my-node-red-plan P1v2

Parameters:
  resource-group   - Azure resource group name
  app-name         - Unique Azure Web App name
  location         - Azure region (default: eastus)
  app-service-plan - App Service plan name (default: <app-name>-plan)
  sku              - Pricing sku (default: P1v2)
EOF
  exit 1
}

if [ "${1:-}" = "" ] || [ "${2:-}" = "" ]; then
  usage
fi

RESOURCE_GROUP="$1"
APP_NAME="$2"
LOCATION="${3:-eastus}"
PLAN_NAME="${4:-${APP_NAME}-plan}"
SKU="${5:-P1v2}"
NODE_VERSION="20-lts"

echo "[1/10] Validating Azure CLI login and required tools..."
if ! command -v az >/dev/null 2>&1; then
  echo "ERROR: Azure CLI is not installed. Install from https://learn.microsoft.com/cli/azure/install-azure-cli"
  exit 2
fi

az account show >/dev/null 2>&1 || {
  echo "ERROR: Azure CLI not logged in. Run: az login"
  exit 2
}

echo "[2/10] Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

echo "[3/10] Creating App Service plan '$PLAN_NAME' with SKU '$SKU'..."
az appservice plan create \
  --name "$PLAN_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --sku "$SKU" \
  --is-linux \
  --location "$LOCATION"

echo "[4/10] Creating Linux Web App '$APP_NAME' with Node $NODE_VERSION..."
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$PLAN_NAME" \
  --name "$APP_NAME" \
  --runtime "NODE|$NODE_VERSION"

echo "[5/11] Enabling FTP/FTPS and HTTPS-only production settings..."
az webapp config set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --ftps-state AllAllowed \
  --http20-enabled true \
  --always-on true

az webapp update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --https-only true

echo "[6/11] Configuring diagnostic logging for the Web App..."
az webapp log config \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --application-logging filesystem \
  --web-server-logging filesystem \
  --detailed-error-messages true \
  --failed-request-tracing true \
  --level verbose

echo "[7/11] Applying App Settings for persistent storage, build, startup timeout, and Node-RED config..."
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --settings \
    WEBSITE_RUN_FROM_PACKAGE=0 \
    WEBSITES_ENABLE_APP_SERVICE_STORAGE=true \
    WEBSITES_PORT=8080 \
    PORT=8080 \
    WEBSITE_NODE_DEFAULT_VERSION=18.20.0 \
    SCM_DO_BUILD_DURING_DEPLOYMENT=true \
    SCM_COMMAND_IDLE_TIMEOUT=1800 \
    WEBSITES_CONTAINER_START_TIME_LIMIT=1800 \
    WEBSITES_CONTAINER_SHUTDOWN_TIME_LIMIT=1800 \
    NODE_RED_USER_DIR=/home/site/wwwroot/.node-red \
    NODE_RED_ENABLE_PROJECTS=true \
    NODE_RED_DISABLE_HTTP_ADMIN=false \
    NODE_RED_ENABLE_SAFE_MODE=false \
    NODE_RED_ADMIN_ROOT=/red

echo "[8/11] Preparing local deployment package..."
if [ -f package-lock.json ] || [ -f npm-shrinkwrap.json ]; then
  echo "  Installing local dependencies so deployment package metadata is consistent..."
  npm install
fi

rm -f app.zip
zip -r app.zip . -x 'node_modules/*' '.git/*' 'app.zip' >/dev/null

echo "[8/10] Deploying application via zip deployment..."
az webapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --src app.zip

echo "[9/10] Recycling web app to apply settings and restart cleanly..."
az webapp restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"

echo "[10/11] Downloading recent diagnostics logs..."
LOG_ARCHIVE="${APP_NAME}-azure-logs-$(date +%Y%m%d%H%M%S).zip"
az webapp log download \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --log-file "$LOG_ARCHIVE"
echo "  Logs downloaded to $LOG_ARCHIVE"

echo "[11/11] Deployment complete. App URL and FTP/FTPS publishing profile:"
WEBAPP_URL="https://${APP_NAME}.azurewebsites.net"
echo "  Web App URL: $WEBAPP_URL"
az webapp deployment list-publishing-profiles \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --query "[?publishMethod=='FTP' || publishMethod=='FTPS']" --output table

echo "
Tip: Node-RED user data and palette persistence are stored under /home/site/wwwroot/.node-red inside the App Service container."
