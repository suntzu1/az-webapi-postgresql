using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportsApi.Data;
using SportsApi.DTOs;
using SportsApi.Models;

namespace SportsApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(ApplicationDbContext context, ILogger<ProductsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetProducts()
    {
        var products = await _context.Products
            .Include(p => p.Client)
            .Include(p => p.CampaignProducts)
                .ThenInclude(cp => cp.Campaign)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                Sku = p.Sku,
                Price = p.Price,
                Category = p.Category,
                ClientId = p.ClientId,
                ClientName = p.Client.Name,
                CampaignNames = p.CampaignProducts.Select(cp => cp.Campaign.Name).ToList(),
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .ToListAsync();

        return Ok(products);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(int id)
    {
        var product = await _context.Products
            .Include(p => p.Client)
            .Include(p => p.CampaignProducts)
                .ThenInclude(cp => cp.Campaign)
            .Where(p => p.Id == id)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                Sku = p.Sku,
                Price = p.Price,
                Category = p.Category,
                ClientId = p.ClientId,
                ClientName = p.Client.Name,
                CampaignNames = p.CampaignProducts.Select(cp => cp.Campaign.Name).ToList(),
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .FirstOrDefaultAsync();

        if (product == null)
        {
            return NotFound();
        }

        return Ok(product);
    }

    [HttpPost]
    public async Task<ActionResult<ProductDto>> CreateProduct(CreateProductDto dto)
    {
        if (!await _context.Clients.AnyAsync(c => c.Id == dto.ClientId))
        {
            return BadRequest("Client not found");
        }

        var product = new Product
        {
            Name = dto.Name,
            Description = dto.Description,
            Sku = dto.Sku,
            Price = dto.Price,
            Category = dto.Category,
            ClientId = dto.ClientId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync();

        var productDto = await _context.Products
            .Include(p => p.Client)
            .Include(p => p.CampaignProducts)
                .ThenInclude(cp => cp.Campaign)
            .Where(p => p.Id == product.Id)
            .Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                Sku = p.Sku,
                Price = p.Price,
                Category = p.Category,
                ClientId = p.ClientId,
                ClientName = p.Client.Name,
                CampaignNames = p.CampaignProducts.Select(cp => cp.Campaign.Name).ToList(),
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            })
            .FirstAsync();

        return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, productDto);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateProduct(int id, UpdateProductDto dto)
    {
        var product = await _context.Products.FindAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        if (!string.IsNullOrWhiteSpace(dto.Name))
        {
            product.Name = dto.Name;
        }

        if (dto.Description != null)
        {
            product.Description = dto.Description;
        }

        if (dto.Sku != null)
        {
            product.Sku = dto.Sku;
        }

        if (dto.Price.HasValue)
        {
            product.Price = dto.Price.Value;
        }

        if (dto.Category != null)
        {
            product.Category = dto.Category;
        }

        product.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteProduct(int id)
    {
        var product = await _context.Products.FindAsync(id);

        if (product == null)
        {
            return NotFound();
        }

        _context.Products.Remove(product);
        await _context.SaveChangesAsync();

        return NoContent();
    }
}
