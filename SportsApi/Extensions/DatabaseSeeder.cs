using Microsoft.EntityFrameworkCore;
using SportsApi.Data;
using SportsApi.Models;

namespace SportsApi.Extensions;

public static class DatabaseSeeder
{
    public static async Task SeedDataAsync(ApplicationDbContext context)
    {
        // Check if data already exists
        if (await context.Clients.AnyAsync())
        {
            return; // Database has been seeded
        }

        // Create Clients
        var nike = new Client
        {
            Name = "Nike",
            Description = "Global sports brand and footwear company",
            CreatedAt = DateTime.UtcNow
        };

        var hurleys = new Client
        {
            Name = "Hurley",
            Description = "Premium surf and beach lifestyle brand",
            CreatedAt = DateTime.UtcNow
        };

        var adidas = new Client
        {
            Name = "Adidas",
            Description = "German multinational sports corporation",
            CreatedAt = DateTime.UtcNow
        };

        context.Clients.AddRange(nike, hurleys, adidas);
        await context.SaveChangesAsync();

        // Create Campaigns
        var nikeSummerCampaign = new Campaign
        {
            Name = "Summer 2026 Collection",
            Description = "New summer sports apparel and footwear line",
            StartDate = new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc),
            EndDate = new DateTime(2026, 8, 31, 0, 0, 0, DateTimeKind.Utc),
            TargetAudience = "Athletes and fitness enthusiasts aged 18-35",
            Budget = 500000.00m,
            ClientId = nike.Id,
            CreatedAt = DateTime.UtcNow
        };

        var hurleySurfCampaign = new Campaign
        {
            Name = "Surf Championship 2026",
            Description = "Professional surf championship sponsorship campaign",
            StartDate = new DateTime(2026, 7, 1, 0, 0, 0, DateTimeKind.Utc),
            EndDate = new DateTime(2026, 9, 30, 0, 0, 0, DateTimeKind.Utc),
            TargetAudience = "Surfers and beach lifestyle enthusiasts",
            Budget = 250000.00m,
            ClientId = hurleys.Id,
            CreatedAt = DateTime.UtcNow
        };

        var adidasBackToSchool = new Campaign
        {
            Name = "Back to School 2026",
            Description = "Student athletic gear and sportswear campaign",
            StartDate = new DateTime(2026, 8, 1, 0, 0, 0, DateTimeKind.Utc),
            EndDate = new DateTime(2026, 10, 31, 0, 0, 0, DateTimeKind.Utc),
            TargetAudience = "Students and young athletes aged 12-22",
            Budget = 350000.00m,
            ClientId = adidas.Id,
            CreatedAt = DateTime.UtcNow
        };

        context.Campaigns.AddRange(nikeSummerCampaign, hurleySurfCampaign, adidasBackToSchool);
        await context.SaveChangesAsync();

        // Create Products (belong directly to clients)
        var products = new List<Product>
        {
            // Nike Products
            new Product
            {
                Name = "Air Max 2026",
                Description = "Latest Air Max running shoe with enhanced cushioning",
                Sku = "AM2026-BLK-10",
                Price = 149.99m,
                Category = "Footwear",
                ClientId = nike.Id,
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Dri-FIT Pro Training Shirt",
                Description = "Moisture-wicking performance training shirt",
                Sku = "DFPT-WHT-L",
                Price = 45.99m,
                Category = "Apparel",
                ClientId = nike.Id,
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Nike Pro Compression Shorts",
                Description = "High-performance compression shorts for training",
                Sku = "NPC-BLK-M",
                Price = 39.99m,
                Category = "Apparel",
                ClientId = nike.Id,
                CreatedAt = DateTime.UtcNow
            },
            
            // Hurley Products
            new Product
            {
                Name = "Pro Surf Board Shorts",
                Description = "Professional grade board shorts with quick-dry technology",
                Sku = "HUR-PBS-001",
                Price = 79.99m,
                Category = "Apparel",
                ClientId = hurleys.Id,
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Phantom Elite Wetsuit",
                Description = "Premium wetsuit for professional surfers",
                Sku = "HUR-PEW-L",
                Price = 299.99m,
                Category = "Surf Gear",
                ClientId = hurleys.Id,
                CreatedAt = DateTime.UtcNow
            },
            
            // Adidas Products
            new Product
            {
                Name = "Ultraboost 2026",
                Description = "Revolutionary running shoe with boost technology",
                Sku = "UB2026-GRY-9",
                Price = 180.00m,
                Category = "Footwear",
                ClientId = adidas.Id,
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Tiro Track Pants",
                Description = "Classic athletic track pants for training",
                Sku = "TTP-BLK-M",
                Price = 55.00m,
                Category = "Apparel",
                ClientId = adidas.Id,
                CreatedAt = DateTime.UtcNow
            },
            new Product
            {
                Name = "Classic Backpack",
                Description = "Durable backpack for students and athletes",
                Sku = "ABP-NVY-001",
                Price = 45.00m,
                Category = "Accessories",
                ClientId = adidas.Id,
                CreatedAt = DateTime.UtcNow
            }
        };

        context.Products.AddRange(products);
        await context.SaveChangesAsync();
        
        // Link Products to Campaigns (many-to-many)
        var campaignProducts = new List<CampaignProduct>
        {
            // Nike Summer Campaign products
            new CampaignProduct { CampaignId = nikeSummerCampaign.Id, ProductId = products[0].Id, AddedAt = DateTime.UtcNow },
            new CampaignProduct { CampaignId = nikeSummerCampaign.Id, ProductId = products[1].Id, AddedAt = DateTime.UtcNow },
            new CampaignProduct { CampaignId = nikeSummerCampaign.Id, ProductId = products[2].Id, AddedAt = DateTime.UtcNow },
            
            // Hurley Surf Campaign products
            new CampaignProduct { CampaignId = hurleySurfCampaign.Id, ProductId = products[3].Id, AddedAt = DateTime.UtcNow },
            new CampaignProduct { CampaignId = hurleySurfCampaign.Id, ProductId = products[4].Id, AddedAt = DateTime.UtcNow },
            
            // Adidas Back to School Campaign products
            new CampaignProduct { CampaignId = adidasBackToSchool.Id, ProductId = products[5].Id, AddedAt = DateTime.UtcNow },
            new CampaignProduct { CampaignId = adidasBackToSchool.Id, ProductId = products[6].Id, AddedAt = DateTime.UtcNow },
            new CampaignProduct { CampaignId = adidasBackToSchool.Id, ProductId = products[7].Id, AddedAt = DateTime.UtcNow },
        };
        
        context.CampaignProducts.AddRange(campaignProducts);
        await context.SaveChangesAsync();
    }
}