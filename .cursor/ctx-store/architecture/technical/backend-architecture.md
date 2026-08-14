# Laundry App Backend Architecture

## Overview

Laundry App backend follows a modular, layered REST API architecture built using Node.js (Express.js) and PostgreSQL. The backend is deployed as Docker containers and provides RESTful endpoints for the admin panel (React) and mobile apps (Flutter).

---

## Technology Stack

| Component         | Technology/Tool                    |
| ----------------- | ---------------------------------- |
| Language          | JavaScript/TypeScript (Node.js 18+)|
| Framework         | Express.js                         |
| Runtime           | Node.js                            |
| API Architecture  | REST API                           |
| Database          | PostgreSQL 14+                     |
| ORM               | Prisma                             |
| Authentication    | JWT (jsonwebtoken)                 |
| Password Hashing  | bcrypt                             |
| File Upload       | Multer                             |
| Cloud Storage     | Amazon S3 (AWS SDK)                |
| Validation        | Joi / Zod                          |
| API Documentation | Swagger/OpenAPI                    |
| Testing           | Jest + Supertest                   |
| Logging           | Winston / Pino                     |
| Deployment        | Docker + Docker Compose/Kubernetes |
| CI/CD             | GitHub Actions                     |

---

## Key Dependencies

| Package                  | Purpose                              |
| ------------------------ | ------------------------------------ |
| express                  | Web framework for REST API           |
| @prisma/client           | Database ORM and type-safe queries   |
| prisma                   | Database migrations and schema       |
| jsonwebtoken             | JWT authentication                   |
| bcrypt                   | Password hashing                     |
| multer                   | File upload handling                 |
| aws-sdk                  | S3 integration for images            |
| joi / zod                | Request validation                   |
| swagger-jsdoc            | API documentation generation         |
| swagger-ui-express       | Swagger UI hosting                   |
| jest                     | Unit and integration testing         |
| supertest                | API endpoint testing                 |
| winston / pino           | Structured logging                   |
| dotenv                   | Environment configuration            |
| cors                     | Cross-origin resource sharing        |

---

## Architecture Layers

### 1. Controllers Layer (HTTP Handlers)

* Handle HTTP requests and responses
* Input validation at API level
* Call appropriate service methods
* Format responses consistently
* Delegate error handling to middleware
* **Location**: `backend/src/controllers/`

**Example:**
```javascript
// controllers/order.controller.js
exports.createOrder = async (req, res, next) => {
  try {
    const order = await orderService.createOrder(req.user.id, req.body);
    res.status(201).json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};
```

### 2. Services Layer (Business Logic)

* Core business logic and orchestration
* Transaction management with Prisma
* Data validation and business rules
* Interact with database through Prisma Client
* Coordinate multiple operations
* **Location**: `backend/src/services/`

**Example:**
```javascript
// services/order.service.js
class OrderService {
  async createOrder(userId, orderData) {
    return await prisma.$transaction(async (tx) => {
      const order = await tx.orders.create({ data: { /* ... */ } });
      await tx.order_items.createMany({ data: orderData.items });
      await billingService.createBill(order.order_id, tx);
      return order;
    });
  }
}
```

### 3. Middleware Layer

* Authentication (JWT verification)
* Authorization (role-based access control)
* Request validation (Joi/Zod schemas)
* Error handling (centralized)
* Logging (request/response)
* CORS configuration
* File upload handling
* **Location**: `backend/src/middleware/`

**Example:**
```javascript
// middleware/auth.middleware.js
exports.authenticateJWT = async (req, res, next) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  req.user = decoded;
  next();
};
```

### 4. Routes Layer (API Endpoints)

* Define REST API endpoints
* Map URLs to controller methods
* Apply middleware (auth, validation)
* Group related endpoints
* **Location**: `backend/src/routes/`

**Example:**
```javascript
// routes/order.routes.js
router.post('/orders', authenticateJWT, validate(schema), orderController.createOrder);
router.get('/orders/:id', authenticateJWT, orderController.getOrderById);
```

### 5. Database Layer (Prisma)

* Type-safe database queries
* Schema-first approach
* Automatic migrations
* Connection pooling
* Query optimization
* **Location**: `backend/prisma/schema.prisma`

**Example:**
```prisma
model Order {
  order_id     String   @id @default(uuid())
  customer_id  String
  mart_id      String
  order_status String
  total_amount Decimal  @db.Decimal(10, 2)
  created_at   DateTime @default(now())
  
  @@map("orders")
}
```

---

## Project Structure

```
backend/
├── src/
│   ├── controllers/      # HTTP request handlers
│   │   ├── order.controller.js
│   │   ├── customer.controller.js
│   │   ├── delivery.controller.js
│   │   ├── cart.controller.js                    # NEW
│   │   ├── collection-manager.controller.js      # NEW
│   │   ├── service-man.controller.js             # NEW
│   │   ├── distribution-manager.controller.js    # NEW
│   │   ├── service-queue.controller.js           # NEW
│   │   └── admin.controller.js
│   ├── services/         # Business logic
│   │   ├── order.service.js
│   │   ├── billing.service.js
│   │   ├── delivery.service.js
│   │   ├── cart.service.js                       # NEW
│   │   ├── collection.service.js                 # NEW
│   │   ├── service-queue.service.js              # NEW
│   │   ├── distribution.service.js               # NEW
│   │   └── verification.service.js               # NEW
│   ├── middleware/       # Express middleware
│   │   ├── auth.middleware.js
│   │   ├── validation.middleware.js
│   │   ├── error.middleware.js
│   │   └── role.middleware.js                    # NEW
│   ├── routes/           # API route definitions
│   │   ├── order.routes.js
│   │   ├── customer.routes.js
│   │   ├── cart.routes.js                        # NEW
│   │   ├── collection.routes.js                  # NEW
│   │   ├── service-queue.routes.js               # NEW
│   │   ├── distribution.routes.js                # NEW
│   │   └── admin.routes.js
│   ├── utils/            # Helper functions
│   │   ├── errors.js
│   │   ├── logger.js
│   │   └── helpers.js
│   ├── config/           # Configuration
│   │   └── database.js
│   ├── types/            # TypeScript types
│   └── constants/        # Application constants
│       └── order-statuses.js                     # NEW
├── prisma/
│   ├── schema.prisma     # Database schema (UPDATED with 6 user roles)
│   ├── migrations/       # Database migrations
│   └── seed.ts           # Seed data (UPDATED)
├── tests/
│   ├── unit/
│   │   ├── cart.service.test.js                  # NEW
│   │   ├── service-queue.service.test.js         # NEW
│   │   └── collection.service.test.js            # NEW
│   └── integration/
│       ├── cart-workflow.test.js                 # NEW
│       └── order-workflow.test.js                # UPDATED
├── Dockerfile
├── .env.example
└── package.json
```

---

## Design Principles

### 1. Separation of Concerns
* Controllers handle HTTP, not business logic
* Services contain business logic, not HTTP concerns
* Middleware handles cross-cutting concerns
* Database access only through Prisma

### 2. Single Responsibility
* Each service handles one domain (orders, customers, delivery)
* Each controller handles one resource
* Each middleware has one purpose

### 3. Dependency Injection
* Services are injected where needed
* No tight coupling between layers
* Easy to test and mock

### 4. Error Handling
* Custom error classes with status codes
* Centralized error middleware
* Consistent error response format
* Proper logging of errors

### 5. Transaction Management
* Use Prisma transactions for atomic operations
* Handle rollbacks automatically
* Ensure data consistency

---

## API Design Standards

### RESTful Endpoints
```
POST   /api/v1/orders              # Create order
GET    /api/v1/orders              # List orders
GET    /api/v1/orders/:id          # Get order
PUT    /api/v1/orders/:id          # Update order
PATCH  /api/v1/orders/:id/status   # Update status
DELETE /api/v1/orders/:id          # Delete order
```

### Request/Response Format
```json
// Success
{
  "success": true,
  "data": { /* resource */ },
  "message": "Operation successful"
}

// Error
{
  "success": false,
  "message": "Error message",
  "errorCode": "ERROR_CODE",
  "errors": [ /* validation errors */ ]
}
```

---

## Security Best Practices

1. **Authentication**: JWT tokens with expiration
2. **Password Security**: bcrypt hashing (10 rounds)
3. **Input Validation**: Joi/Zod schemas for all inputs
4. **SQL Injection**: Prisma handles parameterization
5. **XSS Prevention**: Proper input sanitization
6. **CORS**: Configured for specific origins
7. **Rate Limiting**: Prevent abuse
8. **Environment Variables**: Secrets in .env files
9. **HTTPS**: Required in production
10. **File Upload Security**: Type and size validation

---

## Performance Optimization

1. **Database Indexes**: On frequently queried fields
2. **Connection Pooling**: Built into Prisma
3. **Pagination**: For list endpoints
4. **Caching**: Redis for frequently accessed data
5. **Query Optimization**: Use Prisma's select/include wisely
6. **Batch Operations**: Process multiple items efficiently
7. **Async/Await**: Non-blocking operations
8. **Compression**: Gzip for responses

---

## Logging Standards

**Library**: Winston or Pino with structured logging

**Log Levels**:
- `error`: Application errors
- `warn`: Warning conditions
- `info`: General information
- `debug`: Debugging information (dev only)

**Log Format**:
```json
{
  "timestamp": "2025-10-29T12:00:00Z",
  "level": "info",
  "message": "Order created",
  "service": "order-service",
  "orderId": "order-123",
  "userId": "user-456",
  "correlationId": "req-789"
}
```

---

## Testing Strategy

### Unit Tests (Jest)
* Test services in isolation
* Mock Prisma Client
* Test business logic
* Coverage: 70%+ target

### Integration Tests (Supertest)
* Test API endpoints
* Real database (test instance)
* Test authentication
* Test error cases

### Example:
```javascript
describe('OrderService', () => {
  it('should create order with items', async () => {
    const order = await orderService.createOrder(userId, orderData);
    expect(order).toHaveProperty('order_id');
  });
});
```

---

## Deployment Architecture

### Docker Containerization
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
RUN npx prisma generate
EXPOSE 3000
CMD ["npm", "start"]
```

### Environment-Specific Configuration
- **Development**: Local PostgreSQL, debug logging
- **Staging**: Staging database, info logging
- **Production**: Production database, error logging, monitoring

### Deployment Options
1. **Docker Compose**: Single-server deployments
2. **Kubernetes**: Multi-server, auto-scaling
3. **Docker Swarm**: Alternative orchestration

---

## Summary Table

| Layer          | Responsibilities                              | Location          |
| -------------- | --------------------------------------------- | ----------------- |
| Controllers    | HTTP handling, request/response formatting    | src/controllers/  |
| Services       | Business logic, transactions, orchestration   | src/services/     |
| Middleware     | Auth, validation, error handling, logging     | src/middleware/   |
| Routes         | Endpoint definitions, middleware application  | src/routes/       |
| Database       | Schema, migrations, type-safe queries         | prisma/           |

---

## Related Documentation

- REST API Guidelines: `.cursor/rules/backend/backend-api-guideline.mdc`
- Coding Standards: `.cursor/rules/backend/javascript-coding-standards.mdc`
- Review Checklist: `.cursor/rules/backend/backend-review-checklist.mdc`

---

**Last Updated**: October 29, 2025
