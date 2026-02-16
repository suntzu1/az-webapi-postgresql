import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { campaignsApi, clientsApi } from '../../services/api';

function CampaignsList() {
  const [campaigns, setCampaigns] = useState([]);
  const [allCampaigns, setAllCampaigns] = useState([]);
  const [clients, setClients] = useState([]);
  const [selectedClientId, setSelectedClientId] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const [campaignsRes, clientsRes] = await Promise.all([
        campaignsApi.getAll(),
        clientsApi.getAll()
      ]);
      setAllCampaigns(campaignsRes.data);
      setCampaigns(campaignsRes.data);
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
      setCampaigns(allCampaigns);
    } else {
      setCampaigns(allCampaigns.filter(c => c.clientId === parseInt(clientId)));
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this campaign?')) {
      try {
        await campaignsApi.delete(id);
        const updatedCampaigns = allCampaigns.filter(c => c.id !== id);
        setAllCampaigns(updatedCampaigns);
        handleClientFilter(selectedClientId);
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
          <Link to="/campaigns/new" className="btn btn-primary">+ Add Campaign</Link>
        </div>
      </div>

      {selectedClientId && (
        <div className="filter-info">
          Showing {campaigns.length} campaign{campaigns.length !== 1 ? 's' : ''} for{' '}
          <strong>{clients.find(c => c.id === parseInt(selectedClientId))?.name}</strong>
        </div>
      )}

      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Client</th>
              <th>Products</th>
              <th>Budget</th>
              <th>Start Date</th>
              <th>End Date</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {campaigns.length === 0 ? (
              <tr>
                <td colSpan="8" style={{ textAlign: 'center', padding: '2rem' }}>
                  No campaigns found{selectedClientId ? ' for this client' : ''}
                </td>
              </tr>
            ) : (
              campaigns.map(campaign => (
                <tr key={campaign.id}>
                  <td>{campaign.id}</td>
                  <td><strong>{campaign.name}</strong></td>
                  <td>{campaign.clientName}</td>
                  <td>
                    <span className="badge badge-success">
                      {campaign.productCount} {campaign.productCount === 1 ? 'product' : 'products'}
                    </span>
                  </td>
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
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default CampaignsList;
