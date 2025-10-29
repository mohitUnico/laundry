# Domain Module Templates (aligned with new `DoorSync-core`)

This directory provides FreeMarker templates to scaffold pure domain code for microservices. The generated code follows the greenfield architecture in `libs/DoorSync-core/docs/Architecture.md` and `layers/Domain_Layer.md`.

## Included templates

- `aggregate-id.ftl`: Strongly-typed identifier value object for an aggregate (e.g., `OrderId`).
- `aggregate-root.ftl`: Minimal aggregate root skeleton extending `AggregateRoot<ID>`.
- `repository-interface.ftl`: Domain repository port with optional capability interfaces.
- `domain-event.ftl`: Minimal domain event extending `AbstractDomainEvent` with `(aggregateId, occurredAt)`. Event classes MUST end with suffix `Event` (e.g., `UserCreatedEvent`) to align with publisher/consumer conventions.
- `value-object.ftl`: Immutable value object extending `BaseValueObject<T>`.
- `enum.ftl`: Domain enumeration with Optional-based lookup helpers.
- `pom.xml.ftl`: Domain module POM including `DoorSync-core` and test deps.
- `domain-service-interface.ftl`: Domain service interface for aggregate-specific domain logic.
- `domain-service-implementation.ftl`: Default domain service implementation depending only on domain ports.

## Removed templates (not compliant with new architecture)

- Framework-annotated services (annotations belong in application/infrastructure)
- Domain-specific exception hierarchies referencing application layer
- Infrastructure exceptions under domain
- Versioned event scaffolding (can be added later case-by-case)
- In-memory `Specification` for production (tests may define their own helpers)

## Key alignment points

- Aggregates: extend `AggregateRoot<ID>`; call `super(id)` in constructor; no tenant/audit/transport concerns.
- IDs: value objects for type-safety (e.g., `UserId`), extend `BaseValueObject`.
- Events: extend `AbstractDomainEvent`; include only `aggregateId` and `occurredAt` plus domain attributes; no tenant/correlation.
- Repositories: minimal `Repository<T, ID>` plus opt-in `SupportsSoftDelete`, `SupportsHardDelete`, `SupportsBatch`, `SupportsQuery`.
- Validation: use `io.DoorSync.core.domain.validation.ValidationResult` or simple guards; no framework imports.

See `libs/DoorSync-core/docs/guidelines/Repository_Design.md` for repository and query DSL guidance.