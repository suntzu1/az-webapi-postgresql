import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { productsApi, clientsApi } from '../../services/api';

function ProductForm() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  const [clients, setClients] = useState([]);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    sku: '',
    price: '',
    category: '',
    clientId: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchData();
    if (isEditMode) {
      fetchProduct();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const fetchData = async () => {
    try {
      const clientsRes = await clientsApi.getAll();
      setClients(clientsRes.data);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to load data. Please refresh the page.');
    }
  };

  const fetchProduct = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await productsApi.getById(id);
      const product = response.data;
      setFormData({
        name: product.name,
        description: product.description || '',
        sku: product.sku,
        price: product.price,
        category: product.category,
        clientId: product.clientId,
      });
    } catch (err) {
      console.error('Error fetching product:', err);
      setError('Failed to load product data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.clientId) {
      setError('Please select a client');
      return;
    }
    
    if (!formData.name.trim() || !formData.sku.trim() || !formData.category.trim()) {
      setError('Please fill in all required fields');
      return;
    }
    
    setLoading(true);
    setError(null);

    try {
      const data = {
        ...formData,
        price: parseFloat(formData.price),
        clientId: parseInt(formData.clientId),
      };

      const apiCall = isEditMode
        ? () => productsApi.update(id, data)
        : () => productsApi.create(data);
      
      await apiCall();
      navigate('/products');
    } catch (err) {
      console.error('Error saving product:', err);
      setError(err.response?.data?.message || 'Failed to save product. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const selectedClient = clients.find(c => c.id === parseInt(formData.clientId));

  return (
    <div className="form-container">
      <h1>{isEditMode ? 'Edit Product' : 'Add New Product'}</h1>
      {error && (
        <div className="alert alert-error" role="alert">
          {error}
        </div>
      )}
      <form onSubmit={handleSubmit} className="form">
        <div className="alert alert-info">
          <strong>?? Product Ownership:</strong> Products belong directly to clients. 
          You can assign products to marketing campaigns later.
        </div>

        <div className="form-group">
          <label htmlFor="clientId">
            Client * 
            <span className="required-indicator">Required</span>
          </label>
          <select
            id="clientId"
            name="clientId"
            value={formData.clientId}
            onChange={handleChange}
            required
            className="form-control"
          >
            <option value="">-- Select Client --</option>
            {clients.map(client => (
              <option key={client.id} value={client.id}>
                {client.name} ({client.productCount} {client.productCount === 1 ? 'product' : 'products'})
              </option>
            ))}
          </select>
          <small className="form-text">
            This product will belong to this client
          </small>
        </div>

        {selectedClient && (
          <div className="client-selected-banner">
            ? Creating product for: <strong>{selectedClient.name}</strong>
          </div>
        )}

        <hr style={{ margin: '2rem 0', border: 'none', borderTop: '1px solid #ddd' }} />

        <h3 style={{ marginBottom: '1.5rem', color: '#2c3e50' }}>Product Details</h3>

        <div className="form-group">
          <label htmlFor="name">Name *</label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
            className="form-control"
            placeholder="e.g., Air Max 2026"
          />
        </div>

        <div className="form-group">
          <label htmlFor="sku">SKU *</label>
          <input
            type="text"
            id="sku"
            name="sku"
            value={formData.sku}
            onChange={handleChange}
            required
            className="form-control"
            placeholder="e.g., AM2026-BLK-10"
          />
        </div>

        <div className="form-row">
          <div className="form-group">
            <label htmlFor="category">Category *</label>
            <input
              type="text"
              id="category"
              name="category"
              value={formData.category}
              onChange={handleChange}
              required
              className="form-control"
              placeholder="e.g., Footwear, Apparel"
            />
          </div>

          <div className="form-group">
            <label htmlFor="price">Price *</label>
            <input
              type="number"
              id="price"
              name="price"
              value={formData.price}
              onChange={handleChange}
              step="0.01"
              min="0"
              required
              className="form-control"
              placeholder="0.00"
            />
          </div>
        </div>

        <div className="form-group">
          <label htmlFor="description">Description</label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleChange}
            rows="4"
            className="form-control"
            placeholder="Enter product description..."
          />
        </div>

        <div className="form-actions">
          <button type="submit" disabled={loading || !formData.clientId} className="btn btn-primary">
            {loading ? 'Saving...' : isEditMode ? 'Update Product' : 'Create Product'}
          </button>
          <button 
            type="button" 
            onClick={() => navigate('/products')} 
            className="btn btn-secondary"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

export default ProductForm;
