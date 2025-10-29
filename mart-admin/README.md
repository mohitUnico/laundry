# Laundry Mart Admin Panel

Modern React admin panel for managing laundry mart operations.

## Features

- 📊 **Dashboard** - Real-time metrics and analytics
- 📦 **Order Management** - Track and manage orders
- 👥 **Customer Management** - View and manage customers
- 🚚 **Delivery Management** - Manage delivery staff and assignments
- 🧺 **Service Catalog** - Configure services and pricing
- 🎁 **Promotions** - Create and manage promotional offers
- 📈 **Analytics** - Business insights and reports
- ⚙️ **Settings** - Configure mart settings and preferences

## Tech Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool
- **Material-UI** - UI components
- **React Router** - Navigation
- **Zustand** - State management
- **Axios** - API client
- **Recharts** - Data visualization
- **React Hook Form** - Form handling
- **date-fns** - Date manipulation

## Project Structure

```
mart-admin/
├── src/
│   ├── components/      # React components
│   │   ├── common/      # Reusable UI components
│   │   ├── layout/      # Layout components
│   │   └── [features]/  # Feature-specific components
│   ├── pages/           # Page components (routes)
│   ├── hooks/           # Custom React hooks
│   ├── context/         # React Context providers
│   ├── services/        # API services
│   ├── utils/           # Utility functions
│   ├── types/           # TypeScript types
│   ├── interfaces/      # TypeScript interfaces
│   ├── enums/           # TypeScript enums
│   ├── routes/          # Routing configuration
│   └── styles/          # Global styles
├── tests/               # Test files
└── public/              # Static assets
```

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- Backend API running on port 5000 (or configure VITE_API_BASE_URL)

### Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Lint code
npm run lint

# Format code
npm run format
```

### Environment Variables

Create a `.env` file in the root directory:

```env
VITE_API_BASE_URL=http://localhost:5000/api/v1
VITE_API_TIMEOUT=10000
VITE_APP_NAME=Laundry Mart Admin
```

## Development

### Code Style

- Follow the ESLint and Prettier configurations
- Use TypeScript for type safety
- Write functional components with hooks
- Keep components small and focused (< 200 lines)
- Use SCSS modules for styling

### Component Structure

```tsx
import React from 'react';
import './ComponentName.module.scss';

interface ComponentNameProps {
  prop1: string;
  prop2?: number;
}

export const ComponentName: React.FC<ComponentNameProps> = ({ prop1, prop2 }) => {
  // Component logic
  return <div>{prop1}</div>;
};
```

### Testing

Write tests for all components and custom hooks:

```tsx
import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { MyComponent } from './MyComponent';

describe('MyComponent', () => {
  it('renders correctly', () => {
    render(<MyComponent />);
    expect(screen.getByText('Hello')).toBeInTheDocument();
  });
});
```

## Deployment

### Docker

```bash
# Build Docker image
docker build -t laundry-mart-admin .

# Run container
docker run -p 3000:3000 laundry-mart-admin
```

### Production Build

```bash
# Build for production
npm run build:production

# Preview production build
npm run preview
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Write tests
4. Run linting and formatting
5. Create a pull request

## License

MIT
