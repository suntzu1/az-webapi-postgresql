# Azure Deployment Guide

This guide provides step-by-step instructions for deploying the Sports API to Azure.

## Prerequisites

- Azure subscription
- Azure CLI installed (`az --version` should show version 2.50+)
- .NET 9.0 SDK installed
- Docker installed (for containerized deployment)

## Deployment Options

### Option 1: Azure App Service (Recommended for Simple Deployment)

This option deploys the API to Azure App Service with Azure Database for PostgreSQL.

#### Step 1: Prepare Azure Resources

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "Your-Subscription-Name"

# Run the infrastructure deployment script
cd azure
chmod +x deploy-infrastructure.sh
./deploy-infrastructure.sh
```

The script will create:
- Resource Group
- Azure Database for PostgreSQL Flexible Server
- App Service Plan
- App Service

#### Step 2: Apply Database Migrations

After the infrastructure is created, apply migrations:

```bash
# Update connection string in appsettings.json with your Azure PostgreSQL details
# Connection string format:
# Host=<server-name>.postgres.database.azure.com;Database=sportsapi;Username=<admin-user>;Password=<admin-password>;SslMode=Require

cd ../SportsApi
dotnet ef database update
```

#### Step 3: Deploy the Application

```bash
# Build and publish
dotnet publish -c Release -o ./publish

# Create deployment package
cd publish
zip -r ../deploy.zip .

# Deploy to Azure App Service
cd ..
az webapp deployment source config-zip \
  --resource-group rg-sportsapi \
  --name <your-app-service-name> \
  --src deploy.zip
```

#### Step 4: Verify Deployment

```bash
# Open the app in browser
az webapp browse --resource-group rg-sportsapi --name <your-app-service-name>

# Check logs
az webapp log tail --resource-group rg-sportsapi --name <your-app-service-name>
```

### Option 2: Azure Container Instances (ACI)

Deploy as containers for better control and portability.

#### Step 1: Create Azure Container Registry

```bash
ACR_NAME="acrsportsapi${RANDOM}"
RESOURCE_GROUP="rg-sportsapi"
LOCATION="eastus"

# Create ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Login to ACR
az acr login --name $ACR_NAME
```

#### Step 2: Build and Push Docker Image

```bash
# Build the image
docker build -t sportsapi:latest .

# Tag the image
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
docker tag sportsapi:latest $ACR_LOGIN_SERVER/sportsapi:latest

# Push to ACR
docker push $ACR_LOGIN_SERVER/sportsapi:latest
```

#### Step 3: Deploy to Container Instances

```bash
# Get ACR credentials
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

# Create PostgreSQL if not already created
POSTGRES_SERVER="psql-sportsapi-${RANDOM}"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --location $LOCATION \
  --admin-user sqladmin \
  --admin-password "P@ssw0rd123!" \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --public-access 0.0.0.0

# Create container instance
az container create \
  --resource-group $RESOURCE_GROUP \
  --name sportsapi-container \
  --image $ACR_LOGIN_SERVER/sportsapi:latest \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASSWORD \
  --dns-name-label sportsapi-${RANDOM} \
  --ports 8080 \
  --environment-variables \
    ASPNETCORE_ENVIRONMENT=Production \
    ConnectionStrings__DefaultConnection="Host=${POSTGRES_SERVER}.postgres.database.azure.com;Database=sportsapi;Username=sqladmin;Password=P@ssw0rd123!;SslMode=Require"
```

### Option 3: Azure Kubernetes Service (AKS)

For production-grade, scalable deployments.

#### Step 1: Create AKS Cluster

```bash
RESOURCE_GROUP="rg-sportsapi"
AKS_NAME="aks-sportsapi"
LOCATION="eastus"

# Create AKS
az aks create \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --node-count 2 \
  --enable-managed-identity \
  --generate-ssh-keys \
  --network-plugin azure

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME
```

#### Step 2: Attach ACR to AKS

```bash
ACR_NAME="<your-acr-name>"
az aks update \
  --resource-group $RESOURCE_GROUP \
  --name $AKS_NAME \
  --attach-acr $ACR_NAME
```

#### Step 3: Update Kubernetes Manifests

Edit the files in `azure/` directory:

**postgres-config.yaml**: Update connection string
**app-deployment.yaml**: Update image URL to your ACR

#### Step 4: Deploy to Kubernetes

```bash
# Create namespace
kubectl create namespace sportsapi

# Apply configurations
kubectl apply -f azure/postgres-config.yaml -n sportsapi
kubectl apply -f azure/app-deployment.yaml -n sportsapi

# Check deployment status
kubectl get pods -n sportsapi
kubectl get services -n sportsapi

# Get external IP
kubectl get service sportsapi-service -n sportsapi
```

## Post-Deployment Configuration

### 1. Configure SSL/TLS

For App Service:
```bash
# Azure manages SSL automatically for *.azurewebsites.net
# For custom domain:
az webapp config ssl bind \
  --resource-group rg-sportsapi \
  --name <app-name> \
  --certificate-thumbprint <thumbprint> \
  --ssl-type SNI
```

### 2. Configure Authentication (Optional)

Enable Azure AD authentication:
```bash
az webapp auth update \
  --resource-group rg-sportsapi \
  --name <app-name> \
  --enabled true \
  --action LoginWithAzureActiveDirectory \
  --aad-client-id <client-id>
```

### 3. Set Up Monitoring

Enable Application Insights:
```bash
az monitor app-insights component create \
  --app sportsapi-insights \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web

# Link to App Service
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
  --app sportsapi-insights \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv)

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name <app-name> \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY=$INSTRUMENTATION_KEY
```

### 4. Configure Backup (for PostgreSQL)

```bash
az postgres flexible-server backup create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER \
  --backup-name initial-backup
```

## CI/CD with GitHub Actions

The project includes a GitHub Actions workflow for automated deployment.

### Setup:

1. **Get Publish Profile**
   ```bash
   az webapp deployment list-publishing-profiles \
     --resource-group rg-sportsapi \
     --name <app-name> \
     --xml
   ```

2. **Add to GitHub Secrets**
   - Go to your repository → Settings → Secrets and variables → Actions
   - Create secret: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - Paste the XML content

3. **Update Workflow**
   - Edit `.github/workflows/azure-deploy.yml`
   - Update `AZURE_WEBAPP_NAME` with your app service name

4. **Push to trigger deployment**
   ```bash
   git push origin main
   ```

## Monitoring and Troubleshooting

### View Logs

App Service logs:
```bash
az webapp log tail --resource-group rg-sportsapi --name <app-name>
```

Container logs (ACI):
```bash
az container logs --resource-group rg-sportsapi --name sportsapi-container
```

Kubernetes logs:
```bash
kubectl logs -f deployment/sportsapi -n sportsapi
```

### Common Issues

**Database Connection Issues:**
- Verify firewall rules allow Azure services
- Check connection string format
- Ensure PostgreSQL server is running

**App Not Starting:**
- Check environment variables are set correctly
- Verify .NET runtime version matches
- Review application logs for errors

**Performance Issues:**
- Scale up App Service plan
- Add more container instances
- Optimize database queries

## Security Best Practices

1. **Use Azure Key Vault** for secrets:
   ```bash
   az keyvault create --name kv-sportsapi --resource-group rg-sportsapi
   az keyvault secret set --vault-name kv-sportsapi --name DbPassword --value "your-password"
   ```

2. **Enable Private Endpoints** for PostgreSQL:
   ```bash
   az postgres flexible-server update \
     --resource-group rg-sportsapi \
     --name $POSTGRES_SERVER \
     --public-access Disabled
   ```

3. **Use Managed Identities** instead of connection strings

4. **Enable DDoS Protection** for production

## Cost Optimization

- Use **Basic** tier for dev/test environments
- Enable **auto-shutdown** for non-production resources
- Use **reserved instances** for production
- Monitor costs with **Azure Cost Management**

## Cleanup Resources

To delete all resources:
```bash
az group delete --name rg-sportsapi --yes --no-wait
```

## Support

For issues or questions:
- Check Azure documentation: https://docs.microsoft.com/azure
- Review application logs
- Contact support through Azure portal
