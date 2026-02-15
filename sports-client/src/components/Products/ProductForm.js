import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { productsApi, campaignsApi } from '../../services/api';

function ProductForm() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  const [campaigns, setCampaigns] = useState([]);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    sku: '',
    price: '',
    category: '',
    campaignId: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchCampaigns();
    if (isEditMode) {
      fetchProduct();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const fetchCampaigns = async () => {
    try {
      const response = await campaignsApi.getAll();
      setCampaigns(response.data);
    } catch (err) {
      console.error('Error fetching campaigns:', err);
      setError('Failed to load campaigns. Please refresh the page.');
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
        description: product.description,
        sku: product.sku,
        price: product.price,
        category: product.category,
        campaignId: product.campaignId,
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
    
    if (!formData.name.trim() || !formData.sku.trim() || !formData.category.trim()) {
      setError('Please fill in all required fields');
      return;
    }
    
    if (!formData.campaignId) {
      setError('Please select a campaign');
      return;
    }
    
    setLoading(true);
    setError(null);

    try {
      const data = {
        ...formData,
        price: parseFloat(formData.price),
        campaignId: parseInt(formData.campaignId),
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

  return (
    <div className="form-container">
      <h1>{isEditMode ? 'Edit Product' : 'Add New Product'}</h1>
      {error && (
        <div className="alert alert-error" role="alert">
          {error}
        </div>
      )}
      <form onSubmit={handleSubmit} className="form">
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
            />
          </div>
        </div>

        <div className="form-group">
          <label htmlFor="campaignId">Campaign *</label>
          <select
            id="campaignId"
            name="campaignId"
            value={formData.campaignId}
            onChange={handleChange}
            required
            className="form-control"
          >
            <option value="">Select a campaign</option>
            {campaigns.map(campaign => (
              <option key={campaign.id} value={campaign.id}>
                {campaign.name}
              </option>
            ))}
          </select>
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
          />
        </div>

        <div className="form-actions">
          <button type="submit" disabled={loading} className="btn btn-primary">
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
