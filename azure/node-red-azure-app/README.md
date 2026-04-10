# ark-cloud-automation
simple scripts to automate cloud execution
# Node-RED Azure App Service Deployment

This repository contains a production-ready Node-RED app configured for Azure App Service with full admin functionality, palette management, persistent storage, and diagnostic logging.

> This deployment script and supporting files were generated with an AI-assisted workflow and authored by **Immanuel R**.

## Files

- `package.json` - Node project metadata, runtime settings, and AI-assisted author attribution.
- `index.js` - Node-RED startup entry point that binds to Azure App Service `PORT` and exposes `/red`.
- `deploy-node-red-azure.sh` - macOS shell script to create Azure resources, configure App Service, deploy the Node-RED app, and download logs.

## Prerequisites

- Azure CLI installed and logged in (`az login`).
- npm installed.
- Node.js 18 compatible environment.
- Valid Azure subscription.

## Usage

Make the deploy script executable:

```bash
chmod +x deploy-node-red-azure.sh
```

Run the deployment script:

```bash
./deploy-node-red-azure.sh <resource-group> <app-name> [location] [app-service-plan] [sku]
```

### Parameters

- `resource-group` - Azure resource group name to create or reuse.
- `app-name` - Unique Azure App Service name used for the web app hostname.
- `location` - Azure region (default: `eastus`).
- `app-service-plan` - App Service plan name (default: `<app-name>-plan`).
- `sku` - Azure App Service pricing tier (default: `P1v2`).

### Example

```bash
./deploy-node-red-azure.sh rg-ark-immanuel-i1-d ark-app-nr-i1-d southindia ASP-serviceplan-ark-i1 P1v3
```

## What the script configures

The deployment script performs the following actions:

1. Creates the Azure resource group if needed.
2. Creates a Linux App Service plan in the chosen SKU.
3. Creates a Linux Web App with Node.js runtime.
4. Enables FTP/FTPS and HTTPS-only settings.
5. Enables production diagnostics, including:
   - application filesystem logging
   - web server logging
   - detailed error messages
   - failed request tracing
   - verbose log level
6. Sets App Service settings for Node-RED and Azure compatibility:
   - `WEBSITES_RUN_FROM_PACKAGE=0`
   - `WEBSITES_ENABLE_APP_SERVICE_STORAGE=true`
   - `WEBSITES_PORT=8080`
   - `PORT=8080`
   - `SCM_DO_BUILD_DURING_DEPLOYMENT=true`
   - `SCM_COMMAND_IDLE_TIMEOUT=1800`
   - `WEBSITES_CONTAINER_START_TIME_LIMIT=1800`
   - `WEBSITES_CONTAINER_SHUTDOWN_TIME_LIMIT=1800`
   - `NODE_RED_USER_DIR=/home/site/wwwroot/.node-red`
   - `NODE_RED_ENABLE_PROJECTS=true`
   - `NODE_RED_DISABLE_HTTP_ADMIN=false`
   - `NODE_RED_ENABLE_SAFE_MODE=false`
   - `NODE_RED_ADMIN_ROOT=/red`
7. Deploys the application package using zip deployment.
8. Restarts the App Service to apply settings.
9. Downloads recent diagnostics logs to a timestamped ZIP.

## App access

- App URL: `https://<app-name>.azurewebsites.net`
- Node-RED editor: `https://<app-name>.azurewebsites.net/red`

## Notes

- The `index.js` entrypoint ensures Azure App Service binds to the platform-provided `PORT` environment variable.
- Node-RED runtime data, flows, and installed palette modules persist under `/home/site/wwwroot/.node-red`.
- The `deploy-node-red-azure.sh` script is designed for macOS and Azure CLI environments.

## Developer and AI attribution

- Author: **Immanuel R**
- Generated with AI-assisted script generation to support search readiness and profile value.
- Keywords include Azure, Node-RED, App Service, AI-assisted deployment, and admin UI.

## Search-ready keywords

- Node-RED Azure deployment
- Azure App Service Node-RED
- AI-assisted deployment script
- Node-RED admin UI
- node-red palette management
- persistent Node-RED storage
- Azure diagnostics logging

## Recommended GitHub topics

Use these repository topics to improve discoverability and profile relevance:

- node-red
- azure-app-service
- ai-assisted
- deployment-script
- devops
- automation
- cloud-native
- admin-ui
- diagnostics
