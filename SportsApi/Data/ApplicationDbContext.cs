using Microsoft.EntityFrameworkCore;
using SportsApi.Models;

namespace SportsApi.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Client> Clients { get; set; }
    public DbSet<Campaign> Campaigns { get; set; }
    public DbSet<Product> Products { get; set; }
    public DbSet<CampaignProduct> CampaignProducts { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure Client
        modelBuilder.Entity<Client>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.CreatedAt).IsRequired();
            
            // Indexes
            entity.HasIndex(e => e.Name).HasDatabaseName("IX_Clients_Name");
            entity.HasIndex(e => e.CreatedAt).HasDatabaseName("IX_Clients_CreatedAt");
            
            entity.HasMany(e => e.Campaigns)
                .WithOne(e => e.Client)
                .HasForeignKey(e => e.ClientId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasMany(e => e.Products)
                .WithOne(e => e.Client)
                .HasForeignKey(e => e.ClientId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        // Configure Campaign
        modelBuilder.Entity<Campaign>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.StartDate).IsRequired();
            entity.Property(e => e.EndDate).IsRequired();
            entity.Property(e => e.TargetAudience).HasMaxLength(500);
            entity.Property(e => e.Budget).HasColumnType("decimal(18,2)");
            entity.Property(e => e.CreatedAt).IsRequired();
            
            // Indexes
            entity.HasIndex(e => e.ClientId).HasDatabaseName("IX_Campaigns_ClientId");
            entity.HasIndex(e => e.Name).HasDatabaseName("IX_Campaigns_Name");
            entity.HasIndex(e => new { e.StartDate, e.EndDate }).HasDatabaseName("IX_Campaigns_DateRange");
            entity.HasIndex(e => e.CreatedAt).HasDatabaseName("IX_Campaigns_CreatedAt");
        });

        // Configure Product
        modelBuilder.Entity<Product>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Sku).HasMaxLength(100);
            entity.Property(e => e.Price).HasColumnType("decimal(18,2)");
            entity.Property(e => e.Category).HasMaxLength(100);
            entity.Property(e => e.CreatedAt).IsRequired();
            
            // Indexes
            entity.HasIndex(e => e.ClientId).HasDatabaseName("IX_Products_ClientId");
            entity.HasIndex(e => e.Sku).IsUnique().HasDatabaseName("IX_Products_Sku");
            entity.HasIndex(e => e.Name).HasDatabaseName("IX_Products_Name");
            entity.HasIndex(e => e.Category).HasDatabaseName("IX_Products_Category");
            entity.HasIndex(e => e.CreatedAt).HasDatabaseName("IX_Products_CreatedAt");
        });
        
        // Configure CampaignProduct (Many-to-Many Join Table)
        modelBuilder.Entity<CampaignProduct>(entity =>
        {
            entity.HasKey(cp => new { cp.CampaignId, cp.ProductId });
            
            entity.HasOne(cp => cp.Campaign)
                .WithMany(c => c.CampaignProducts)
                .HasForeignKey(cp => cp.CampaignId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.HasOne(cp => cp.Product)
                .WithMany(p => p.CampaignProducts)
                .HasForeignKey(cp => cp.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
                
            entity.Property(cp => cp.AddedAt).IsRequired();
        });
    }
}
