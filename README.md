# Sports Campaigns API

A production-grade ASP.NET Core 9 Web API for managing sports clients, campaigns, and products. Built with Entity Framework Core and PostgreSQL, designed for Azure deployment.

## Features

- **Client Management**: Create and manage sports clients (e.g., Nike, Hurley's)
- **Campaign Management**: Create campaigns with start/end dates, budgets, and target audiences
- **Product Management**: Associate products with campaigns
- **RESTful API**: Full CRUD operations for all entities
- **Azure Ready**: Deployment scripts and configurations included
- **PostgreSQL Backend**: Production-grade database with Entity Framework Core
- **OpenAPI/Swagger**: Auto-generated API documentation

## Architecture

### Data Models

- **Client**: Represents sports brands/clients
- **Campaign**: Marketing campaigns with date ranges and budgets
- **Product**: Products associated with campaigns

### Technology Stack

- .NET 9.0
- ASP.NET Core Web API
- Entity Framework Core 9.0
- PostgreSQL (via Npgsql)
- Azure App Service
- Azure Database for PostgreSQL Flexible Server

## API Endpoints

### Clients
- `GET /api/clients` - Get all clients
- `GET /api/clients/{id}` - Get client by ID
- `POST /api/clients` - Create new client
- `PUT /api/clients/{id}` - Update client
- `DELETE /api/clients/{id}` - Delete client

### Campaigns
- `GET /api/campaigns` - Get all campaigns
- `GET /api/campaigns/{id}` - Get campaign by ID
- `POST /api/campaigns` - Create new campaign
- `PUT /api/campaigns/{id}` - Update campaign
- `DELETE /api/campaigns/{id}` - Delete campaign

### Products
- `GET /api/products` - Get all products
- `GET /api/products/{id}` - Get product by ID
- `POST /api/products` - Create new product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product

## Local Development

### Prerequisites

- .NET 9.0 SDK
- PostgreSQL 16+
- Docker (optional, for PostgreSQL)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/suntzu1/az-webapi-postgresql.git
   cd az-webapi-postgresql
   ```

2. **Start PostgreSQL** (using Docker)
   ```bash
   docker run --name postgres-dev -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:16
   ```

3. **Update connection string** (if needed)
   Edit `SportsApi/appsettings.Development.json` with your PostgreSQL credentials

4. **Apply database migrations**
   ```bash
   cd SportsApi
   dotnet ef database update
   ```

5. **Run the application**
   ```bash
   dotnet run
   ```

6. **Access the API**
   - API: https://localhost:7000
   - Swagger UI: https://localhost:7000/openapi/v1.json

## Azure Deployment

### Option 1: Using Azure CLI Script

1. **Install Azure CLI**
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```

2. **Login to Azure**
   ```bash
   az login
   ```

3. **Run deployment script**
   ```bash
   cd azure
   ./deploy-infrastructure.sh
   ```

4. **Deploy the application**
   ```bash
   cd ../SportsApi
   dotnet publish -c Release -o ./publish
   cd ./publish
   zip -r ../app.zip .
   az webapp deployment source config-zip \
     --resource-group rg-sportsapi \
     --name <app-service-name> \
     --src ../app.zip
   ```

### Option 2: Using Kubernetes (AKS)

1. **Create AKS cluster**
   ```bash
   az aks create \
     --resource-group rg-sportsapi \
     --name aks-sportsapi \
     --node-count 2 \
     --enable-managed-identity
   ```

2. **Get AKS credentials**
   ```bash
   az aks get-credentials --resource-group rg-sportsapi --name aks-sportsapi
   ```

3. **Update YAML files** in `azure/` directory with your values

4. **Deploy to AKS**
   ```bash
   kubectl apply -f azure/postgres-config.yaml
   kubectl apply -f azure/app-deployment.yaml
   ```

## Configuration

### Environment Variables

- `ASPNETCORE_ENVIRONMENT`: Set to `Development`, `Staging`, or `Production`
- `ConnectionStrings__DefaultConnection`: PostgreSQL connection string

### Connection String Format

```
Host=<server>;Database=<database>;Username=<username>;Password=<password>;SslMode=Require
```

## Database Schema

### Clients Table
- Id (PK)
- Name
- Description
- CreatedAt
- UpdatedAt

### Campaigns Table
- Id (PK)
- Name
- Description
- StartDate
- EndDate
- TargetAudience
- Budget
- ClientId (FK)
- CreatedAt
- UpdatedAt

### Products Table
- Id (PK)
- Name
- Description
- Sku
- Price
- Category
- CampaignId (FK)
- CreatedAt
- UpdatedAt

## Example Usage

### Create a Client
```bash
curl -X POST https://localhost:7000/api/clients \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Nike",
    "description": "Global sports brand"
  }'
```

### Create a Campaign
```bash
curl -X POST https://localhost:7000/api/campaigns \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Summer 2026 Collection",
    "description": "New summer product line",
    "startDate": "2026-06-01",
    "endDate": "2026-08-31",
    "targetAudience": "Athletes 18-35",
    "budget": 500000.00,
    "clientId": 1
  }'
```

### Create a Product
```bash
curl -X POST https://localhost:7000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Air Max 2026",
    "description": "Latest Air Max model",
    "sku": "AM2026-001",
    "price": 149.99,
    "category": "Footwear",
    "campaignId": 1
  }'
```

## Security Considerations

- Always use HTTPS in production
- Store sensitive data (connection strings, passwords) in Azure Key Vault
- Enable Azure AD authentication for the database
- Use managed identities for Azure resources
- Implement rate limiting and authentication/authorization as needed

## License

This project is licensed under the MIT License.

