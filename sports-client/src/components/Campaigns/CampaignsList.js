import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { campaignsApi } from '../../services/api';

function CampaignsList() {
  const [campaigns, setCampaigns] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCampaigns();
  }, []);

  const fetchCampaigns = async () => {
    try {
      const response = await campaignsApi.getAll();
      setCampaigns(response.data);
    } catch (error) {
      console.error('Error fetching campaigns:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this campaign?')) {
      try {
        await campaignsApi.delete(id);
        setCampaigns(campaigns.filter(c => c.id !== id));
      } catch (error) {
        console.error('Error deleting campaign:', error);
        alert('Failed to delete campaign');
      }
    }
  };

  if (loading) {
    return <div className="loading">Loading campaigns...</div>;
  }

  return (
    <div className="campaigns-list">
      <div className="page-header">
        <h1>Campaigns</h1>
        <Link to="/campaigns/new" className="btn btn-primary">+ Add Campaign</Link>
      </div>

      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Client</th>
              <th>Budget</th>
              <th>Start Date</th>
              <th>End Date</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {campaigns.map(campaign => (
              <tr key={campaign.id}>
                <td>{campaign.id}</td>
                <td>{campaign.name}</td>
                <td>{campaign.clientName}</td>
                <td>${campaign.budget.toLocaleString()}</td>
                <td>{new Date(campaign.startDate).toLocaleDateString()}</td>
                <td>{new Date(campaign.endDate).toLocaleDateString()}</td>
                <td>
                  <Link to={`/campaigns/edit/${campaign.id}`} className="btn btn-sm btn-secondary">
                    Edit
                  </Link>
                  <button 
                    onClick={() => handleDelete(campaign.id)} 
                    className="btn btn-sm btn-danger"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default CampaignsList;
