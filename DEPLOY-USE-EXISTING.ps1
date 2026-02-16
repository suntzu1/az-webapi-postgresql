# ========================================
# Azure Deployment - USE EXISTING RESOURCES
# You already have Free tier ASP + Database!
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "?? Azure Deployment - Using Existing Resources" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Configuration - using EXISTING resources
$resourceGroup = "rg-campaign-manager"
$existingPlan = "plan-campaign-manager"  # Your FREE tier plan
$existingDb = "campaignmanager-db-9944"  # Your existing DB
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"  # Use your actual password
$apiAppName = "campaignmanager-api-$(Get-Random -Minimum 1000 -Maximum 9999)"
$staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "`n?? Using Existing Resources:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup" -ForegroundColor Cyan
Write-Host "App Service Plan: $existingPlan (FREE tier!)" -ForegroundColor Green
Write-Host "Database: $existingDb" -ForegroundColor Cyan
Write-Host "New API App: $apiAppName" -ForegroundColor Yellow
Write-Host "New Frontend: $staticWebAppName" -ForegroundColor Yellow

# Verify login
Write-Host "`n? Step 1: Verifying Azure login..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Cyan
} catch {
    Write-Host "? Not logged in. Run 'az login'" -ForegroundColor Red
    exit 1
}

# Verify existing resources
Write-Host "`n? Step 2: Verifying existing resources..." -ForegroundColor Green
$plan = az appservice plan show --name $existingPlan --resource-group $resourceGroup 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "? App Service Plan not found!" -ForegroundColor Red
    exit 1
}
Write-Host "? App Service Plan exists (FREE tier)" -ForegroundColor Green

$db = az postgres flexible-server show --name $existingDb --resource-group $resourceGroup 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Database not found!" -ForegroundColor Red
    exit 1
}
Write-Host "? PostgreSQL Database exists" -ForegroundColor Green

# Create Web App (using existing FREE plan!)
Write-Host "`n? Step 3: Creating Web App on FREE tier..." -ForegroundColor Green
az webapp create --resource-group $resourceGroup --plan $existingPlan --name $apiAppName --runtime "DOTNETCORE:9.0" --output none
if ($LASTEXITCODE -ne 0) { 
    Write-Host "? Failed to create Web App" -ForegroundColor Red
    exit 1 
}
Write-Host "Web App created on FREE tier!" -ForegroundColor Green

# Configure Connection String
Write-Host "`n? Step 4: Configuring Connection String..." -ForegroundColor Green
$connectionString = "Server=$existingDb.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"
az webapp config connection-string set --resource-group $resourceGroup --name $apiAppName --connection-string-type PostgreSQL --settings "DefaultConnection=$connectionString" --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed"; exit 1 }
Write-Host "Connection string configured" -ForegroundColor Green

# Build Backend
Write-Host "`n? Step 5: Building Backend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\SportsApi"
dotnet publish -c Release -o ./publish --nologo -v q
if ($LASTEXITCODE -ne 0) { Write-Host "? Build failed"; exit 1 }

# Create Deployment Package
Write-Host "`n? Step 6: Creating Deployment Package..." -ForegroundColor Green
if (Test-Path "./deploy.zip") { Remove-Item "./deploy.zip" -Force }
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Deploy to Azure
Write-Host "`n? Step 7: Deploying Backend (2-3 minutes)..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $resourceGroup --name $apiAppName --src ./deploy.zip --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Deployment failed"; exit 1 }
Write-Host "Backend deployed!" -ForegroundColor Green

# Run Migrations
Write-Host "`n? Step 8: Running Migrations..." -ForegroundColor Green
dotnet ef database update --connection $connectionString --no-build
if ($LASTEXITCODE -ne 0) { Write-Host "?? Migrations had issues (may be ok)" -ForegroundColor Yellow }

# Get API URL
$apiUrl = "https://$apiAppName.azurewebsites.net"
Write-Host "`n? API URL: $apiUrl" -ForegroundColor Cyan

# Configure Frontend
Write-Host "`n? Step 9: Configuring Frontend..." -ForegroundColor Green
Set-Content -Path "D:\Work\Outform\az-webapi-postgresql\sports-client\.env.production" -Value "REACT_APP_API_URL=$apiUrl"

# Enable CORS
Write-Host "`n? Step 10: Enabling CORS..." -ForegroundColor Green
az webapp cors add --resource-group $resourceGroup --name $apiAppName --allowed-origins "*" --output none 2>&1 | Out-Null

# Build Frontend
Write-Host "`n? Step 11: Building Frontend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\sports-client"
Write-Host "Installing packages..." -ForegroundColor Cyan
npm install --silent
Write-Host "Building..." -ForegroundColor Cyan
npm run build

# Create Static Web App
Write-Host "`n? Step 12: Creating Static Web App..." -ForegroundColor Green
az staticwebapp create --name $staticWebAppName --resource-group $resourceGroup --location "eastus2" --sku Free --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create Static Web App"; exit 1 }

# Deploy Frontend
Write-Host "`n? Step 13: Deploying Frontend..." -ForegroundColor Green
$deployToken = az staticwebapp secrets list --name $staticWebAppName --resource-group $resourceGroup --query "properties.apiKey" -o tsv
Write-Host "Installing SWA CLI..." -ForegroundColor Cyan
npm install -g @azure/static-web-apps-cli --silent 2>&1 | Out-Null
Write-Host "Deploying..." -ForegroundColor Cyan
swa deploy ./build --deployment-token $deployToken --env production --no-use-keychain

# Get Frontend URL
$frontendUrl = az staticwebapp show --name $staticWebAppName --resource-group $resourceGroup --query "defaultHostname" -o tsv
$frontendUrl = "https://$frontendUrl"

# Update CORS
Write-Host "`n? Step 14: Updating CORS..." -ForegroundColor Green
az webapp cors remove --resource-group $resourceGroup --name $apiAppName --allowed-origins "*" --output none 2>&1 | Out-Null
az webapp cors add --resource-group $resourceGroup --name $apiAppName --allowed-origins $frontendUrl --output none

# Success!
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n?? YOUR APPLICATION:" -ForegroundColor Cyan
Write-Host "Frontend:  $frontendUrl" -ForegroundColor Green
Write-Host "API:       $apiUrl" -ForegroundColor Green

Write-Host "`n?? MONTHLY COST (Using FREE Tier!):" -ForegroundColor Green
Write-Host "App Service Plan:  `$0 (FREE F1 tier)" -ForegroundColor Green
Write-Host "PostgreSQL:        ~`$12-16/month" -ForegroundColor Yellow
Write-Host "Static Web App:    `$0 (FREE)" -ForegroundColor Green
Write-Host "??????????????????????????????????" -ForegroundColor DarkGray
Write-Host "TOTAL:             ~`$12-16/month" -ForegroundColor Green
Write-Host "Per Day:           ~`$0.40-0.53/day" -ForegroundColor Green

Write-Host "`n?? Database Credentials:" -ForegroundColor Yellow
Write-Host "Server: $existingDb.postgres.database.azure.com"
Write-Host "Database: $dbName"
Write-Host "Username: $dbAdminUser"

Write-Host "`n?? To stop database (save money):" -ForegroundColor Cyan
Write-Host ".\manage-database.ps1 -Action stop"

Write-Host "`n?? To delete ONLY new resources:" -ForegroundColor Yellow
Write-Host "az webapp delete --name $apiAppName --resource-group $resourceGroup"
Write-Host "az staticwebapp delete --name $staticWebAppName --resource-group $resourceGroup"

Write-Host "`n?? Opening application..." -ForegroundColor Green
Start-Process $frontendUrl

Write-Host "`n========================================`n" -ForegroundColor Green
