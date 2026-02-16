namespace SportsApi.Models;

public class Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Sku { get; set; }
    public decimal? Price { get; set; }
    public string? Category { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Foreign key - Product belongs to Client
    public int ClientId { get; set; }
    
    // Navigation properties
    public Client Client { get; set; } = null!;
    public ICollection<CampaignProduct> CampaignProducts { get; set; } = new List<CampaignProduct>();
}
