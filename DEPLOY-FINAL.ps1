# ========================================
# FINAL Azure Deployment Script
# Client Campaign Manager - Complete & Working
# ========================================

Write-Host "?? Client Campaign Manager - Azure Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

# ========================================
# CONFIGURATION
# ========================================
$resourceGroup = "rg-campaign-manager"
$location = "eastus2"
$dbServerName = "campaignmanager-db"  # Fixed name - will be reused
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"  # CHANGE THIS IN PRODUCTION!
$apiAppName = "campaignmanager-api-$(Get-Random -Minimum 1000 -Maximum 9999)"
$appServicePlan = "plan-campaign-manager"

Write-Host "`n?? Configuration:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "Database: $dbServerName"
Write-Host "API App: $apiAppName"

# ========================================
# STEP 1: VERIFY AZURE LOGIN
# ========================================
Write-Host "`n? Step 1: Verifying Azure CLI..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "   Logged in as: $($account.user.name)" -ForegroundColor Cyan
} catch {
    Write-Host "   ? Not logged in. Run 'az login' first." -ForegroundColor Red
    exit 1
}

# ========================================
# STEP 2: CREATE/CHECK RESOURCE GROUP
# ========================================
Write-Host "`n? Step 2: Checking Resource Group..." -ForegroundColor Green
$rgExists = az group exists --name $resourceGroup
if ($rgExists -eq "true") {
    Write-Host "   ? Resource group exists - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating resource group..." -ForegroundColor Cyan
    az group create --name $resourceGroup --location $location --output none
    Write-Host "   ? Created" -ForegroundColor Green
}

# ========================================
# STEP 3: CREATE/CHECK POSTGRESQL
# ========================================
Write-Host "`n? Step 3: Checking PostgreSQL Database..." -ForegroundColor Green
$existingDb = az postgres flexible-server show --resource-group $resourceGroup --name $dbServerName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ? PostgreSQL server '$dbServerName' exists - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating PostgreSQL server (3-5 minutes)..." -ForegroundColor Cyan
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
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create PostgreSQL" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ? Created" -ForegroundColor Green
}

# ========================================
# STEP 4: CREATE/CHECK DATABASE
# ========================================
Write-Host "`n? Step 4: Checking Database..." -ForegroundColor Green
$existingDbName = az postgres flexible-server db show --resource-group $resourceGroup --server-name $dbServerName --database-name $dbName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ? Database '$dbName' exists - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating database..." -ForegroundColor Cyan
    az postgres flexible-server db create `
      --resource-group $resourceGroup `
      --server-name $dbServerName `
      --database-name $dbName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create database" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ? Created" -ForegroundColor Green
}

# ========================================
# STEP 5: ADD DATABASE FIREWALL RULE
# ========================================
Write-Host "`n? Step 5: Configuring Database Firewall..." -ForegroundColor Green
az postgres flexible-server firewall-rule create `
  --resource-group $resourceGroup `
  --name $dbServerName `
  --rule-name AllowAzureServices `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 0.0.0.0 `
  --output none 2>$null

Write-Host "   ? Firewall configured" -ForegroundColor Green

# ========================================
# STEP 6: CREATE APP SERVICE PLAN (WINDOWS)
# ========================================
Write-Host "`n? Step 6: Creating App Service Plan (B1 Windows)..." -ForegroundColor Green
$existingPlan = az appservice plan show --name $appServicePlan --resource-group $resourceGroup 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ? App Service Plan exists - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating B1 Windows plan..." -ForegroundColor Cyan
    az appservice plan create `
      --name $appServicePlan `
      --resource-group $resourceGroup `
      --location eastus `
      --sku B1 `
      --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create App Service Plan" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ? Created" -ForegroundColor Green
}

# ========================================
# STEP 7: CREATE WEB APP (WINDOWS/.NET 9)
# ========================================
Write-Host "`n? Step 7: Creating Web App..." -ForegroundColor Green
$existingApp = az webapp list --resource-group $resourceGroup --query "[?name=='$apiAppName']" 2>$null | ConvertFrom-Json
if ($existingApp -and $existingApp.Count -gt 0) {
    Write-Host "   ? Web App exists - reusing" -ForegroundColor Yellow
} else {
    Write-Host "   Creating Windows Web App..." -ForegroundColor Cyan
    az webapp create `
      --resource-group $resourceGroup `
      --plan $appServicePlan `
      --name $apiAppName `
      --runtime "DOTNET:9" `
      --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create Web App" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ? Created" -ForegroundColor Green
}

# ========================================
# STEP 8: CONFIGURE CONNECTION STRING
# ========================================
Write-Host "`n? Step 8: Configuring Connection String..." -ForegroundColor Green
$connectionString = "Server=$dbServerName.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"

az webapp config appsettings set `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --settings "ConnectionStrings__DefaultConnection=$connectionString" `
  --output none

Write-Host "   ? Connection string configured" -ForegroundColor Green

# ========================================
# STEP 9: BUILD BACKEND
# ========================================
Write-Host "`n? Step 9: Building Backend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\SportsApi"
dotnet publish -c Release -o ./publish --nologo -v q

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Build failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Built successfully" -ForegroundColor Green

# ========================================
# STEP 10: CREATE DEPLOYMENT PACKAGE
# ========================================
Write-Host "`n? Step 10: Creating Deployment Package..." -ForegroundColor Green
if (Test-Path "./deploy.zip") { Remove-Item "./deploy.zip" -Force }
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force
Write-Host "   ? Package created" -ForegroundColor Green

# ========================================
# STEP 11: DEPLOY TO AZURE (ZIP)
# ========================================
Write-Host "`n? Step 11: Deploying Backend to Azure..." -ForegroundColor Green
az webapp deployment source config-zip `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --src ./deploy.zip `
  --output none

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Deployed successfully" -ForegroundColor Green

# ========================================
# STEP 12: RESTART WEB APP
# ========================================
Write-Host "`n? Step 12: Restarting Web App..." -ForegroundColor Green
az webapp restart --name $apiAppName --resource-group $resourceGroup --output none
Start-Sleep -Seconds 20
Write-Host "   ? App restarted" -ForegroundColor Green

# Get API URL
$apiUrl = "https://$apiAppName.azurewebsites.net"
$apiUrlWithPath = "$apiUrl/api"

# ========================================
# STEP 13: CONFIGURE FRONTEND
# ========================================
Write-Host "`n? Step 13: Configuring Frontend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\sports-client"
Set-Content -Path ".env.production" -Value "REACT_APP_API_URL=$apiUrlWithPath"
Write-Host "   ? Frontend configured with: $apiUrlWithPath" -ForegroundColor Green

# ========================================
# STEP 14: BUILD FRONTEND
# ========================================
Write-Host "`n? Step 14: Building Frontend..." -ForegroundColor Green
npm install --silent
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Frontend build failed" -ForegroundColor Red
    exit 1
}
Write-Host "   ? Frontend built" -ForegroundColor Green

# ========================================
# STEP 15: CREATE/CHECK STATIC WEB APP
# ========================================
Write-Host "`n? Step 15: Checking Static Web App..." -ForegroundColor Green
$existingStaticApps = az staticwebapp list --resource-group $resourceGroup 2>$null | ConvertFrom-Json

if ($existingStaticApps -and $existingStaticApps.Count -gt 0) {
    $staticWebAppName = $existingStaticApps[0].name
    Write-Host "   ? Using existing: $staticWebAppName" -ForegroundColor Yellow
} else {
    $staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"
    Write-Host "   Creating Static Web App: $staticWebAppName..." -ForegroundColor Cyan
    az staticwebapp create `
      --name $staticWebAppName `
      --resource-group $resourceGroup `
      --location "eastus2" `
      --sku Free `
      --output none
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ? Failed to create Static Web App" -ForegroundColor Red
        exit 1
    }
    Write-Host "   ? Created" -ForegroundColor Green
}

# ========================================
# STEP 16: DEPLOY FRONTEND
# ========================================
Write-Host "`n? Step 16: Deploying Frontend..." -ForegroundColor Green
$deploymentToken = az staticwebapp secrets list `
  --name $staticWebAppName `
  --resource-group $resourceGroup `
  --query "properties.apiKey" -o tsv

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ? Failed to get deployment token" -ForegroundColor Red
    exit 1
}

Write-Host "   Installing SWA CLI..." -ForegroundColor Cyan
npm install -g @azure/static-web-apps-cli --silent 2>&1 | Out-Null

Write-Host "   Deploying..." -ForegroundColor Cyan
swa deploy ./build --deployment-token $deploymentToken --env production --no-use-keychain

Write-Host "   ? Frontend deployed" -ForegroundColor Green

# Get Frontend URL
$frontendUrl = az staticwebapp show `
  --name $staticWebAppName `
  --resource-group $resourceGroup `
  --query "defaultHostname" -o tsv
$frontendUrl = "https://$frontendUrl"

# ========================================
# STEP 17: UPDATE CORS
# ========================================
Write-Host "`n? Step 17: Configuring CORS..." -ForegroundColor Green
az webapp cors remove `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --allowed-origins "*" `
  --output none 2>$null

az webapp cors add `
  --resource-group $resourceGroup `
  --name $apiAppName `
  --allowed-origins $frontendUrl `
  --output none

Write-Host "   ? CORS configured for: $frontendUrl" -ForegroundColor Green

# ========================================
# DEPLOYMENT COMPLETE
# ========================================
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n?? YOUR APPLICATION:" -ForegroundColor Cyan
Write-Host "   Frontend:  $frontendUrl" -ForegroundColor Green
Write-Host "   API:       $apiUrl/api/clients" -ForegroundColor Green

Write-Host "`n?? RESOURCES:" -ForegroundColor Cyan
Write-Host "   Resource Group:  $resourceGroup"
Write-Host "   Database:        $dbServerName.postgres.database.azure.com"
Write-Host "   App Service:     $apiAppName"
Write-Host "   Static Web App:  $staticWebAppName"

Write-Host "`n?? DATABASE CREDENTIALS:" -ForegroundColor Yellow
Write-Host "   Server:   $dbServerName.postgres.database.azure.com"
Write-Host "   Database: $dbName"
Write-Host "   Username: $dbAdminUser"
Write-Host "   Password: $dbPassword"

Write-Host "`n?? MONTHLY COST: ~`$25-29" -ForegroundColor Cyan
Write-Host "   App Service (B1):      ~`$13/month"
Write-Host "   PostgreSQL (B1ms):     ~`$12-16/month"
Write-Host "   Static Web App:        `$0 (Free)"

Write-Host "`n?? USEFUL COMMANDS:" -ForegroundColor Cyan
Write-Host "   Stop Database:    .\manage-database.ps1 -Action stop"
Write-Host "   Start Database:   .\manage-database.ps1 -Action start"
Write-Host "   Delete All:       az group delete --name $resourceGroup --yes"

Write-Host "`n?? Opening application..." -ForegroundColor Green
Start-Process $frontendUrl

Write-Host "`n========================================`n" -ForegroundColor Green
