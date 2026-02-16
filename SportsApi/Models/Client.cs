namespace SportsApi.Models;

public class Client
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Navigation properties
    public ICollection<Campaign> Campaigns { get; set; } = new List<Campaign>();
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
