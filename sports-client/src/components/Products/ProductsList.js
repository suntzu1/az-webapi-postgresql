import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { productsApi, clientsApi } from '../../services/api';

function ProductsList() {
  const [products, setProducts] = useState([]);
  const [allProducts, setAllProducts] = useState([]);
  const [clients, setClients] = useState([]);
  const [selectedClientId, setSelectedClientId] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [productsRes, clientsRes] = await Promise.all([
        productsApi.getAll(),
        clientsApi.getAll()
      ]);
      setAllProducts(productsRes.data);
      setProducts(productsRes.data);
      setClients(clientsRes.data);
    } catch (error) {
      console.error('Error fetching data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleClientFilter = (clientId) => {
    setSelectedClientId(clientId);
    if (clientId === '') {
      setProducts(allProducts);
    } else {
      setProducts(allProducts.filter(p => p.clientId === parseInt(clientId)));
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this product?')) {
      try {
        await productsApi.delete(id);
        const updatedProducts = allProducts.filter(p => p.id !== id);
        setAllProducts(updatedProducts);
        handleClientFilter(selectedClientId);
      } catch (error) {
        console.error('Error deleting product:', error);
        alert('Failed to delete product');
      }
    }
  };

  if (loading) {
    return <div className="loading">Loading products...</div>;
  }

  return (
    <div className="products-list">
      <div className="page-header">
        <h1>Products</h1>
        <div className="header-actions">
          <select 
            value={selectedClientId} 
            onChange={(e) => handleClientFilter(e.target.value)}
            className="filter-select"
          >
            <option value="">All Clients</option>
            {clients.map(client => (
              <option key={client.id} value={client.id}>
                {client.name}
              </option>
            ))}
          </select>
          <Link to="/products/new" className="btn btn-primary">+ Add Product</Link>
        </div>
      </div>

      {selectedClientId && (
        <div className="filter-info">
          Showing {products.length} product{products.length !== 1 ? 's' : ''} for{' '}
          <strong>{clients.find(c => c.id === parseInt(selectedClientId))?.name}</strong>
        </div>
      )}

      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>SKU</th>
              <th>Category</th>
              <th>Price</th>
              <th>Client</th>
              <th>Campaigns</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {products.length === 0 ? (
              <tr>
                <td colSpan="8" style={{ textAlign: 'center', padding: '2rem' }}>
                  No products found{selectedClientId ? ' for this client' : ''}
                </td>
              </tr>
            ) : (
              products.map(product => (
                <tr key={product.id}>
                  <td>{product.id}</td>
                  <td><strong>{product.name}</strong></td>
                  <td><code>{product.sku}</code></td>
                  <td>{product.category}</td>
                  <td>${product.price.toFixed(2)}</td>
                  <td>
                    <span className="badge badge-primary">
                      {product.clientName}
                    </span>
                  </td>
                  <td>
                    {product.campaignNames && product.campaignNames.length > 0 ? (
                      <div style={{ display: 'flex', gap: '5px', flexWrap: 'wrap' }}>
                        {product.campaignNames.map((name, idx) => (
                          <span key={idx} className="badge badge-success">
                            {name}
                          </span>
                        ))}
                      </div>
                    ) : (
                      <span className="text-muted" style={{ fontSize: '0.85rem' }}>No campaigns</span>
                    )}
                  </td>
                  <td>
                    <Link to={`/products/edit/${product.id}`} className="btn btn-sm btn-secondary">
                      Edit
                    </Link>
                    <button 
                      onClick={() => handleDelete(product.id)} 
                      className="btn btn-sm btn-danger"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default ProductsList;
