# Laundry App - Admin Panel

React-based web application for laundry mart administration and management.

## Tech Stack

- **Framework**: React 18
- **Build Tool**: Vite
- **Language**: TypeScript
- **UI Library**: Material-UI (MUI)
- **State Management**: Zustand
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Forms**: React Hook Form
- **Charts**: Recharts
- **Date Handling**: date-fns

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- Backend API running on port 5000

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Update .env with your configuration
```

### Development

```bash
# Start development server (http://localhost:3000)
npm run dev

# Run tests
npm run test

# Run linter
npm run lint
```

### Build

```bash
# Build for production
npm run build

# Preview production build
npm run preview
```

## Project Structure

```
admin-panel/
├── public/           # Static assets
├── src/
│   ├── components/   # Reusable components
│   │   ├── common/   # Generic UI components
│   │   ├── layout/   # Layout components (Header, Sidebar)
│   │   └── features/ # Feature-specific components
│   ├── pages/        # Page components
│   │   ├── Dashboard/
│   │   ├── Orders/
│   │   ├── Customers/
│   │   ├── Delivery/
│   │   ├── Services/
│   │   └── Reports/
│   ├── hooks/        # Custom React hooks
│   ├── services/     # API services
│   ├── store/        # State management
│   ├── utils/        # Utility functions
│   ├── types/        # TypeScript types
│   ├── constants/    # Constants
│   ├── routes/       # Route configuration
│   └── styles/       # Global styles
└── package.json
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run lint` - Run ESLint
- `npm run preview` - Preview production build
- `npm run test` - Run tests
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Generate test coverage report

## Features

- 📊 **Dashboard**: Revenue, orders, and analytics overview
- 📦 **Order Management**: Track and manage orders
- 👥 **Customer Management**: View customer profiles and history
- 🚚 **Delivery Management**: Manage delivery staff and assignments
- 🧺 **Service Catalog**: Configure services and pricing
- 📈 **Reports**: Analytics and business insights

## Environment Variables

See `.env.example` for all available configuration options.

## Contributing

Follow the coding standards defined in `.cursor/rules/frontend/react-coding-standards.mdc`.

## License

Proprietary - Laundry App

