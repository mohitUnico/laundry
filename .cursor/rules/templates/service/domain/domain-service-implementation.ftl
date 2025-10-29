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
 * Default domain service implementation for ${aggregateName}.
 * Depends only on domain ports and types. No framework annotations here.
 */
public final class Default${aggregateName}Service implements ${aggregateName}Service {

	private final ${aggregateName}Repository repository;

	public Default${aggregateName}Service(${aggregateName}Repository repository) {
		this.repository = repository;
	}

	@Override
	public ${aggregateName} create(${aggregateName} aggregate, Instant occurredAt) {
		aggregate.recordCreatedEvent(occurredAt);
		return repository.save(aggregate);
	}

	@Override
	public ${aggregateName} update(${aggregateName} aggregate) {
		aggregate.recordUpdatedEvent(Instant.now());
		return repository.save(aggregate);
	}

	@Override
	public void delete(${aggregateName}Id id, String updatedBy) {
	<#if deleteStrategy?? && deleteStrategy == "viaAggregate">
		repository.findById(id).ifPresent(aggregate -> {
			aggregate.markDeleted(Instant.now(), updatedBy);
			repository.save(aggregate);
		});
	<#else>
		<#if supportsSoftDelete?? && supportsSoftDelete>
		repository.softDeleteById(id);
		<#elseif supportsHardDelete?? && supportsHardDelete>
		repository.hardDeleteById(id);
		<#else>
		throw new UnsupportedOperationException("Delete not supported by repository capabilities");
		</#if>
	</#if>
	}

	@Override
	public Optional<${aggregateName}> get(${aggregateName}Id id) {
		return repository.findById(id);
	}

	<#if supportsQuery?? && supportsQuery>
	@Override
	public Page<${aggregateName}> search(Query query) {
		return repository.query(query);
	}
	</#if>
}


