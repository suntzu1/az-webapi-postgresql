# ========================================
# Azure Deployment Script
# Client Campaign Manager - Quick Deploy
# ========================================

Write-Host "?? Starting Azure Deployment for Client Campaign Manager" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Configuration Variables
$resourceGroup = "rg-campaign-manager"
$location = "eastus2"  # Changed to West US - often has better quota availability
$dbServerName = "campaignmanager-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"  # Change this to a secure password
$apiAppName = "campaignmanager-api-$(Get-Random -Minimum 1000 -Maximum 9999)"
$appServicePlan = "plan-campaign-manager"

Write-Host "`n?? Configuration:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "Database Server: $dbServerName"
Write-Host "API App: $apiAppName"

# Verify Azure CLI is installed and logged in
Write-Host "`n? Step 1: Verifying Azure CLI..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Cyan
} catch {
    Write-Host "? Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Create Resource Group
Write-Host "`n? Step 2: Creating Resource Group..." -ForegroundColor Green
az group create --name $resourceGroup --location $location --output table

# Create PostgreSQL Flexible Server
Write-Host "`n? Step 3: Creating PostgreSQL Database (this may take 3-5 minutes)..." -ForegroundColor Green
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
  --public-access 0.0.0.0 `
  --yes

# Create Database
Write-Host "`n? Step 4: Creating Database..." -ForegroundColor Green
az postgres flexible-server db create `
  --resource-group $resourceGroup `
  --server-name $dbServerName `
  --database-name $dbName

# Create App Service Plan
Write-Host "`n? Step 5: Creating App Service Plan (B1 Linux)..." -ForegroundColor Green
Write-Host "Note: F1 Free doesn't support .NET 9, using B1 (~$13/month)" -ForegroundColor Yellow
az appservice plan create `
  --name $appServicePlan `
  --resource-group $resourceGroup `
  --location eastus `
  --sku B1 `
  --is-linux

# Create Web App
Write-Host "`n? Step 6: Creating Web App..." -ForegroundColor Green
az webapp create `
  --resource-group $resourceGroup `
  --plan $appServicePlan `
  --name $apiAppName `
  --runtime "DOTNETCORE:9.0"

# Configure Connection String (as App Setting - CRITICAL!)
Write-Host "`n? Step 7: Configuring Connection String..." -ForegroundColor Green
$connectionString = "Server=$dbServerName.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"

# Set as app setting (double underscore format for .NET configuration)
az webapp config appsettings set `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --settings "ConnectionStrings__DefaultConnection=$connectionString"

# Add firewall rule to allow Azure services to access PostgreSQL
Write-Host "`n? Step 7.5: Configuring Database Firewall..." -ForegroundColor Green
az postgres flexible-server firewall-rule create `
  --resource-group $resourceGroup `
  --name $dbServerName `
  --rule-name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0 `
  --output none

# Build and Publish Backend
Write-Host "`n? Step 8: Building Backend API..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\SportsApi"
dotnet publish -c Release -o ./publish --nologo

# Create Deployment Package
Write-Host "`n? Step 9: Creating Deployment Package..." -ForegroundColor Green
if (Test-Path "./deploy.zip") { Remove-Item "./deploy.zip" -Force }
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Deploy to Azure using az webapp up (more reliable)
Write-Host "`n? Step 10: Deploying Backend to Azure (2-3 minutes)..." -ForegroundColor Green
az webapp up `
  --name $apiAppName `
  --resource-group $resourceGroup `
  --runtime "DOTNETCORE:9.0" `
  --os-type Linux

Write-Host "`n? Step 11: Deployment complete! Waiting for app to start..." -ForegroundColor Green
Start-Sleep -Seconds 20

# Get API URL
$apiUrl = "https://$apiAppName.azurewebsites.net"

# Update Frontend Environment
Write-Host "`n? Step 12: Updating Frontend Configuration..." -ForegroundColor Green
Set-Content -Path "D:\Work\Outform\az-webapi-postgresql\sports-client\.env.production" -Value "REACT_APP_API_URL=$apiUrl"

# Enable CORS
Write-Host "`n? Step 13: Enabling CORS..." -ForegroundColor Green
az webapp cors add `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --allowed-origins "*"  2>&1 | Out-Null  # Suppress "already exists" errors

# Build Frontend
Write-Host "`n? Step 14: Building Frontend..." -ForegroundColor Green
try {
    Set-Location "D:\Work\Outform\az-webapi-postgresql\sports-client"
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "? Failed to install npm packages" -ForegroundColor Red
        exit 1
    }
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "? Failed to build frontend" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "? Error building frontend: $_" -ForegroundColor Red
    exit 1
}

# Deploy Frontend to Azure Static Web Apps
Write-Host "`n? Step 15: Deploying Frontend to Azure Static Web Apps..." -ForegroundColor Green

# Check if any static web app exists in the resource group
$existingStaticApps = az staticwebapp list --resource-group $resourceGroup 2>&1 | ConvertFrom-Json
if ($existingStaticApps -and $existingStaticApps.Count -gt 0) {
    $staticWebAppName = $existingStaticApps[0].name
    Write-Host "Found existing Static Web App: $staticWebAppName - reusing" -ForegroundColor Yellow
} else {
    # Create new static web app with generated name
    $staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"
    Write-Host "Creating new Static Web App: $staticWebAppName..." -ForegroundColor Cyan
    az staticwebapp create --name $staticWebAppName --resource-group $resourceGroup --location "eastus2" --sku Free --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "? Failed to create Static Web App" -ForegroundColor Red
        exit 1
    }
    Write-Host "? Static Web App created" -ForegroundColor Green
}

# Get deployment token
Write-Host "`n? Step 16: Deploying Frontend Build..." -ForegroundColor Green
$deploymentToken = az staticwebapp secrets list --name $staticWebAppName --resource-group $resourceGroup --query "properties.apiKey" -o tsv

if ($LASTEXITCODE -ne 0) {
    Write-Host "? Failed to get deployment token" -ForegroundColor Red
    exit 1
}

# Install SWA CLI if not already installed
Write-Host "Installing Azure Static Web Apps CLI..." -ForegroundColor Cyan
npm install -g @azure/static-web-apps-cli --silent 2>&1 | Out-Null

# Deploy using SWA CLI
Write-Host "Deploying frontend build to Static Web App..." -ForegroundColor Cyan
swa deploy ./build --deployment-token $deploymentToken --env production --no-use-keychain

if ($LASTEXITCODE -ne 0) {
    Write-Host "?? Frontend deployment had issues (may be ok)" -ForegroundColor Yellow
}

# Get Static Web App URL
$frontendUrl = az staticwebapp show --name $staticWebAppName --resource-group $resourceGroup --query "defaultHostname" -o tsv
$frontendUrl = "https://$frontendUrl"

# Update CORS to allow frontend
Write-Host "`n? Step 17: Updating CORS for Frontend URL..." -ForegroundColor Green
az webapp cors remove --resource-group $resourceGroup --name $apiAppName --allowed-origins "*" --output none 2>&1 | Out-Null
az webapp cors add --resource-group $resourceGroup --name $apiAppName --allowed-origins $frontendUrl --output none

Write-Host "? CORS updated with frontend URL" -ForegroundColor Green

# Success Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n?? Deployment Summary:" -ForegroundColor Cyan
Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
Write-Host "Backend API: $apiUrl" -ForegroundColor Yellow
Write-Host "Frontend Web: $frontendUrl" -ForegroundColor Cyan
Write-Host "Database Server: $dbServerName.postgres.database.azure.com" -ForegroundColor White
Write-Host "Database Name: $dbName" -ForegroundColor White
Write-Host "Database User: $dbAdminUser" -ForegroundColor White

Write-Host "`n?? YOUR APPLICATION IS LIVE:" -ForegroundColor Green
Write-Host "  Frontend:  $frontendUrl" -ForegroundColor Cyan
Write-Host "  API:       $apiUrl/api/clients" -ForegroundColor Yellow

Write-Host "`n?? Save These Credentials:" -ForegroundColor Yellow
Write-Host "Database Server: $dbServerName.postgres.database.azure.com"
Write-Host "Database Name: $dbName"
Write-Host "Username: $dbAdminUser"
Write-Host "Password: $dbPassword"

Write-Host "`n? Your backend API is now live at: $apiUrl" -ForegroundColor Green

Write-Host "`n?? PAY-AS-YOU-GO COST MANAGEMENT:" -ForegroundColor Cyan
Write-Host "???????????????????????????????????????????" -ForegroundColor DarkGray
Write-Host "Current Monthly Costs:" -ForegroundColor Yellow
Write-Host "  ? App Service (B1):       ~`$13/month" -ForegroundColor Yellow
Write-Host "  ? PostgreSQL (running):   ~`$12-16/month" -ForegroundColor Yellow
Write-Host "  ? PostgreSQL (stopped):   ~`$4/month (storage only)" -ForegroundColor Green
Write-Host "  ? Static Web App:         `$0 (Free)" -ForegroundColor Green
Write-Host "  ? TOTAL (running):        ~`$25-29/month" -ForegroundColor Yellow
Write-Host "  ? TOTAL (DB stopped):     ~`$13/month" -ForegroundColor Green
Write-Host "???????????????????????????????????????????" -ForegroundColor DarkGray

Write-Host "`n?? SAVE MONEY - STOP DATABASE WHEN NOT USING:" -ForegroundColor Cyan
Write-Host "  Stop now:   .\manage-database.ps1 -Action stop" -ForegroundColor White
Write-Host "  Start when needed: .\manage-database.ps1 -Action start" -ForegroundColor White
Write-Host "  Check status:      .\manage-database.ps1 -Action status" -ForegroundColor White
Write-Host "`n  When stopped: Only ~`$4/month!" -ForegroundColor Green
Write-Host "  For occasional use: Average ~`$5-8/month total" -ForegroundColor Green

Write-Host "`n========================================`n" -ForegroundColor Green

# Open Frontend in browser
Write-Host "`n?? Opening your live application..." -ForegroundColor Green
Start-Process $frontendUrl
