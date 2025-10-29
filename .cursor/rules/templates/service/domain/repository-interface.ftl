package ${packageName}.repository;

import io.DoorSync.core.domain.Repository;
import io.DoorSync.core.domain.SupportsBatch;
import io.DoorSync.core.domain.SupportsHardDelete;
import io.DoorSync.core.domain.SupportsQuery;
import io.DoorSync.core.domain.SupportsSoftDelete;
import ${packageName}.model.${aggregateName};
import ${packageName}.model.${aggregateName}Id;

/**
 * Repository port for ${aggregateName} aggregate.
 * Minimal domain API; infrastructure provides tenant scoping and composition.
 */
public interface ${aggregateName}Repository
        extends Repository<${aggregateName}, ${aggregateName}Id>
        <#if supportsBatch?? && supportsBatch>
        , SupportsBatch<${aggregateName}, ${aggregateName}Id>
        </#if>
        <#if supportsSoftDelete?? && supportsSoftDelete>
        , SupportsSoftDelete<${aggregateName}Id>
        </#if>
        <#if supportsHardDelete?? && supportsHardDelete>
        , SupportsHardDelete<${aggregateName}Id>
        </#if>
        <#if supportsQuery?? && supportsQuery>
        , SupportsQuery<${aggregateName}>
        </#if>
{
}