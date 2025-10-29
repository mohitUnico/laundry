# {{serviceName}} Service API Documentation

This directory contains API documentation for the {{serviceName}} service.

## Overview

The API documentation is provided in two formats:

1. **OpenAPI Specification**: A standardized, language-agnostic description of the API
2. **Postman Collection**: A collection of ready-to-use API requests for testing and integration

## OpenAPI Specification

The [OpenAPI Specification](https://www.openapis.org/) (formerly known as Swagger) is located in the `openapi.yaml` file. This file describes:

- Available endpoints and operations
- Input/output parameters for each operation
- Authentication methods
- Contact information, terms of use, and other metadata

### Viewing the OpenAPI Specification

You can view and interact with the OpenAPI specification using:

1. **Swagger UI**: Import the `openapi.yaml` file into [Swagger Editor](https://editor.swagger.io/)
2. **Swagger UI Docker**: Run Swagger UI locally using Docker:
   ```
   docker run -p 8080:8080 -e SWAGGER_JSON=/foo/openapi.yaml -v $(pwd):/foo swaggerapi/swagger-ui
   ```
   Then visit http://localhost:8080 in your browser.

## Postman Collection

The Postman collection is located in the `{{serviceName}}.postman_collection.json` file. This collection includes:

- Organized API requests grouped by functionality
- Request parameters and authentication setup
- Pre-request scripts for environment setup
- Test scripts to validate responses

### Using the Postman Collection

To use the Postman collection:

1. **Import the collection**:
   - Open Postman
   - Click on "Import" in the top-left corner
   - Select the `{{serviceName}}.postman_collection.json` file

2. **Set up environment variables**:
   - Create a new environment in Postman
   - Add the following variables:
     - `base_url`: Base URL of your API (e.g., `http://localhost:8080` or API Gateway URL)
     - `api_version`: API version (default `v1`)
     - `jwt_token`: A valid JWT token for authentication
     - Optional: `correlation_id` (client-provided correlation id; generated if omitted)
     - Optional: `x_tenant_id` (header override permitted only for explicitly documented exceptions)

3. **Run requests**:
   - Select the imported environment
   - Navigate through the collection folders
   - Run individual requests or use the Collection Runner to run multiple requests

## Authentication

All API endpoints require authentication using a JWT token. The token should be provided as a Bearer token in the Authorization header.

```
Authorization: Bearer <your-jwt-token>
```

## Error Handling

The API uses standard HTTP status codes and provides detailed error responses in the following format:

```json
{
  "code": "ERROR_CODE",
  "message": "Human-readable error message",
  "details": { "...": "Additional error details if applicable" },
  "correlationId": "uuid echoed from X-Correlation-Id"
}
```

## Security and Tenant Resolution

- JWT Bearer authentication (Cognito). Tenant identity is resolved from the JWT claim configured by `DOORSYNC_TENANT_CLAIM` (default `tenantId`).
- Do not include `tenantId` or `userId` in request bodies; these are injected at the edge from `RequestContext`.

## Correlation ID

- Responses include `X-Correlation-Id` for tracing. You can provide your own via request header; otherwise one is generated and echoed back. The error envelope includes `correlationId`.

## Pagination

- Client-facing pagination uses an opaque, signed cursor. Requests accept `pageRequest.size` and optional `pageRequest.cursor`. Responses include `nextCursor`.

## Available Environments

| Environment | Base URL                                      | Description                  |
|-------------|-----------------------------------------------|------------------------------|
| Development | http://localhost:8080/api/v1                  | Local development environment |
| Test        | https://api-test.DoorSync.com/{{serviceName}}/v1  | Test environment             |
| UAT         | https://api-uat.DoorSync.com/{{serviceName}}/v1   | User acceptance testing      |
| Production  | https://api.DoorSync.com/{{serviceName}}/v1       | Production environment       |

## Additional Resources

- [{{serviceName}} Service Documentation](../README.md)
- libs/DoorSync-core/docs/Architecture.md
- libs/DoorSync-core/docs/guidelines/Exception_Handling_Guidelines.md
- libs/DoorSync-core/docs/guidelines/Tenant_Management_Architecture.md
- For a canonical example, see `apis/reference/docs/api/` (OpenAPI, Postman, README)