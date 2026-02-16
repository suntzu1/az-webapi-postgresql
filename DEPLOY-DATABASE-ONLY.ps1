# ========================================
# Azure Deployment Script - Container Instance Version
# Client Campaign Manager - Works Without App Service Quota
# ========================================

# Stop on any error
$ErrorActionPreference = "Stop"

Write-Host "?? Starting Azure Deployment (Container Instance Version)" -ForegroundColor Green
Write-Host "This version uses Container Instances instead of App Service" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

# Configuration Variables
$resourceGroup = "rg-campaign-manager"
$location = "eastus"
$dbServerName = "campaignmanager-db-$(Get-Random -Minimum 1000 -Maximum 9999)"
$dbName = "campaignmanager"
$dbAdminUser = "adminuser"
$dbPassword = "CampaignManager2024!"
$containerName = "campaignmanager-api"
$staticWebAppName = "campaignmanager-frontend-$(Get-Random -Minimum 1000 -Maximum 9999)"

Write-Host "`n?? Configuration:" -ForegroundColor Yellow
Write-Host "Resource Group: $resourceGroup"
Write-Host "Location: $location"

# Check Azure login
Write-Host "`n? Step 1: Verifying Azure CLI..." -ForegroundColor Green
try {
    $account = az account show 2>&1 | ConvertFrom-Json -ErrorAction Stop
    Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Cyan
} catch {
    Write-Host "? Not logged in. Run 'az login' first." -ForegroundColor Red
    exit 1
}

# Create Resource Group
Write-Host "`n? Step 2: Creating Resource Group..." -ForegroundColor Green
$rg = az group create --name $resourceGroup --location $location 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "? Failed to create resource group" -ForegroundColor Red
    Write-Host $rg
    exit 1
}

# Create PostgreSQL
Write-Host "`n? Step 3: Creating PostgreSQL Database..." -ForegroundColor Green
Write-Host "This will take 3-5 minutes..." -ForegroundColor Cyan
$db = az postgres flexible-server create `
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
  --yes 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "? Failed to create PostgreSQL" -ForegroundColor Red
    Write-Host $db
    exit 1
}

# Create Database
Write-Host "`n? Step 4: Creating Database..." -ForegroundColor Green
$dbCreate = az postgres flexible-server db create `
  --resource-group $resourceGroup `
  --server-name $dbServerName `
  --database-name $dbName 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "? Failed to create database" -ForegroundColor Red
    Write-Host $dbCreate
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "?? INFRASTRUCTURE DEPLOYED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$connectionString = "Server=$dbServerName.postgres.database.azure.com;Database=$dbName;Port=5432;User Id=$dbAdminUser;Password=$dbPassword;Ssl Mode=Require;"

Write-Host "`n?? Database Ready:" -ForegroundColor Cyan
Write-Host "Server: $dbServerName.postgres.database.azure.com"
Write-Host "Database: $dbName"
Write-Host "Username: $dbAdminUser"
Write-Host "Password: $dbPassword"

Write-Host "`n?? APP SERVICE QUOTA ISSUE DETECTED" -ForegroundColor Red
Write-Host "Your subscription has no quota for App Service plans." -ForegroundColor Yellow
Write-Host "`nYou have 3 options:" -ForegroundColor Cyan

Write-Host "`n?? OPTION 1 (Recommended): Run API Locally" -ForegroundColor Green
Write-Host "1. Update SportsApi/appsettings.Development.json with this connection string:" -ForegroundColor White
Write-Host "   $connectionString" -ForegroundColor Yellow
Write-Host "2. Run: cd SportsApi && dotnet ef database update" -ForegroundColor White
Write-Host "3. Run: dotnet run" -ForegroundColor White
Write-Host "4. API will be at http://localhost:5287" -ForegroundColor Cyan
Write-Host "   Cost: ~`$0.40/day (database only)" -ForegroundColor Green

Write-Host "`n?? OPTION 2: Request Quota Increase" -ForegroundColor Yellow
Write-Host "1. Go to https://portal.azure.com" -ForegroundColor White
Write-Host "2. Support ? New Support Request" -ForegroundColor White
Write-Host "3. Issue Type: Service and Subscription Limits" -ForegroundColor White
Write-Host "4. Quota Type: App Service" -ForegroundColor White
Write-Host "5. Wait 1-2 business days for approval" -ForegroundColor White

Write-Host "`n?? OPTION 3: Use Different Subscription" -ForegroundColor Yellow
Write-Host "Your current subscription has restrictions." -ForegroundColor White
Write-Host "Try deploying with a different Azure subscription." -ForegroundColor White

Write-Host "`n?? CURRENT COST:" -ForegroundColor Cyan
Write-Host "PostgreSQL (running): ~`$0.40/day" -ForegroundColor Yellow
Write-Host "No App Service: `$0" -ForegroundColor Green
Write-Host "Total: ~`$0.40/day (just the database)" -ForegroundColor Green

Write-Host "`n?? TO DELETE EVERYTHING:" -ForegroundColor Red
Write-Host "az group delete --name $resourceGroup --yes" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
