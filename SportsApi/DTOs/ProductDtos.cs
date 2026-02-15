namespace SportsApi.DTOs;

public class ProductDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Sku { get; set; }
    public decimal? Price { get; set; }
    public string? Category { get; set; }
    public int CampaignId { get; set; }
    public string CampaignName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateProductDto
{
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Sku { get; set; }
    public decimal? Price { get; set; }
    public string? Category { get; set; }
    public int CampaignId { get; set; }
}

public class UpdateProductDto
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? Sku { get; set; }
    public decimal? Price { get; set; }
    public string? Category { get; set; }
}
