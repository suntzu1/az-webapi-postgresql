# ========================================
# Azure Container Instance Deployment
# Client Campaign Manager - NO APP SERVICE QUOTA NEEDED
# ========================================

$ErrorActionPreference = "Stop"

Write-Host "?? Azure Container Instance Deployment (App Service Alternative)" -ForegroundColor Green
Write-Host "This uses Container Instances - different quota than App Service!" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Configuration
$resourceGroup = "rg-campaign-manager"
$location = "eastus"
$dbServerName = "campaignmanager-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"
$acrName = "campaignmanageracr$(Get-Random -Minimum 100 -Maximum 999)"
$containerGroupName = "campaignmanager-api-aci"
$staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "`n?? Configuration:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"
Write-Host "ACR: $acrName"

# Verify login
Write-Host "`n? Step 1: Verifying Azure CLI..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Cyan
} catch {
    Write-Host "? Not logged in. Run 'az login' first." -ForegroundColor Red
    exit 1
}

# Create Resource Group
Write-Host "`n? Step 2: Creating Resource Group..." -ForegroundColor Green
az group create --name $resourceGroup --location $location --output table
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed"; exit 1 }

# Create PostgreSQL
Write-Host "`n? Step 3: Creating PostgreSQL Database (3-5 minutes)..." -ForegroundColor Green
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
  --public-access 0.0.0.0-255.255.255.255 `
  --yes

if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create PostgreSQL"; exit 1 }

# Create Database
Write-Host "`n? Step 4: Creating Database..." -ForegroundColor Green
az postgres flexible-server db create `
  --resource-group $resourceGroup `
  --server-name $dbServerName `
  --database-name $dbName

if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create database"; exit 1 }

# Create Azure Container Registry
Write-Host "`n? Step 5: Creating Container Registry..." -ForegroundColor Green
az acr create `
  --resource-group $resourceGroup `
  --name $acrName `
  --sku Basic `
  --admin-enabled true

if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create ACR"; exit 1 }

# Build Docker image
Write-Host "`n? Step 6: Building Docker Image..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\SportsApi"

# Create Dockerfile if not exists
$dockerfileContent = @"
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["SportsApi.csproj", "./"]
RUN dotnet restore "SportsApi.csproj"
COPY . .
RUN dotnet build "SportsApi.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "SportsApi.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SportsApi.dll"]
"@

Set-Content -Path "Dockerfile" -Value $dockerfileContent

# Build and push to ACR
az acr build --registry $acrName --image campaignmanager-api:latest .
if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to build image"; exit 1 }

# Get ACR credentials
$acrUser = az acr credential show --name $acrName --query username -o tsv
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" -o tsv
$acrServer = "$acrName.azurecr.io"

# Connection string
$connectionString = "Server=$dbServerName.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"

# Create Container Instance
Write-Host "`n? Step 7: Creating Container Instance..." -ForegroundColor Green
az container create `
  --resource-group $resourceGroup `
  --name $containerGroupName `
  --image "$acrServer/campaignmanager-api:latest" `
  --registry-login-server $acrServer `
  --registry-username $acrUser `
  --registry-password $acrPassword `
  --dns-name-label "campaignmanager-api-$(Get-Random -Minimum 1000 -Maximum 9999)" `
  --ports 80 `
  --environment-variables `
    "ASPNETCORE_ENVIRONMENT=Production" `
    "ConnectionStrings__DefaultConnection=$connectionString" `
  --cpu 1 `
  --memory 1.5

if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create container"; exit 1 }

# Get API URL
$apiFqdn = az container show `
  --resource-group $resourceGroup `
  --name $containerGroupName `
  --query "ipAddress.fqdn" -o tsv

$apiUrl = "http://$apiFqdn"

Write-Host "`n? API is running at: $apiUrl" -ForegroundColor Green

# Run migrations from local
Write-Host "`n? Step 8: Running Database Migrations..." -ForegroundColor Green
dotnet ef database update --connection $connectionString
if ($LASTEXITCODE -ne 0) { Write-Host "?? Migrations failed (non-critical)" -ForegroundColor Yellow }

# Build Frontend
Write-Host "`n? Step 9: Building Frontend..." -ForegroundColor Green
Set-Location "D:\Work\Outform\az-webapi-postgresql\sports-client"
Set-Content -Path ".env.production" -Value "REACT_APP_API_URL=$apiUrl"
npm install
npm run build

# Create Static Web App
Write-Host "`n? Step 10: Deploying Frontend to Static Web Apps..." -ForegroundColor Green
az staticwebapp create `
  --name $staticWebAppName `
  --resource-group $resourceGroup `
  --location "eastus2" `
  --sku Free

if ($LASTEXITCODE -ne 0) { Write-Host "? Failed to create Static Web App"; exit 1 }

# Deploy frontend
$deployToken = az staticwebapp secrets list `
  --name $staticWebAppName `
  --resource-group $resourceGroup `
  --query "properties.apiKey" -o tsv

npm install -g @azure/static-web-apps-cli
swa deploy ./build --deployment-token $deployToken --env production

# Get Frontend URL
$frontendUrl = az staticwebapp show `
  --name $staticWebAppName `
  --resource-group $resourceGroup `
  --query "defaultHostname" -o tsv

$frontendUrl = "https://$frontendUrl"

# Success!
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`n?? YOUR APPLICATION:" -ForegroundColor Cyan
Write-Host "Frontend: $frontendUrl" -ForegroundColor Green
Write-Host "API:      $apiUrl/api/clients" -ForegroundColor Green

Write-Host "`n?? MONTHLY COST:" -ForegroundColor Cyan
Write-Host "Container Instance: ~`$30/month" -ForegroundColor Yellow
Write-Host "PostgreSQL:         ~`$12-16/month" -ForegroundColor Yellow
Write-Host "Container Registry: ~`$5/month" -ForegroundColor Yellow
Write-Host "Static Web App:     `$0 (Free)" -ForegroundColor Green
Write-Host "TOTAL:              ~`$47-51/month" -ForegroundColor Yellow
Write-Host "Per Day:            ~`$1.57/day" -ForegroundColor Green

Write-Host "`n?? Credentials:" -ForegroundColor Yellow
Write-Host "Database: $dbServerName.postgres.database.azure.com"
Write-Host "Username: $dbAdminUser"
Write-Host "Password: $dbPassword"

Write-Host "`n?? TO DELETE:" -ForegroundColor Red
Write-Host "az group delete --name $resourceGroup --yes"

Write-Host "`n?? Opening application..." -ForegroundColor Green
Start-Process $frontendUrl
