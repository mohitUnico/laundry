package ${packageName}.infrastructure.translator;

import ${packageName}.domain.${entityName};
import io.DoorSync.core.infrastructure.persistence.QueryTranslator;
import io.DoorSync.core.domain.query.*;
import org.springframework.stereotype.Component;

/**
 * Translates the storage-agnostic Query DSL into DynamoDB-specific query definitions
 * for ${entityName}. Must enforce no-scan guarantee by failing fast when
 * a given criteria cannot be served by declared access patterns.
 */
@Component
public final class ${className} implements QueryTranslator<${entityName}, Object> {

    @Override
    public Object translate(String tenantId, Query query) {
        // TODO: Implement translation based on declared access patterns for ${entityName}
        // Example outline:
        // - Recognize supported criteria (Eq, BeginsWith, Between) on whitelisted fields
        // - Build DynamoQuery with PK/SK or GSI keys; include tenant prefix in PK
        // - Throw IllegalArgumentException for unsupported patterns to enforce no-scan policy
        throw new io.DoorSync.core.domain.RepositoryException(
            io.DoorSync.core.domain.RepositoryException.Code.VALIDATION,
            "No access pattern declared for provided query on ${entityName}",
            null
        );
    }
}

