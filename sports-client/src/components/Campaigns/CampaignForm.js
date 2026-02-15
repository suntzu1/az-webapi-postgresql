import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { campaignsApi, clientsApi } from '../../services/api';

function CampaignForm() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  const [clients, setClients] = useState([]);
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

  useEffect(() => {
    fetchClients();
    if (isEditMode) {
      fetchCampaign();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  const fetchClients = async () => {
    try {
      const response = await clientsApi.getAll();
      setClients(response.data);
    } catch (error) {
      console.error('Error fetching clients:', error);
    }
  };

  const fetchCampaign = async () => {
    try {
      const response = await campaignsApi.getById(id);
      const campaign = response.data;
      setFormData({
        name: campaign.name,
        description: campaign.description,
        startDate: campaign.startDate.split('T')[0],
        endDate: campaign.endDate.split('T')[0],
        targetAudience: campaign.targetAudience,
        budget: campaign.budget,
        clientId: campaign.clientId,
      });
    } catch (error) {
      console.error('Error fetching campaign:', error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      const data = {
        ...formData,
        budget: parseFloat(formData.budget),
        clientId: parseInt(formData.clientId),
      };

      if (isEditMode) {
        await campaignsApi.update(id, data);
      } else {
        await campaignsApi.create(data);
      }
      navigate('/campaigns');
    } catch (error) {
      console.error('Error saving campaign:', error);
      alert('Failed to save campaign');
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
      <h1>{isEditMode ? 'Edit Campaign' : 'Add New Campaign'}</h1>
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
          <label htmlFor="clientId">Client *</label>
          <select
            id="clientId"
            name="clientId"
            value={formData.clientId}
            onChange={handleChange}
            required
            className="form-control"
          >
            <option value="">Select a client</option>
            {clients.map(client => (
              <option key={client.id} value={client.id}>
                {client.name}
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

        <div className="form-group">
          <label htmlFor="targetAudience">Target Audience</label>
          <input
            type="text"
            id="targetAudience"
            name="targetAudience"
            value={formData.targetAudience}
            onChange={handleChange}
            className="form-control"
          />
        </div>

        <div className="form-group">
          <label htmlFor="budget">Budget *</label>
          <input
            type="number"
            id="budget"
            name="budget"
            value={formData.budget}
            onChange={handleChange}
            step="0.01"
            min="0"
            required
            className="form-control"
          />
        </div>

        <div className="form-actions">
          <button type="submit" disabled={loading} className="btn btn-primary">
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
