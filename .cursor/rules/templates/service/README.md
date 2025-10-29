# Service Templates

This directory contains FreeMarker templates for generating Java application layer components in DoorSync microservices.

## Template Overview

### Application Layer Templates

- **application-exception.ftl**: Generates custom exception classes extending DoorSync-core base exceptions
- **command-dto.ftl**: Generates command DTOs extending AbstractCommandDTO
- **query-dto.ftl**: Generates query DTOs extending AbstractQueryDTO
- **response-dto.ftl**: Generates immutable response DTOs
- **command-handler.ftl**: Generates command handlers extending BaseCommandHandler
- **query-handler.ftl**: Generates query handlers extending BaseQueryHandler
- **mapper.ftl**: Generates mapper interfaces for domain-to-DTO conversions
- **validator.ftl**: Generates Jakarta Bean Validation custom validators
- **domain-service-impl.ftl**: **NEW** - Generates domain service implementations that implement interfaces from domain module
- **process-manager.ftl**: Generates process managers for complex workflows
- **application-service.ftl**: Generates application services for orchestration

## DDD Module Dependencies

DoorSync microservices follow a strict Hexagonal Architecture with Domain-Driven Design principles. The dependency structure is carefully designed to maintain proper separation of concerns and leverage Spring Boot's IoC container.

### Dependency Structure

#### Compile-Time Dependencies

- **Domain Module**: No dependencies on other modules
  - Contains domain models, repository interfaces, domain events, and domain service interfaces
  - Depends only on DoorSync-core and essential libraries

- **Application Module**: Depends only on Domain module
  - Contains use cases, command/query handlers, DTOs, and service implementations
  - Uses interfaces defined in the domain layer

- **Infrastructure Module**: Depends only on Domain module
  - Implements repository interfaces and other abstractions defined in domain layer
  - Should NOT depend on application module (avoid circular dependencies)

- **Interface Module**: Depends on Application, Infrastructure, and Domain modules
  - Depends on application for use cases and business logic
  - Depends on infrastructure for runtime wiring by Spring IoC container
  - Depends on domain for direct access to domain models (design decision)

#### Runtime Dependencies (Spring IoC)

- Spring's IoC container dynamically injects concrete implementations from the Infrastructure module into beans defined in the Application module
- This happens without explicit compile-time coupling between Application and Infrastructure modules
- The Interface module serves as the composition root that brings all layers together at runtime

### Dependency Flow Diagram

```
┌───────────┐     ┌───────────┐     ┌───────────┐
│           │     │           │     │           │
│  Domain   │◄────┤Application│     │Infrastructure│
│           │     │           │     │           │
└───────────┘     └───────────┘     └───────────┘
      ▲                 ▲                 │
      │                 │                 │
      │                 │                 │
      │           ┌───────────┐           │
      │           │           │           │
      └───────────┤ Interface │◄──────────┘
                  │           │
                  └───────────┘
```

## Core Patterns and Conventions

### DTO Inheritance

All DTOs must extend DoorSync-core base classes:

```java
// Command DTOs
public class CreateUserCommand extends AbstractCommandDTO {
    // Inherits: tenantId, userId, correlationId
}

// Query DTOs  
public class GetUserByIdQuery extends AbstractQueryDTO {
    // Inherits: tenantId, userId, correlationId, page, size, sortField, sortDirection
}
```

### Validation Patterns

#### 1. Jakarta Bean Validation (Field-Level)

Use standard Jakarta validation annotations for field-level constraints:

```java
public class CreateUserCommand extends AbstractCommandDTO {
    @NotBlank(message = "Email cannot be blank")
    @Email(message = "Email must be valid")
    private String email;
    
    @NotNull(message = "Age cannot be null")
    @Min(value = 18, message = "Age must be at least 18")
    private Integer age;
}
```

#### 2. Custom Business Rule Validation

For complex business rules, implement the Validateable interface:

```java
import io.DoorSync.core.application.validation.Validateable;

public class CreateUserCommand extends AbstractCommandDTO implements Validateable {
    private String email;
    private String department;
    
    @Override
    public void validate() throws ValidationException {
        // Custom business rule: Admin emails must end with @admin.company.com
        if ("ADMIN".equals(department) && !email.endsWith("@admin.company.com")) {
            throw new ValidationException(
                "Admin users must have admin email domain", 
                ErrorCode.VALIDATION_BUSINESS_RULE
            );
        }
    }
}
```

#### 3. Custom Jakarta Validators

For reusable field validation logic, create custom annotations:

```java
@ValidEmail // Custom validator annotation
@NotBlank
private String email;
```

### Pagination Patterns

#### Query DTOs

Pagination fields are inherited from AbstractQueryDTO:

```java
public class SearchUsersQuery extends AbstractQueryDTO {
    private String searchTerm;
    
    // page, size, sortField, sortDirection inherited
    // Use isPaginated() to check if pagination requested
}
```

#### Query Handlers

Handle pagination in the executeQuery method:

```java
@Override
protected PageResponse<UserResponse> executeQuery(SearchUsersQuery query, RequestContext requestContext) {
    if (query.isPaginated()) {
        // Create PageRequest
        PageRequest pageRequest = PageRequest.builder()
            .page(query.getPageOrDefault())
            .size(query.getSizeOrDefault())
            .build();
            
        // Get paginated results
        List<User> users = repository.findBySearchTerm(query.getSearchTerm(), pageRequest);
        long totalCount = repository.countBySearchTerm(query.getSearchTerm());
        
        // Map and return PageResponse
        List<UserResponse> items = users.stream()
            .map(mapper::toResponse)
            .collect(Collectors.toList());
            
        return PageResponse.of(items, totalCount, pageRequest);
    } else {
        // Handle non-paginated request
        List<User> users = repository.findBySearchTerm(query.getSearchTerm());
        // ... return as PageResponse or List based on return type
    }
}
```

### Exception Handling

Use DoorSync-core exception hierarchy:

```java
// Not found scenarios
throw new UserNotFoundException("User not found with ID: " + userId);

// Validation failures  
throw new ValidationException("Email already exists", ErrorCode.VALIDATION_DUPLICATE);

// Business rule violations
throw new ApplicationException("Operation not allowed in current state");

// Authorization issues
throw new AuthorizationException("Insufficient permissions");
```

### Domain Service Implementation Patterns

Domain services implement business operations that don't naturally fit within a single aggregate:

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class UserDomainServiceImpl implements UserDomainService {
    
    private final UserRepository userRepository;
    private final DomainEventPublisher eventPublisher;
    
    @Override
    @Transactional
    public User performComplexOperation(User user, String additionalData) {
        log.debug("Executing complex operation for user: {} with tenant: {}", 
                 user.getIdAsString(), TenantContext.getTenantId());
        
        // Input validation
        Assert.notNull(user, "User cannot be null");
        Assert.hasText(additionalData, "Additional data required");
        
        // Business rule validation using ValidationResult
        ValidationResult validationResult = ValidationResult.success();
        
        if (additionalData.length() < 5) {
            validationResult.addError("additionalData", "Must be at least 5 characters");
        }
        
        validationResult.throwIfInvalid();
        
        // Perform domain operation
        user.performComplexOperation(additionalData);
        
        // Save and return
        User updatedUser = userRepository.save(user);
        
        log.info("Complex operation completed for user: {}", updatedUser.getIdAsString());
        return updatedUser;
    }
}
```

### Handler Patterns

#### Command Handlers

```java
@Component
public class CreateUserCommandHandler extends BaseCommandHandler<CreateUserCommand, UserCreatedResponse> {
    
    public CreateUserCommandHandler(
            Validator validator,
            DomainEventDispatcher eventDispatcher,
            MeterRegistry meterRegistry,
            UserRepository repository,
            UserMapper mapper) {
        super(validator, eventDispatcher, meterRegistry);
        // Store dependencies
    }
    
    @Override
    protected UserCreatedResponse executeCommand(CreateUserCommand command, RequestContext requestContext) {
        // Implementation with RequestContext
    }
    
    @Override  
    protected UserCreatedResponse executeCommand(CreateUserCommand command) {
        // Legacy implementation without RequestContext
    }
}
```

#### Query Handlers

```java
@Component
public class GetUserByIdQueryHandler extends BaseQueryHandler<GetUserByIdQuery, UserResponse> {
    
    public GetUserByIdQueryHandler(
            Validator validator,
            MeterRegistry meterRegistry,
            UserRepository repository,
            UserMapper mapper) {
        super(validator, meterRegistry);
        // Store dependencies
    }
    
    @Override
    protected UserResponse executeQuery(GetUserByIdQuery query, RequestContext requestContext) {
        // Implementation with RequestContext
    }
    
    @Override
    protected UserResponse executeQuery(GetUserByIdQuery query) {
        // Legacy implementation without RequestContext  
    }
}
```

## Template Usage

Templates are used by the create-application-module command. Each template expects specific parameters:

### Command DTO Template Parameters

- `packageName`: Base package for the DTO
- `className`: Command class name
- `commandDescription`: Purpose description
- `properties`: Array of field definitions
- `additionalImports`: Extra import statements

### Query DTO Template Parameters

- `packageName`: Base package for the DTO
- `className`: Query class name  
- `queryDescription`: Purpose description
- `properties`: Array of field definitions
- `additionalImports`: Extra import statements

### Handler Template Parameters

- `packageName`: Base package
- `className`: Handler class name
- `commandName`/`queryName`: DTO class name
- `aggregateName`: Domain entity name
- `responseName`: Response DTO name
- `hasMapper`: Whether to inject mapper
- `mapperName`: Mapper class name

### Domain Service Implementation Template Parameters

- `packageName`: Base package for the implementation
- `serviceName`: Domain service interface name
- `interfacePackage`: Package path for domain service interface
- `aggregateName`: Primary entity the service operates on
- `aggregateInstanceLower`: camelCase version of entity name
- `hasRepository`: Whether service needs repository access (usually true)
- `hasEventPublisher`: Whether service publishes domain events (usually true)
- `operations`: Array of operations from domain service interface
- `additionalDependencies`: Array of extra dependencies needed

## Best Practices

1. **Always extend base classes**: Use AbstractCommandDTO, AbstractQueryDTO, BaseCommandHandler, BaseQueryHandler
2. **Use @SuperBuilder**: For DTOs extending base classes, use @SuperBuilder and @NoArgsConstructor
3. **Implement Validateable**: Only when custom business rules are needed beyond Jakarta validation (use io.DoorSync.core.application.validation.Validateable)
4. **Handle pagination**: Use PageRequest/PageResponse for paginated queries - all list queries return PageResponse<T>
5. **Tenant isolation**: Rely on RequestContext and repository automatic handling
6. **Event handling**: Use DomainEventDispatcher in command handlers
7. **Logging**: Include appropriate debug/info logging in handlers
8. **Exception handling**: Use specific exception types from DoorSync-core hierarchy
9. **Domain service implementations**: Implement ALL methods from domain service interfaces
10. **Business rule validation**: Use ValidationResult for complex validation in domain services
11. **Transaction boundaries**: Use @Transactional on domain service methods that modify data
12. **Repository methods**: Use findAllPaginated() and count() for paginated queries - these are now available in base Repository interface
13. **Mapper consistency**: Use toResponse() as primary method, toDto() as alias for backward compatibility

## Validation Decision Tree

```
Field validation needed?
├── Simple constraint (NotNull, Email, Size)?
│   └── Use Jakarta Bean Validation annotations
├── Reusable business rule?
│   └── Create custom Jakarta validator with @Constraint
└── Complex business rule involving multiple fields/external data?
    └── Implement io.DoorSync.core.application.validation.Validateable interface in DTO
```