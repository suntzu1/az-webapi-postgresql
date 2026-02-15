#!/bin/bash
# Azure Infrastructure Deployment Script
# This script creates the necessary Azure resources for the Sports API

# Variables - Update these with your values
RESOURCE_GROUP="rg-sportsapi"
LOCATION="eastus"
APP_SERVICE_PLAN="plan-sportsapi"
APP_SERVICE_NAME="app-sportsapi-${RANDOM}"
POSTGRES_SERVER="psql-sportsapi-${RANDOM}"
POSTGRES_DB="sportsapi"
POSTGRES_ADMIN_USER="sqladmin"
POSTGRES_ADMIN_PASSWORD="P@ssw0rd123!"  # Change this to a secure password

echo "Creating Resource Group..."
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

echo "Creating PostgreSQL Flexible Server..."
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --location $LOCATION \
  --admin-user $POSTGRES_ADMIN_USER \
  --admin-password $POSTGRES_ADMIN_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --storage-size 32 \
  --version 16 \
  --public-access 0.0.0.0

echo "Creating PostgreSQL Database..."
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER \
  --database-name $POSTGRES_DB

echo "Configuring firewall rules..."
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --rule-name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

echo "Creating App Service Plan..."
az appservice plan create \
  --name $APP_SERVICE_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku B1 \
  --is-linux

echo "Creating App Service..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN \
  --name $APP_SERVICE_NAME \
  --runtime "DOTNETCORE:9.0"

# Construct connection string
CONNECTION_STRING="Host=${POSTGRES_SERVER}.postgres.database.azure.com;Database=${POSTGRES_DB};Username=${POSTGRES_ADMIN_USER};Password=${POSTGRES_ADMIN_PASSWORD};SslMode=Require"

echo "Configuring App Service connection string..."
az webapp config connection-string set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --connection-string-type PostgreSQL \
  --settings DefaultConnection="${CONNECTION_STRING}"

echo "Configuring App Service settings..."
az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $APP_SERVICE_NAME \
  --settings ASPNETCORE_ENVIRONMENT="Production"

echo "Deployment completed!"
echo "App Service URL: https://${APP_SERVICE_NAME}.azurewebsites.net"
echo "PostgreSQL Server: ${POSTGRES_SERVER}.postgres.database.azure.com"
echo ""
echo "To deploy your application, use:"
echo "az webapp deployment source config-zip --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME --src <path-to-zip-file>"
