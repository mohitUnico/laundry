package ${packageName}.service;

import java.time.Instant;
import java.util.Optional;

import ${packageName}.model.${aggregateName};
import ${packageName}.model.${aggregateName}Id;
import ${packageName}.repository.${aggregateName}Repository;
<#if supportsQuery?? && supportsQuery>
import io.DoorSync.core.domain.Page;
import io.DoorSync.core.domain.query.Query;
</#if>

/**
 * Domain service interface for ${aggregateName} business operations.
 * Pure domain contract: framework-agnostic, tenant-agnostic.
 */
public interface ${aggregateName}Service {

	/** Create a new aggregate and record a created event with the provided timestamp. */
	${aggregateName} create(${aggregateName} aggregate, Instant occurredAt);

	/** Update an existing aggregate while preserving invariants. */
	${aggregateName} update(${aggregateName} aggregate);

	/** Delete aggregate by id. Semantics depend on repository capabilities or aggregate behavior. */
	void delete(${aggregateName}Id id, String updatedBy);

	/** Retrieve an aggregate by id. */
	Optional<${aggregateName}> get(${aggregateName}Id id);

	<#if supportsQuery?? && supportsQuery>
	/** Search aggregates using the domain Query DSL. */
	Page<${aggregateName}> search(Query query);
	</#if>
}


