# Azure Deployment Guide - Client Campaign Manager

## ?? Architecture Overview

Your application will be deployed as:
1. **Backend API**: Azure App Service (.NET 9)
2. **Database**: Azure Database for PostgreSQL
3. **Frontend**: Azure Static Web Apps (React)

---

## ?? Prerequisites

Before deploying, ensure you have:
- ? Azure account ([Create free account](https://azure.microsoft.com/free/))
- ? Azure CLI installed ([Download](https://aka.ms/installazurecli))
- ? Git repository (you already have this!)

---

## ?? Deployment Steps

### Step 1: Login to Azure

```powershell
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account list --output table
az account set --subscription "YOUR_SUBSCRIPTION_NAME"
```

---

### Step 2: Create Resource Group

```powershell
# Create a resource group
az group create --name rg-campaign-manager --location eastus
```

---

### Step 3: Create PostgreSQL Database

```powershell
# Create PostgreSQL Flexible Server
az postgres flexible-server create `
  --resource-group rg-campaign-manager `
  --name campaignmanager-db `
  --location eastus `
  --admin-user adminuser `
  --admin-password "YourSecurePassword123!" `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --storage-size 32 `
  --public-access 0.0.0.0-255.255.255.255

# Create the database
az postgres flexible-server db create `
  --resource-group rg-campaign-manager `
  --server-name campaignmanager-db `
  --database-name campaignmanager
```

**?? Note:** Save your connection string! It will look like:
```
Server=campaignmanager-db.postgres.database.azure.com;Database=campaignmanager;Port=5432;User Id=adminuser;Password=YourSecurePassword123!;Ssl Mode=Require;
```

---

### Step 4: Deploy Backend API to Azure App Service

#### 4.1: Update appsettings.json for Production

Create `SportsApi/appsettings.Production.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "WILL_BE_SET_FROM_AZURE"
  }
}
```

#### 4.2: Create App Service

```powershell
# Create App Service Plan
az appservice plan create `
  --name plan-campaign-manager `
  --resource-group rg-campaign-manager `
  --location eastus `
  --sku B1 `
  --is-linux

# Create Web App
az webapp create `
  --resource-group rg-campaign-manager `
  --plan plan-campaign-manager `
  --name campaignmanager-api `
  --runtime "DOTNETCORE:9.0"
```

#### 4.3: Configure App Settings

```powershell
# Set connection string
az webapp config connection-string set `
  --resource-group rg-campaign-manager `
  --name campaignmanager-api `
  --connection-string-type PostgreSQL `
  --settings DefaultConnection="Server=campaignmanager-db.postgres.database.azure.com;Database=campaignmanager;Port=5432;User Id=adminuser;Password=YourSecurePassword123!;Ssl Mode=Require;"

# Enable CORS for your frontend
az webapp cors add `
  --resource-group rg-campaign-manager `
  --name campaignmanager-api `
  --allowed-origins https://YOUR-STATIC-WEB-APP.azurestaticapps.net
```

#### 4.4: Deploy Backend Code

```powershell
# Build and publish
cd D:\Work\Outform\az-webapi-postgresql\SportsApi
dotnet publish -c Release -o ./publish

# Create deployment package
Compress-Archive -Path ./publish/* -DestinationPath ./deploy.zip -Force

# Deploy to Azure
az webapp deployment source config-zip `
  --resource-group rg-campaign-manager `
  --name campaignmanager-api `
  --src ./deploy.zip
```

---

### Step 5: Run Database Migrations

```powershell
# SSH into the web app (or use Azure Cloud Shell)
# Run migrations from your local machine targeting Azure DB

# Update connection string temporarily in appsettings.json
# Then run:
cd D:\Work\Outform\az-webapi-postgresql\SportsApi
dotnet ef database update --connection "Server=campaignmanager-db.postgres.database.azure.com;Database=campaignmanager;Port=5432;User Id=adminuser;Password=YourSecurePassword123!;Ssl Mode=Require;"
```

---

### Step 6: Deploy Frontend to Azure Static Web Apps

#### 6.1: Update Frontend API URL

Update `sports-client/.env.production`:

```env
REACT_APP_API_URL=https://campaignmanager-api.azurewebsites.net
```

Update `sports-client/package.json` - remove proxy for production:

```json
{
  "name": "client-campaign-manager",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    ...
  }
}
```

Update `sports-client/src/services/api.js`:

```javascript
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:5287';

const api = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Rest of your code...
```

#### 6.2: Create Static Web App via Azure Portal

**Option A: Using Azure Portal**
1. Go to [Azure Portal](https://portal.azure.com)
2. Click "Create a resource" ? "Static Web App"
3. Fill in:
   - Resource Group: `rg-campaign-manager`
   - Name: `campaignmanager-frontend`
   - Plan: `Free`
   - Region: `East US 2`
   - Source: `GitHub`
   - Repository: `suntzu1/az-webapi-postgresql`
   - Branch: `Front-end-cleanup`
   - Build preset: `React`
   - App location: `/sports-client`
   - Output location: `build`

**Option B: Using Azure CLI**

```powershell
# First, build the React app
cd D:\Work\Outform\az-webapi-postgresql\sports-client
npm run build

# Create Static Web App
az staticwebapp create `
  --name campaignmanager-frontend `
  --resource-group rg-campaign-manager `
  --source https://github.com/suntzu1/az-webapi-postgresql `
  --location eastus2 `
  --branch Front-end-cleanup `
  --app-location "/sports-client" `
  --output-location "build" `
  --login-with-github
```

---

### Step 7: Update CORS Settings

After deployment, get your Static Web App URL and update backend CORS:

```powershell
# Get Static Web App URL
az staticwebapp show `
  --name campaignmanager-frontend `
  --resource-group rg-campaign-manager `
  --query "defaultHostname" -o tsv

# Update CORS
az webapp cors add `
  --resource-group rg-campaign-manager `
  --name campaignmanager-api `
  --allowed-origins https://YOUR-STATIC-WEB-APP-URL.azurestaticapps.net
```

---

## ?? Configuration Summary

After deployment, your resources will be:

| Resource | URL |
|----------|-----|
| **Frontend** | https://campaignmanager-frontend.azurestaticapps.net |
| **Backend API** | https://campaignmanager-api.azurewebsites.net |
| **Database** | campaignmanager-db.postgres.database.azure.com |

---

## ? Post-Deployment Checklist

- [ ] Test API: https://campaignmanager-api.azurewebsites.net/api/clients
- [ ] Test Frontend: https://campaignmanager-frontend.azurestaticapps.net
- [ ] Verify database connection
- [ ] Check CORS settings
- [ ] Verify data seeding ran successfully
- [ ] Test campaign creation with product selection

---

## ?? Troubleshooting

### API Not Working
```powershell
# View API logs
az webapp log tail --resource-group rg-campaign-manager --name campaignmanager-api
```

### Database Connection Issues
```powershell
# Check firewall rules
az postgres flexible-server firewall-rule list `
  --resource-group rg-campaign-manager `
  --server-name campaignmanager-db
```

### Frontend Not Loading
```powershell
# Check deployment status
az staticwebapp show `
  --name campaignmanager-frontend `
  --resource-group rg-campaign-manager
```

---

## ?? Cost Estimation

**Monthly Costs (Approximate):**
- PostgreSQL (Burstable B1ms): ~$12/month
- App Service (B1): ~$13/month
- Static Web App (Free tier): $0/month
- **Total**: ~$25/month

**Free Tier Alternative:**
- Use Azure PostgreSQL free tier (if available)
- Use Azure App Service Free tier (F1) - has limitations
- Static Web App stays free

---

## ?? Security Recommendations

1. **Use Azure Key Vault** for connection strings
2. **Enable Application Insights** for monitoring
3. **Configure Custom Domains** with SSL
4. **Set up Azure AD Authentication** (optional)
5. **Enable DDoS Protection**

---

## ?? Useful Azure CLI Commands

```powershell
# Restart API
az webapp restart --resource-group rg-campaign-manager --name campaignmanager-api

# View all resources
az resource list --resource-group rg-campaign-manager --output table

# Delete everything (when done testing)
az group delete --name rg-campaign-manager --yes
```

---

## ?? Next Steps

1. Run the deployment commands in order
2. Test each component as you deploy
3. Set up monitoring with Application Insights
4. Configure custom domain (optional)
5. Set up CI/CD with GitHub Actions (automated)

---

## ?? Need Help?

- Azure Documentation: https://docs.microsoft.com/azure
- Azure Support: https://azure.microsoft.com/support
- GitHub Issues: Create an issue in your repository

**Your Client Campaign Manager is ready for the cloud!** ??
