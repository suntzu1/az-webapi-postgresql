import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faTrophy } from '@fortawesome/free-solid-svg-icons';
import ClientsList from './components/Clients/ClientsList';
import ClientForm from './components/Clients/ClientForm';
import CampaignsList from './components/Campaigns/CampaignsList';
import CampaignForm from './components/Campaigns/CampaignForm';
import ProductsList from './components/Products/ProductsList';
import ProductForm from './components/Products/ProductForm';
import Dashboard from './components/Dashboard';
import './App.css';

function App() {
  return (
    <Router>
      <div className="App">
        <nav className="navbar">
          <div className="nav-container">
            <Link to="/" className="nav-logo">
              <FontAwesomeIcon icon={faTrophy} style={{ marginRight: '10px' }} />
              Sports API Manager
            </Link>
            <ul className="nav-menu">
              <li className="nav-item">
                <Link to="/" className="nav-link">Dashboard</Link>
              </li>
              <li className="nav-item">
                <Link to="/clients" className="nav-link">Clients</Link>
              </li>
              <li className="nav-item">
                <Link to="/campaigns" className="nav-link">Campaigns</Link>
              </li>
              <li className="nav-item">
                <Link to="/products" className="nav-link">Products</Link>
              </li>
            </ul>
          </div>
        </nav>

        <div className="container">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/clients" element={<ClientsList />} />
            <Route path="/clients/new" element={<ClientForm />} />
            <Route path="/clients/edit/:id" element={<ClientForm />} />
            <Route path="/campaigns" element={<CampaignsList />} />
            <Route path="/campaigns/new" element={<CampaignForm />} />
            <Route path="/campaigns/edit/:id" element={<CampaignForm />} />
            <Route path="/products" element={<ProductsList />} />
            <Route path="/products/new" element={<ProductForm />} />
            <Route path="/products/edit/:id" element={<ProductForm />} />
          </Routes>
        </div>
      </div>
    </Router>
  );
}

export default App;
