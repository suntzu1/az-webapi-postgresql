import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faUsers, faBullhorn, faBox } from '@fortawesome/free-solid-svg-icons';
import { clientsApi, campaignsApi, productsApi } from '../services/api';
import './Dashboard.css';

function Dashboard() {
  const [stats, setStats] = useState({
    clients: 0,
    campaigns: 0,
    products: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const [clientsRes, campaignsRes, productsRes] = await Promise.all([
        clientsApi.getAll(),
        campaignsApi.getAll(),
        productsApi.getAll(),
      ]);

      setStats({
        clients: clientsRes.data.length,
        campaigns: campaignsRes.data.length,
        products: productsRes.data.length,
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="loading">Loading...</div>;
  }

  return (
    <div className="dashboard">
      <h1>Dashboard</h1>
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-icon stat-icon-clients">
            <FontAwesomeIcon icon={faUsers} />
          </div>
          <div className="stat-info">
            <h3>{stats.clients}</h3>
            <p>Clients</p>
          </div>
          <Link to="/clients" className="stat-link">View All ?</Link>
        </div>

        <div className="stat-card">
          <div className="stat-icon stat-icon-campaigns">
            <FontAwesomeIcon icon={faBullhorn} />
          </div>
          <div className="stat-info">
            <h3>{stats.campaigns}</h3>
            <p>Campaigns</p>
          </div>
          <Link to="/campaigns" className="stat-link">View All ?</Link>
        </div>

        <div className="stat-card">
          <div className="stat-icon stat-icon-products">
            <FontAwesomeIcon icon={faBox} />
          </div>
          <div className="stat-info">
            <h3>{stats.products}</h3>
            <p>Products</p>
          </div>
          <Link to="/products" className="stat-link">View All ?</Link>
        </div>
      </div>

      <div className="quick-actions">
        <h2>Quick Actions</h2>
        <div className="action-buttons">
          <Link to="/clients/new" className="btn btn-primary">+ Add Client</Link>
          <Link to="/campaigns/new" className="btn btn-primary">+ Add Campaign</Link>
          <Link to="/products/new" className="btn btn-primary">+ Add Product</Link>
        </div>
      </div>
    </div>
  );
}

export default Dashboard;
