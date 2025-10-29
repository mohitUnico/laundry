package ${packageName}.handler.query;

import io.DoorSync.core.application.query.BaseQueryHandler;
import io.DoorSync.core.application.observability.AppLogger;
import io.DoorSync.core.application.observability.AppMetrics;
import io.DoorSync.core.interfaces.lambda.RequestContext;
import io.DoorSync.core.application.exception.NotFoundException;
import io.DoorSync.core.domain.Page;
import jakarta.validation.Validator;
import lombok.extern.slf4j.Slf4j;
import ${packageName}.dto.query.${queryName};
<#if hasResponse>
import ${packageName}.dto.response.${responseName};
</#if>
<#if hasMapper>
import ${packageName}.mapper.${mapperName};
</#if>
import ${packageName}.model.${aggregateName};
import ${packageName}.repository.${aggregateName}Repository;
import io.DoorSync.core.domain.query.Query;
import io.DoorSync.core.domain.query.Criteria;
import io.DoorSync.core.domain.query.Eq;
import io.DoorSync.core.domain.query.And;
import io.DoorSync.core.domain.query.BeginsWith;
<#if returnsList>
import java.util.List;
import java.util.stream.Collectors;
</#if>
import org.springframework.stereotype.Component;

/**
 * Query handler for ${queryName}.
 */
@Slf4j
@Component
public class ${className} extends BaseQueryHandler<${queryName}, <#if returnsList><#if isPaginated?? && isPaginated>Page<${responseName}><#else>List<${responseName}></#if><#else>${responseName}</#if>> {

    private final ${aggregateName}Repository repository;
    <#if hasMapper>
    private final ${mapperName} mapper;
    </#if>
    <#if additionalDependencies??>
    <#list additionalDependencies as dependency>
    private final ${dependency.type} ${dependency.name};
    </#list>
    </#if>

    public ${className}(
            Validator validator,
            AppLogger appLogger,
            AppMetrics appMetrics,
            ${aggregateName}Repository repository<#if hasMapper>,
            ${mapperName} mapper</#if><#if additionalDependencies??><#list additionalDependencies as dependency>,
            ${dependency.type} ${dependency.name}</#list></#if>) {
        super(validator, appLogger, appMetrics);
        this.repository = repository;
        <#if hasMapper>
        this.mapper = mapper;
        </#if>
        <#if additionalDependencies??>
        <#list additionalDependencies as dependency>
        this.${dependency.name} = ${dependency.name};
        </#list>
        </#if>
    }

    @Override
    protected <#if returnsList><#if isPaginated?? && isPaginated>Page<${responseName}><#else>List<${responseName}></#if><#else>${responseName}</#if> executeQuery(${queryName} query, RequestContext requestContext) {
        log.debug("Handling ${queryName}: {}", query);

        <#if hasImplementation?? && hasImplementation>
        ${implementationCode}
        <#else>
        <#if returnsList>
        <#if isPaginated?? && isPaginated>
        // Default guidance: when paginated, either list-all or filter with Criteria
        Criteria criteria = null; // Build from non-null filters if applicable
        return mapper.toPage(repository.search(Query.of(criteria, query.getPageRequest())));
        <#else>
        // Default guidance: return empty list for non-paginated until implemented
        return List.of();
        </#if>
        <#else>
        // Retrieve single item
        ${aggregateName} ${aggregateInstance} = repository.findById(<#if idAccessorExpr??>${idAccessorExpr}<#else>query.getId()</#if>)
            .orElseThrow(() -> new NotFoundException("${aggregateName} not found with ID: " + (<#if idAccessorExpr??>${idAccessorExpr}<#else>query.getId()</#if>)));
        return <#if hasMapper>mapper.toResponse(${aggregateInstance})<#else>new ${responseName}(${aggregateInstance})</#if>;
        </#if>
        </#if>
    }
}