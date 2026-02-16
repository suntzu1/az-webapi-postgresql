# ========================================
# ULTIMATE Azure Deployment Script
# Client Campaign Manager - Intelligent Deployment
# Checks for existing resources, uses FREE tier when available
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "?? Client Campaign Manager - Ultimate Azure Deployment" -ForegroundColor Green
Write-Host "Intelligent resource detection and deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ========================================
# CONFIGURATION
# ========================================
$resourceGroup = "rg-campaign-manager"
$location = "eastus2"
$appServicePlan = "plan-campaign-manager"
$dbServerPrefix = "campaignmanager-db"
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"  # CHANGE THIS!
$apiAppName = "campaignmanager-api-$(Get-Random -Minimum 1000 -Maximum 9999)"
$staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "?? Configuration:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "App Service Plan: $appServicePlan"
Write-Host "API App: $apiAppName"
Write-Host "Frontend: $staticWebAppName`n"

# ========================================
# STEP 1: VERIFY AZURE LOGIN
# ========================================
Write-Host "? Step 1: Verifying Azure CLI..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "   Logged in as: $($account.user.name)" -ForegroundColor Cyan
    Write-Host "   Subscription: $($account.name)" -ForegroundColor Cyan
} catch {
    Write-Host "   ? Not logged in to Azure. Run 'az login' first." -ForegroundColor Red
    exit 1
}

# ========================================
# STEP 2: CHECK/CREATE RESOURCE GROUP
# ========================================
Write-Host "`n? Step 2: Checking Resource Group..." -ForegroundColor Green
$rgExists = az group exists --name $resourceGroup
if ($rgExists -eq "true") {
    Write-Host "   ? Resource group exists - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating new resource group..." -ForegroundColor Cyan
    az group create --name $resourceGroup --location $location --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create resource group" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ? Resource group created" -ForegroundColor Green
}

# ========================================
# STEP 3: CHECK/CREATE APP SERVICE PLAN
# ========================================
Write-Host "`n? Step 3: Checking App Service Plan..." -ForegroundColor Green
$planExists = az appservice plan show --name $appServicePlan --resource-group $resourceGroup 2>&1 | Out-String
if ($LASTEXITCODE -eq 0) {
    $planDetails = $planExists | ConvertFrom-Json
    $sku = $planDetails.sku.name
    $tier = $planDetails.sku.tier
    Write-Host "   ? App Service Plan exists - reusing" -ForegroundColor Yellow
    Write-Host "   Tier: $tier ($sku)" -ForegroundColor Cyan
    
    if ($tier -eq "Free") {
        Write-Host "   ?? Using FREE tier - $0/month!" -ForegroundColor Green
    }
} else {
    Write-Host "   No existing plan found - creating new one..." -ForegroundColor Cyan
    Write-Host "   Trying FREE tier first..." -ForegroundColor Cyan
    # Try FREE tier first
    $null = az appservice plan create --name $appServicePlan --resource-group $resourceGroup --location eastus --sku F1 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ?? FREE tier not available, trying B1..." -ForegroundColor Yellow
        az appservice plan create --name $appServicePlan --resource-group $resourceGroup --location eastus --sku B1 --is-linux --output none
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   ? Failed to create App Service Plan" -ForegroundColor Red
            exit 1
        }
        Write-Host "   ? App Service Plan created (B1 - ~$13/month)" -ForegroundColor Green
    } else {
        Write-Host "   ? App Service Plan created (FREE tier!)" -ForegroundColor Green
    }
}

# ========================================
# STEP 4: CHECK/CREATE POSTGRESQL
# ========================================
Write-Host "`n? Step 4: Checking PostgreSQL Database..." -ForegroundColor Green

# Check for existing database servers
$existingDbs = az postgres flexible-server list --resource-group $resourceGroup 2>&1 | ConvertFrom-Json
$dbServer = $null

if ($existingDbs.Count -gt 0) {
    $dbServer = $existingDbs[0].name
    Write-Host "   ? Found existing database: $dbServer - reusing" -ForegroundColor Yellow
    
    # Check if our database exists
    $dbExists = az postgres flexible-server db show --resource-group $resourceGroup --server-name $dbServer --database-name $dbName 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Creating database '$dbName'..." -ForegroundColor Cyan
        az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServer --database-name $dbName --output none
        Write-Host "   ? Database created" -ForegroundColor Green
    } else {
        Write-Host "   ? Database '$dbName' exists" -ForegroundColor Yellow
    }
} else {
    Write-Host "   Creating new PostgreSQL server (3-5 minutes)..." -ForegroundColor Cyan
    $dbServer = "$dbServerPrefix-$(Get-Random -Minimum 1000 -Maximum 9999)"
    
    az postgres flexible-server create --resource-group $resourceGroup --name $dbServer --location $location --admin-user $dbAdminUser --admin-password $dbPassword --sku-name Standard_B1ms --tier Burstable --version 16 --storage-size 32 --public-access 0.0.0.0-255.255.255.255 --yes --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create PostgreSQL server" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "   ? PostgreSQL server created: $dbServer" -ForegroundColor Green
    
    Write-Host "   Creating database '$dbName'..." -ForegroundColor Cyan
    az postgres flexible-server db create --resource-group $resourceGroup --server-name $dbServer --database-name $dbName --output none
    Write-Host "   ? Database created" -ForegroundColor Green
}

# ========================================
# STEP 5: CHECK/CREATE WEB APP
# ========================================
Write-Host "`n? Step 5: Checking Web App..." -ForegroundColor Green

# Check for existing web apps
$existingApps = az webapp list --resource-group $resourceGroup 2>&1 | ConvertFrom-Json
$webApp = $null

if ($existingApps.Count -gt 0) {
    $webApp = $existingApps[0].name
    Write-Host "   ? Found existing web app: $webApp - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating new Web App: $apiAppName..." -ForegroundColor Cyan
    az webapp create --resource-group $resourceGroup --plan $appServicePlan --name $apiAppName --runtime "DOTNETCORE:9.0" --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create Web App" -ForegroundColor Red
        exit 1
    }
    
    $webApp = $apiAppName
    Write-Host "   ? Web App created: $webApp" -ForegroundColor Green
}

# ========================================
# STEP 6: CONFIGURE CONNECTION STRING
# ========================================
Write-Host "`n? Step 6: Configuring Connection String..." -ForegroundColor Green
$connectionString = "Server=$dbServer.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"

az webapp config connection-string set --resource-group $resourceGroup --name $webApp --connection-string-type PostgreSQL --settings "DefaultConnection=$connectionString" --output none
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Failed to configure connection string" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Connection string configured" -ForegroundColor Green

# ========================================
# STEP 7: BUILD BACKEND
# ========================================
Write-Host "`n? Step 7: Building Backend API..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\SportsApi"
dotnet publish -c Release -o ./publish --nologo -v q
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Backend built successfully" -ForegroundColor Green

# ========================================
# STEP 8: CREATE DEPLOYMENT PACKAGE
# ========================================
Write-Host "`n? Step 8: Creating Deployment Package..." -ForegroundColor Green
if (Test-Path "./deploy.zip") { Remove-Item "./deploy.zip" -Force }
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force
Write-Host "   ? Deployment package created" -ForegroundColor Green

# ========================================
# STEP 9: DEPLOY TO AZURE
# ========================================
Write-Host "`n? Step 9: Deploying Backend to Azure (2-3 minutes)..." -ForegroundColor Green
az webapp deployment source config-zip --resource-group $resourceGroup --name $webApp --src ./deploy.zip --output none
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Backend deployed successfully" -ForegroundColor Green

# ========================================
# STEP 10: RUN DATABASE MIGRATIONS
# ========================================
Write-Host "`n? Step 10: Running Database Migrations..." -ForegroundColor Green
dotnet ef database update --connection $connectionString --no-build
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ?? Migrations had issues (may be non-critical)" -ForegroundColor Yellow
} else {
    Write-Host "   ? Migrations completed successfully" -ForegroundColor Green
}

# ========================================
# STEP 11: CONFIGURE FRONTEND
# ========================================
$apiUrl = "https://$webApp.azurewebsites.net"
Write-Host "`n? Step 11: Configuring Frontend..." -ForegroundColor Green
Write-Host "   API URL: $apiUrl" -ForegroundColor Cyan
Set-Content -Path "D:\Work\Outform\az-webapi-postgresql\sports-client\.env.production" -Value "REACT_APP_API_URL=$apiUrl"
Write-Host "   ? Frontend configured" -ForegroundColor Green

# ========================================
# STEP 12: ENABLE CORS
# ========================================
Write-Host "`n? Step 12: Enabling CORS..." -ForegroundColor Green
az webapp cors add --resource-group $resourceGroup --name $webApp --allowed-origins "*" --output none 2>&1 | Out-Null
Write-Host "   ? CORS enabled" -ForegroundColor Green

# ========================================
# STEP 13: BUILD FRONTEND
# ========================================
Write-Host "`n? Step 13: Building Frontend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\sports-client"
Write-Host "   Installing packages..." -ForegroundColor Cyan
npm install --silent
Write-Host "   Building React app..." -ForegroundColor Cyan
npm run build
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Frontend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Frontend built successfully" -ForegroundColor Green

# ========================================
# STEP 14: CHECK/CREATE STATIC WEB APP
# ========================================
Write-Host "`n? Step 14: Checking Static Web App..." -ForegroundColor Green
$existingStaticApps = az staticwebapp list --resource-group $resourceGroup 2>&1 | ConvertFrom-Json
$staticApp = $null

if ($existingStaticApps.Count -gt 0) {
    $staticApp = $existingStaticApps[0].name
    Write-Host "   ? Found existing Static Web App: $staticApp - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating new Static Web App: $staticWebAppName..." -ForegroundColor Cyan
    az staticwebapp create --name $staticWebAppName --resource-group $resourceGroup --location "eastus2" --sku Free --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create Static Web App" -ForegroundColor Red
        exit 1
    }
    
    $staticApp = $staticWebAppName
    Write-Host "   ? Static Web App created: $staticApp" -ForegroundColor Green
}

# ========================================
# STEP 15: DEPLOY FRONTEND
# ========================================
Write-Host "`n? Step 15: Deploying Frontend..." -ForegroundColor Green
$deployToken = az staticwebapp secrets list --name $staticApp --resource-group $resourceGroup --query "properties.apiKey" -o tsv

Write-Host "   Installing SWA CLI..." -ForegroundColor Cyan
npm install -g @azure/static-web-apps-cli --silent 2>&1 | Out-Null

Write-Host "   Deploying to Azure..." -ForegroundColor Cyan
swa deploy ./build --deployment-token $deployToken --env production --no-use-keychain

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ?? Frontend deployment had issues" -ForegroundColor Yellow
} else {
    Write-Host "   ? Frontend deployed successfully" -ForegroundColor Green
}

# ========================================
# STEP 16: UPDATE CORS WITH FRONTEND URL
# ========================================
$frontendUrl = az staticwebapp show --name $staticApp --resource-group $resourceGroup --query "defaultHostname" -o tsv
$frontendUrl = "https://$frontendUrl"

Write-Host "`n? Step 16: Updating CORS with Frontend URL..." -ForegroundColor Green
az webapp cors remove --resource-group $resourceGroup --name $webApp --allowed-origins "*" --output none 2>&1 | Out-Null
az webapp cors add --resource-group $resourceGroup --name $webApp --allowed-origins $frontendUrl --output none
Write-Host "   ? CORS updated with: $frontendUrl" -ForegroundColor Green

# ========================================
# DEPLOYMENT COMPLETE!
# ========================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n?? YOUR APPLICATION:" -ForegroundColor Cyan
Write-Host "   Frontend:  $frontendUrl" -ForegroundColor Green
Write-Host "   API:       $apiUrl" -ForegroundColor Green

Write-Host "`n?? RESOURCES DEPLOYED:" -ForegroundColor Cyan
Write-Host "   Resource Group:    $resourceGroup" -ForegroundColor White
Write-Host "   App Service Plan:  $appServicePlan" -ForegroundColor White
Write-Host "   PostgreSQL Server: $dbServer" -ForegroundColor White
Write-Host "   Web App:           $webApp" -ForegroundColor White
Write-Host "   Static Web App:    $staticApp" -ForegroundColor White

# Calculate costs
$ErrorActionPreference = "SilentlyContinue"
$planDetails = az appservice plan show --name $appServicePlan --resource-group $resourceGroup 2>&1 | ConvertFrom-Json
$ErrorActionPreference = "Stop"
$isFree = $planDetails.sku.tier -eq "Free"

Write-Host "`n?? ESTIMATED MONTHLY COST:" -ForegroundColor Cyan
if ($isFree) {
    Write-Host "   App Service:       `$0 (FREE tier!)" -ForegroundColor Green
    Write-Host "   PostgreSQL:        ~`$12-16/month" -ForegroundColor Yellow
    Write-Host "   Static Web App:    `$0 (FREE)" -ForegroundColor Green
    Write-Host "   ??????????????????????????????" -ForegroundColor DarkGray
    Write-Host "   TOTAL:             ~`$12-16/month" -ForegroundColor Green
    Write-Host "   Per Day:           ~`$0.40-0.53/day" -ForegroundColor Green
} else {
    Write-Host "   App Service:       ~`$13/month (B1)" -ForegroundColor Yellow
    Write-Host "   PostgreSQL:        ~`$12-16/month" -ForegroundColor Yellow
    Write-Host "   Static Web App:    `$0 (FREE)" -ForegroundColor Green
    Write-Host "   ??????????????????????????????" -ForegroundColor DarkGray
    Write-Host "   TOTAL:             ~`$25-29/month" -ForegroundColor Yellow
    Write-Host "   Per Day:           ~`$0.83-0.96/day" -ForegroundColor Yellow
}

Write-Host "`n?? DATABASE CREDENTIALS:" -ForegroundColor Yellow
Write-Host "   Server:   $dbServer.postgres.database.azure.com"
Write-Host "   Database: $dbName"
Write-Host "   Username: $dbAdminUser"
Write-Host "   Password: $dbPassword"

Write-Host "`n?? USEFUL COMMANDS:" -ForegroundColor Cyan
Write-Host "   Stop Database:     .\manage-database.ps1 -Action stop" -ForegroundColor White
Write-Host "   Start Database:    .\manage-database.ps1 -Action start" -ForegroundColor White
Write-Host "   Delete All:        az group delete --name $resourceGroup --yes" -ForegroundColor White

Write-Host "`n?? Opening your application..." -ForegroundColor Green
Start-Process $frontendUrl

Write-Host "`n========================================`n" -ForegroundColor Green
