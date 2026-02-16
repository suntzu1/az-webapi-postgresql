# Product-Client Association Guide

## ?? Data Hierarchy

```
Client (e.g., Nike)
  ??? Campaign (e.g., Summer 2026 Collection)
      ??? Product (e.g., Air Max 2026)
```

**Every product is tied to a client through its campaign.**

---

## ? Backend Implementation

### 1. Database Models (EF Core)
- **Client** has many **Campaigns** (one-to-many)
- **Campaign** belongs to one **Client** (foreign key: ClientId)
- **Campaign** has many **Products** (one-to-many)
- **Product** belongs to one **Campaign** (foreign key: CampaignId)

### 2. DTOs (Data Transfer Objects)

**ProductDto:**
```csharp
public int ClientId { get; set; }        // ? Client association
public string ClientName { get; set; }   // ? Client name
public int CampaignId { get; set; }
public string CampaignName { get; set; }
```

**CampaignDto:**
```csharp
public int ClientId { get; set; }
public string ClientName { get; set; }
public int ProductCount { get; set; }    // ? Number of products
```

**ClientDto:**
```csharp
public int CampaignCount { get; set; }   // ? Number of campaigns
```

### 3. Controllers

**ProductsController** uses `.ThenInclude()` to load the full chain:
```csharp
.Include(p => p.Campaign)
    .ThenInclude(c => c.Client)
```

This ensures every product response includes:
- Campaign information
- Client information (through the campaign)

---

## ?? Frontend Implementation

### 1. Products List Page (`/products`)

**Features:**
- ? Displays **Client Name** badge for each product
- ? **Filter by Client** dropdown at the top
- ? Shows campaign name
- ? Filter info banner: "Showing 3 products for Nike"

**Example:**
```
Filter: [Nike ?]  [+ Add Product]
Showing 3 products for Nike

| ID | Name      | SKU          | Category | Price    | Campaign    | Client |
|----|-----------|--------------|----------|----------|-------------|--------|
| 1  | Air Max   | AM2026-BLK-10| Footwear | $149.99  | Summer 2026 | [Nike] |
```

### 2. Product Form Page (`/products/new` or `/products/edit/:id`)

**Features:**
- ? **Client Filter** dropdown to filter campaigns
- ? Campaign dropdown shows: `"Summer 2026 Collection (Nike)"`
- ? Selected campaign shows client badge: **Client: Nike**
- ? Helper text: "Filter campaigns by client to make selection easier"
- ? Warning if no campaigns exist for selected client

**Workflow:**
1. User selects "Nike" in the client filter
2. Campaign dropdown shows only Nike campaigns
3. User selects "Summer 2026 Collection"
4. Badge displays: "Client: Nike"
5. Product is automatically associated with Nike (through the campaign)

### 3. Campaigns List Page (`/campaigns`)

**Features:**
- ? **Filter by Client** dropdown
- ? Shows **Product Count** badge for each campaign
- ? Displays client name for each campaign

### 4. Clients List Page (`/clients`)

**Features:**
- ? Shows **Campaign Count** badge for each client
- ? Click on campaign count to view campaigns (future enhancement)

### 5. Dashboard (`/`)

**Features:**
- ? Statistics cards for Clients, Campaigns, Products
- ? **Data Hierarchy Info Box** explaining the relationship:
  ```
  Client ? Campaign ? Product
  ```
- ? Helpful text explaining how to use filters

---

## ?? How Products are Tied to Clients

### Example Data Flow:

1. **Nike** (Client ID: 1) is created
2. **Summer 2026 Collection** (Campaign ID: 1, ClientId: 1) is created for Nike
3. **Air Max 2026** (Product ID: 1, CampaignId: 1) is created for the campaign

**Result:**
- Product "Air Max 2026" ? Campaign "Summer 2026 Collection" ? Client "Nike"
- The product is **indirectly tied to Nike through the campaign**

### API Response Example:

```json
GET /api/products/1
{
  "id": 1,
  "name": "Air Max 2026",
  "sku": "AM2026-BLK-10",
  "price": 149.99,
  "category": "Footwear",
  "campaignId": 1,
  "campaignName": "Summer 2026 Collection",
  "clientId": 1,           // ? Client association
  "clientName": "Nike"     // ? Client name
}
```

---

## ?? How to Verify the Association

### Test Scenario:

1. **Create a Client:**
   - Go to `/clients/new`
   - Create "Nike"

2. **Create a Campaign:**
   - Go to `/campaigns/new`
   - Select "Nike" as the client
   - Create "Summer 2026 Collection"

3. **Create a Product:**
   - Go to `/products/new`
   - Select "Nike" in the client filter
   - Select "Summer 2026 Collection" campaign
   - Create "Air Max 2026"

4. **Verify:**
   - Go to `/products`
   - See the product with client badge "Nike"
   - Filter by "Nike" - product appears
   - Filter by "Adidas" - product disappears ?

---

## ?? Key Takeaways

? **Every product is tied to exactly one client** (through its campaign)
? **Backend enforces this relationship** through foreign keys
? **Frontend displays this relationship** clearly with badges and filters
? **Users can filter** products and campaigns by client
? **Product form shows client info** when selecting a campaign
? **Dashboard explains** the hierarchy to users

---

## ?? Future Enhancements

- [ ] Add "View Products" button on Campaign cards
- [ ] Add "View Campaigns" button on Client cards
- [ ] Add breadcrumb navigation: Client > Campaign > Product
- [ ] Add visual graph showing client-campaign-product relationships
- [ ] Add bulk import products with automatic client detection
- [ ] Add client analytics dashboard showing product counts

---

## ?? Notes

- The association is **enforced at the database level** with foreign keys
- Deleting a client will cascade delete all its campaigns and products
- Deleting a campaign will cascade delete all its products
- SKU must be unique across all products
- All dates are stored in UTC in the database
