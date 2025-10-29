# Laundry App - Backend API

Node.js/Express REST API with PostgreSQL and Prisma ORM for the Laundry App platform.

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: PostgreSQL 14+
- **ORM**: Prisma
- **Authentication**: JWT (jsonwebtoken)
- **File Upload**: Multer + AWS S3
- **Validation**: Joi
- **Logging**: Winston
- **Testing**: Jest + Supertest

## Project Structure

```
backend/
├── src/
│   ├── server.js              # Application entry point
│   ├── app.js                 # Express app configuration
│   ├── controllers/           # HTTP request handlers
│   │   ├── order.controller.js
│   │   ├── customer.controller.js
│   │   └── delivery.controller.js
│   ├── services/              # Business logic layer
│   │   ├── order.service.js
│   │   ├── billing.service.js
│   │   └── delivery.service.js
│   ├── middleware/            # Express middleware
│   │   ├── auth.middleware.js
│   │   ├── validation.middleware.js
│   │   ├── error.middleware.js
│   │   └── logger.middleware.js
│   ├── routes/                # API route definitions
│   │   ├── index.js
│   │   ├── order.routes.js
│   │   └── customer.routes.js
│   ├── utils/                 # Utility functions
│   │   ├── errors.js
│   │   ├── logger.js
│   │   └── helpers.js
│   ├── config/                # Configuration
│   │   └── database.js
│   ├── types/                 # Type definitions
│   └── constants/             # Application constants
├── prisma/
│   ├── schema.prisma          # Database schema
│   ├── migrations/            # Database migrations
│   └── seed.js                # Seed data
├── tests/
│   ├── unit/                  # Unit tests
│   └── integration/           # Integration tests
├── logs/                      # Application logs
├── uploads/                   # Temporary uploads
├── .env.example               # Environment variables template
├── Dockerfile                 # Docker configuration
├── docker-compose.yml         # Docker Compose setup
└── package.json
```

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL 14+
- (Optional) Docker and Docker Compose

### Installation

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Update .env with your configuration
# Especially DATABASE_URL, JWT_SECRET, AWS credentials
```

### Database Setup

```bash
# Generate Prisma Client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# (Optional) Seed database with sample data
npm run prisma:seed

# (Optional) Open Prisma Studio
npm run prisma:studio
```

### Development

```bash
# Start development server with auto-reload
npm run dev

# Server runs on http://localhost:5000
```

### Production

```bash
# Start production server
npm start
```

### Docker

```bash
# Build and run with Docker Compose (includes PostgreSQL)
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down

# Build Docker image only
npm run docker:build
```

## API Documentation

### Base URL

```
http://localhost:5000/api/v1
```

### Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Main Endpoints

#### Authentication
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - User logout

#### Orders
- `POST /api/v1/orders` - Create order
- `GET /api/v1/orders` - List orders
- `GET /api/v1/orders/:id` - Get order details
- `PATCH /api/v1/orders/:id/status` - Update order status
- `DELETE /api/v1/orders/:id` - Cancel order

#### Customers
- `GET /api/v1/customers` - List customers
- `GET /api/v1/customers/:id` - Get customer details
- `PUT /api/v1/customers/:id` - Update customer
- `GET /api/v1/customers/:id/orders` - Get customer orders

#### Delivery
- `GET /api/v1/delivery/tasks` - Get available tasks
- `POST /api/v1/delivery/:id/accept` - Accept delivery task
- `POST /api/v1/delivery/:id/pickup` - Complete pickup
- `POST /api/v1/delivery/:id/deliver` - Complete delivery
- `PATCH /api/v1/delivery/:id/location` - Update location

#### Services
- `GET /api/v1/services` - List services
- `GET /api/v1/services/:id` - Get service details
- `POST /api/v1/services` - Create service (Admin)
- `PUT /api/v1/services/:id` - Update service (Admin)

### Response Format

#### Success Response
```json
{
  "success": true,
  "data": { /* resource data */ },
  "message": "Operation successful"
}
```

#### Error Response
```json
{
  "success": false,
  "message": "Error message",
  "errorCode": "ERROR_CODE",
  "errors": [ /* validation errors */ ]
}
```

### Status Codes

- `200 OK` - Successful GET, PUT, PATCH
- `201 Created` - Successful POST
- `204 No Content` - Successful DELETE
- `400 Bad Request` - Validation error
- `401 Unauthorized` - Authentication required
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource conflict
- `500 Internal Server Error` - Server error

## Environment Variables

See `.env.example` for all available configuration options.

### Required Variables
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret key for JWT tokens
- `PORT` - Server port (default: 5000)

### Optional Variables
- AWS S3 credentials for file storage
- SMS provider credentials for OTP
- Email provider credentials
- Payment gateway credentials
- Google Maps API key

## Database Schema

The database includes 17 main entities:

### Core Tables
- `laundry_mart` - Mart information
- `users` - Admin users
- `customers` - Customer profiles
- `customer_addresses` - Delivery addresses
- `customer_mart_profile` - Customer-mart relationships

### Service Catalog
- `service_categories` - Service groupings
- `services` - Individual services
- `clothes_items` - Clothing item catalog

### Orders & Billing
- `orders` - Order management
- `order_items` - Per-piece items
- `order_items_kg` - Per-kg items
- `bills` - Invoicing and payments

### Delivery
- `delivery_staffs` - Delivery partners
- `delivery` - Delivery assignments
- `pickup_for_delivery` - Pickup tasks
- `drop_for_delivery` - Delivery tasks

### Analytics
- `mart_daily_metrics` - Daily metrics

See `prisma/schema.prisma` for complete schema details.

## Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Generate coverage report
npm test -- --coverage
```

### Test Structure

```bash
tests/
├── unit/               # Unit tests for services, utils
│   ├── services/
│   └── utils/
└── integration/        # API endpoint tests
    ├── auth.test.js
    ├── orders.test.js
    └── customers.test.js
```

## Logging

Logs are stored in `logs/app.log` and include:
- HTTP requests and responses
- Database queries (in development)
- Application errors
- Authentication attempts

Log levels: `error`, `warn`, `info`, `debug`

## Security Best Practices

- ✅ JWT authentication with expiration
- ✅ Password hashing with bcrypt
- ✅ Input validation with Joi
- ✅ SQL injection prevention (Prisma)
- ✅ XSS protection with helmet
- ✅ CORS configuration
- ✅ Rate limiting
- ✅ Environment variable security
- ✅ HTTPS in production
- ✅ File upload validation

## Performance Optimization

- Database indexes on frequently queried fields
- Connection pooling (built into Prisma)
- Response compression
- Request pagination
- Caching strategies (TODO)
- Query optimization

## Deployment

### Using Docker

```bash
# Build and deploy
docker-compose up -d

# Run migrations in production
docker-compose exec backend npm run prisma:migrate:prod
```

### Manual Deployment

1. Set environment variables
2. Install dependencies: `npm ci --production`
3. Generate Prisma Client: `npm run prisma:generate`
4. Run migrations: `npm run prisma:migrate:prod`
5. Start server: `npm start`

## Monitoring

- Health check endpoint: `GET /health`
- Database connection check
- Application metrics (TODO)
- Error tracking (TODO)

## Contributing

Follow the coding standards defined in:
- `.cursor/rules/backend/javascript-coding-standards.mdc`
- `.cursor/rules/backend/backend-architecture.mdc`
- `.cursor/rules/backend/backend-review-checklist.mdc`

## Troubleshooting

### Database Connection Issues
- Verify PostgreSQL is running
- Check `DATABASE_URL` in `.env`
- Ensure database exists

### Port Already in Use
```bash
# Find and kill process using port 5000
lsof -ti:5000 | xargs kill -9
```

### Prisma Issues
```bash
# Regenerate Prisma Client
npm run prisma:generate

# Reset database (caution: deletes all data)
npx prisma migrate reset
```

## License

Proprietary - Laundry App

## Support

For issues and questions, refer to:
- Backend Architecture: `.cursor/ctx-store/architecture/technical/backend-architecture.md`
- API Guidelines: `.cursor/rules/backend/backend-api-guideline.mdc`
- Knowledge Base: `.cursor/ctx-store/kb/backend/`

---

**Last Updated**: October 29, 2025  
**Version**: 1.0.0  
**Status**: Ready for Development

