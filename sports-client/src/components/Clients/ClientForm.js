import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { clientsApi } from '../../services/api';

function ClientForm() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  const [formData, setFormData] = useState({
    name: '',
    description: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isEditMode) {
      fetchClient();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const fetchClient = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await clientsApi.getById(id);
      setFormData({
        name: response.data.name,
        description: response.data.description,
      });
    } catch (err) {
      console.error('Error fetching client:', err);
      setError('Failed to load client data. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.name.trim()) {
      setError('Client name is required');
      return;
    }
    
    setLoading(true);
    setError(null);

    try {
      const apiCall = isEditMode 
        ? () => clientsApi.update(id, formData)
        : () => clientsApi.create(formData);
      
      await apiCall();
      navigate('/clients');
    } catch (err) {
      console.error('Error saving client:', err);
      setError(err.response?.data?.message || 'Failed to save client. Please try again.');
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
      <h1>{isEditMode ? 'Edit Client' : 'Add New Client'}</h1>
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
            {loading ? 'Saving...' : isEditMode ? 'Update Client' : 'Create Client'}
          </button>
          <button 
            type="button" 
            onClick={() => navigate('/clients')} 
            className="btn btn-secondary"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

export default ClientForm;
