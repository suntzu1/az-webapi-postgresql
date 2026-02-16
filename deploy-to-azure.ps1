# Azure Deployment Script for Client Campaign Manager
# Run this script step-by-step (copy each section)

# ========================================
# STEP 1: AZURE LOGIN
# ========================================
az login
az account list --output table
# az account set --subscription "YOUR_SUBSCRIPTION_NAME"  # Uncomment if needed

# ========================================
# STEP 2: SET VARIABLES
# ========================================
$resourceGroup = "rg-campaign-manager"
$location = "eastus"
$dbServerName = "campaignmanager-db"
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "YourSecurePassword123!"  # CHANGE THIS!
$apiAppName = "campaignmanager-api"
$frontendAppName = "campaignmanager-frontend"
$appServicePlan = "plan-campaign-manager"

# ========================================
# STEP 3: CREATE RESOURCE GROUP
# ========================================
az group create --name $resourceGroup --location $location

# ========================================
# STEP 4: CREATE POSTGRESQL DATABASE
# ========================================
Write-Host "Creating PostgreSQL database..." -ForegroundColor Green

az postgres flexible-server create `
  --resource-group $resourceGroup `
  --name $dbServerName `
  --location $location `
  --admin-user $dbAdminUser `
  --admin-password $dbPassword `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --storage-size 32 `
  --public-access 0.0.0.0-255.255.255.255

az postgres flexible-server db create `
  --resource-group $resourceGroup `
  --server-name $dbServerName `
  --database-name $dbName

# ========================================
# STEP 5: CREATE APP SERVICE
# ========================================
Write-Host "Creating App Service for API..." -ForegroundColor Green

az appservice plan create `
  --name $appServicePlan `
  --resource-group $resourceGroup `
  --location $location `
  --sku B1 `
  --is-linux

az webapp create `
  --resource-group $resourceGroup `
  --plan $appServicePlan `
  --name $apiAppName `
  --runtime "DOTNETCORE:9.0"

# ========================================
# STEP 6: CONFIGURE APP SETTINGS
# ========================================
Write-Host "Configuring connection string..." -ForegroundColor Green

$connectionString = "Server=$dbServerName.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"

az webapp config connection-string set `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --connection-string-type PostgreSQL `
  --settings DefaultConnection=$connectionString

# ========================================
# STEP 7: BUILD AND DEPLOY BACKEND
# ========================================
Write-Host "Building and deploying backend API..." -ForegroundColor Green

cd D:\Work\Outform\az-webapi-postgresql\SportsApi
dotnet publish -c Release -o ./publish

Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

az webapp deployment source config-zip `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --src ./deploy.zip

# ========================================
# STEP 8: RUN DATABASE MIGRATIONS
# ========================================
Write-Host "Running database migrations..." -ForegroundColor Green

dotnet ef database update --connection $connectionString

# ========================================
# STEP 9: GET API URL
# ========================================
$apiUrl = "https://$apiAppName.azurewebsites.net"
Write-Host "API URL: $apiUrl" -ForegroundColor Cyan

# ========================================
# STEP 10: UPDATE FRONTEND ENVIRONMENT
# ========================================
Write-Host "Updating frontend configuration..." -ForegroundColor Green

$envContent = "REACT_APP_API_URL=$apiUrl"
Set-Content -Path "D:\Work\Outform\az-webapi-postgresql\sports-client\.env.production" -Value $envContent

# ========================================
# STEP 11: BUILD FRONTEND
# ========================================
Write-Host "Building frontend..." -ForegroundColor Green

cd D:\Work\Outform\az-webapi-postgresql\sports-client
npm install
npm run build

# ========================================
# STEP 12: CREATE STATIC WEB APP
# ========================================
Write-Host "Creating Static Web App..." -ForegroundColor Green
Write-Host "You'll need to do this via Azure Portal or GitHub integration" -ForegroundColor Yellow
Write-Host "Go to: https://portal.azure.com/#create/Microsoft.StaticApp" -ForegroundColor Cyan

# ========================================
# STEP 13: CONFIGURE CORS
# ========================================
# After Static Web App is created, run this:
# $frontendUrl = "YOUR-STATIC-WEB-APP-URL"  # Get from Azure Portal
# az webapp cors add `
#   --resource-group $resourceGroup `
#   --name $apiAppName `
#   --allowed-origins $frontendUrl

# ========================================
# DEPLOYMENT COMPLETE!
# ========================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "API URL: $apiUrl" -ForegroundColor Cyan
Write-Host "Database Server: $dbServerName.postgres.database.azure.com" -ForegroundColor White
Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. Create Static Web App via Azure Portal" -ForegroundColor White
Write-Host "2. Connect to GitHub repository" -ForegroundColor White
Write-Host "3. Update CORS settings with frontend URL" -ForegroundColor White
Write-Host "4. Test the application!" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Green
