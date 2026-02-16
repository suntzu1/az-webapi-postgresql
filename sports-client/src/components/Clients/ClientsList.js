import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { clientsApi } from '../../services/api';

function ClientsList() {
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      const response = await clientsApi.getAll();
      setClients(response.data);
    } catch (error) {
      console.error('Error fetching clients:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this client?')) {
      try {
        await clientsApi.delete(id);
        setClients(clients.filter(c => c.id !== id));
      } catch (error) {
        console.error('Error deleting client:', error);
        alert('Failed to delete client');
      }
    }
  };

  if (loading) {
    return <div className="loading">Loading clients...</div>;
  }

  return (
    <div className="clients-list">
      <div className="page-header">
        <h1>Clients</h1>
        <Link to="/clients/new" className="btn btn-primary">+ Add Client</Link>
      </div>

      <div className="table-container">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Description</th>
              <th>Products</th>
              <th>Campaigns</th>
              <th>Created At</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {clients.map(client => (
              <tr key={client.id}>
                <td>{client.id}</td>
                <td><strong>{client.name}</strong></td>
                <td>{client.description}</td>
                <td>
                  <span className="badge badge-primary">
                    {client.productCount} {client.productCount === 1 ? 'product' : 'products'}
                  </span>
                </td>
                <td>
                  <span className="badge badge-info">
                    {client.campaignCount} {client.campaignCount === 1 ? 'campaign' : 'campaigns'}
                  </span>
                </td>
                <td>{new Date(client.createdAt).toLocaleDateString()}</td>
                <td>
                  <Link to={`/clients/edit/${client.id}`} className="btn btn-sm btn-secondary">
                    Edit
                  </Link>
                  <button 
                    onClick={() => handleDelete(client.id)} 
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

export default ClientsList;
