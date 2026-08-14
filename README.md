# Laundry App - On-Demand Laundry Service Platform

A comprehensive multi-tenant laundry service platform connecting customers, laundry marts, and delivery partners through mobile and web applications.

## 🎯 Overview

Laundry App provides:
- **Customer App** (Flutter): Order placement, tracking, and management
- **Staff App** (Flutter): Role-based app for collection manager, service man, distribution manager, and delivery partner
- **Admin Panel** (React): Mart administration and analytics
- **Backend API** (Node.js/Express): REST API with PostgreSQL database

---

## 📁 Project Structure

```
laundry/
├── .cursor/                    # AI assistant configuration
│   ├── rules/                 # Coding standards and guidelines
│   ├── ctx-store/            # Documentation and knowledge base
│   └── README.md             # AI assistant guide
├── admin-panel/              # React Admin Web Application
│   ├── src/
│   │   ├── components/      # UI components
│   │   ├── pages/          # Page components
│   │   ├── services/       # API services
│   │   └── ...
│   ├── package.json
│   └── README.md
├── customer-app/             # Flutter Customer Mobile App
│   ├── lib/
│   │   ├── screens/        # Full-screen pages
│   │   ├── widgets/        # Reusable widgets
│   │   ├── providers/      # State management
│   │   └── ...
│   ├── pubspec.yaml
│   └── README.md
├── staff-app/                # Flutter Staff (Multi-role) Mobile App
│   ├── lib/
│   │   ├── screens/        # Full-screen pages
│   │   ├── widgets/        # Reusable widgets
│   │   ├── providers/      # State management
│   │   └── ...
│   ├── pubspec.yaml
│   └── README.md
├── backend/                  # Node.js/Express API (to be created)
│   ├── src/
│   │   ├── controllers/    # HTTP handlers
│   │   ├── services/       # Business logic
│   │   ├── middleware/     # Express middleware
│   │   └── ...
│   ├── prisma/
│   │   └── schema.prisma   # Database schema
│   └── package.json
└── README.md                # This file
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** 18+ and npm/yarn (for Admin Panel and Backend)
- **Flutter** 3.0+ and Dart 3.0+ (for Mobile Apps)
- **PostgreSQL** 14+ (for Backend Database)
- **Docker** (optional, for containerized deployment)

### Installation

#### 1. Admin Panel (React)

```bash
cd admin-panel

# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Start development server
npm run dev
```

Access at: http://localhost:3000

#### 2. Customer App (Flutter)

```bash
cd customer-app

# Get dependencies
flutter pub get

# Run on Android/iOS
flutter run
```

#### 3. Staff App (Flutter)

```bash
cd staff-app

# Get dependencies
flutter pub get

# Run on Android/iOS
flutter run
```

#### 4. Backend API (Coming Soon)

```bash
cd backend

# Install dependencies
npm install

# Set up database
npx prisma migrate dev

# Start development server
npm run dev
```

Access API at: http://localhost:5000/api/v1

---

## 🛠️ Technology Stack

### Admin Panel
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **UI Library**: Material-UI (MUI)
- **State Management**: Zustand
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Charts**: Recharts

### Mobile Apps (Customer & Delivery)
- **Framework**: Flutter 3.x
- **Language**: Dart 3.x
- **State Management**: Provider
- **Navigation**: GoRouter
- **HTTP Client**: Dio
- **Maps**: Google Maps Flutter
- **Location**: Geolocator
- **Push Notifications**: Firebase Cloud Messaging

### Backend
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 14+
- **ORM**: Prisma
- **Authentication**: JWT
- **Storage**: Amazon S3
- **Deployment**: Docker

---

## 📱 Application Features

### Customer App
- ✅ OTP-based authentication
- ✅ Mart discovery with geolocation
- ✅ Service catalog browsing
- ✅ Order creation (per-piece & per-kg pricing)
- ✅ Multiple address management
- ✅ Real-time order tracking
- ✅ Multiple payment options (Card, COD, UPI, Wallet)
- ✅ Order history and reordering
- ✅ Ratings and reviews

### Staff App (Multi-role)
- ✅ Role-based access (collection manager, service man, distribution manager, delivery partner)
- ✅ Delivery partner: tasks, navigation, proof, earnings
- ⏳ Collection manager: incoming/received/submitted orders
- ⏳ Service man: FIFO service queue processing
- ⏳ Distribution manager: dispatch assignment and delivery tracking

### Admin Panel
- ✅ Dashboard with analytics
- ✅ Order management and tracking
- ✅ Customer relationship management
- ✅ Delivery staff management
- ✅ Service catalog configuration
- ✅ Pricing management
- ✅ Reports and insights
- ✅ Daily metrics tracking

---

## 🗄️ Database Schema

The PostgreSQL database includes 17 main entities:

### Core Entities
- `laundry_mart` - Mart information and configuration
- `users` - Admin panel users
- `customers` - Customer profiles
- `customer_addresses` - Delivery addresses
- `customer_mart_profile` - Customer-mart relationship

### Service Catalog
- `service_categories` - Service groupings
- `services` - Individual services with pricing
- `clothes_items` - Per-piece clothing items

### Orders & Billing
- `orders` - Main order entity
- `order_items` - Per-piece items in order
- `order_items_kg` - Per-kg items in order
- `bills` - Invoice and payment tracking

### Delivery Management
- `delivery_staffs` - Delivery partner profiles
- `delivery` - Delivery assignment
- `pickup_for_delivery` - Pickup tasks with proof
- `drop_for_delivery` - Drop tasks with proof

### Analytics
- `mart_daily_metrics` - Daily aggregated metrics

See `docs/database-schema.sql` for complete schema details.

---

## 🔐 Environment Configuration

### Admin Panel (.env)
```bash
VITE_API_BASE_URL=http://localhost:5000/api/v1
VITE_JWT_TOKEN_KEY=laundry_admin_token
VITE_GOOGLE_MAPS_API_KEY=your_key_here
```

### Mobile Apps
Update `lib/services/api_service.dart` with backend URL and configure:
- Google Maps API key in manifest files
- Firebase configuration for push notifications
- Location permissions

### Backend (.env)
```bash
DATABASE_URL=postgresql://user:password@localhost:5432/laundry_db
JWT_SECRET=your_secret_here
AWS_S3_BUCKET=laundry-app-storage
PORT=5000
```

---

## 📚 Documentation

### Architecture & Guidelines
- **Backend Architecture**: `.cursor/ctx-store/architecture/technical/backend-architecture.md`
- **Frontend Architecture**: `.cursor/ctx-store/architecture/technical/frontend-architecture.md`
- **UX Design Principles**: `.cursor/ctx-store/architecture/experience/design-principles.md`

### Coding Standards
- **Backend Standards**: `.cursor/rules/backend/javascript-coding-standards.mdc`
- **React Standards**: `.cursor/rules/frontend/react-coding-standards.mdc`
- **Flutter Standards**: `.cursor/rules/frontend/flutter-coding-standards.mdc`

### API Documentation
- REST API endpoints documented with Swagger/OpenAPI
- Access at: `http://localhost:5000/api-docs` (when backend is running)

---

## 🧪 Testing

### Admin Panel
```bash
cd admin-panel
npm run test              # Run tests
npm run test:coverage     # Generate coverage report
```

### Mobile Apps
```bash
cd customer-app  # or staff-app
flutter test              # Run tests
flutter test --coverage   # Generate coverage
```

### Backend
```bash
cd backend
npm run test              # Run tests
npm run test:integration  # Run integration tests
```

---

## 🐳 Docker Deployment

### Docker Compose
```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Individual Services
```bash
# Build backend
cd backend && docker build -t laundry-backend .

# Build admin panel
cd admin-panel && docker build -t laundry-admin .
```

---

## 🔄 Development Workflow

### Using AI Assistant
The project includes comprehensive AI assistant configuration in `.cursor/`:

```bash
# Create a new task
/command create-task

# Generate backend controller
/command create-controller

# Generate React component
/command create-react-component

# Search knowledge base
/command search-kb [keyword]
```

See `.cursor/README.md` for complete AI assistant guide.

### Git Workflow
```bash
# Feature development
git checkout -b feature/order-tracking
git add .
git commit -m "feat: implement order tracking"
git push origin feature/order-tracking

# Create pull request and merge to main
```

---

## 📊 Project Status

- ✅ **AI Assistant Configuration** - Complete
- ✅ **Admin Panel Setup** - Complete (structure and configuration)
- ✅ **Customer App Setup** - Complete (structure and configuration)
- ✅ **Delivery App Setup** - Complete (structure and configuration)
- ⏳ **Backend API** - To be implemented
- ⏳ **Database Setup** - To be implemented
- ⏳ **Feature Implementation** - In progress

---

## 🤝 Contributing

1. Follow coding standards in `.cursor/rules/`
2. Write tests for new features
3. Update documentation as needed
4. Submit pull requests with clear descriptions
5. Use conventional commits (feat, fix, docs, style, refactor, test, chore)

---

## 📄 License

Proprietary - Laundry App

---

## 🆘 Support

For issues and questions:
- Check documentation in `.cursor/ctx-store/`
- Search knowledge base: `/command search-kb`
- Review architecture docs
- Contact development team

---

**Last Updated**: October 29, 2025  
**Version**: 1.0.0  
**Status**: Initial Setup Complete

