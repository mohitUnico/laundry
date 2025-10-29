package ${packageName}.infrastructure.factory;

import ${packageName}.domain.${entityName};
import ${packageName}.domain.repository.${entityName}Repository;
import ${packageName}.infrastructure.model.${entityName}Model;
import ${packageName}.infrastructure.mapper.${entityName}ModelMapper;
import ${packageName}.infrastructure.repository.${entityName}DynamoRepository;
import io.DoorSync.core.infrastructure.persistence.TableOperations;
import io.DoorSync.core.infrastructure.persistence.QueryOperations;
import io.DoorSync.core.infrastructure.persistence.QueryResult;
import io.DoorSync.core.infrastructure.persistence.QueryTranslator;
import io.DoorSync.core.infrastructure.persistence.factory.RepositoryFactory;
import io.DoorSync.core.domain.event.DomainEventPublisher;

/**
 * Factory for creating tenant-scoped ${entityName}Repository instances.
 */
public final class ${className} implements RepositoryFactory<${entityName}Repository> {

    private final TableOperations<${entityName}Model, ${idType}> tableOps;
    private final ${entityName}ModelMapper mapper;
    private final QueryTranslator<${entityName}, Object> translator;
    private final QueryOperations<Object, QueryResult<${entityName}>> queryOps;
    private final DomainEventPublisher eventPublisher;

    public ${className}(
        TableOperations<${entityName}Model, ${idType}> tableOps,
        ${entityName}ModelMapper mapper,
        QueryTranslator<${entityName}, Object> translator,
        QueryOperations<Object, QueryResult<${entityName}>> queryOps,
        DomainEventPublisher eventPublisher
    ) {
        this.tableOps = tableOps;
        this.mapper = mapper;
        this.translator = translator;
        this.queryOps = queryOps;
        this.eventPublisher = eventPublisher;
    }

    @Override
    public ${entityName}Repository createRepository(software.amazon.awssdk.enhanced.dynamodb.DynamoDbEnhancedClient client, String tenantId) {
        return new ${entityName}DynamoRepository(
            tenantId,
            tableOps,
            mapper,
            translator,
            queryOps,
            eventPublisher
        );
    }
}

