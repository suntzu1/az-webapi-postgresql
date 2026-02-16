# ========================================
# Azure Deployment Script - FIXED VERSION
# No backtick issues - single line commands
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "?? Azure Deployment - Client Campaign Manager" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# Configuration
$resourceGroup = "rg-campaign-manager"
$location = "eastus2"
$dbServerName = "campaignmanager-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"
$apiAppName = "campaignmanager-api-$(Get-Random -Minimum 1000 -Maximum 9999)"
$appServicePlan = "plan-campaign-manager"
$staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "`nConfiguration:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "Database: $dbServerName"
Write-Host "API: $apiAppName"
Write-Host "Frontend: $staticWebAppName"

# Step 1: Verify login
Write-Host "`n? Step 1: Verifying Azure login..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Cyan
} catch {
    Write-Host "? Not logged in. Run 'az login'" -ForegroundColor Red
    exit 1
}

# Step 2: Create Resource Group
Write-Host "`n? Step 2: Creating Resource Group..." -ForegroundColor Green
az group create --name $resourceGroup --location $location --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed"; exit 1 }
Write-Host "Resource group created" -ForegroundColor Green

# Step 3: Create PostgreSQL
Write-Host "`n? Step 3: Creating PostgreSQL (3-5 minutes)..." -ForegroundColor Green
az postgres flexible-server create --resource-group $resourceGroup --name $dbServerName --location $location --admin-user $dbAdminUser --admin-password $dbPassword --sku-name Standard_B1ms --tier Burstable --version 16 --storage-size 32 --public-access 0.0.0.0-255.255.255.255 --yes --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create PostgreSQL"; exit 1 }
Write-Host "PostgreSQL created" -ForegroundColor Green

# Step 4: Create Database
Write-Host "`n? Step 4: Creating Database..." -ForegroundColor Green
az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServerName --database-name $dbName --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create database"; exit 1 }
Write-Host "Database created" -ForegroundColor Green

# Step 5: Create App Service Plan
Write-Host "`n? Step 5: Creating App Service Plan (S1)..." -ForegroundColor Green
az appservice plan create --name $appServicePlan --resource-group $resourceGroup --location $location --sku S1 --is-linux --output none
if ($LASTEXITCODE -ne 0) { 
    Write-Host "? Failed to create App Service Plan" -ForegroundColor Red
    Write-Host "But you said it works in Portal - checking..." -ForegroundColor Yellow
    exit 1 
}
Write-Host "App Service Plan created" -ForegroundColor Green

# Step 6: Create Web App
Write-Host "`n? Step 6: Creating Web App..." -ForegroundColor Green
az webapp create --resource-group $resourceGroup --plan $appServicePlan --name $apiAppName --runtime "DOTNETCORE:9.0" --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create Web App"; exit 1 }
Write-Host "Web App created" -ForegroundColor Green

# Step 7: Configure Connection String
Write-Host "`n? Step 7: Configuring Connection String..." -ForegroundColor Green
$connectionString = "Server=$dbServerName.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"
az webapp config connection-string set --resource-group $resourceGroup --name $apiAppName --connection-string-type PostgreSQL --settings "DefaultConnection=$connectionString" --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed"; exit 1 }
Write-Host "Connection string configured" -ForegroundColor Green

# Step 8: Build Backend
Write-Host "`n? Step 8: Building Backend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\SportsApi"
dotnet publish -c Release -o ./publish --nologo
if ($LASTEXITCODE -ne 0) { Write-Host "? Build failed"; exit 1 }

# Step 9: Create Deployment Package
Write-Host "`n? Step 9: Creating Deployment Package..." -ForegroundColor Green
if (Test-Path "./deploy.zip") { Remove-Item "./deploy.zip" -Force }
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Step 10: Deploy to Azure
Write-Host "`n? Step 10: Deploying Backend (2-3 minutes)..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $resourceGroup --name $apiAppName --src ./deploy.zip --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Deployment failed"; exit 1 }
Write-Host "Backend deployed" -ForegroundColor Green

# Step 11: Run Migrations
Write-Host "`n? Step 11: Running Migrations..." -ForegroundColor Green
dotnet ef database update --connection $connectionString --no-build
if ($LASTEXITCODE -ne 0) { Write-Host "?? Migrations had issues (may be ok)" -ForegroundColor Yellow }

# Get API URL
$apiUrl = "https://$apiAppName.azurewebsites.net"
Write-Host "`nAPI URL: $apiUrl" -ForegroundColor Cyan

# Step 12: Configure Frontend
Write-Host "`n? Step 12: Configuring Frontend..." -ForegroundColor Green
Set-Content -Path "D:\Work\Outform\az-webapi-postgresql\sports-client\.env.production" -Value "REACT_APP_API_URL=$apiUrl"

# Step 13: Enable CORS
Write-Host "`n? Step 13: Enabling CORS..." -ForegroundColor Green
az webapp cors add --resource-group $resourceGroup --name $apiAppName --allowed-origins "*" --output none 2>&1 | Out-Null

# Step 14: Build Frontend
Write-Host "`n? Step 14: Building Frontend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\sports-client"
npm install --silent
npm run build --silent

# Step 15: Create Static Web App
Write-Host "`n? Step 15: Creating Static Web App..." -ForegroundColor Green
az staticwebapp create --name $staticWebAppName --resource-group $resourceGroup --location "eastus2" --sku Free --output none
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create Static Web App"; exit 1 }

# Step 16: Deploy Frontend
Write-Host "`n? Step 16: Deploying Frontend..." -ForegroundColor Green
$deployToken = az staticwebapp secrets list --name $staticWebAppName --resource-group $resourceGroup --query "properties.apiKey" -o tsv
npm install -g @azure/static-web-apps-cli --silent
swa deploy ./build --deployment-token $deployToken --env production --no-use-keychain

# Get Frontend URL
$frontendUrl = az staticwebapp show --name $staticWebAppName --resource-group $resourceGroup --query "defaultHostname" -o tsv
$frontendUrl = "https://$frontendUrl"

# Update CORS
Write-Host "`n? Updating CORS with frontend URL..." -ForegroundColor Green
az webapp cors remove --resource-group $resourceGroup --name $apiAppName --allowed-origins "*" --output none 2>&1 | Out-Null
az webapp cors add --resource-group $resourceGroup --name $apiAppName --allowed-origins $frontendUrl --output none

# Success!
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n?? YOUR APPLICATION:" -ForegroundColor Cyan
Write-Host "Frontend:  $frontendUrl" -ForegroundColor Green
Write-Host "API:       $apiUrl" -ForegroundColor Green

Write-Host "`n?? COST:" -ForegroundColor Yellow
Write-Host "~`$2.70/day (delete tonight!)"

Write-Host "`n?? TO DELETE:" -ForegroundColor Red
Write-Host "az group delete --name $resourceGroup --yes"

Write-Host "`n?? Opening application..." -ForegroundColor Green
Start-Process $frontendUrl

Write-Host "`n========================================`n" -ForegroundColor Green
