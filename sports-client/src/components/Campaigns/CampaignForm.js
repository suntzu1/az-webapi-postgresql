import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { campaignsApi, clientsApi, productsApi } from '../../services/api';

function CampaignForm() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  const [clients, setClients] = useState([]);
  const [products, setProducts] = useState([]);
  const [selectedProducts, setSelectedProducts] = useState([]);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    startDate: '',
    endDate: '',
    targetAudience: '',
    budget: '',
    clientId: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchClients();
    if (isEditMode) {
      fetchCampaign();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  useEffect(() => {
    if (formData.clientId) {
      fetchClientProducts(formData.clientId);
    } else {
      setProducts([]);
      setSelectedProducts([]);
    }
  }, [formData.clientId]);

  const fetchClients = async () => {
    try {
      const response = await clientsApi.getAll();
      setClients(response.data);
    } catch (err) {
      console.error('Error fetching clients:', err);
      setError('Failed to load clients. Please refresh the page.');
    }
  };

  const fetchClientProducts = async (clientId) => {
    try {
      const response = await productsApi.getAll();
      const clientProducts = response.data.filter(p => p.clientId === parseInt(clientId));
      setProducts(clientProducts);
    } catch (err) {
      console.error('Error fetching products:', err);
    }
  };

  const fetchCampaign = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await campaignsApi.getById(id);
      const campaign = response.data;
      setFormData({
        name: campaign.name,
        description: campaign.description || '',
        startDate: campaign.startDate.split('T')[0],
        endDate: campaign.endDate.split('T')[0],
        targetAudience: campaign.targetAudience || '',
        budget: campaign.budget || '',
        clientId: campaign.clientId,
      });
    } catch (err) {
      console.error('Error fetching campaign:', err);
      setError('Failed to load campaign data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.name.trim()) {
      setError('Campaign name is required');
      return;
    }
    
    if (!formData.clientId) {
      setError('Please select a client');
      return;
    }
    
    if (!formData.startDate || !formData.endDate) {
      setError('Start date and end date are required');
      return;
    }
    
    if (formData.startDate > formData.endDate) {
      setError('End date must be after start date');
      return;
    }
    
    setLoading(true);
    setError(null);

    try {
      const data = {
        ...formData,
        budget: formData.budget ? parseFloat(formData.budget) : null,
        clientId: parseInt(formData.clientId),
        productIds: selectedProducts,
      };

      const apiCall = isEditMode
        ? () => campaignsApi.update(id, data)
        : () => campaignsApi.create(data);
      
      await apiCall();
      navigate('/campaigns');
    } catch (err) {
      console.error('Error saving campaign:', err);
      setError(err.response?.data?.message || err.response?.data || 'Failed to save campaign. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData({
      ...formData,
      [name]: value,
    });
  };

  const handleProductToggle = (productId) => {
    setSelectedProducts(prev => 
      prev.includes(productId)
        ? prev.filter(id => id !== productId)
        : [...prev, productId]
    );
  };

  const selectedClient = clients.find(c => c.id === parseInt(formData.clientId));

  return (
    <div className="form-container">
      <h1>{isEditMode ? 'Edit Campaign' : 'Add New Campaign'}</h1>
      {error && (
        <div className="alert alert-error" role="alert">
          {error}
        </div>
      )}
      <form onSubmit={handleSubmit} className="form">
        <div className="alert alert-info">
          <strong>?? Campaign Creation:</strong> Select a client, enter campaign details, and choose which products to promote in this campaign.
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
            This campaign will belong to this client
          </small>
        </div>

        {selectedClient && (
          <div className="client-selected-banner">
            ? Creating campaign for: <strong>{selectedClient.name}</strong>
          </div>
        )}

        <hr style={{ margin: '2rem 0', border: 'none', borderTop: '1px solid #ddd' }} />

        <h3 style={{ marginBottom: '1.5rem', color: '#2c3e50' }}>Campaign Details</h3>

        <div className="form-group">
          <label htmlFor="name">Campaign Name *</label>
          <input
            type="text"
            id="name"
            name="name"
            value={formData.name}
            onChange={handleChange}
            required
            className="form-control"
            placeholder="e.g., Summer 2026 Collection"
          />
        </div>

        <div className="form-row">
          <div className="form-group">
            <label htmlFor="startDate">Start Date *</label>
            <input
              type="date"
              id="startDate"
              name="startDate"
              value={formData.startDate}
              onChange={handleChange}
              required
              className="form-control"
            />
          </div>

          <div className="form-group">
            <label htmlFor="endDate">End Date *</label>
            <input
              type="date"
              id="endDate"
              name="endDate"
              value={formData.endDate}
              onChange={handleChange}
              required
              className="form-control"
            />
          </div>
        </div>

        <div className="form-row">
          <div className="form-group">
            <label htmlFor="budget">Budget</label>
            <input
              type="number"
              id="budget"
              name="budget"
              value={formData.budget}
              onChange={handleChange}
              step="0.01"
              min="0"
              className="form-control"
              placeholder="0.00"
            />
          </div>

          <div className="form-group">
            <label htmlFor="targetAudience">Target Audience</label>
            <input
              type="text"
              id="targetAudience"
              name="targetAudience"
              value={formData.targetAudience}
              onChange={handleChange}
              className="form-control"
              placeholder="e.g., Athletes aged 18-35"
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
            placeholder="Enter campaign description..."
          />
        </div>

        {formData.clientId && products.length > 0 && (
          <>
            <hr style={{ margin: '2rem 0', border: 'none', borderTop: '1px solid #ddd' }} />
            
            <h3 style={{ marginBottom: '1.5rem', color: '#2c3e50' }}>
              Select Products to Promote ({selectedProducts.length} selected)
            </h3>

            <div className="products-selection">
              {products.map(product => (
                <div key={product.id} className="product-checkbox-item">
                  <label className="checkbox-label">
                    <input
                      type="checkbox"
                      checked={selectedProducts.includes(product.id)}
                      onChange={() => handleProductToggle(product.id)}
                    />
                    <div className="product-info">
                      <strong>{product.name}</strong>
                      <span className="product-details">
                        {product.sku} - {product.category} - ${product.price}
                      </span>
                    </div>
                  </label>
                </div>
              ))}
            </div>
          </>
        )}

        {formData.clientId && products.length === 0 && (
          <div className="alert alert-info" style={{ marginTop: '1rem' }}>
            <strong>?? No products available:</strong> This client doesn't have any products yet. 
            You can create the campaign now and add products later.
          </div>
        )}

        <div className="form-actions" style={{ marginTop: '2rem' }}>
          <button type="submit" disabled={loading || !formData.clientId} className="btn btn-primary">
            {loading ? 'Saving...' : isEditMode ? 'Update Campaign' : 'Create Campaign'}
          </button>
          <button 
            type="button" 
            onClick={() => navigate('/campaigns')} 
            className="btn btn-secondary"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

export default CampaignForm;
