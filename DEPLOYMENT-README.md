# ?? Quick Azure Deployment Guide

## Prerequisites
- Azure account with active subscription
- Azure CLI installed
- Git repository access

## ?? Quick Start (3 Options)

### Option 1: Automated Script (Recommended)
```powershell
# Run the deployment script
.\deploy-to-azure.ps1
```

### Option 2: Step-by-Step Manual
Follow `AZURE-DEPLOYMENT-GUIDE.md` for detailed instructions.

### Option 3: Azure Portal (GUI)
Use Azure Portal to create resources visually.

---

## ?? What Gets Deployed

1. **PostgreSQL Database** - `campaignmanager-db`
2. **Backend API** - `campaignmanager-api.azurewebsites.net`
3. **Frontend** - `campaignmanager-frontend.azurestaticapps.net`

---

## ? Fast Track (Copy & Paste)

### 1. Login & Setup
```powershell
az login
az group create --name rg-campaign-manager --location eastus
```

### 2. Create Database
```powershell
az postgres flexible-server create `
  --resource-group rg-campaign-manager `
  --name campaignmanager-db `
  --location eastus `
  --admin-user adminuser `
  --admin-password "YourPassword123!" `
  --sku-name Standard_B1ms `
  --tier Burstable `
  --version 16 `
  --public-access 0.0.0.0
```

### 3. Deploy Backend
```powershell
cd SportsApi
dotnet publish -c Release
az webapp up --name campaignmanager-api --resource-group rg-campaign-manager --runtime "DOTNETCORE:9.0"
```

### 4. Deploy Frontend
```powershell
cd sports-client
npm run build
# Upload to Azure Static Web Apps via Portal
```

---

## ?? Configuration Files Created

- ? `SportsApi/appsettings.Production.json` - Production settings
- ? `sports-client/.env.production` - Frontend API URL
- ? `deploy-to-azure.ps1` - Automated deployment script
- ? `AZURE-DEPLOYMENT-GUIDE.md` - Full documentation

---

## ?? Estimated Monthly Cost

- **PostgreSQL B1ms**: ~$12/month
- **App Service B1**: ~$13/month
- **Static Web App**: FREE
- **Total**: ~$25/month

---

## ?? After Deployment

1. Visit `https://campaignmanager-api.azurewebsites.net/api/clients`
2. Visit `https://campaignmanager-frontend.azurestaticapps.net`
3. Test creating campaigns with products
4. Set up monitoring in Azure Portal

---

## ?? Troubleshooting

**API not responding?**
```powershell
az webapp log tail --name campaignmanager-api --resource-group rg-campaign-manager
```

**Database connection failed?**
```powershell
az postgres flexible-server firewall-rule create `
  --resource-group rg-campaign-manager `
  --name campaignmanager-db `
  --rule-name AllowAll `
  --start-ip-address 0.0.0.0 `
  --end-ip-address 255.255.255.255
```

**Frontend CORS error?**
```powershell
az webapp cors add `
  --resource-group rg-campaign-manager `
  --name campaignmanager-api `
  --allowed-origins https://YOUR-FRONTEND-URL.azurestaticapps.net
```

---

## ?? Support

- Full Guide: See `AZURE-DEPLOYMENT-GUIDE.md`
- Azure Docs: https://docs.microsoft.com/azure
- Issues: Create GitHub issue

**Happy Deploying!** ??
