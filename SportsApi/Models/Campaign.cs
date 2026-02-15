namespace SportsApi.Models;

public class Campaign
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? TargetAudience { get; set; }
    public decimal? Budget { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    
    // Foreign key
    public int ClientId { get; set; }
    
    // Navigation properties
    public Client Client { get; set; } = null!;
    public ICollection<Product> Products { get; set; } = new List<Product>();
}
