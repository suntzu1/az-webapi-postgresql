# Sports API Manager - React Frontend

This is the React frontend for the Sports API Manager application.

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Sports API running on http://localhost:5000

## Installation

```bash
npm install
```

## Running the Application

```bash
npm start
```

The application will open at `http://localhost:3000`

## Features

- **Dashboard**: Overview with statistics for Clients, Campaigns, and Products
- **Clients Management**: Create, Read, Update, Delete clients
- **Campaigns Management**: Manage marketing campaigns with client associations
- **Products Management**: Manage products linked to campaigns

## Project Structure

```
src/
??? components/
?   ??? Clients/
?   ?   ??? ClientsList.js
?   ?   ??? ClientForm.js
?   ??? Campaigns/
?   ?   ??? CampaignsList.js
?   ?   ??? CampaignForm.js
?   ??? Products/
?   ?   ??? ProductsList.js
?   ?   ??? ProductForm.js
?   ??? Dashboard.js
?   ??? Dashboard.css
??? services/
?   ??? api.js
??? App.js
??? App.css
??? index.js
```

## API Endpoints

The application connects to the following API endpoints:

- `/api/clients` - Clients CRUD operations
- `/api/campaigns` - Campaigns CRUD operations
- `/api/products` - Products CRUD operations

## Technologies Used

- React 18
- React Router DOM v6
- Axios for HTTP requests
- CSS3 for styling
