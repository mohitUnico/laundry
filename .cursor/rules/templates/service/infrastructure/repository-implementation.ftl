package ${packageName}.infrastructure.repository;

import ${packageName}.domain.${entityName};
import ${packageName}.domain.repository.${entityName}Repository;
import ${packageName}.infrastructure.model.${entityName}Model;
import io.DoorSync.core.infrastructure.persistence.ModelMapper;
import io.DoorSync.core.infrastructure.persistence.TableOperations;
import io.DoorSync.core.infrastructure.persistence.QueryOperations;
import io.DoorSync.core.infrastructure.persistence.QueryResult;
import io.DoorSync.core.infrastructure.persistence.QueryTranslator;
import io.DoorSync.core.domain.Repository;
import io.DoorSync.core.domain.event.DomainEventPublisher;
import io.DoorSync.core.infrastructure.exception.InfrastructureException;
import io.DoorSync.core.domain.Page;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Optional;

/**
 * Composition-first DynamoDB repository implementation for ${entityName}.
 * Tenant scoping is achieved via constructor injection of tenantId.
 * Translates the storage-agnostic Query DSL to DynamoDB queries using a translator.
 */
@Slf4j
@Repository
public final class ${className} implements ${entityName}Repository {

    private final String tenantId;
    private final TableOperations<${entityName}Model, ${idType}> table;
    private final ModelMapper<${entityName}Model, ${entityName}> mapper;
    private final QueryTranslator<${entityName}, Object> translator;
    private final QueryOperations<Object, QueryResult<${entityName}>> queryOps;
    private final DomainEventPublisher eventPublisher;

    public ${className}(
        String tenantId,
        TableOperations<${entityName}Model, ${idType}> table,
        ModelMapper<${entityName}Model, ${entityName}> mapper,
        QueryTranslator<${entityName}, Object> translator,
        QueryOperations<Object, QueryResult<${entityName}>> queryOps,
        DomainEventPublisher eventPublisher
    ) {
        this.tenantId = tenantId;
        this.table = table;
        this.mapper = mapper;
        this.translator = translator;
        this.queryOps = queryOps;
        this.eventPublisher = eventPublisher;
    }

    @Override
    public Optional<${entityName}> findById(${idType} id) {
        try {
            return table.load(tenantId, id).map(mapper::toAggregate);
        } catch (Exception e) {
            log.error("findById failed for {} tenant {}", id, tenantId, e);
            throw new InfrastructureException("Failed to load ${entityName}", e);
        }
    }

    @Override
    public ${entityName} save(${entityName} aggregate) {
        try {
            ${entityName}Model model = mapper.toModel(aggregate);
            long expected = model.getVersion();
            boolean create = expected == 0;
            ${entityName}Model persisted = table.put(tenantId, model, expected, create);
            ${entityName} saved = mapper.toAggregate(persisted);
            <#if useEventPublishing?? && useEventPublishing>
            // Publish domain events after successful persistence (minimal profile)
            for (var event : aggregate.pullDomainEvents()) {
                try { eventPublisher.publish(event); } catch (Exception ex) { log.error("event publish failed", ex); }
            }
            </#if>
            return saved;
        } catch (Exception e) {
            log.error("save failed for aggregate {} tenant {}", aggregate, tenantId, e);
            throw new InfrastructureException("Failed to save ${entityName}", e);
        }
    }

    /**
     * Example query method using the storage-agnostic DSL. Adjust to your repository interface.
     */
    public Page<${entityName}> query(io.DoorSync.core.domain.query.Query q) {
        try {
            Object translated = translator.translate(tenantId, q);
            QueryResult<${entityName}> result = queryOps.execute(translated);
            String nextToken = result.lastEvaluatedKey() == null ? null : encodeInternalToken(result.lastEvaluatedKey());
            return new Page<>(result.items(), nextToken);
        } catch (io.DoorSync.core.domain.RepositoryException validation) {
            // Translator enforces no-scan guarantee and access pattern validation
            throw validation;
        } catch (Exception e) {
            log.error("query failed for tenant {}", tenantId, e);
            throw new InfrastructureException("Failed to execute query for ${entityName}", e);
        }
    }

    private String encodeInternalToken(Object storeKey) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(String.valueOf(storeKey).getBytes(StandardCharsets.UTF_8));
    }
}